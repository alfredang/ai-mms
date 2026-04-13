<?php

class Stripe_Payments_Model_Source_ApplePayLocation
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 1,
                'label' => Mage::helper('stripe_payments')->__('Above all payment methods')
            ),
            array(
                'value' => 2,
                'label' => Mage::helper('stripe_payments')->__('Inside the Stripe payment form (default)')
            ),
            array(
                'value' => 3,
                'label' => Mage::helper('stripe_payments')->__('Below all payment methods')
            ),
        );
    }
}
