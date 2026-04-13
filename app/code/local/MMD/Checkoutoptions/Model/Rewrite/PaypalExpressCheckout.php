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
 * @copyright  Copyright (c) 2011 MMD, Inc. 
 */
class MMD_Checkoutoptions_Model_Rewrite_PaypalExpressCheckout extends Mage_Paypal_Model_Express_Checkout
{
    public function place($token, $shippingMethodCode = null)
    {        
        $return = parent::place($token, $shippingMethodCode);
        $orderId = $this->getOrder() instanceof Mage_Sales_Model_Order ? $this->getOrder()->getId() : null;
		
		$recurringProfiles = $this->getRecurringPaymentProfiles();
		$recurringProfileIds = array();
		foreach($recurringProfiles as $recProfile)
		{
		    $recurringProfileIds[] =$recProfile->getId();
	    }
		if(count($recurringProfileIds) > 0)
		    Mage::dispatchEvent('checkoutoptions_paypal_express_order_place_after', array('order_id' => $orderId,
                                                                                            'recurring_profile_ids' => $recurringProfileIds));
		else
            Mage::dispatchEvent('checkoutoptions_paypal_express_order_place_after', array('order_id' => $orderId));
		return $return;
    }
}