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

class MMD_CustomOptions_Model_Group extends Mage_Core_Model_Abstract {

    protected function _construct() {
        parent::_construct();
        $this->_init('customoptions/group');
    }

    public function getActiveGruopsIds($store = null) {
        $result = array();
        $collection = $this->getResourceCollection()
                        //->addStoreFilter($store)
                        ->addStatusFilter();

        $items = $collection->getItems();
        if ($items) {
            foreach ($items as $value) {
                $result[] = $value->getGroupId();
            }
        }
        return $result;
    }
    
    public function duplicate() {
        $tablePrefix = (string) Mage::getConfig()->getTablePrefix();
        $table = $tablePrefix . 'custom_options_group';
        $connection = Mage::getSingleton('core/resource')->getConnection('core_write');
        
        $connection->query("INSERT INTO {$table} (title, is_active, hash_options) 
                    SELECT title, is_active, hash_options 
                    FROM {$table} 
                    WHERE group_id = '{$this->getId()}'");
        $newGroupId = $connection->lastInsertId();
        if (!$newGroupId) return false;
        
        // duplicate store group data
        $groupStoreCollection = Mage::getResourceModel('customoptions/group_store_collection')->addFieldToFilter('group_id', $this->getId());                    
        if (count($groupStoreCollection)>0) {
            $groupStoreNew = Mage::getModel('customoptions/group_store');
            foreach ($groupStoreCollection as $groupStore) {
                $groupStoreNew->setData($groupStore->getData())->setGroupStoreId(null)->setGroupId($newGroupId)->save();
            }
        }
                    
        return $newGroupId;
    }

    public function delete() {
        $hashOptions = unserialize($this->getHashOptions());
        if (is_array($hashOptions) && !empty($hashOptions)) {
            foreach ($hashOptions as $hashOption) {
                Mage::helper('customoptions')->deleteOptionFile($this->getId(), $hashOption['id']);
                @rmdir(Mage::helper('customoptions')->getCustomOptionsPath($this->getId()));
            }
        }

        parent::delete();
    }

    public function getStoreValues($store = null) {
        $result[] = array(
            'label' => Mage::helper('customoptions')->__('None'),
            'value' => ''
        );
        $collection = $this->getResourceCollection()
                        //->addStoreFilter($store)
                        //->addStatusFilter()
                        ->addSortOrder();

        $items = $collection->getItems();
        if ($items) {
            foreach ($items as $value) {
                $result[] = array(
                    'label' => $value->getTitle() . ($value->getIsActive()==2?' (disabled)':''),
                    'value' => $value->getGroupId(),
                );
            }
        } else {
            return '';
        }
        return $result;
    }

}
