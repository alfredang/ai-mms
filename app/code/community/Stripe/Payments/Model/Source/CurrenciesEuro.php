<?php

class Stripe_Payments_Model_Source_CurrenciesEuro
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 0,
                'label' => Mage::helper('stripe_payments')->__('All Currencies')
            ),
            array(
                'value' => 'EUR',
                'label' => Mage::helper('stripe_payments')->__('Euro Only')
            ),
        );
    }
}
