<?php
/** Class Reschedule handler — reschedule/index/post. Honeypot + Turnstile.
 *  Learner identified by Name + NRIC; Email + Phone mandatory. Notification goes
 *  to sales@ + angss@ (To), CC angch@ + tansc@. */
class MMD_Reschedule_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'class-reschedule.html';
    const EXTRA_TO   = 'angss@tertiaryinfotech.com';

    public function postAction()
    {
        $session = Mage::getSingleton('core/session');
        if (empty($_SERVER['HTTP_REFERER']) || strpos((string) $_SERVER['HTTP_REFERER'], (string) $_SERVER['HTTP_HOST']) === false) { $this->_redirect(self::RETURN_URL); return; }
        $post = $this->getRequest()->getPost();
        if (!$post) { $this->_redirect(self::RETURN_URL); return; }
        try {
            if (!empty($post['hideit']) && trim((string) $post['hideit']) !== '') { Mage::throwException($this->__('Unable to submit your request. Please try again later.')); }
            $name        = trim((string) ($post['name'] ?? ''));
            $nric        = trim((string) ($post['nric'] ?? ''));
            $email       = trim((string) ($post['email'] ?? ''));
            $telephone   = trim((string) ($post['telephone'] ?? ''));
            $course      = trim((string) ($post['course'] ?? ''));
            $courseCode  = trim((string) ($post['course_code'] ?? ''));
            $startDate   = trim((string) ($post['current_date'] ?? ''));
            $nextDate    = trim((string) ($post['preferred_date'] ?? ''));
            $comment     = trim((string) ($post['comment'] ?? ''));
            if (!Zend_Validate::is($name, 'NotEmpty') || !Zend_Validate::is($nric, 'NotEmpty')
                || !Zend_Validate::is($email, 'EmailAddress') || !Zend_Validate::is($telephone, 'NotEmpty')
                || !Zend_Validate::is($course, 'NotEmpty') || !Zend_Validate::is($courseCode, 'NotEmpty')
                || !Zend_Validate::is($startDate, 'NotEmpty')) {
                Mage::throwException($this->__('Please complete all required fields.'));
            }
            $turnstile = Mage::helper('magentocaptcha/turnstile');
            if ($turnstile->isConfigured()) { $r = $turnstile->verify((string) ($post[MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD] ?? ''), $turnstile->getRemoteIp()); if (empty($r['ok'])) { Mage::throwException($this->__('Spam check failed. Please refresh the page and try again.')); } }
            $lead = Mage::getModel('mmd_reschedule/lead')->setStoreId(Mage::app()->getStore()->getId())->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)->setNric($nric)->setEmail($email)->setTelephone($telephone)
                ->setCourse($course)->setCourseCode($courseCode)->setCourseStartDate($startDate)->setNextCourseStartDate($nextDate)
                ->setMessage($comment)->setSource('class-reschedule')->setIp($turnstile->getRemoteIp())
                ->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))->setStatus('new')->save();
            Mage::helper('mmd_leadmail')->notify('Class Reschedule Request', $name, $email, $telephone, array(
                array('NRIC', $nric),
                array('Course Title', $course),
                array('Course Code', $courseCode),
                array('Course Start Date', $startDate),
                array('Next Course Start Date', $nextDate),
            ), $comment, array(self::EXTRA_TO));
            $session->addSuccess($this->__('Thank you for your submission. We will respond in 7 working days. If you do not receive any response from us, please call our office hotline +65 6100 0613 for further assistance.'));
            try {
                Mage::helper('mmd_reschedule/googleCalendar')->syncRescheduleLead($lead);
            } catch (Exception $gcalEx) {
                Mage::logException($gcalEx);
                $lead->setGcalStatus('error')->setGcalError(substr($gcalEx->getMessage(), 0, 65535))->save();
            }
        } catch (Mage_Core_Exception $e) { $session->addError($e->getMessage()); }
        catch (Exception $e) { Mage::logException($e); $session->addError($this->__('Unable to submit your request. Please try again later.')); }
        $this->_redirect(self::RETURN_URL);
    }
}
