<?php
/**
 * Trainer Application enquiry handler — trainer/index/post. Same invisible spam
 * shield as Contact Us (honeypot `hideit` + Cloudflare Turnstile). On success the
 * application is stored in mmd_trainer_lead and emailed to the trainer mailbox.
 */
class MMD_Trainer_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'trainer-application.html';

    public function postAction()
    {
        $session = Mage::getSingleton('core/session');

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
            if (!empty($post['hideit']) && trim((string) $post['hideit']) !== '') {
                Mage::throwException($this->__('Unable to submit your request. Please try again later.'));
            }

            $name    = trim((string) ($post['name'] ?? ''));
            $email   = trim((string) ($post['email'] ?? ''));
            $comment = trim((string) ($post['comment'] ?? ''));
            if (!Zend_Validate::is($name, 'NotEmpty') || !Zend_Validate::is($email, 'EmailAddress')) {
                Mage::throwException($this->__('Please provide your name and a valid email address.'));
            }

            $turnstile = Mage::helper('magentocaptcha/turnstile');
            /** @var MMD_MagentoCaptcha_Helper_Turnstile $turnstile */
            if ($turnstile->isConfigured()) {
                $token  = (string) ($post[MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD] ?? '');
                $result = $turnstile->verify($token, $turnstile->getRemoteIp());
                if (empty($result['ok'])) {
                    Mage::throwException($this->__('Spam check failed. Please refresh the page and try again.'));
                }
            }

            $lead = Mage::getModel('mmd_trainer/lead')
                ->setStoreId(Mage::app()->getStore()->getId())
                ->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)
                ->setEmail($email)
                ->setTelephone((string) ($post['telephone'] ?? ''))
                ->setQualification((string) ($post['qualification'] ?? ''))
                ->setExpertise((string) ($post['expertise'] ?? ''))
                ->setAclp((string) ($post['aclp'] ?? ''))
                ->setTaepp((string) ($post['taepp'] ?? ''))
                ->setYearsExperience((string) ($post['years_experience'] ?? ''))
                ->setMessage($comment)
                ->setSource((string) ($post['source'] ?? 'trainer-application'))
                ->setIp($turnstile->getRemoteIp())
                ->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))
                ->setStatus('new');
            $lead->save();

            $this->_notify($lead);
            $session->addSuccess($this->__('Thank you! Your trainer application has been received — our team will review it and be in touch.'));
        } catch (Mage_Core_Exception $e) {
            $session->addError($e->getMessage());
        } catch (Exception $e) {
            Mage::logException($e);
            $session->addError($this->__('Unable to submit your request. Please try again later.'));
        }

        $this->_redirect(self::RETURN_URL);
    }

    protected function _notify(MMD_Trainer_Model_Lead $lead)
    {
        Mage::helper('mmd_leadmail')->notify('Trainer Application', $lead->getName(), $lead->getEmail(), $lead->getTelephone(), array(
            array('Highest Qualification', $lead->getQualification()),
            array('Area of Expertise', $lead->getExpertise()),
            array('ACLP Certified', $lead->getAclp()),
            array('TAEPP Registered', $lead->getTaepp()),
            array('Years of Experience', $lead->getYearsExperience()),
        ), $lead->getMessage());
    }
}
