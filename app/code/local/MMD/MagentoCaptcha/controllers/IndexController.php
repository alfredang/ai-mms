<?php
/**
 * Front controller for the storefront Contact Us form.
 *
 * Spam protection: Cloudflare Turnstile (invisible widget). The form posts a
 * `cf-turnstile-response` token alongside the user data; we verify it against
 * Cloudflare's siteverify endpoint before sending the email. On verification
 * failure we surface the error to the visitor — we deliberately do NOT
 * silently show "your inquiry was submitted" the way the old reCAPTCHA path
 * did, because that masked genuine spam-shield rejections AND any real
 * delivery problems.
 *
 * Recipient routing: contacts/email/recipient_email is a comma- or
 * semicolon-separated list, so each country store can deliver to multiple
 * mailboxes (e.g. SG: sales@…sg + enquiry@…com). The values are split and
 * passed as an array to sendTransactional, which adds each as a To: header.
 */
class MMD_MagentoCaptcha_IndexController extends Mage_Core_Controller_Front_Action
{
    const XML_PATH_EMAIL_RECIPIENT  = 'contacts/email/recipient_email';
    const XML_PATH_EMAIL_SENDER     = 'contacts/email/sender_email_identity';
    const XML_PATH_EMAIL_TEMPLATE   = 'contacts/email/email_template';
    const XML_PATH_ENABLED          = 'contacts/contacts/enabled';

    public function preDispatch()
    {
        parent::preDispatch();
        if (!Mage::getStoreConfigFlag(self::XML_PATH_ENABLED)) {
            $this->norouteAction();
        }
    }

    public function indexAction()
    {
        $this->loadLayout();
        $this->getLayout()->getBlock('contactForm')
            ->setFormAction(Mage::getUrl('*/*/post'));

        $this->_initLayoutMessages('customer/session');
        $this->_initLayoutMessages('catalog/session');
        $this->renderLayout();
    }

    public function postAction()
    {
        // Same-origin guard — keeps casual scripted POSTs at bay even before captcha.
        if (empty($_SERVER['HTTP_REFERER'])
            || strpos((string) $_SERVER['HTTP_REFERER'], (string) $_SERVER['HTTP_HOST']) === false) {
            $this->_redirect('*/*/');
            return;
        }

        $post = $this->getRequest()->getPost();
        if (!$post) {
            $this->_redirect('*/*/');
            return;
        }

        $session = Mage::getSingleton('customer/session');
        $translate = Mage::getSingleton('core/translate');
        /** @var Mage_Core_Model_Translate $translate */
        $translate->setTranslateInline(false);

        try {
            // Honeypot — bots fill all visible fields including the hidden one.
            if (!empty($post['hideit']) && trim($post['hideit']) !== '') {
                Mage::throwException($this->__('Unable to submit your request. Please, try again later'));
            }

            // Form validation
            $error = false;
            if (!Zend_Validate::is(trim($post['name'] ?? ''), 'NotEmpty')) {
                $error = true;
            } elseif (!Zend_Validate::is(trim($post['comment'] ?? ''), 'NotEmpty')) {
                $error = true;
            } elseif (!Zend_Validate::is(trim($post['email'] ?? ''), 'EmailAddress')) {
                $error = true;
            }
            if ($error) {
                Mage::throwException($this->__('Please fill in all required fields with a valid email.'));
            }

            // Cloudflare Turnstile verification.
            $turnstile = Mage::helper('magentocaptcha/turnstile');
            /** @var MMD_MagentoCaptcha_Helper_Turnstile $turnstile */
            $token  = (string)($post[MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD] ?? '');
            $result = $turnstile->verify($token, $turnstile->getRemoteIp());
            if (empty($result['ok'])) {
                Mage::throwException($this->__('Spam check failed. Please refresh the page and try again.'));
            }

            // Persist the lead FIRST so operators always see it in the
            // admin grid (Tertiary → Leads) even if mail delivery hiccups —
            // a lost staff email must never mean a lost lead.
            $lead = Mage::getModel('mmd_leads/lead')
                ->setStoreId(Mage::app()->getStore()->getId())
                ->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName((string)($post['name'] ?? ''))
                ->setEmail((string)($post['email'] ?? ''))
                ->setTelephone((string)($post['telephone'] ?? ''))
                ->setCompany((string)($post['company'] ?? ''))
                ->setCoursesInterested((string)($post['courses'] ?? ''))
                ->setCourseCode((string)($post['course_code'] ?? ''))
                ->setComment((string)($post['comment'] ?? ''))
                ->setIp((string) $turnstile->getRemoteIp())
                ->setUserAgent(substr((string)($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))
                ->save();

            // Notify staff via the shared branded HTML template (To:
            // Tertiary Courses Singapore <sales@tertiarycourses.com.sg>,
            // CC angch@/tansc@) — same layout every MMD lead form uses.
            // Mail failures are logged, not surfaced: the lead is already
            // captured above, so the visitor still gets a success message.
            try {
                $sent = Mage::helper('mmd_leadmail')->notify(
                    'Website Enquiry',
                    (string)($post['name'] ?? ''),
                    (string)($post['email'] ?? ''),
                    (string)($post['telephone'] ?? ''),
                    array(
                        array('Company', (string)($post['company'] ?? '')),
                        array('Courses Interested', (string)($post['courses'] ?? '')),
                        array('Course Code', (string)($post['course_code'] ?? '')),
                    ),
                    (string)($post['comment'] ?? '')
                );
                if (!$sent) {
                    Mage::log('Contact form: staff notification failed for lead #' . $lead->getId(), null, 'mmd_leadmail.log');
                }

                // Automatic acknowledgement to the visitor with matched
                // course info. The helper records the outcome on the lead
                // (auto_reply_status) and never throws.
                Mage::helper('mmd_leads')->sendAutoReply($lead);

                // Auto-subscribe the lead to the site's MailerLite group.
                // Records mailerlite_status on the lead; never throws.
                Mage::helper('mmd_leads')->subscribeToMailerlite($lead);
            } catch (Exception $e) {
                Mage::logException($e);
            }

            $translate->setTranslateInline(true);
            $session->addSuccess($this->__('Thank you for your submission. We will respond in 7 working days. If you do not receive any response from us, please call our office hotline +65 6100 0613 for further assistance.'));
        } catch (Mage_Core_Exception $e) {
            $translate->setTranslateInline(true);
            Mage::logException($e);
            $session->addError($e->getMessage());
        } catch (Exception $e) {
            $translate->setTranslateInline(true);
            Mage::logException($e);
            $session->addError($this->__('Unable to submit your request. Please, try again later'));
        }

        $this->_redirect('*/*/');
    }
}
