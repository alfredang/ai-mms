<?php
/** Job application handler — hiring/index/post. Honeypot + Cloudflare Turnstile.
 *  Stores to mmd_hiring_lead and emails the careers mailbox. */
class MMD_Hiring_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'jobs.html';
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
            if ($turnstile->isConfigured()) {
                $result = $turnstile->verify((string) ($post[MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD] ?? ''), $turnstile->getRemoteIp());
                if (empty($result['ok'])) { Mage::throwException($this->__('Spam check failed. Please refresh the page and try again.')); }
            }
            Mage::getModel('mmd_hiring/lead')
                ->setStoreId(Mage::app()->getStore()->getId())->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)->setEmail($email)->setTelephone((string) ($post['telephone'] ?? ''))
                ->setPosition((string) ($post['position'] ?? ''))->setYearsExperience((string) ($post['years_experience'] ?? ''))
                ->setExpertise((string) ($post['expertise'] ?? ''))->setLinkedin((string) ($post['linkedin'] ?? ''))
                ->setMessage($comment)->setSource((string) ($post['source'] ?? 'hiring'))
                ->setIp($turnstile->getRemoteIp())->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))
                ->setStatus('new')->save();
            $this->_notify($post, $name, $email);
            $session->addSuccess($this->__('Thank you for applying! We will review your application and contact shortlisted candidates.'));
        } catch (Mage_Core_Exception $e) { $session->addError($e->getMessage()); }
        catch (Exception $e) { Mage::logException($e); $session->addError($this->__('Unable to submit your request. Please try again later.')); }
        $this->_redirect(self::RETURN_URL);
    }
    protected function _notify($post, $name, $email)
    {
        Mage::helper('mmd_leadmail')->notify('Job Application', $name, $email, (string)($post['telephone'] ?? ''), array(
            array('Position', (string)($post['position'] ?? '')),
            array('Years of Experience', (string)($post['years_experience'] ?? '')),
            array('Expertise', (string)($post['expertise'] ?? '')),
            array('LinkedIn / Resume', (string)($post['linkedin'] ?? '')),
        ), (string)($post['comment'] ?? ''));
    }
}
