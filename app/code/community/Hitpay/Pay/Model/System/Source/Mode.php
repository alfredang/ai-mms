<?php
class Hitpay_Pay_Model_System_Source_Mode
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 1,
                'label' => Mage::helper('hitpay')->__('Live')
            ),
            array(
                'value' => 0,
                'label' => Mage::helper('hitpay')->__('Sandbox')
            ),
        );
    }
}
