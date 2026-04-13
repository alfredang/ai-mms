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

class MMD_Checkoutoptions_Block_Rewrite_FrontCheckoutMultishippingShipping extends Mage_Checkout_Block_Multishipping_Shipping
{
    
    protected function _construct()
    {
        parent::_construct();
    }
    
    public function getFieldHtml($aField)
    {
        $sSetName = 'multi';
        
        return Mage::getModel('checkoutoptions/checkoutoptions')->getAttributeHtml($aField, $sSetName, 'multishipping');
    }
    
    public function getCustomFieldList($iTplPlaceId)
    {
        $iStepId = Mage::helper('checkoutoptions')->getStepId('mult_shippinfo');
        
        if (!$iStepId) return false;

        return Mage::getModel('checkoutoptions/checkoutoptions')->getCheckoutAttributeList($iStepId, $iTplPlaceId, 'multishipping');
    } 
}