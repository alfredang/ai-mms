<?php

class Stripe_Payments_Model_Source_CurrenciesP24 {
    public function toOptionArray(){
        return array(
            array(
                'value' => 0,
                'label' => Mage::helper('stripe_payments')->__('All Currencies')
            ),
            array(
                'value' => 'EUR,PL',
                'label' => Mage::helper('stripe_payments')->__('Euro and Polish Złoty Only')
            )
        );
    }
}
