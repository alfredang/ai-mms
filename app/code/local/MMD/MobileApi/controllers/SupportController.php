<?php
/**
 * The app's Support tab: GET the academy's contacts; POST {subject, message}
 * emails the signed-in person's message to the academy with their name and
 * email, so the team can reply.
 */
class MMD_MobileApi_SupportController extends MMD_MobileApi_Controller_Base
{
    public function indexAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $page = Mage::helper('mmd_mobileapi/classPage');
            if (!$this->getRequest()->isPost()) {
                return $this->_ok(array('support' => $page->supportInfo()));
            }
            if ($this->_isDemo()) {
                return $this->_ok(array('message' => 'Sample account: your message was not sent.'));
            }
            try {
                $page->sendSupport(
                    $this->_email(),
                    (string) $this->_input('subject', ''),
                    (string) $this->_input('message', ''),
                    (string) $this->_input('app_version', '')
                );
            } catch (Exception $e) {
                return $this->_error(422, $e->getMessage(), 'invalid');
            }
            return $this->_ok(array('message' => 'Thank you. Your message has been sent.'));
        });
    }
}
