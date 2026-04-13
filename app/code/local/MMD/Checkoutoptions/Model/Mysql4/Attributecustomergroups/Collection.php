<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
class MMD_Checkoutoptions_Model_Mysql4_Attributecategoryrefs_Collection extends Mage_Core_Model_Mysql4_Collection_Abstract
{
    
    protected $_sCGAttrTable            = 'mmd_custom_attribute_cg'; 
    
    public function _construct()
    {
        $this->_sCGAttrTable    = Mage::getSingleton('core/resource')->getTableName('mmd_custom_attribute_cg');
        $this->_init('checkoutoptions/attributecustomergroups');
    }    
    
    
    //customer groups save and get. we store only unselected groups for reverse compatibility
    
    public function getGroups($iAttributeId)
    {
        $customerGroups = Mage::getResourceModel('customer/group_collection')->load()->toArray();
        
        $oDb = Mage::getSingleton('core/resource')->getConnection('core_read');

        $select = $oDb->select()
            ->from(array('c' => $this->_sCGAttrTable), array('customer_group_id'))
            ->where('c.attribute_id=?', (int)$iAttributeId)
        ;
        
        $aDoNotShowIn = $oDb->fetchCol($select);
        
        $aItemList = array();
        foreach($customerGroups['items'] as $group)
        {
            if(!in_array($group['customer_group_id'], $aDoNotShowIn))
            {
                $aItemList[] = $group['customer_group_id'];
            }
        }
        
        return $aItemList;
    }
    
    public function saveGroups($iAttributeId, $aCustomerGroups)
    {

        $this->deleteGroups($iAttributeId);
        
        $oDb = Mage::getSingleton('core/resource')->getConnection('core_write');
        $customerGroups = Mage::getResourceModel('customer/group_collection')->load()->toArray();
        
        $aDoNotShowIn = array();
        foreach($customerGroups['items'] as $group)
        {
            if(!in_array($group['customer_group_id'], $aCustomerGroups))
            {
                $aDoNotShowIn[] = $group['customer_group_id'];
            }
        }
        
        
        if (!empty($aDoNotShowIn))
        {
            foreach ($aDoNotShowIn as $iValue)
            {
                $aDBInfo = array
                (
                    'attribute_id'  => $iAttributeId,
                    'customer_group_id'     => $iValue,
                );
        
                $oDb->insert($this->_sCGAttrTable, $aDBInfo);
            }
        }
        
        return true;
    }    
    
    public function deleteGroups($iAttributeId)
    {
        $oDb = Mage::getSingleton('core/resource')->getConnection('core_write');
        $oDb->delete($this->_sCGAttrTable, 'attribute_id = ' . $iAttributeId);        
    }    
 
}