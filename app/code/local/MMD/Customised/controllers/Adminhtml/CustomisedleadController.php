<?php
class MMD_Customised_Adminhtml_CustomisedleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd_marketing/customised_leads');
    }
    public function indexAction()
    {
        $this->loadLayout()->_setActiveMenu('mmd_marketing/customised_leads')
            ->_title($this->__('Marketing'))->_title($this->__('Customised Application Leads'));
        $this->_addContent($this->getLayout()->createBlock('mmd_customised/adminhtml_customisedlead'));
        $this->renderLayout();
    }
    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody($this->getLayout()->createBlock('mmd_customised/adminhtml_customisedlead_grid')->toHtml());
    }
}
