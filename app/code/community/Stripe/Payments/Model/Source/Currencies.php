<?php

class Stripe_Payments_Model_Source_Currencies
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 0,
                'label' => Mage::helper('stripe_payments')->__('All Allowed Currencies')
            ),
            array(
                'value' => 1,
                'label' => Mage::helper('stripe_payments')->__('Specific Currencies')
            ),
        );
    }
}
