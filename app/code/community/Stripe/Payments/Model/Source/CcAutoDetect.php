<?php

class Stripe_Payments_Model_Source_CcAutoDetect
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 0,
                'label' => Mage::helper('stripe_payments')->__('Disabled')
            ),
            array(
                'value' => 1,
                'label' => Mage::helper('stripe_payments')->__('Show all accepted card types')
            ),
            array(
                'value' => 2,
                'label' => Mage::helper('stripe_payments')->__('Show only the detected card type')
            ),
        );
    }
}
