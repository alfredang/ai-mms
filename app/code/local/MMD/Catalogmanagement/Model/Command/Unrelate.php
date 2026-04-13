<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2008-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_Command_Unrelate extends MMD_Catalogmanagement_Model_Command_Abstract 
{ 
    public function __construct($type)
    {
        parent::__construct($type);
        $this->_label      = 'Remove Relations';
    }
    
    public function getLinkType()
    {
        $types = array(
            'uncrosssell' => Mage_Catalog_Model_Product_Link::LINK_TYPE_CROSSSELL,
            'unupsell'    => Mage_Catalog_Model_Product_Link::LINK_TYPE_UPSELL,
            'unrelate'    => Mage_Catalog_Model_Product_Link::LINK_TYPE_RELATED,
        );
        return $types[$this->_type];
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
        if (!is_array($ids)) {
            throw new Exception($hlp->__('Please select product(s)')); 
        }
        
        $hlp = Mage::helper('catalogmanagement');
        
        $num = 0;
        
        foreach ($ids as $id) {
            foreach ($ids as $id2) {
                if ($id == $id2){
                    continue;
                }
                $num += $this->_deleteLink($id, $id2);
            }
        }
        
        if ($num){
            if (1 == $num)
                $success = $hlp->__('Product association has been successfully deleted.');
            else {
                $success = $hlp->__(' %d product associations have been successfully deleted.', $num);
            }
        }
        
        return $success; 
    }
    
    //@todo optimize, move to one "delete values (), (), .. ON DUPLICATE IGNORE"
    protected function _deleteLink($productId, $linkedProductId)
    {
        $db     = Mage::getSingleton('core/resource')->getConnection('core_write');  
        $table  = Mage::getSingleton('core/resource')->getTableName('catalog/product_link'); 
        
        $select = $db->select()->from($table)
            ->where('link_type_id=?', $this->getLinkType())           
            ->where('product_id =?', $productId)           
            ->where('linked_product_id =?', $linkedProductId);
        $row = $db->fetchRow($select); 

        $deletedCnt = 0;
        if ($row){
            $db->delete($table, array(
                'product_id = ?'        => $productId,
                'linked_product_id = ?' => $linkedProductId,
                'link_type_id = ?'      => $this->getLinkType(),
            )); 
            $deletedCnt = 1;                   
        }
        
        return $deletedCnt;        
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