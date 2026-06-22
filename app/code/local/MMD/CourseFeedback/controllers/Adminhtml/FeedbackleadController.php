<?php
class MMD_CourseFeedback_Adminhtml_FeedbackleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/feedback_leads');
    }
    public function indexAction()
    {
        $this->loadLayout()->_setActiveMenu('system/feedback_leads')
            ->_title($this->__('System'))->_title($this->__('Course Feedback'));
        $this->_addContent($this->getLayout()->createBlock('mmd_coursefeedback/adminhtml_corporatelead'));
        $this->renderLayout();
    }
    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody($this->getLayout()->createBlock('mmd_coursefeedback/adminhtml_corporatelead_grid')->toHtml());
    }
}
