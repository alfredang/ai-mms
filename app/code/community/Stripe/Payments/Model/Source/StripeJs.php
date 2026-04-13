<?php

class Stripe_Payments_Model_Source_StripeJs
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 0,
                'label' => Mage::helper('stripe_payments')->__('None')
            ),
            array(
                'value' => 1,
                'label' => Mage::helper('stripe_payments')->__('Stripe.js v2')
            ),
            array(
                'value' => 2,
                'label' => Mage::helper('stripe_payments')->__('Stripe.js v3 + Stripe Elements (default)')
            ),
        );
    }
}
