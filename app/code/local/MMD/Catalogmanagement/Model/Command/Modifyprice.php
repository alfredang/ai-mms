<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Modifyprice extends MMD_Catalogmanagement_Model_Command_Abstract
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label      = 'Update Price';
        $this->_fieldLabel = 'By';
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
        parent::execute($ids, $storeId, $val);
        
        $hlp = Mage::helper('catalogmanagement');
        
        if (!preg_match('/^[+-][0-9]+(\.[0-9]+)?%?$/', $val)){
            throw new Exception($hlp->__('Please provide the difference as +12.5, -12.5, +12.5% or -12.5%')); 
        }
        
        $sign = substr($val, 0, 1);
        $val  = substr($val, 1);
        
        $percent = ('%' == substr($val, -1, 1));
        if ($percent)
            $val = substr($val, 0, -1);
            
        $val = floatval($val);
        if ($val < 0.00001){
            throw new Exception($hlp->__('Please provide a non empty difference'));            
        }
        
        $attrCode = $this->_getAttrCode();
        $this->_updateAttribute($attrCode, $ids, $storeId, array(
            'sign' => $sign, 'val' => $val, 'percent' => $percent)
        );
        
        if (version_compare(Mage::getVersion(), '1.4.1.0') > 0){
            $obj = new Varien_Object();
            $obj->setData(array(
                'product_ids'       => array_unique($ids),
                'attributes_data'   => array($attrCode => true), // known indexers use just keys
                'store_id'          => $storeId,
            ));
            // register mass action indexer event
            Mage::getSingleton('index/indexer')->processEntityAction(
                $obj, Mage_Catalog_Model_Product::ENTITY, Mage_Index_Model_Event::TYPE_MASS_ACTION
            );
        }
        
        $success = $hlp->__('Total of %d products(s) have been successfully updated', count($ids));
        return $success; 
    }
    
    /**
     * Mass update attribute value
     *
     * @param string $attrCode attribute code, price or special price
     * @param array $productIds applied product ids
     * @param int $storeId store id
     * @param array $diff difference data (sign, value, if percentage)
     * @return bool true
     */
    protected function _updateAttribute($attrCode, $productIds, $storeId, $diff)
    {
        $attribute = Mage::getSingleton('eav/config')->getAttribute('catalog_product', $attrCode);
        
        $db     = Mage::getSingleton('core/resource')->getConnection('core_write');  
        $table  = $attribute->getBackend()->getTable();        
         
        $where = array(
            $db->quoteInto('entity_id IN(?)', $productIds),
            $db->quoteInto('attribute_id=?', $attribute->getAttributeId()),
        );
        
        /**
         * If we work in single store mode all values should be saved just
         * for default store id. In this case we clear all not default values
         */
        
        $defaultStoreId = Mage_Catalog_Model_Abstract::DEFAULT_STORE_ID;
        if (Mage::app()->isSingleStoreMode()) {
            $db->delete($table, join(' AND ', array_merge($where, array(
                $db->quoteInto('store_id <> ?', $defaultStoreId)
            ))));
        } 
        
        $value = $diff['percent'] ? '`value` * ' . $diff['val'] . '/ 100' : $diff['val'];
        $value = '`value`' . $diff['sign'] . $value; 
        
        $rounding = floatval(Mage::getStoreConfig('catalogmanagement/general/rounding', $storeId));
        if ($rounding){ 
            $value = 'FLOOR(' . $value . ') + ' . $rounding;      
        }
        
        $storeIds  = array();
        if ($attribute->isScopeStore()) {
            $where[] = $db->quoteInto('store_id = ?', $storeId);
            $storeIds[] = $storeId;
        } 
        elseif ($attribute->isScopeWebsite() && $storeId != $defaultStoreId) {
            $storeIds = Mage::app()->getStore($storeId)->getWebsite()->getStoreIds(true);
            $where[] = $db->quoteInto('store_id IN(?)', $storeIds);
        } 
        else {
            $where[] = $db->quoteInto('store_id = ?', $defaultStoreId);
        }  
        
        // in case of store-view or website scope we need to insert default values
        // first, to be able to update them. 
        // @todo: Special price can be null in the base store
        if ($storeIds){
            $cond = array(
                $db->quoteInto('t.entity_id IN(?)', $productIds),
                $db->quoteInto('t.attribute_id=?', $attribute->getAttributeId()),
                't.store_id = ' . $defaultStoreId,
            ); 
            foreach ($storeIds as $id){           
                // copy attr value from global scope if current attr value does not exists.
                $sql = "INSERT IGNORE INTO $table (`entity_type_id`, `attribute_id`, `store_id`, `entity_id`, `value`) "
                     . " SELECT t.`entity_type_id`, t.`attribute_id`, $id, t.`entity_id`, t.`value` FROM $table AS t"
                     . " WHERE " . join(' AND ', $cond)
                ;
                $db->raw_query($sql);  
            }
        }
        
        $sql = $this->_prepareQuery($table, $value, $where);
        $db->raw_query($sql);     
              
        return true;
    }

    protected function _prepareQuery($table, $value, $where)
    {
        $sql = "UPDATE $table SET `value` = $value WHERE " . join(' AND ', $where);
        return $sql;
    }   
    
    protected function _getAttrCode()
    {
        return 'price';
    }    
    
}