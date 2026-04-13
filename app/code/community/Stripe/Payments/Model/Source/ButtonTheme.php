<?php

class Stripe_Payments_Model_Source_ButtonTheme
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 'dark',
                'label' => Mage::helper('stripe_payments/express')->__('Dark')
            ),
            array(
                'value' => 'light',
                'label' => Mage::helper('stripe_payments/express')->__('Light')
            ),
            array(
                'value' => 'light-outline',
                'label' => Mage::helper('stripe_payments/express')->__('Light-Outline')
            ),
        );
    }
}
