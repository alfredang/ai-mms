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

class MMD_CustomOptions_Model_Mysql4_Group_Store extends Mage_Core_Model_Mysql4_Abstract {

    protected function _construct() {
        $this->_init('customoptions/group_store', 'group_store_id');
    }
    
    public function loadByGroupAndStore($object, $groupId, $storeId) {
	$read = $this->_getReadAdapter();
        if ($read) {  
            $select = $read->select()
                    ->from($this->getMainTable())
                    ->where('group_id = ?', $groupId)
                    ->where('store_id = ?', $storeId)
                    ->limit(1);
 
            $data = $read->fetchRow($select);
            if ($data) {
                $object->addData($data);
            }
        }
    }
    
}