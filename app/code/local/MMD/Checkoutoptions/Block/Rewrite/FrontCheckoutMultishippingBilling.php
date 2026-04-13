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

class MMD_Checkoutoptions_Block_Rewrite_FrontCheckoutMultishippingBilling extends Mage_Checkout_Block_Multishipping_Billing
{
    
    // overwright parent
    protected function _construct()
    {
        parent::_construct();
    }
    
    public function getFieldHtml($aField)
    {
        $sSetName = 'multi';
        
        return Mage::getModel('checkoutoptions/checkoutoptions')->getAttributeHtml($aField, $sSetName, 'multishipping');
    }
    
    public function getAttributeEnableHtml($aField)
    {
        $sSetName = 'multi';
        
        return Mage::getModel('checkoutoptions/checkoutoptions')->getAttributeEnableHtml($aField, $sSetName);
    }
    
    public function getCustomFieldList($iTplPlaceId)
    {
        $iStepId = Mage::helper('checkoutoptions')->getStepId('mult_billing');
        
        if (!$iStepId) return false;

        return Mage::getModel('checkoutoptions/checkoutoptions')->getCheckoutAttributeList($iStepId, $iTplPlaceId, 'multishipping');
    } 
}