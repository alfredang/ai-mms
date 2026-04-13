<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Copyattr extends MMD_Catalogmanagement_Model_Command_Abstract 
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label      = 'Copy Attributes';
        $this->_fieldLabel = 'From'; 
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
        $success = parent::execute($ids, $storeId, $val);
        
        $hlp = Mage::helper('catalogmanagement');
        
        $fromId = intVal(trim($val));
        if (!$fromId) {
            throw new Exception($hlp->__('Please provide a valid product ID'));
        }
        
        if (in_array($fromId, $ids)) {
            throw new Exception($hlp->__('Please remove source product from the selected products'));
        }        
        
        $product = Mage::getModel('catalog/product')
            ->setStoreId($storeId)
            ->load($fromId); 
        if (!$product->getId()){
            throw new Exception($hlp->__('Please provide a valid product ID'));
        }
        
          
        
        // check attributes
        $codes = Mage::getStoreConfig('catalogmanagement/general/attr');
        if (!$codes){
            throw new Exception($hlp->__('Please set attribute codes in the module configuration'));    
        }
       
        $config = array();
        
        $codes = explode(',', $codes); 
        foreach ($codes as $code){
            $code = trim($code);
            
            $attribute = Mage::getModel('catalog/product')->getResource()->getAttribute($code);
            if (!$attribute || !$attribute->getId()){
                throw new Exception($hlp->__('There is no product attribute with code `%s`, please compare values in the module configuration with catalog > attibutes > manage attributes section.', $code));    
            }
            
            if ($attribute->getIsUnique()){
                throw new Exception($hlp->__('Attribute `%s` is unique and can not be copied. Please remove the code in the module configuration.', $code));        
            }
            
            $type = $attribute->getBackendType();
            if ('static' == $type){
                throw new Exception($hlp->__('Attribute `%s` is static and can not be copied. Please remove the code in the module configuration.', $code));        
            }
            
            if (!isset($config[$type])){
                $config[$type] = array();
            }
            
            $config[$type][] = $attribute->getId();
        }
        
        // we do not use store id as it is global action
        $this->_copyData($fromId, $ids, $config);
        
        $success = $hlp->__('Attributes have been successfully copied.');
        
        return $success; 
    }
    
    protected function _copyData($fromId, $ids, $config)
    {
        $entityTypeId = Mage::getModel('eav/entity')->setType('catalog_product')->getTypeId();
        
        $db = Mage::getSingleton('core/resource')->getConnection('core_write');  
        foreach ($config as $type => $attributes){
            if (!$attributes){
                continue;
            }
            $attributes = implode(',', $attributes);
            
            $table  = Mage::getSingleton('core/resource')->getTableName(array('catalog/product', $type));
            foreach ($ids as $id){
                $sql = "INSERT INTO $table (`entity_type_id`, `attribute_id`, `store_id`, `entity_id`, `value`) "
                     . " SELECT t.`entity_type_id`, t.`attribute_id`, t.`store_id`, $id, t.`value`"
                     . " FROM $table AS t "
                     . " WHERE t.`entity_type_id`=$entityTypeId AND t.`entity_id`=$fromId AND t.`attribute_id` IN($attributes)"
                     . " ON DUPLICATE KEY UPDATE `value` = t.`value`"
                ;
                $db->raw_query($sql);
            }
        }
        
        return true;        
    }    
    
}