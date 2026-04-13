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
/**
 * @refactor Direct usage of the database in all methods
 */
class MMD_Checkoutoptions_Model_Attributecatalogrefs extends Mage_Core_Model_Abstract
{

    protected $_sCRAttrTable = 'mmd_custom_attribute_cat_refs';    
    
    public function _construct()
    {
        parent::_construct();
        $this->_sCRAttrTable    = Mage::getSingleton('core/resource')->getTableName('mmd_custom_attribute_cat_refs');
        $this->_init('checkoutoptions/attributecategoryrefs');
    }    
    
    
    public function getRefs($iAttributeId, $sType)
    {

        $oDb = Mage::getSingleton('core/resource')->getConnection('core_read');

        $select = $oDb->select()
            ->from(array('c' => $this->_sCRAttrTable), array('value'))
            ->where('c.attribute_id=?', (int)$iAttributeId)
            ->where('c.type=?',$sType);

        return $oDb->fetchCol($select);
    }
    
    
    public function saveRefs($iAttributeId, $sType,$aValues)
    {
       $oDb = Mage::getSingleton('core/resource')->getConnection('core_write');
       $this->deleteRefs($iAttributeId, $sType);
         
        
        foreach ($aValues as $iValue)
        {
            if($iValue)
            {
                $aDBInfo = array
                (
                    'attribute_id'  => $iAttributeId,
                    'type' => $sType,
                    'value'     => $iValue,
                );

                $oDb->insert($this->_sCRAttrTable, $aDBInfo);
            }
        }
        return $this;
    }
    
    public function deleteRefs($iAttributeId, $sType)
    {
        $oDb = Mage::getSingleton('core/resource')->getConnection('core_write');
        $oDb->delete($this->_sCRAttrTable, array('attribute_id = ?' => $iAttributeId, 'type = ?'=> $sType));
        return $this;
    }            
    
}