<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Copyoptions extends MMD_Catalogmanagement_Model_Command_Abstract 
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label      = 'Copy Custom Options';
        $this->_fieldLabel = 'From Product ID'; 
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
        
        $srcId = intVal($val);
        $collection = $this->_getCollection($val);
        if (!count($collection)) {
            throw new Exception($hlp->__('Please provide a product with custom options'));
        }

        $options = array();
        foreach ($collection as $option) { 
            $options[] = $this->_convertToArray($option);
        }  
        
        $num = 0;
        foreach ($ids as $id) {
            if ($srcId == $id)  
                continue;
               
            try {
                $product = Mage::getModel('catalog/product');
                /* @var Mage_Catalog_Model_Product */
                $product->reset()
                    ->load($id)
                    ->setIsMassupdate(true)
                    ->setExcludeUrlRewrite(true);
                
                // set new    
                $product->setProductOptions($options); 
                $product->setCanSaveCustomOptions(!$product->getOptionsReadonly()); 
                
                // delete old
                $option = $product->getOptionInstance();
                $optionsCollection = $this->_getCollection($id);
                $optionsCollection->walk('delete');
                $option->unsetOptions();            
                
                $product->save();          
                
                ++$num;
            } 
            catch (Exception $e) {
                $this->_errors[] = $hlp->__('Can not copy the options to the product ID=%d, the error is: %s', 
                    $id, $e->getMessage());
            }               
        }
        
        if ($num){
            $success = $hlp->__('Total of %d products(s) have been successfully updated.', $num);
        }        
        
        return $success; 
    }
    
    
    /**
     * Get options associated with the product as a collection
     *
     * @param int $productId product id
     * @return Mage_Catalog_Model_Resource_Eav_Mysql4_Product_Option_Collection
     */
    protected function _getCollection($productId)
    {
        $collection = Mage::getModel('catalog/product_option')
            ->getCollection()
            ->addTitleToResult(Mage::app()->getStore()->getId())
            ->addPriceToResult(Mage::app()->getStore()->getId())
            ->addProductToFilter($productId)
            ->addValuesToResult();  
        return $collection;     
    }
    
    /**
     * Converts option object to the array representation
     *
     * @param Mage_Catalog_Model_Product_Option $option otion to convert
     * @return array
     */
    public function _convertToArray($option)
    {
        $commonArgs = array(
            'is_delete',
            'previous_type',
            'previous_group',
            'title',
            'type',
            'is_require',
            'sort_order',
            'values',
        );
        
        $priceArgs = array(
            'price_type',
            'price',
            'sku',
        );
        
        $txtArgs = array('max_characters');
        
        $fileArgs = array(
            'file_extension',
            'image_size_x',
            'image_size_y'
        );
        
        $type = $option->getType();
        switch ($type) {
            case 'file':
                $optionArgs = array_merge($commonArgs, $priceArgs, $fileArgs);
                break;
            case 'field':
            case 'area':
                $optionArgs = array_merge($commonArgs, $priceArgs, $txtArgs);
                break;
            case 'date':
            case 'date_time':
            case 'time':
                $optionArgs = array_merge($commonArgs, $priceArgs);
                break;
            default :
                $optionArgs = $commonArgs;
        }
        
        
        $optionAsArray = $option->toArray($optionArgs);
        if (in_array($type, array('drop_down', 'radio', 'checkbox', 'multiple'))) {
            $valueArgs = array_merge(array('is_delete', 'title', 'sort_order'), $priceArgs);
            $optionAsArray['values'] = array();
            foreach ($option->getValues() as $value) {
                $optionAsArray['values'][] = $value->toArray($valueArgs);
            }
        }
        
        return $optionAsArray;
    }
    
   
}