<?php
class MMD_Hiring_Adminhtml_HiringleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/hiring_leads');
    }
    public function indexAction()
    {
        $this->loadLayout()->_setActiveMenu('system/hiring_leads')
            ->_title($this->__('System'))->_title($this->__('Job Application Leads'));
        $this->_addContent($this->getLayout()->createBlock('mmd_hiring/adminhtml_corporatelead'));
        $this->renderLayout();
    }
    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody($this->getLayout()->createBlock('mmd_hiring/adminhtml_corporatelead_grid')->toHtml());
    }
}
