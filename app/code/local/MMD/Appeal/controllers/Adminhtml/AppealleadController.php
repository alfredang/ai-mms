<?php
class MMD_Appeal_Adminhtml_AppealleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/appeal_leads');
    }
    public function indexAction()
    {
        $this->loadLayout()->_setActiveMenu('system/appeal_leads')
            ->_title($this->__('System'))->_title($this->__('Assessment Appeals'));
        $this->_addContent($this->getLayout()->createBlock('mmd_appeal/adminhtml_corporatelead'));
        $this->renderLayout();
    }
    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody($this->getLayout()->createBlock('mmd_appeal/adminhtml_corporatelead_grid')->toHtml());
    }
}
