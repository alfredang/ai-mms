<?php
/**
 * Franchise Partnership enquiry handler — franchise/index/post.
 *
 * Same invisible spam shield as the Contact Us form: honeypot `hideit` +
 * Cloudflare Turnstile (verified server-side via MMD_MagentoCaptcha, when
 * configured). On success the lead is stored in mmd_franchise_lead and a
 * notification is emailed to the franchise mailbox.
 */
class MMD_Franchise_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'franchising-application.html';

    public function postAction()
    {
        $session = Mage::getSingleton('core/session');

        // Same-origin guard — block casual scripted cross-site POSTs.
        if (empty($_SERVER['HTTP_REFERER'])
            || strpos((string) $_SERVER['HTTP_REFERER'], (string) $_SERVER['HTTP_HOST']) === false) {
            $this->_redirect(self::RETURN_URL);
            return;
        }

        $post = $this->getRequest()->getPost();
        if (!$post) {
            $this->_redirect(self::RETURN_URL);
            return;
        }

        try {
            // Honeypot — bots fill the hidden field.
            if (!empty($post['hideit']) && trim((string) $post['hideit']) !== '') {
                Mage::throwException($this->__('Unable to submit your request. Please try again later.'));
            }

            $name    = trim((string) ($post['name'] ?? ''));
            $email   = trim((string) ($post['email'] ?? ''));
            $comment = trim((string) ($post['comment'] ?? ''));
            if (!Zend_Validate::is($name, 'NotEmpty') || !Zend_Validate::is($email, 'EmailAddress')) {
                Mage::throwException($this->__('Please provide your name and a valid email address.'));
            }

            // Cloudflare Turnstile (only when keys are configured).
            $turnstile = Mage::helper('magentocaptcha/turnstile');
            /** @var MMD_MagentoCaptcha_Helper_Turnstile $turnstile */
            if ($turnstile->isConfigured()) {
                $token  = (string) ($post[MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD] ?? '');
                $result = $turnstile->verify($token, $turnstile->getRemoteIp());
                if (empty($result['ok'])) {
                    Mage::throwException($this->__('Spam check failed. Please refresh the page and try again.'));
                }
            }

            $lead = Mage::getModel('mmd_franchise/lead')
                ->setStoreId(Mage::app()->getStore()->getId())
                ->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)
                ->setEmail($email)
                ->setTelephone((string) ($post['telephone'] ?? ''))
                ->setCompany((string) ($post['company'] ?? ''))
                ->setCountry((string) ($post['country'] ?? ''))
                ->setMessage($comment)
                ->setSource((string) ($post['source'] ?? 'franchising-application'))
                ->setIp($turnstile->getRemoteIp())
                ->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))
                ->setStatus('new');
            $lead->save();

            $this->_notify($lead);

            $session->addSuccess($this->__('Thank you for your submission. We will respond in 7 working days. If you do not receive any response from us, please call our office hotline +65 6100 0613 for further assistance.'));
        } catch (Mage_Core_Exception $e) {
            $session->addError($e->getMessage());
        } catch (Exception $e) {
            Mage::logException($e);
            $session->addError($this->__('Unable to submit your request. Please try again later.'));
        }

        $this->_redirect(self::RETURN_URL);
    }

    /** Email the franchise mailbox, reusing the contacts transactional template. */
    protected function _notify(MMD_Franchise_Model_Lead $lead)
    {
        Mage::helper('mmd_leadmail')->notify('Franchise Partnership Enquiry', $lead->getName(), $lead->getEmail(), $lead->getTelephone(), array(
            array('Country / Region', $lead->getCountry()),
            array('Company', $lead->getCompany()),
        ), $lead->getMessage());
    }
}
