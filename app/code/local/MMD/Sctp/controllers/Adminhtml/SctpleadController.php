<?php
class MMD_Sctp_Adminhtml_SctpleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/sctp_leads');
    }

    public function indexAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/sctp_leads')
            ->_title($this->__('System'))->_title($this->__('SCTP Program Leads'));
        $this->_addContent($this->getLayout()->createBlock('mmd_sctp/adminhtml_sctplead'));
        $this->renderLayout();
    }

    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody(
            $this->getLayout()->createBlock('mmd_sctp/adminhtml_sctplead_grid')->toHtml()
        );
    }
}
