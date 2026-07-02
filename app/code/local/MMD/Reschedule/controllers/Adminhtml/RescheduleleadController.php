<?php
class MMD_Reschedule_Adminhtml_RescheduleleadController extends Mage_Adminhtml_Controller_Action
{
    const EXTRA_TO = 'angss@tertiaryinfotech.com';

    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/reschedule_leads');
    }

    public function indexAction()
    {
        $this->loadLayout()->_setActiveMenu('system/reschedule_leads')
            ->_title($this->__('System'))->_title($this->__('Class Reschedule Requests'));
        $this->_addContent($this->getLayout()->createBlock('mmd_reschedule/adminhtml_corporatelead'));
        $this->renderLayout();
    }

    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody(
            $this->getLayout()->createBlock('mmd_reschedule/adminhtml_corporatelead_grid')->toHtml()
        );
    }

    /** Mark lead as confirmed and send a staff notification with updated status. */
    public function approveAction()
    {
        $id   = (int) $this->getRequest()->getParam('id');
        $lead = Mage::getModel('mmd_reschedule/lead')->load($id);

        if (!$lead->getId()) {
            $this->_getSession()->addError($this->__('Lead #%s not found.', $id));
            return $this->_redirect('*/*/');
        }
        if ($lead->getIsWsq()) {
            $this->_getSession()->addNotice(
                $this->__('Lead #%s is a WSQ reschedule — approval is handled in the LMS dashboard.', $id)
            );
            return $this->_redirect('*/*/');
        }

        $lead->setStatus('confirmed')->save();

        Mage::helper('mmd_leadmail')->notify(
            'Class Reschedule — APPROVED',
            $lead->getName(), $lead->getEmail(), $lead->getTelephone(),
            array(
                array('Course',          $lead->getCourse()),
                array('Course Code',     $lead->getCourseCode()),
                array('Class Date',      $lead->getCourseStartDate()),
                array('Preferred Date',  $lead->getNextCourseStartDate()),
                array('Lead ID',         '#' . $id),
            ),
            $lead->getMessage(),
            array(self::EXTRA_TO)
        );

        $this->_getSession()->addSuccess($this->__('Lead #%s approved. Staff notified.', $id));
        $this->_redirect('*/*/');
    }

    /** Mark lead as closed (no action taken). */
    public function closeAction()
    {
        $id   = (int) $this->getRequest()->getParam('id');
        $lead = Mage::getModel('mmd_reschedule/lead')->load($id);

        if (!$lead->getId()) {
            $this->_getSession()->addError($this->__('Lead #%s not found.', $id));
            return $this->_redirect('*/*/');
        }

        $lead->setStatus('closed')->save();
        $this->_getSession()->addSuccess($this->__('Lead #%s closed.', $id));
        $this->_redirect('*/*/');
    }

    /**
     * Attempt to push a WSQ lead to the LMS reschedule-request endpoint.
     * Only useful for leads with lms_status = pending_push or failed.
     * Requires LMS_API_URL + LMS_API_KEY env vars to be set in Coolify.
     */
    public function resendlmsAction()
    {
        $id   = (int) $this->getRequest()->getParam('id');
        $lead = Mage::getModel('mmd_reschedule/lead')->load($id);

        if (!$lead->getId()) {
            $this->_getSession()->addError($this->__('Lead #%s not found.', $id));
            return $this->_redirect('*/*/');
        }
        if (!$lead->getIsWsq()) {
            $this->_getSession()->addNotice($this->__('Lead #%s is not a WSQ lead — no LMS push needed.', $id));
            return $this->_redirect('*/*/');
        }

        $baseUrl = rtrim((string) getenv('LMS_API_URL'), '/');
        $apiKey  = (string) getenv('LMS_API_KEY');

        if (!$baseUrl || !$apiKey) {
            $this->_getSession()->addError($this->__('LMS_API_URL / LMS_API_KEY not configured in Coolify env vars.'));
            return $this->_redirect('*/*/');
        }

        $payload = json_encode(array(
            'learner_email'  => $lead->getEmail(),
            'current_run_id' => $lead->getRunId(),
            'target_run_id'  => $lead->getTargetRunId(),
            'course_sku'     => $lead->getCourseCode(),
            'course_title'   => $lead->getCourse(),
            'preferred_date' => $lead->getNextCourseStartDate(),
            'name'           => $lead->getName(),
            'nric'           => $lead->getNric(),
        ));

        $ch = curl_init($baseUrl . '/api/external/reschedule-request');
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 10,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_HTTPHEADER     => array(
                'X-API-Key: ' . $apiKey,
                'Content-Type: application/json',
                'Accept: application/json',
            ),
            CURLOPT_SSL_VERIFYPEER => true,
        ));
        $resp = curl_exec($ch);
        $http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $lmsStatus   = ($http === 200) ? 'pushed' : 'failed';
        $lmsResponse = (string) $resp;
        $lead->setLmsStatus($lmsStatus)->setLmsResponse($lmsResponse)->save();

        if ($http === 200) {
            $this->_getSession()->addSuccess($this->__('Lead #%s pushed to LMS successfully.', $id));
        } else {
            $this->_getSession()->addError(
                $this->__('LMS returned HTTP %s for lead #%s. Response: %s', $http, $id, substr($lmsResponse, 0, 200))
            );
        }

        $this->_redirect('*/*/');
    }
}
