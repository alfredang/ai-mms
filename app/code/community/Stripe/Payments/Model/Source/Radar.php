<?php

class Stripe_Payments_Model_Source_Radar
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 0,
                'label' => Mage::helper('stripe_payments')->__('Disabled')
            ),
            array(
                'value' => 10,
                'label' => Mage::helper('stripe_payments')->__('Enabled')
            ),
        );
    }
}
