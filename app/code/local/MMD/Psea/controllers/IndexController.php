<?php
/**
 * PSEA Withdrawal Form submission page (/psea-submission/).
 *
 * SG-only (404s on partner stores — PSEA is a Singapore scheme). Spam
 * protection mirrors the Contact Us form: same-origin referer guard,
 * honeypot, Cloudflare Turnstile. The uploaded form is validated (PDF/JPG/PNG,
 * max 8 MB, finfo-verified MIME) and emailed with the submission details to
 * the ops mailboxes. Nothing is persisted — no lead row, no stored file.
 */
class MMD_Psea_IndexController extends Mage_Core_Controller_Front_Action
{
    const MAX_FILE_BYTES = 8388608; // 8 MB

    public function preDispatch()
    {
        parent::preDispatch();
        if (Mage::app()->getStore()->getCode() !== 'singapore') {
            $this->norouteAction();
            $this->setFlag('', self::FLAG_NO_DISPATCH, true);
        }
        return $this;
    }

    public function indexAction()
    {
        $this->loadLayout();
        $this->_initLayoutMessages('customer/session');
        $head = $this->getLayout()->getBlock('head');
        if ($head) {
            $head->setTitle('Submit PSEA Withdrawal Form');
        }
        $this->renderLayout();
    }

    public function postAction()
    {
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
        try {
            // Honeypot
            if (!empty($post['hideit']) && trim($post['hideit']) !== '') {
                Mage::throwException($this->__('Unable to submit your request. Please, try again later'));
            }

            $name      = trim((string)($post['name'] ?? ''));
            $email     = trim((string)($post['email'] ?? ''));
            $telephone = trim((string)($post['telephone'] ?? ''));
            $course    = trim((string)($post['course_code'] ?? ''));
            $message   = trim((string)($post['message'] ?? ''));

            if (!Zend_Validate::is($name, 'NotEmpty') || !Zend_Validate::is($email, 'EmailAddress')) {
                Mage::throwException($this->__('Please fill in your name and a valid email address.'));
            }

            // Cloudflare Turnstile (shared helper; fails open when unconfigured — dev mode).
            $turnstile = Mage::helper('magentocaptcha/turnstile');
            $token  = (string)($post[MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD] ?? '');
            $result = $turnstile->verify($token, $turnstile->getRemoteIp());
            if (empty($result['ok'])) {
                Mage::throwException($this->__('Spam check failed. Please refresh the page and try again.'));
            }

            $file = $this->_validateUpload();

            $sent = Mage::helper('mmd_psea')->sendSubmission(array(
                'name'        => $name,
                'email'       => $email,
                'telephone'   => $telephone,
                'course_code' => $course,
                'message'     => $message,
            ), $file);

            if (!$sent) {
                Mage::throwException($this->__('We could not send your submission. Please try again later or email it to enquiry@tertiaryinfotech.com.'));
            }

            $session->addSuccess($this->__('Thank you! Your PSEA Withdrawal Form has been submitted. Our team will process it and get back to you shortly.'));
            $this->_redirect('*/*/', array('_query' => $course !== '' ? array('course' => $course) : array()));
            return;
        } catch (Mage_Core_Exception $e) {
            $session->addError($e->getMessage());
        } catch (Exception $e) {
            Mage::logException($e);
            $session->addError($this->__('Unable to submit your request. Please, try again later'));
        }
        $this->_redirect('*/*/');
    }

    /**
     * Validate the uploaded PSEA form: present, ≤8 MB, PDF/JPG/PNG by both
     * extension and finfo-sniffed MIME. Returns bytes + safe filename + mime.
     */
    protected function _validateUpload()
    {
        $f = $_FILES['psea_form'] ?? null;
        if (!$f || !isset($f['error']) || is_array($f['error'])) {
            Mage::throwException($this->__('Please attach your filled PSEA Withdrawal Form.'));
        }
        if ($f['error'] === UPLOAD_ERR_NO_FILE) {
            Mage::throwException($this->__('Please attach your filled PSEA Withdrawal Form.'));
        }
        if ($f['error'] === UPLOAD_ERR_INI_SIZE || $f['error'] === UPLOAD_ERR_FORM_SIZE || (int) $f['size'] > self::MAX_FILE_BYTES) {
            Mage::throwException($this->__('The attached file is too large — please keep it under 8 MB.'));
        }
        if ($f['error'] !== UPLOAD_ERR_OK || !is_uploaded_file($f['tmp_name'])) {
            Mage::throwException($this->__('The file upload failed. Please try again.'));
        }

        $allowed = array(
            'pdf'  => array('application/pdf'),
            'jpg'  => array('image/jpeg'),
            'jpeg' => array('image/jpeg'),
            'png'  => array('image/png'),
        );
        $ext = strtolower(pathinfo((string) $f['name'], PATHINFO_EXTENSION));
        if (!isset($allowed[$ext])) {
            Mage::throwException($this->__('Please attach the form as a PDF, JPG or PNG file.'));
        }
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime  = (string) $finfo->file($f['tmp_name']);
        if (!in_array($mime, $allowed[$ext], true)) {
            Mage::throwException($this->__('The attached file does not look like a valid %s file.', strtoupper($ext)));
        }

        $safeName = preg_replace('/[^A-Za-z0-9._ -]/', '', (string) $f['name']);
        if (trim(str_replace('.', '', (string) $safeName)) === '') {
            $safeName = 'psea-withdrawal-form.' . $ext;
        }

        return array(
            'bytes' => file_get_contents($f['tmp_name']),
            'name'  => $safeName,
            'mime'  => $mime,
        );
    }
}
