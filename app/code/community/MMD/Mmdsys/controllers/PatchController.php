<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_PatchController extends Mage_Adminhtml_Controller_Action
{
    public function instructionAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/mmdsys')
            ->_title(Mage::helper('mmdsys')->__('MMD Modules Manager'))
            ->_title(Mage::helper('mmdsys')->__('MMD Manual Patch Instructions'));
        $this->renderLayout();
    }
    
    public function indexAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/mmdsys')
            ->_title(Mage::helper('mmdsys')->__('MMD Modules Manager'))
            ->_title(Mage::helper('mmdsys')->__('Customized Templates'));
        $this->renderLayout();
    }
    
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('system/mmdsys');
    }
}