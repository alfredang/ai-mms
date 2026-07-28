<?php
/**
 * Admin grid + view/reply actions for storefront leads.
 *
 * Actions:
 *   indexAction()       — renders the grid (default landing for the menu).
 *   gridAction()        — AJAX reload of the grid (sort/filter/page).
 *   viewAction()        — single-lead view with the pre-filled reply form.
 *   aidraftAction()     — AJAX JSON endpoint; asks Claude to draft the reply
 *                         (subject + HTML body) from the lead context plus
 *                         live course data from the schedule API.
 *   replyAction()       — POST handler; sends the email via the existing
 *                         Gmail OAuth transport and marks the lead replied.
 *                         Honours the operator-editable To / CC fields.
 *   deleteAction()      — single delete.
 *   massDeleteAction()  — bulk delete from grid mass-action.
 */
class MMD_Leads_Adminhtml_LeadsController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')
            ->isAllowed('admin/mmd_tertiary/leads');
    }

    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('mmd_tertiary/leads');
        $this->_addContent($this->getLayout()->createBlock('mmd_leads/adminhtml_leads'));
        $this->renderLayout();
    }

    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody(
            $this->getLayout()->createBlock('mmd_leads/adminhtml_leads_grid')->toHtml()
        );
    }

    public function viewAction()
    {
        $id   = (int) $this->getRequest()->getParam('id');
        $lead = Mage::getModel('mmd_leads/lead')->load($id);

        if (!$lead->getId()) {
            Mage::getSingleton('adminhtml/session')->addError($this->__('Lead not found.'));
            $this->_redirect('*/*/');
            return;
        }

        Mage::register('current_lead', $lead);

        $this->loadLayout();
        $this->_setActiveMenu('mmd_tertiary/leads');
        $this->_addContent($this->getLayout()->createBlock('mmd_leads/adminhtml_leads_view'));
        $this->renderLayout();
    }

    /**
     * AJAX: AI-draft the reply for a lead. Returns JSON
     *   { ok: true, subject_course, body_html }
     * or { ok: false, error }. Called by view.phtml on page load (and by
     * the "Regenerate AI Draft" button) to prepopulate the reply form.
     */
    public function aidraftAction()
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json; charset=utf-8', true);

        $id   = (int) $this->getRequest()->getParam('id');
        $lead = Mage::getModel('mmd_leads/lead')->load($id);
        if (!$lead->getId()) {
            $this->getResponse()->setBody(json_encode(array('ok' => false, 'error' => 'Lead not found.')));
            return;
        }

        try {
            $draft = Mage::helper('mmd_leads/aiDraft')->draft($lead);
            $this->getResponse()->setBody(json_encode(array(
                'ok'             => true,
                'subject_course' => $draft['subject_course'],
                'body_html'      => $draft['body_html'],
            ), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        } catch (Exception $e) {
            Mage::logException($e);
            $this->getResponse()->setBody(json_encode(array('ok' => false, 'error' => $e->getMessage())));
        }
    }

    public function replyAction()
    {
        $id   = (int) $this->getRequest()->getParam('id');
        $lead = Mage::getModel('mmd_leads/lead')->load($id);

        if (!$lead->getId()) {
            Mage::getSingleton('adminhtml/session')->addError($this->__('Lead not found.'));
            $this->_redirect('*/*/');
            return;
        }

        $subjectCourse = trim((string) $this->getRequest()->getPost('subject_course', ''));
        $replyHtml     = (string) $this->getRequest()->getPost('reply_body_html', '');
        if ($subjectCourse === '' || trim(strip_tags($replyHtml)) === '') {
            Mage::getSingleton('adminhtml/session')->addError(
                $this->__('Please fill in both the subject course and the reply body before sending.')
            );
            $this->_redirect('*/*/view', array('id' => $id));
            return;
        }

        // Operator-editable recipient + CC list (both optional; To falls
        // back to the lead's email, CC to none).
        $emailTo = trim((string) $this->getRequest()->getPost('email_to', '')) ?: (string) $lead->getEmail();
        if (!Zend_Validate::is($emailTo, 'EmailAddress')) {
            Mage::getSingleton('adminhtml/session')->addError(
                $this->__('"%s" is not a valid To address.', $emailTo)
            );
            $this->_redirect('*/*/view', array('id' => $id));
            return;
        }
        $ccList = array();
        foreach (preg_split('/[,;]+/', (string) $this->getRequest()->getPost('email_cc', '')) ?: array() as $cc) {
            $cc = trim($cc);
            if ($cc === '') {
                continue;
            }
            if (!Zend_Validate::is($cc, 'EmailAddress')) {
                Mage::getSingleton('adminhtml/session')->addError(
                    $this->__('"%s" is not a valid CC address.', $cc)
                );
                $this->_redirect('*/*/view', array('id' => $id));
                return;
            }
            $ccList[$cc] = $cc;
        }

        try {
            $storeId = (int) $lead->getStoreId();
            $sender  = Mage::helper('mmd_leads')->getReplySender($storeId);

            // sendTransactional pulls the From identity from the named
            // sender ("general" / "sales" etc); MMD_Email's setReplyTo
            // observer then sets Reply-To to the per-store sales identity
            // so customer replies land in the right country mailbox.
            $mail = Mage::getModel('core/email_template');
            /** @var Mage_Core_Model_Email_Template $mail */
            $mail->setDesignConfig(array('area' => 'frontend', 'store' => $storeId));

            // addCc() on the underlying Zend_Mail survives sendTransactional()
            // (send() only re-adds To/Bcc, never clears Cc) — same pattern as
            // the auto-reply CC in Helper/Data.php::sendAutoReply().
            foreach ($ccList as $cc) {
                $mail->getMail()->addCc($cc);
            }

            $mail->sendTransactional(
                    'mmd_leads_course_reply',
                    $sender,
                    $emailTo,
                    $lead->getName(),
                    array(
                        'lead_name'       => $lead->getName(),
                        'subject_course'  => $subjectCourse,
                        'reply_body_html' => $replyHtml,
                        'store_brand'     => Mage::helper('mmd_leads')->getStoreBrandName($storeId),
                        'sender_name'     => Mage::getStoreConfig('contacts/email/sender_email_identity', $storeId)
                            ? Mage::getStoreConfig(
                                'trans_email/ident_' . Mage::getStoreConfig('contacts/email/sender_email_identity', $storeId) . '/name',
                                $storeId
                            )
                            : Mage::helper('mmd_leads')->getStoreBrandName($storeId),
                    ),
                    $storeId
                );

            if (!$mail->getSentSuccess()) {
                Mage::throwException($this->__('Email send failed — check var/log/system.log'));
            }

            $lead->markReplied(
                $subjectCourse . "\n\n" . $replyHtml,
                Mage::getSingleton('admin/session')->getUser()->getId()
            );

            Mage::getSingleton('adminhtml/session')->addSuccess(
                $ccList
                    ? $this->__('Reply sent to %s (cc: %s).', $emailTo, implode(', ', $ccList))
                    : $this->__('Reply sent to %s.', $emailTo)
            );
            $this->_redirect('*/*/');
        } catch (Exception $e) {
            Mage::logException($e);
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
            $this->_redirect('*/*/view', array('id' => $id));
        }
    }

    public function deleteAction()
    {
        $id = (int) $this->getRequest()->getParam('id');
        if ($id) {
            try {
                Mage::getModel('mmd_leads/lead')->setId($id)->delete();
                Mage::getSingleton('adminhtml/session')->addSuccess($this->__('Lead deleted.'));
            } catch (Exception $e) {
                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
            }
        }
        $this->_redirect('*/*/');
    }

    public function massDeleteAction()
    {
        $ids = $this->getRequest()->getParam('leads');
        if (!is_array($ids) || empty($ids)) {
            Mage::getSingleton('adminhtml/session')->addError($this->__('Please select at least one lead.'));
            $this->_redirect('*/*/');
            return;
        }
        $count = 0;
        foreach ($ids as $id) {
            try {
                Mage::getModel('mmd_leads/lead')->setId((int) $id)->delete();
                $count++;
            } catch (Exception $e) {
                Mage::logException($e);
            }
        }
        Mage::getSingleton('adminhtml/session')->addSuccess(
            $this->__('%d lead(s) deleted.', $count)
        );
        $this->_redirect('*/*/');
    }

    /**
     * Mass-action: push the selected leads' emails to the site's
     * configured MailerLite group. The helper records the outcome on
     * each lead (mailerlite_status), which drives the grid checkbox.
     */
    public function massMailerliteAction()
    {
        $ids = $this->getRequest()->getParam('leads');
        if (!is_array($ids) || empty($ids)) {
            Mage::getSingleton('adminhtml/session')->addError($this->__('Please select at least one lead.'));
            $this->_redirect('*/*/');
            return;
        }
        $helper = Mage::helper('mmd_leads');
        $sent = $skipped = $failed = 0;
        foreach ($ids as $id) {
            $lead = Mage::getModel('mmd_leads/lead')->load((int) $id);
            if (!$lead->getId()) {
                continue;
            }
            $helper->subscribeToMailerlite($lead);
            switch ($lead->getMailerliteStatus()) {
                case MMD_Leads_Model_Lead::MAILERLITE_SENT:
                    $sent++;
                    break;
                case MMD_Leads_Model_Lead::MAILERLITE_SKIPPED:
                    $skipped++;
                    break;
                default:
                    $failed++;
            }
        }
        $session = Mage::getSingleton('adminhtml/session');
        if ($sent) {
            $session->addSuccess($this->__('%d lead(s) sent to MailerLite.', $sent));
        }
        if ($skipped) {
            $session->addNotice($this->__('%d lead(s) skipped (unsubscribed previously, or MailerLite not configured).', $skipped));
        }
        if ($failed) {
            $session->addError($this->__('%d lead(s) failed — see var/log/mailerlite.log.', $failed));
        }
        $this->_redirect('*/*/');
    }
}
