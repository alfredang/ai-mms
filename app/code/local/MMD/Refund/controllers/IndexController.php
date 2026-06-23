<?php
/** Refund Request handler — refund/index/post. Honeypot + Turnstile.
 *  To: sales@ + tansc@ + zulaikha@ + lakshaya@; CC: angch@. */
class MMD_Refund_IndexController extends Mage_Core_Controller_Front_Action
{
    const RETURN_URL = 'refund-request.html';
    const EXTRA_TO   = 'tansc@tertiaryinfotech.com,zulaikha@tertiaryinfotech.com,lakshayakandasamy@gmail.com';
    const CC_TO      = 'angch@tertiaryinfotech.com';

    public function postAction()
    {
        $session = Mage::getSingleton('core/session');
        if (empty($_SERVER['HTTP_REFERER']) || strpos((string) $_SERVER['HTTP_REFERER'], (string) $_SERVER['HTTP_HOST']) === false) { $this->_redirect(self::RETURN_URL); return; }
        $post = $this->getRequest()->getPost();
        if (!$post) { $this->_redirect(self::RETURN_URL); return; }
        try {
            if (!empty($post['hideit']) && trim((string) $post['hideit']) !== '') { Mage::throwException($this->__('Unable to submit your request. Please try again later.')); }
            $name       = trim((string) ($post['name'] ?? ''));
            $email      = trim((string) ($post['email'] ?? ''));
            $telephone  = trim((string) ($post['telephone'] ?? ''));
            $nric       = trim((string) ($post['nric'] ?? ''));
            $course     = trim((string) ($post['course'] ?? ''));
            $courseCode = trim((string) ($post['course_code'] ?? ''));
            $orderRef   = trim((string) ($post['order_ref'] ?? ''));
            $netPaid    = trim((string) ($post['net_amount_paid'] ?? ''));
            $sfClaimed  = trim((string) ($post['skillsfuture_claimed'] ?? ''));
            $refundAmt  = trim((string) ($post['refund_amount'] ?? ''));
            $comment    = trim((string) ($post['comment'] ?? ''));
            if (!Zend_Validate::is($name, 'NotEmpty') || !Zend_Validate::is($email, 'EmailAddress')
                || !Zend_Validate::is($telephone, 'NotEmpty') || !Zend_Validate::is($nric, 'NotEmpty')
                || !Zend_Validate::is($course, 'NotEmpty') || !Zend_Validate::is($courseCode, 'NotEmpty')
                || !Zend_Validate::is($orderRef, 'NotEmpty') || !Zend_Validate::is($netPaid, 'NotEmpty')
                || !Zend_Validate::is($refundAmt, 'NotEmpty')) {
                Mage::throwException($this->__('Please complete all required fields.'));
            }
            $turnstile = Mage::helper('magentocaptcha/turnstile');
            if ($turnstile->isConfigured()) { $r = $turnstile->verify((string) ($post[MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD] ?? ''), $turnstile->getRemoteIp()); if (empty($r['ok'])) { Mage::throwException($this->__('Spam check failed. Please refresh the page and try again.')); } }
            Mage::getModel('mmd_refund/lead')->setStoreId(Mage::app()->getStore()->getId())->setStoreCode(Mage::app()->getStore()->getCode())
                ->setName($name)->setNric($nric)->setEmail($email)->setTelephone($telephone)
                ->setCourse($course)->setCourseCode($courseCode)->setOrderRef($orderRef)
                ->setNetAmountPaid($netPaid)->setSkillsfutureClaimed($sfClaimed)->setRefundAmount($refundAmt)
                ->setMessage($comment)->setSource('refund-request')->setIp($turnstile->getRemoteIp())
                ->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))->setStatus('new')->save();
            Mage::helper('mmd_leadmail')->notify('Refund Request', $name, $email, $telephone, array(
                array('NRIC', $nric),
                array('Course Title', $course),
                array('Course Code', $courseCode),
                array('Order / Invoice No.', $orderRef),
                array('Net Amount Paid', $netPaid),
                array('SkillsFuture Claimed Amount', $sfClaimed),
                array('Amount to Refund', $refundAmt),
            ), $comment, explode(',', self::EXTRA_TO), explode(',', self::CC_TO));
            $session->addSuccess($this->__('Thank you for your submission. We will respond in 7 working days. If you do not receive any response from us, please call our office hotline +65 6100 0613 for further assistance.'));
        } catch (Mage_Core_Exception $e) { $session->addError($e->getMessage()); }
        catch (Exception $e) { Mage::logException($e); $session->addError($this->__('Unable to submit your request. Please try again later.')); }
        $this->_redirect(self::RETURN_URL);
    }
}
