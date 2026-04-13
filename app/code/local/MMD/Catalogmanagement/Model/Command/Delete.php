<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Delete extends MMD_Catalogmanagement_Model_Command_Abstract
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label = 'Fast Delete';
    } 
        
    /**
     * Executes the command
     *
     * @param array $ids product ids
     * @param int $storeId store id
     * @param string $val field value
     * @return string success message if any
     */    
    public function execute($ids, $storeId, $val)
    {
        // we don't need to call parent as there are no values needed
        $this->_errors = array();
        
        $hlp = Mage::helper('catalogmanagement');
        if (!is_array($ids)) {
            throw new Exception($hlp->__('Please select product(s)')); 
        }
        
        // do the bulk delete skiping all _before/_after delete observers
        // and indexing, as it cause thousands of queries in the
        // getProductParentsByChild function
        
        $db     = Mage::getSingleton('core/resource')->getConnection('core_write');  
        $table  = Mage::getSingleton('core/resource')->getTableName('catalog/product');        
     
        // foreign keys delete the rest
        $db->delete($table, $db->quoteInto('entity_id IN(?)', $ids));
        
        $hlp = Mage::helper('catalogmanagement');
        $success = $hlp->__('Products have been successfully deleted. We recommend to refresh indexes at the System > Index Management page.');
        
        return $success; 
    }
    
    /**
     * Returns value field options for the mass actions block
     *
     * @param string $title field title
     * @return array
     */
    protected function _getValueField($title)
    {
        $title = $title; // prevents Zend Studio validtaion error
        return null;       
    }
}