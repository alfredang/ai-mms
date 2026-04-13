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


class MMD_Checkoutoptions_Model_Rewrite_FrontCheckoutTypeMultishippingState extends Mage_Checkout_Model_Type_Multishipping_State
{
    
    
    public function setCompleteStep($step)
    {
        $oReq = Mage::app()->getFrontController()->getRequest();
        
        $sKey  = 'multi';
        
        $data = $oReq->getPost($sKey);

        if ($data)
        {
            $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
            
            foreach ($data as $sKey => $sVal)
            {
                $oAttribute->setCustomValue($sKey, $sVal, 'multishipping');
            }
        }
        
        parent::setCompleteStep($step);
    }
    
    
}