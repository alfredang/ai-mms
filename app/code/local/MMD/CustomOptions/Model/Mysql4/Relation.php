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
class MMD_CustomOptions_Model_Mysql4_Relation extends Mage_Core_Model_Mysql4_Abstract {

    protected function _construct() {
        $this->_init('customoptions/relation', 'id');
    }

    public function deleteGroup($groupId) {
        $this->_getWriteAdapter()->delete(
                $this->getMainTable(),
                $this->_getReadAdapter()->quoteInto('group_id = ?', $groupId, 'INTEGER')
        );
        return $this;
    }

    public function deleteGroupProduct($groupId, $productId) {
        $this->_getWriteAdapter()->delete(
                $this->getMainTable(),
                'group_id = '.$groupId.' AND product_id = '.$productId
        );
        return $this;
    }
    
    public function deleteOptionProduct($groupId, $productId, $opId) {
        $this->_getWriteAdapter()->delete(
                $this->getMainTable(),
                'group_id = '.$groupId.' AND product_id = '.$productId.' AND option_id = '.$opId
        );
        return $this;
    }    

    public function getOptionIds($groupId, $productId = null) {
        $select = $this->_getReadAdapter()->select()
                        ->from($this->getMainTable(), new Zend_Db_Expr('DISTINCT `option_id`'))
                        ->where('group_id = ?', $groupId);

        if (!is_null($productId) && is_numeric($productId)) {
            $select->where('product_id = ?', $productId);
        }

        $result = array();
        $data = $this->_getReadAdapter()->fetchAssoc($select);
        if (is_array($data) && $data) {
            $result = array_keys($data);
        }
        return $result;
    }

    public function getGroupIds($productId, $onlyActive = false) {
        $select = $this->_getReadAdapter()->select()
                        ->from($this->getMainTable(), new Zend_Db_Expr('DISTINCT `group_id`'))
                        ->where('product_id = ?', $productId);

        if ($onlyActive === true) {
            $gruopsIds = Mage::getSingleton('customoptions/group')->getActiveGruopsIds();
            if ($gruopsIds) {
                $select->where('group_id IN (' . implode(",", $gruopsIds) . ')');
            }
        }

        $result = array();
        $data = $this->_getReadAdapter()->fetchAssoc($select);
        if (is_array($data) && $data) {
            $result = array_keys($data);
        }
        return $result;
    }

    public function getProductIds($groupId) {
        $select = $this->_getReadAdapter()->select()
                        ->from($this->getMainTable(), new Zend_Db_Expr('DISTINCT `product_id`'))
                        ->where('group_id = ?', $groupId);

        $result = array();
        $data = $this->_getReadAdapter()->fetchAssoc($select);
        if (is_array($data) && $data) {
            $result = array_keys($data);
        }
        return $result;
    }

    public function setHasOptions($productId, $status = 1) {
        $writeAdapter = $this->_getWriteAdapter();
        $writeAdapter->update(
                $this->getTable('catalog/product'),
                array('has_options' => $status),
                $writeAdapter->quoteInto('entity_id = ?', $productId)
        );
        return $this;
    }

    public function setOptionsStatus($optionId, $status = 1) {
        $this->_getWriteAdapter()->update(
                $this->getTable('catalog/product_option'),
                array('view_mode' => ($status==1?1:0)),
                $this->_getWriteAdapter()->quoteInto('option_id = ?', $optionId)
        );
        return $this;
    }

    public function changeHasOptionsKey($productId) {
        if ($productId) {
            $productOption = Mage::getModel('catalog/product_option');
            $productModel = Mage::getModel('catalog/product');
            $product = $productModel->load($productId);

            $productOption->setProduct($product);
            $options = $productOption->getProduct()->getOptions();
            if (empty($options)) {
                $this->setHasOptions($productId, 0);
            }
        }
        return $this;
    }

}