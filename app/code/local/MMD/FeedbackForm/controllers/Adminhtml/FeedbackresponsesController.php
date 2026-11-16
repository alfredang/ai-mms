<?php
/**
 * Class reviews page — every Course Feedback response for one class.
 * Opened from the class page's Course Feedback card by the class's trainer
 * and by staff (admin, training provider, franchise admin, developer).
 */
class MMD_FeedbackForm_Adminhtml_FeedbackresponsesController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        $h = Mage::helper('mmd_feedbackform');
        return Mage::helper('mmd_rolemanager')->isRoleAllowed($h->reviewRoles());
    }

    /** GET — params: run */
    public function classAction()
    {
        /** @var MMD_FeedbackForm_Helper_Data $h */
        $h   = Mage::helper('mmd_feedbackform');
        $run = $h->loadRun((int) $this->getRequest()->getParam('run'));
        if (!$run || !$h->canViewResponses($run)) {
            Mage::getSingleton('adminhtml/session')->addError($run ? 'You are not the trainer of this class.' : 'Class not found.');
            return $this->_redirect('adminhtml/dashboard');
        }
        Mage::register('mmd_feedback_run', $run);
        $this->loadLayout()->_title('Course Feedback')->_title((string) $run['class_id']);
        // Block added here, not in layout XML: SG's Redis layout cache survives deploys.
        $this->getLayout()->getBlock('content')->append(
            $this->getLayout()->createBlock('core/template', 'mmd.feedback.responses')->setTemplate('feedbackform/responses.phtml')
        );
        $this->renderLayout();
    }
}
