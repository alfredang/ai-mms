<?php
/** Course Feedback handler — coursefeedback/index/post. Mirrors the LMS class
 *  feedback questions. Honeypot + Turnstile. */
class MMD_CourseFeedback_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'course-feedback.html';
    public function postAction()
    {
        $session = Mage::getSingleton('core/session');
        if (empty($_SERVER['HTTP_REFERER']) || strpos((string) $_SERVER['HTTP_REFERER'], (string) $_SERVER['HTTP_HOST']) === false) { $this->_redirect(self::RETURN_URL); return; }
        $post = $this->getRequest()->getPost();
        if (!$post) { $this->_redirect(self::RETURN_URL); return; }
        try {
            if (!empty($post['hideit']) && trim((string) $post['hideit']) !== '') { Mage::throwException($this->__('Unable to submit your request. Please try again later.')); }
            $name = trim((string) ($post['name'] ?? '')); $email = trim((string) ($post['email'] ?? '')); $comment = trim((string) ($post['comment'] ?? ''));
            if (!Zend_Validate::is($name, 'NotEmpty') || !Zend_Validate::is($email, 'EmailAddress')) { Mage::throwException($this->__('Please provide your name and a valid email address.')); }
            $turnstile = Mage::helper('magentocaptcha/turnstile');
            if ($turnstile->isConfigured()) { $r = $turnstile->verify((string) ($post[MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD] ?? ''), $turnstile->getRemoteIp()); if (empty($r['ok'])) { Mage::throwException($this->__('Spam check failed. Please refresh the page and try again.')); } }
            $rO = (int) ($post['rating_objectives'] ?? 0) ?: null; $rT = (int) ($post['rating_trainer'] ?? 0) ?: null; $rE = (int) ($post['rating_environment'] ?? 0) ?: null;
            Mage::getModel('mmd_coursefeedback/lead')->setStoreId(Mage::app()->getStore()->getId())->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)->setEmail($email)->setTelephone((string) ($post['telephone'] ?? ''))
                ->setCourse((string) ($post['course'] ?? ''))->setCourseCode((string) ($post['course_code'] ?? ''))->setTrainer((string) ($post['trainer'] ?? ''))
                ->setClassStartDate((string) ($post['class_start_date'] ?? ''))->setClassEndDate((string) ($post['class_end_date'] ?? ''))
                ->setRatingObjectives($rO)->setRatingTrainer($rT)->setRatingEnvironment($rE)
                ->setMessage($comment)->setSource('course-feedback')->setIp($turnstile->getRemoteIp())
                ->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))->setStatus('new')->save();
            Mage::helper('mmd_leadmail')->notify('Course Feedback', $name, $email, (string) ($post['telephone'] ?? ''), array(
                array('Course Title', (string) ($post['course'] ?? '')),
                array('Course Code', (string) ($post['course_code'] ?? '')),
                array('Trainer', (string) ($post['trainer'] ?? '')),
                array('Class Dates', trim(((string) ($post['class_start_date'] ?? '')) . ' - ' . ((string) ($post['class_end_date'] ?? '')), ' -')),
                array('Met learning objectives', $rO ? $rO . ' / 5' : ''),
                array("Trainer's knowledge", $rT ? $rT . ' / 5' : ''),
                array('Training environment', $rE ? $rE . ' / 5' : ''),
            ), $comment);
            $session->addSuccess($this->__('Thank you for your submission. We will respond in 7 working days. If you do not receive any response from us, please call our office hotline +65 6100 0613 for further assistance.'));
        } catch (Mage_Core_Exception $e) { $session->addError($e->getMessage()); }
        catch (Exception $e) { Mage::logException($e); $session->addError($this->__('Unable to submit your request. Please try again later.')); }
        $this->_redirect(self::RETURN_URL);
    }
}
