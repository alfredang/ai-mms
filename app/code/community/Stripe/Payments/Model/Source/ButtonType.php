<?php

class Stripe_Payments_Model_Source_ButtonType
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 'default',
                'label' => Mage::helper('stripe_payments/express')->__('Default')
            ),
            array(
                'value' => 'buy',
                'label' => Mage::helper('stripe_payments/express')->__('Buy')
            ),
            array(
                'value' => 'donate',
                'label' => Mage::helper('stripe_payments/express')->__('Donate')
            ),
        );
    }
}
