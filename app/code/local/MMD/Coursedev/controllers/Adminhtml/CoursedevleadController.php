<?php
class MMD_Coursedev_Adminhtml_CoursedevleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/coursedev_leads');
    }

    public function indexAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/coursedev_leads')
            ->_title($this->__('System'))->_title($this->__('Course Development Leads'));
        $this->_addContent($this->getLayout()->createBlock('mmd_coursedev/adminhtml_coursedevlead'));
        $this->renderLayout();
    }

    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody(
            $this->getLayout()->createBlock('mmd_coursedev/adminhtml_coursedevlead_grid')->toHtml()
        );
    }
}
