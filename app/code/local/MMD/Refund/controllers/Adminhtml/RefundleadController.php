<?php
class MMD_Refund_Adminhtml_RefundleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/refund_leads');
    }
    public function indexAction()
    {
        $this->loadLayout()->_setActiveMenu('system/refund_leads')
            ->_title($this->__('System'))->_title($this->__('Refund Requests'));
        $this->_addContent($this->getLayout()->createBlock('mmd_refund/adminhtml_corporatelead'));
        $this->renderLayout();
    }
    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody($this->getLayout()->createBlock('mmd_refund/adminhtml_corporatelead_grid')->toHtml());
    }
}
