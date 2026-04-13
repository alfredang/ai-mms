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
 * Magento
 *
 */

class MMD_Checkoutoptions_Block_Rewrite_FrontCheckoutMultishippingAddresses extends Mage_Checkout_Block_Multishipping_Addresses
{
    public function _prepareLayout()
    {
        if ($headBlock = $this->getLayout()->getBlock('head')) {
            $headBlock->setCanLoadCalendarJs(true);
        }
        
        return parent::_prepareLayout();
    }
    
    public function getFieldHtml($aField)
    {
        $sSetName = 'multi';
        
        return Mage::getModel('checkoutoptions/checkoutoptions')->getAttributeHtml($aField, $sSetName, 'multishipping');
    }
    
    public function getCustomFieldList($iTplPlaceId)
    {
        $iStepId = Mage::helper('checkoutoptions')->getStepId('mult_addresses');
        
        if (!$iStepId) return false;

        return Mage::getModel('checkoutoptions/checkoutoptions')->getCheckoutAttributeList($iStepId, $iTplPlaceId, 'multishipping');
    } 
}