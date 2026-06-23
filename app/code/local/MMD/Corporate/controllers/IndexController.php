<?php
/**
 * Corporate On-Site Training enquiry handler — corporate/index/post. Same invisible
 * spam shield as Contact Us (honeypot + Cloudflare Turnstile). Stores to
 * mmd_corporate_lead and emails the corporate-training mailbox.
 */
class MMD_Corporate_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'in-house-training.html';

    public function postAction()
    {
        $session = Mage::getSingleton('core/session');
        if (empty($_SERVER['HTTP_REFERER'])
            || strpos((string) $_SERVER['HTTP_REFERER'], (string) $_SERVER['HTTP_HOST']) === false) {
            $this->_redirect(self::RETURN_URL); return;
        }
        $post = $this->getRequest()->getPost();
        if (!$post) { $this->_redirect(self::RETURN_URL); return; }
        try {
            if (!empty($post['hideit']) && trim((string) $post['hideit']) !== '') {
                Mage::throwException($this->__('Unable to submit your request. Please try again later.'));
            }
            $name = trim((string) ($post['name'] ?? '')); $email = trim((string) ($post['email'] ?? '')); $comment = trim((string) ($post['comment'] ?? ''));
            if (!Zend_Validate::is($name, 'NotEmpty') || !Zend_Validate::is($email, 'EmailAddress')) {
                Mage::throwException($this->__('Please provide your name and a valid email address.'));
            }
            $turnstile = Mage::helper('magentocaptcha/turnstile');
            if ($turnstile->isConfigured()) {
                $result = $turnstile->verify((string) ($post[MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD] ?? ''), $turnstile->getRemoteIp());
                if (empty($result['ok'])) { Mage::throwException($this->__('Spam check failed. Please refresh the page and try again.')); }
            }
            Mage::getModel('mmd_corporate/lead')
                ->setStoreId(Mage::app()->getStore()->getId())->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)->setEmail($email)->setTelephone((string) ($post['telephone'] ?? ''))
                ->setCompany((string) ($post['company'] ?? ''))->setNumPax((string) ($post['num_pax'] ?? ''))
                ->setTrainingTopic((string) ($post['training_topic'] ?? ''))->setPreferredDates((string) ($post['preferred_dates'] ?? ''))
                ->setMessage($comment)->setSource((string) ($post['source'] ?? 'corporate-on-site-training'))
                ->setIp($turnstile->getRemoteIp())->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))
                ->setStatus('new')->save();
            $this->_notify($post, $name, $email);
            $session->addSuccess($this->__('Thank you for your submission. We will respond in 7 working days. If you do not receive any response from us, please call our office hotline +65 6100 0613 for further assistance.'));
        } catch (Mage_Core_Exception $e) { $session->addError($e->getMessage()); }
        catch (Exception $e) { Mage::logException($e); $session->addError($this->__('Unable to submit your request. Please try again later.')); }
        $this->_redirect(self::RETURN_URL);
    }
    protected function _notify($post, $name, $email)
    {
        Mage::helper('mmd_leadmail')->notify('Corporate On-Site Training Enquiry', $name, $email, (string)($post['telephone'] ?? ''), array(
            array('Company', (string)($post['company'] ?? '')),
            array('No. of Participants', (string)($post['num_pax'] ?? '')),
            array('Training Topic', (string)($post['training_topic'] ?? '')),
            array('Preferred Dates', (string)($post['preferred_dates'] ?? '')),
        ), (string)($post['comment'] ?? ''));
    }
}
