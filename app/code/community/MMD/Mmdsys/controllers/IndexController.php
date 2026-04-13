<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_IndexController extends Mage_Adminhtml_Controller_Action
{
    public function errorAction()
    {
        $this->loadLayout()->_setActiveMenu('system/mmdsys');
        $this->renderLayout();
    }
    
    public function indexAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/mmdsys')
            ->_title(Mage::helper('mmdsys')->__('Checkout Options Manager'));
        $this->renderLayout();
    }

    public function saveAction() {
        
        if ($data = $this->getRequest()->getPost('enable')) {
            if ($aErrorList = Mage::getModel('mmdsys/mmdsys')->saveData($data)) {
                $aModuleList = Mage::getModel('mmdsys/mmdsys')->getMMDModuleList();
                
				
                foreach ($aErrorList as $aError) {
                    $this->_getSession()->addError($aError);
                }
                
                if ($notices = Mage::getModel('mmdsys/mmdpatch')->getCompatiblityError($aModuleList)) {
                    foreach ($notices as $notice) {
                        $this->_getSession()->addNotice($notice);
                    }
                }
            } else {
                $this->_getSession()->addSuccess(Mage::helper('mmdsys')->__('Modules\' settings saved successfully'));
            }
        }
        
        $this->_redirect('*/*');
    }
    
    public function permissionsAction()
    {
        $mode = Mage::app()->getRequest()->getParam('mode');
        
        try {
            MMD_Mmdsys_Abstract_Service::get()->filesystem()->permissonsChange($mode);
            Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('mmdsys')->__('Write permissions were changed successfully'));
            // MMD_Mmdsys_Abstract_Service::get()->getCache()->remove('mmdsys_db_config'); // removed from 2.20
        } catch (Exception $e) {
            Mage::getSingleton('adminhtml/session')->addError(Mage::helper('mmdsys')->__('There was an error while changing write permissions. Permissions were not changed.'));        
        }
        
        $this->_redirect('*/index');
    }
    
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('system/mmdsys');
    }
}