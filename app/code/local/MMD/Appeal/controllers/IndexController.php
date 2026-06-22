<?php
/** Assessment Appeal handler — appeal/index/post. Honeypot + Turnstile. */
class MMD_Appeal_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'assessment-appeal-form.html';
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
            Mage::getModel('mmd_appeal/lead')->setStoreId(Mage::app()->getStore()->getId())->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)->setEmail($email)->setTelephone((string) ($post['telephone'] ?? ''))
                ->setCourse((string) ($post['course'] ?? ''))->setAssessmentDate((string) ($post['assessment_date'] ?? ''))
                ->setMessage($comment)->setSource('assessment-appeal')->setIp($turnstile->getRemoteIp())
                ->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))->setStatus('new')->save();
            $this->_notify($post, $name, $email);
            $session->addSuccess($this->__('Your assessment appeal has been submitted. Our team will review and respond to you.'));
        } catch (Mage_Core_Exception $e) { $session->addError($e->getMessage()); }
        catch (Exception $e) { Mage::logException($e); $session->addError($this->__('Unable to submit your request. Please try again later.')); }
        $this->_redirect(self::RETURN_URL);
    }
    protected function _notify($post, $name, $email)
    {
        try {
            $comment = "ASSESSMENT APPEAL\nCourse: " . ($post['course'] ?? '') . "\nAssessment Date: " . ($post['assessment_date'] ?? '') . "\nPhone: " . ($post['telephone'] ?? '') . "\n\n" . ($post['comment'] ?? '');
            $data = new Varien_Object(array('name' => $name, 'email' => $email, 'telephone' => (string)($post['telephone'] ?? ''), 'comment' => $comment));
            Mage::getModel('core/email_template')->setDesignConfig(array('area' => 'frontend'))->setReplyTo($email)
                ->sendTransactional(Mage::getStoreConfig('contacts/email/email_template'), Mage::getStoreConfig('contacts/email/sender_email_identity'), Mage::helper('mmd_appeal')->getRecipients(), null, array('data' => $data));
        } catch (Exception $e) { Mage::logException($e); }
    }
}
