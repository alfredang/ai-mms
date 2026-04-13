<?php

class Stripe_Payments_Model_Source_Mode
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => Stripe_Payments_Model_Method::TEST,
                'label' => Mage::helper('stripe_payments')->__('Test')
            ),
            array(
                'value' => Stripe_Payments_Model_Method::LIVE,
                'label' => Mage::helper('stripe_payments')->__('Live')
            ),
        );
    }
}
