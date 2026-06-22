<?php
class MMD_Franchise_Adminhtml_FranchiseleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/franchise_leads');
    }

    public function indexAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/franchise_leads')
            ->_title($this->__('System'))->_title($this->__('Franchisee Leads'));
        $this->_addContent($this->getLayout()->createBlock('mmd_franchise/adminhtml_franchiselead'));
        $this->renderLayout();
    }

    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody(
            $this->getLayout()->createBlock('mmd_franchise/adminhtml_franchiselead_grid')->toHtml()
        );
    }
}
