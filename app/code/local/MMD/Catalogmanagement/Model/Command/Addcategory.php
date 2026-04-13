<?php

/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Addcategory extends MMD_Catalogmanagement_Model_Command_Abstract 
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label      = 'Assign Category';
        $this->_fieldLabel = 'Category IDs'; 
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
        
        $catIds = explode(',', trim($val));
        if (!is_array($catIds)) {
            throw new Exception($hlp->__('Please provide comma separated category IDs'));
        }

        $numAffectedCats  = 0;
        $allAffectedProducts = array();
        
        foreach ($catIds as $categoryId) {
            $category = Mage::getModel('catalog/category')
                ->setStoreId($storeId)
                ->load($categoryId);
                
            if (!$category->getId()){
                $this->_errors[] = $hlp->__('ID = `%s` has been skipped', $categoryId);
                continue;
            }
            
            $positions = $category->getProductsPosition();
            $currentAffectedProducts = array();
            foreach ($ids as $productId){
                $has = isset($positions[$productId]);
                
                if ('addcategory' == $this->_type && !$has){ // add only new
                    $positions[$productId] = 0;
                    $currentAffectedProducts[] = $productId;
                }
                elseif('removecategory' == $this->_type && $has){ //remove only existing
                    unset($positions[$productId]);
                    $currentAffectedProducts[] = $productId;
                }
            }
                
            $category->setPostedProducts($positions); 
            try {  
                $category->save();
                ++$numAffectedCats;
                $allAffectedProducts = array_merge($allAffectedProducts, $currentAffectedProducts);
                $allAffectedProducts = array_unique($allAffectedProducts);
            } 
            catch (Exception $e) {
                $this->_errors[] = $hlp->__('Can not handle the category ID=%s, the error is: %s', 
                    $categoryId, $e->getMessage());
            }     
        }
        if ($numAffectedCats){
            $success = $hlp->__('Total of %d categories(s) and %d products(s) have been successfully updated.', 
                $numAffectedCats, count($allAffectedProducts));
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
        
        $storeId    = (int)Mage::app()->getRequest()->getParam('store', 0);
        if (Mage::getStoreConfig('catalogmanagement/general/categories', $storeId)){ 
            $rootId = Mage::app()->getStore($storeId)->getRootCategoryId();
            $field['catalogmanagement_value']['label']   = Mage::helper('catalogmanagement')->__('Category');
            $field['catalogmanagement_value']['type']    = 'select';
            $field['catalogmanagement_value']['values']  = $this->getTree($rootId);
        } 
        
        return $field;      
    } 
       
    /**
     * Genarates tree of all categories
     *
     * @param int $rootId root category id
     * @return array sorted list category_id=>title
     */
    protected function getTree($rootId)
    {
        $tree = array();
        
        $collection = Mage::getModel('catalog/category')
            ->getCollection()->addNameToResult();
        
        $pos = array();
        foreach ($collection as $cat){
            $path = explode('/', $cat->getPath());
            if ((!$rootId || in_array($rootId, $path)) && $cat->getLevel() && $cat->getName()){
                $tree[$cat->getId()] = array(
                    'label' => str_repeat('--', $cat->getLevel()) . $cat->getName(), 
                    'value' => $cat->getId(),
                    'path'  => $path,
                );
            }
            $pos[$cat->getId()] = $cat->getPosition();
        }
        
        foreach ($tree as $catId => $cat){
            $order = array();
            foreach ($cat['path'] as $id){
		$order[] = isset($pos[$id]) ? $pos[$id] : 0;
            }
            $tree[$catId]['order'] = $order;
        }
        
        usort($tree, array($this, 'compare'));
        
        return $tree;
    }
    
    /**
     * Compares category data. Must be public as used as a callback value
     *
     * @param array $a
     * @param array $b
     * @return int 0, 1 , or -1
     */
    public function compare($a, $b)
    {
        foreach ($a['path'] as $i => $id){
            if (!isset($b['path'][$i])){ 
                // B path is shorther then A, and values before were equal
                return 1;
            }
            if ($id != $b['path'][$i]){
                // compare category positions at the same level
                return ($a['order'][$i] < $b['order'][$i]) ? -1 : 1;
            }
        }
        // B path is longer or equal then A, and values before were equal
        return ($a['value'] == $b['value']) ? 0 : -1;
    }      
}
