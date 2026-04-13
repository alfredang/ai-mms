<?php
/**
 * MMD
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the MMD EULA that is bundled with
 * this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://www.magemobiledesign.com/LICENSE-1.0.html
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade the extension
 * to newer versions in the future. If you wish to customize the extension
 * for your needs please refer to http://www.magemobiledesign.com/ for more information
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @copyright  Copyright (c) 2012 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * Advanced Product Options extension
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @author     MMD Dev Team
 */

class MMD_CustomOptions_Model_Mysql4_Product_Option_Collection extends Mage_Catalog_Model_Resource_Eav_Mysql4_Product_Option_Collection
{
    public function getOptions($storeId) {
        $this->getSelect()
            ->joinLeft(array('default_option_price' => $this->getTable('catalog/product_option_price')),
                '`default_option_price`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`default_option_price`.store_id = ?', 0),
                array('default_price' => 'price', 'default_price_type' => 'price_type'))
            ->joinLeft(array('store_option_price' => $this->getTable('catalog/product_option_price')),
                '`store_option_price`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`store_option_price`.store_id = ?', $storeId),
                array('store_price' => 'price', 'store_price_type' => 'price_type',
                'price' => new Zend_Db_Expr('IFNULL(`store_option_price`.price,`default_option_price`.price)'),
                'price_type' => new Zend_Db_Expr('IFNULL(`store_option_price`.price_type,`default_option_price`.price_type)')))
            
            // add ViewMode
            ->joinLeft(array('default_option_view_mode' => $this->getTable('customoptions/option_view_mode')),
                '`default_option_view_mode`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`default_option_view_mode`.store_id = ?', 0),
                array('default_view_mode' => 'view_mode'))
            ->joinLeft(array('store_option_view_mode' => $this->getTable('customoptions/option_view_mode')),
                '`store_option_view_mode`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`store_option_view_mode`.store_id = ?', $storeId),
                array('store_view_mode' => 'view_mode',
                'view_mode' => new Zend_Db_Expr('IFNULL(`store_option_view_mode`.view_mode,`default_option_view_mode`.view_mode)')))                
                
            // add Description
            ->joinLeft(array('default_option_description' => $this->getTable('customoptions/option_description')),
                '`default_option_description`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`default_option_description`.store_id = ?', 0),
                array('default_description' => 'description'))
            ->joinLeft(array('store_option_description' => $this->getTable('customoptions/option_description')),
                '`store_option_description`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`store_option_description`.store_id = ?', $storeId),
                array('store_description' => 'description',
                'description' => new Zend_Db_Expr('IFNULL(`store_option_description`.description,`default_option_description`.description)')))
            
            // add DefaultText
            ->joinLeft(array('default_option_default_text' => $this->getTable('customoptions/option_default')),
                '`default_option_default_text`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`default_option_default_text`.store_id = ?', 0),
                array('default_default_text' => 'default_text'))
            ->joinLeft(array('store_option_default_text' => $this->getTable('customoptions/option_default')),
                '`store_option_default_text`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`store_option_default_text`.store_id = ?', $storeId),
                array('store_default_text' => 'default_text',
                'default_text' => new Zend_Db_Expr('IFNULL(`store_option_default_text`.default_text,`default_option_default_text`.default_text)')))    
                
            ->join(array('default_option_title' => $this->getTable('catalog/product_option_title')),
                '`default_option_title`.option_id = `main_table`.option_id',
                array('default_title' => 'title'))
            ->joinLeft(array('store_option_title' => $this->getTable('catalog/product_option_title')),
                '`store_option_title`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`store_option_title`.store_id = ?', $storeId),
                array('store_title' => 'title',
                'title' => new Zend_Db_Expr('IFNULL(`store_option_title`.title,`default_option_title`.title)')))
            ->where('`default_option_title`.store_id = ?', 0);

        return $this;
    }

    public function addViewModeToResult($storeId) {
        $this->getSelect()
            ->joinLeft(array('default_option_view_mode' => $this->getTable('customoptions/option_view_mode')),
                '`default_option_view_mode`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`default_option_view_mode`.store_id = ?', 0),
                array('default_view_mode' => 'view_mode'))
            ->joinLeft(array('store_option_view_mode' => $this->getTable('customoptions/option_view_mode')),
                '`store_option_view_mode`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`store_option_view_mode`.store_id = ?', $storeId),
                array('store_view_mode' => 'view_mode',
                'view_mode' => new Zend_Db_Expr('IFNULL(`store_option_view_mode`.view_mode,`default_option_view_mode`.view_mode)')));
        return $this;
    }
    
    public function addDescriptionToResult($storeId) {
        $this->getSelect()
            ->joinLeft(array('default_option_description' => $this->getTable('customoptions/option_description')),
                '`default_option_description`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`default_option_description`.store_id = ?', 0),
                array('default_description' => 'description'))
            ->joinLeft(array('store_option_description' => $this->getTable('customoptions/option_description')),
                '`store_option_description`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`store_option_description`.store_id = ?', $storeId),
                array('store_description' => 'description',
                'description' => new Zend_Db_Expr('IFNULL(`store_option_description`.description,`default_option_description`.description)')));
        return $this;
    }
    
    
    public function addDefaultTextToResult($storeId) {
        $this->getSelect()
            ->joinLeft(array('default_option_default_text' => $this->getTable('customoptions/option_default')),
                '`default_option_default_text`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`default_option_default_text`.store_id = ?', 0),
                array('default_default_text' => 'default_text'))
            ->joinLeft(array('store_option_default_text' => $this->getTable('customoptions/option_default')),
                '`store_option_default_text`.option_id = `main_table`.option_id AND '.$this->getConnection()->quoteInto('`store_option_default_text`.store_id = ?', $storeId),
                array('store_default_text' => 'default_text',
                'default_text' => new Zend_Db_Expr('IFNULL(`store_option_default_text`.default_text,`default_option_default_text`.default_text)')));
        return $this;
    }
    
    public function addTemplateTitleToResult() {        
        $this->getSelect()->columns(array('group_title' =>new Zend_Db_Expr('(SELECT `title` FROM '.$this->getTable('customoptions/group').' AS group_tbl LEFT JOIN '.$this->getTable('customoptions/relation').' AS relation_tbl ON `group_tbl`.`group_id` = `relation_tbl`.`group_id` WHERE `relation_tbl`.`option_id` = `main_table`.option_id)')));
        // ->joinLeft - does not work!
        return $this;
    }
    
    // fix magento bug!! ->
    public function addTitleToResult($storeId) {
        if (Mage::app()->getStore()->isAdmin() && Mage::app()->getRequest()->getControllerName()!='catalog_product') {
            $storeId = Mage::getSingleton('adminhtml/session_quote')->getStoreId();
        }        
        return parent::addTitleToResult($storeId);
    }
    public function addPriceToResult($storeId) {
        if (Mage::app()->getStore()->isAdmin() && Mage::app()->getRequest()->getControllerName()!='catalog_product') {
            $storeId = Mage::getSingleton('adminhtml/session_quote')->getStoreId();
        }        
        return parent::addPriceToResult($storeId);
    }
    public function addValuesToResult($storeId = null) {
        if (Mage::app()->getStore()->isAdmin() && Mage::app()->getRequest()->getControllerName()!='catalog_product') {
            $storeId = Mage::getSingleton('adminhtml/session_quote')->getStoreId();
        }        
        return parent::addValuesToResult($storeId);
    }
    // end fix
    
}
