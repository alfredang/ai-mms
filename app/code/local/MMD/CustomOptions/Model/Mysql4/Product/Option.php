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

class MMD_CustomOptions_Model_Mysql4_Product_Option extends Mage_Catalog_Model_Resource_Eav_Mysql4_Product_Option {

    protected function _afterSave(Mage_Core_Model_Abstract $object) {
        $storeId = Mage_Catalog_Model_Abstract::DEFAULT_STORE_ID;
        if ($object->getStoreId() != $storeId) {
            $storeId = $object->getStoreId();
        }
        
        // save view_mode
        $table = $this->getTable('customoptions/option_view_mode');
        if (!$object->getData('scope', 'view_mode') && !is_null($object->getViewMode())) {
            $select = $this->_getReadAdapter()->select()
                    ->from($table)
                    ->where('option_id = ?', $object->getId())
                    ->where('store_id = ?', $storeId);

            if ($this->_getReadAdapter()->fetchOne($select)) {
                $this->_getWriteAdapter()->update(
                        $table, array('view_mode' => $object->getViewMode()), 'option_id = ' . $object->getId() . ' AND store_id = ' . $storeId
                );
            } else {
                $this->_getWriteAdapter()->insert(
                    $table, array(
                        'option_id' => $object->getId(),
                        'store_id' => $storeId,
                        'view_mode' => $object->getViewMode()
                    )
                );
            }
        } elseif ($object->getData('scope', 'view_mode') || is_null($object->getViewMode())) {
            $this->_getWriteAdapter()->delete(
                    $table, 'option_id = ' . $object->getId() . ' AND store_id = ' . $storeId
            );
        }
        
        // save description
        $table = $this->getTable('customoptions/option_description');
        if (!$object->getData('scope', 'description') && $object->getDescription()) {
            $select = $this->_getReadAdapter()->select()
                    ->from($table)
                    ->where('option_id = ?', $object->getId())
                    ->where('store_id = ?', $storeId);

            if ($this->_getReadAdapter()->fetchOne($select)) {
                $this->_getWriteAdapter()->update(
                        $table, array('description' => $object->getDescription()), 'option_id = ' . $object->getId() . ' AND store_id = ' . $storeId
                );
            } else {
                $this->_getWriteAdapter()->insert(
                        $table, array(
                    'option_id' => $object->getId(),
                    'store_id' => $storeId,
                    'description' => $object->getDescription()
                        )
                );
            }
        } elseif ($object->getData('scope', 'description') || !$object->getDescription()) {
            $this->_getWriteAdapter()->delete(
                    $table, 'option_id = ' . $object->getId() . ' AND store_id = ' . $storeId
            );
        }
        
        // save default text
        $table = $this->getTable('customoptions/option_default');
        if (!$object->getData('scope', 'default_text') && $object->getDefaultText()) {
            $select = $this->_getReadAdapter()->select()
                    ->from($table)
                    ->where('option_id = ?', $object->getId())
                    ->where('store_id = ?', $storeId);
            
            if ($this->_getReadAdapter()->fetchOne($select)) {
                $this->_getWriteAdapter()->update(
                        $table, array('default_text' => $object->getDefaultText()), 'option_id = ' . $object->getId() . ' AND store_id = ' . $storeId
                );
            } else {
                $this->_getWriteAdapter()->insert(
                        $table, array(
                    'option_id' => $object->getId(),
                    'store_id' => $storeId,
                    'default_text' => $object->getDefaultText()
                        )
                );
            }
        } elseif ($object->getData('scope', 'default_text') || !$object->getDefaultText()) {
            $this->_getWriteAdapter()->delete(
                    $table, 'option_id = ' . $object->getId() . ' AND store_id = ' . $storeId
            );
        }
        
        return parent::_afterSave($object);
    }

    public function getTitle($optionId, $storeId) {
        $tablePrefix = (string) Mage::getConfig()->getTablePrefix();
        $select = $this->_getReadAdapter()->select()
                ->from(array('default_title' => $tablePrefix . 'catalog_product_option_title'), array('title'=>new Zend_Db_Expr('IFNULL(`store_title`.title,`default_title`.title)')))
                ->joinLeft(array('store_title' => $tablePrefix . 'catalog_product_option_title'), '`store_title`.option_id=`default_title`.option_id AND '.$this->_getReadAdapter()->quoteInto('`store_title`.store_id = ?', $storeId), '')
                ->where('default_title.option_id = ?', $optionId)
                ->where('default_title.store_id = 0');
    	return $this->_getReadAdapter()->fetchOne($select);
    }
    
    public function getValueTitle($optionTypeId, $storeId) {
        $tablePrefix = (string) Mage::getConfig()->getTablePrefix();
        $select = $this->_getReadAdapter()->select()
                ->from(array('default_title' => $tablePrefix . 'catalog_product_option_type_title'), array('title'=>new Zend_Db_Expr('IFNULL(`store_title`.title,`default_title`.title)')))
                ->joinLeft(array('store_title' => $tablePrefix . 'catalog_product_option_type_title'), '`store_title`.option_type_id=`default_title`.option_type_id AND '.$this->_getReadAdapter()->quoteInto('`store_title`.store_id = ?', $storeId), '')
                ->where('default_title.option_type_id = ?', $optionTypeId)
                ->where('default_title.store_id = 0');
    	return $this->_getReadAdapter()->fetchOne($select);
    }
    
    public function duplicate(Mage_Catalog_Model_Product_Option $object, $oldProductId, $newProductId) {
        $write  = $this->_getWriteAdapter();
        $read   = $this->_getReadAdapter();

        $optionsCond = array();
        $optionsData = array();

        // read and prepare original product options
        $select = $read->select()
            ->from($this->getTable('catalog/product_option'))
            ->where('product_id=?', $oldProductId);
        $query = $read->query($select);
        while ($row = $query->fetch()) {
            $optionsData[$row['option_id']] = $row;
            $optionsData[$row['option_id']]['product_id'] = $newProductId;
            unset($optionsData[$row['option_id']]['option_id']);
        }

        // insert options to duplicated product
        foreach ($optionsData as $oId => $data) {
            $write->insert($this->getMainTable(), $data);
            $optionsCond[$oId] = $write->lastInsertId();
        }

        // copy options prefs
        foreach ($optionsCond as $oldOptionId => $newOptionId) {
            // title
            $table = $this->getTable('catalog/product_option_title');
            $sql = 'REPLACE INTO `' . $table . '` '
                . 'SELECT NULL, ' . $newOptionId . ', `store_id`, `title`'
                . 'FROM `' . $table . '` WHERE `option_id`=' . $oldOptionId;
            $this->_getWriteAdapter()->query($sql);

            // price
            $table = $this->getTable('catalog/product_option_price');
            $sql = 'REPLACE INTO `' . $table . '` '
                . 'SELECT NULL, ' . $newOptionId . ', `store_id`, `price`, `price_type`'
                . 'FROM `' . $table . '` WHERE `option_id`=' . $oldOptionId;
            $this->_getWriteAdapter()->query($sql);
            
            // view_mode
            $table = $this->getTable('customoptions/option_view_mode');
            $sql = 'REPLACE INTO `' . $table . '` '
                . 'SELECT NULL, ' . $newOptionId . ', `store_id`, `view_mode`'
                . 'FROM `' . $table . '` WHERE `option_id`=' . $oldOptionId;
            $this->_getWriteAdapter()->query($sql);
            
            // description
            $table = $this->getTable('customoptions/option_description');
            $sql = 'REPLACE INTO `' . $table . '` '
                . 'SELECT NULL, ' . $newOptionId . ', `store_id`, `description`'
                . 'FROM `' . $table . '` WHERE `option_id`=' . $oldOptionId;
            $this->_getWriteAdapter()->query($sql);
            
            // default_text
            $table = $this->getTable('customoptions/option_default');
            $sql = 'REPLACE INTO `' . $table . '` '
                . 'SELECT NULL, ' . $newOptionId . ', `store_id`, `default_text`'
                . 'FROM `' . $table . '` WHERE `option_id`=' . $oldOptionId;
            $this->_getWriteAdapter()->query($sql);
            
            $object->getValueInstance()->duplicate($oldOptionId, $newOptionId);
        }

        return $object;
    }
    

}
