<?php
class MMD_Corporate_Adminhtml_CorporateleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd_marketing/corporate_leads');
    }
    public function indexAction()
    {
        $this->loadLayout()->_setActiveMenu('mmd_marketing/corporate_leads')
            ->_title($this->__('Marketing'))->_title($this->__('Corporate Application Leads'));
        $this->_addContent($this->getLayout()->createBlock('mmd_corporate/adminhtml_corporatelead'));
        $this->renderLayout();
    }
    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody($this->getLayout()->createBlock('mmd_corporate/adminhtml_corporatelead_grid')->toHtml());
    }
}
