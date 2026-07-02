<?php
class MMD_Reschedule_Adminhtml_RescheduleleadController extends Mage_Adminhtml_Controller_Action
{
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
        $this->getResponse()->setBody($this->getLayout()->createBlock('mmd_reschedule/adminhtml_corporatelead_grid')->toHtml());
    }
}
