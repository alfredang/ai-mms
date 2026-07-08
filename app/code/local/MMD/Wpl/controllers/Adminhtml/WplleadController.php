<?php
class MMD_Wpl_Adminhtml_WplleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/wpl_leads');
    }

    public function indexAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/wpl_leads')
            ->_title($this->__('System'))->_title($this->__('WPL Development Leads'));
        $this->_addContent($this->getLayout()->createBlock('mmd_wpl/adminhtml_wpllead'));
        $this->renderLayout();
    }

    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody(
            $this->getLayout()->createBlock('mmd_wpl/adminhtml_wpllead_grid')->toHtml()
        );
    }
}
