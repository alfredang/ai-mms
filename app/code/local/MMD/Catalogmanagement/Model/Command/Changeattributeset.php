<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Changeattributeset extends MMD_Catalogmanagement_Model_Command_Abstract
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label      = 'Change Attribute Set';
        $this->_fieldLabel = 'To';
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
        
        $num = 0;
        foreach ($ids as $productId) {
            try {
                Mage::getSingleton('catalog/product')
                    ->unsetData()
                    ->setStoreId($storeId)
                    ->load($productId)
                    ->setAttributeSetId($val)
                    ->setIsMassupdate(true)
                    ->save();
                 ++$num;
            } 
            catch (Exception $e) {
                $this->errors[] = $hlp->__('Can not chnage the attribute set for product ID %d, error is:', 
                    $e->getMessage());
            }    
        }
        Mage::dispatchEvent('catalog_product_massupdate_after', array('products' => $ids));
        
        if ($num){
            $success = $hlp->__('Total of %d products(s) have been successfully updated.', $num);
        }
        
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
        $field = parent::_getValueField($title);
        $field = $field; // prvents Zend Studio validation error
        $field['catalogmanagement_value']['type'] = 'select';
        $field['catalogmanagement_value']['values'] = Mage::getResourceModel('eav/entity_attribute_set_collection')
            ->setEntityTypeFilter(Mage::getModel('catalog/product')->getResource()->getTypeId())
            ->load()
            ->toOptionHash();      

        return $field;       
    }
}