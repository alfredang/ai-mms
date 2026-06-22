<?php
/** Class Reschedule handler — reschedule/index/post. Honeypot + Turnstile. */
class MMD_Reschedule_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'class-reschedule.html';
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
            Mage::getModel('mmd_reschedule/lead')->setStoreId(Mage::app()->getStore()->getId())->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)->setEmail($email)->setTelephone((string) ($post['telephone'] ?? ''))
                ->setCourse((string) ($post['course'] ?? ''))->setCurrentDate((string) ($post['current_date'] ?? ''))->setPreferredDate((string) ($post['preferred_date'] ?? ''))
                ->setMessage($comment)->setSource('class-reschedule')->setIp($turnstile->getRemoteIp())
                ->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))->setStatus('new')->save();
            Mage::helper('mmd_leadmail')->notify('Class Reschedule Request', $name, $email, (string) ($post['telephone'] ?? ''), array(
                array('Course Title / Code', (string) ($post['course'] ?? '')),
                array('Current Class Date', (string) ($post['current_date'] ?? '')),
                array('Preferred New Date', (string) ($post['preferred_date'] ?? '')),
            ), $comment);
            $session->addSuccess($this->__('Your reschedule request has been submitted. Our team will confirm your new class date.'));
        } catch (Mage_Core_Exception $e) { $session->addError($e->getMessage()); }
        catch (Exception $e) { Mage::logException($e); $session->addError($this->__('Unable to submit your request. Please try again later.')); }
        $this->_redirect(self::RETURN_URL);
    }
}
