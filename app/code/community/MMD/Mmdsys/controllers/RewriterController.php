<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_RewriterController extends Mage_Adminhtml_Controller_Action
{
    public function preDispatch()
    {
        $result = parent::preDispatch();

        if (true === $this->_getSession()->getData('mmdsys_rewriter_require_rebuild')) {
            $this->_getSession()->unsetData('mmdsys_rewriter_require_rebuild');
            Mage::getModel('mmdsys/rewriter')->prepare();
        }

        return $result;
    }
    
    public function indexAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/mmdsys')
            ->_title(Mage::helper('mmdsys')->__('MMD Modules Manager'))
            ->_title(Mage::helper('mmdsys')->__('Rewrites Manager'));
        $this->renderLayout();
    }
    
    public function saveAction()
    {
        $currentExtension = Mage::app()->getRequest()->getParam('extension');
        
        $classOrder = Mage::app()->getRequest()->getPost('rewrites');
        $excludeClasses = Mage::app()->getRequest()->getPost('exclude_classes');
        if (!$classOrder) {
            $classOrder = array();
        }
        
        $failed = false;
        foreach ($classOrder as $baseClass => $rewriteClasses) {
            $usedOrders = array();
            foreach ($rewriteClasses as $class => $order) {
                if (!is_numeric($order)) {
                    $failed = true;
                    $this->_getSession()->addError(Mage::helper('mmdsys')->__('Please make sure the numeric values only are entered.'));
                    break(2);
                }
                if (in_array($order, $usedOrders)) {
                    $failed = true;
                    $this->_getSession()->addError(Mage::helper('mmdsys')->__('Please make sure the order numbers are not duplicated.'));
                    break(2);
                }
                $usedOrders[] = $order;
            }
        }
        
        if (!$failed) {
            if (!$currentExtension) {
                Mage::helper('mmdsys/rewriter')->saveOrderConfig($classOrder);
            } else  {
                Mage::helper('mmdsys/rewriter')->mergeOrderConfig($classOrder);
            }

            /* Save excluded base classes */
            Mage::helper('mmdsys/rewriter')->saveExcludeClassesConfig($excludeClasses);
            $this->_getSession()->setData('mmdsys_rewriter_require_rebuild', true);
            $this->_getSession()->addSuccess(Mage::helper('mmdsys')->__('Rewrites changes saved successfully.'));
        }
        $this->_redirect('*/*', array('_current'=>true));
    }
    
    public function resetAction()
    {
        Mage::helper('mmdsys/rewriter')->removeOrderConfig();
        $this->_getSession()->setData('mmdsys_rewriter_require_rebuild', true);
        $this->_getSession()->addSuccess(Mage::helper('mmdsys')->__('Rewrites order resetted successfully.'));
        $this->_redirect('*/*');
    }
    
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('system/mmdsys');
    }
}