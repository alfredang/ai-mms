<?php
class MMD_Trainer_Adminhtml_TrainerleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/trainer_leads');
    }
    public function indexAction()
    {
        $this->loadLayout()->_setActiveMenu('system/trainer_leads')
            ->_title($this->__('System'))->_title($this->__('Trainer Application Leads'));
        $this->_addContent($this->getLayout()->createBlock('mmd_trainer/adminhtml_trainerlead'));
        $this->renderLayout();
    }
    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody($this->getLayout()->createBlock('mmd_trainer/adminhtml_trainerlead_grid')->toHtml());
    }
}
