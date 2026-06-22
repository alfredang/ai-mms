<?php
/** Refund Request handler — refund/index/post. Honeypot + Turnstile. */
class MMD_Refund_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'refund-request.html';
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
            Mage::getModel('mmd_refund/lead')->setStoreId(Mage::app()->getStore()->getId())->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)->setEmail($email)->setTelephone((string) ($post['telephone'] ?? ''))
                ->setCourse((string) ($post['course'] ?? ''))->setOrderRef((string) ($post['order_ref'] ?? ''))
                ->setMessage($comment)->setSource('refund-request')->setIp($turnstile->getRemoteIp())
                ->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))->setStatus('new')->save();
            Mage::helper('mmd_leadmail')->notify('Refund Request', $name, $email, (string) ($post['telephone'] ?? ''), array(
                array('Course Title / Code', (string) ($post['course'] ?? '')),
                array('Order / Invoice No.', (string) ($post['order_ref'] ?? '')),
            ), $comment);
            $session->addSuccess($this->__('Your refund request has been submitted. Our team will review it and respond to you.'));
        } catch (Mage_Core_Exception $e) { $session->addError($e->getMessage()); }
        catch (Exception $e) { Mage::logException($e); $session->addError($this->__('Unable to submit your request. Please try again later.')); }
        $this->_redirect(self::RETURN_URL);
    }
}
