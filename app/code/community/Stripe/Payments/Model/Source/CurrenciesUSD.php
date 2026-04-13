<?php

class Stripe_Payments_Model_Source_CurrenciesUSD
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 0,
                'label' => Mage::helper('stripe_payments')->__('All Currencies')
            ),
            array(
                'value' => 'USD',
                'label' => Mage::helper('stripe_payments')->__('USD Only')
            ),
        );
    }
}
