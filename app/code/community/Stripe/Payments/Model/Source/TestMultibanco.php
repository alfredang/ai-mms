<?php

class Stripe_Payments_Model_Source_TestMultibanco
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 0,
                'label' => Mage::helper('stripe_payments')->__('Disabled (Use this in Live Mode)')
            ),
            array(
                'value' => 1,
                'label' => Mage::helper('stripe_payments')->__('Funds are never sent')
            ),
            array(
                'value' => 2,
                'label' => Mage::helper('stripe_payments')->__('The full amount is sent')
            ),
        );
    }
}
