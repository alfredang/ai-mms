<?php

class MMD_Catalogmanagement_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
{
    public function doAction()
    {
        $productIds  = $this->getRequest()->getParam('product');
        $val         = trim($this->getRequest()->getParam('catalogmanagement_value'));        
        $commandType = trim($this->getRequest()->getParam('command'));
        $storeId     = (int)$this->getRequest()->getParam('store', 0);
        
        try {
            $command = MMD_Catalogmanagement_Model_Command_Abstract::factory($commandType);
            
            $success = $command->execute($productIds, $storeId, $val);
            if ($success){
                 $this->_getSession()->addSuccess($success);
            }
            
            // show non critical erroes to the user
            foreach ($command->getErrors() as $err){
                 $this->_getSession()->addError($err);
            }            
        }
        catch (Exception $e) {
            $this->_getSession()->addError($this->__('Error: %s', $e->getMessage()));
        } 
        
        $this->_redirect('adminhtml/catalog_product/index', array('store'=> $storeId));
        return $this;        
    }
}