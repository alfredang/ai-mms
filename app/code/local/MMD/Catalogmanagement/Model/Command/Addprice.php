<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Addprice extends MMD_Catalogmanagement_Model_Command_Modifyprice
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label      = 'Modify Price using Cost';
    } 
    
    protected function _prepareQuery($table, $value, $where)
    {
        $where[] = 't.`value` > 0 ';
        $id = Mage::getSingleton('eav/config')
            ->getAttribute('catalog_product', 'price')
            ->getAttributeId();
            
        $value = str_replace('`value`', 't.`value`', $value);    
        $sql = "INSERT INTO $table (entity_type_id, attribute_id , store_id, entity_id, `value`) "
             . " SELECT entity_type_id, $id, store_id, entity_id, $value FROM $table AS t"
             . " WHERE " . join(' AND ', $where)
             . " ON DUPLICATE KEY UPDATE `value` = $value";
        return $sql;
    } 
    
    protected function _getAttrCode()
    {
        return 'cost';
    }  
}