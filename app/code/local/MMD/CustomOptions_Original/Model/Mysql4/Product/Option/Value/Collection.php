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
 * @copyright  Copyright (c) 2013 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * Advanced Product Options extension
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @author     MMD Dev Team
 */

class MMD_CustomOptions_Model_Mysql4_Product_Option_Value_Collection extends Mage_Catalog_Model_Resource_Eav_Mysql4_Product_Option_Value_Collection {
    public function addPriceToResult($storeId) {
        $this->getSelect()
            ->joinLeft(array('default_value_price'=>$this->getTable('catalog/product_option_type_price')),
                '`default_value_price`.option_type_id=`main_table`.option_type_id AND '.$this->getConnection()->quoteInto('`default_value_price`.store_id=?',0),
                array('default_option_type_price_id'=>'option_type_price_id', 'default_price'=>'price', 'default_price_type'=>'price_type', 'default_special_price'=>'special_price', 'default_special_comment'=>'special_comment'))
            ->joinLeft(array('store_value_price'=>$this->getTable('catalog/product_option_type_price')),
                '`store_value_price`.option_type_id=`main_table`.option_type_id AND '.$this->getConnection()->quoteInto('`store_value_price`.store_id=?', $storeId),
                array(
                'store_option_type_price_id'=>'option_type_price_id',
                'store_price'=>'price',
                'store_price_type'=>'price_type',
                'store_special_price'=>'special_price',
                'store_special_comment'=>'special_comment',
                'option_type_price_id'=>new Zend_Db_Expr('IFNULL(`store_value_price`.option_type_price_id,`default_value_price`.option_type_price_id)'),
                'price'=>new Zend_Db_Expr('IFNULL(`store_value_price`.price,`default_value_price`.price)'),
                'price_type'=>new Zend_Db_Expr('IFNULL(`store_value_price`.price_type,`default_value_price`.price_type)'),
                'special_price'=>new Zend_Db_Expr('IFNULL(`store_value_price`.special_price,`default_value_price`.special_price)'),
                'special_comment'=>new Zend_Db_Expr('IFNULL(`store_value_price`.special_comment,`default_value_price`.special_comment)')
                )
            );
        return $this;
    }    
}
