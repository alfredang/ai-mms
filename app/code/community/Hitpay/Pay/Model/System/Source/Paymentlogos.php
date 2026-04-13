<?php
class Hitpay_Pay_Model_System_Source_Paymentlogos
{
    public function toOptionArray()
    {
        return array(
            array(
                'value' => 'visa',
                'label' => Mage::helper('hitpay')->__('Visa')
            ),
            array(
                'value' => 'master',
                'label' => Mage::helper('hitpay')->__('Mastercard')
            ),
            array(
                'value' => 'american_express',
                'label' => Mage::helper('hitpay')->__('American Express')
            ),
            array(
                'value' => 'apple_pay',
                'label' => Mage::helper('hitpay')->__('Apple Pay')
            ),
            array(
                'value' => 'google_pay',
                'label' => Mage::helper('hitpay')->__('Google Pay')
            ),
            array(
                'value' => 'paynow',
                'label' => Mage::helper('hitpay')->__('PayNow QR')
            ),
            array(
                'value' => 'grabpay',
                'label' => Mage::helper('hitpay')->__('GrabPay')
            ),
            array(
                'value' => 'wechatpay',
                'label' => Mage::helper('hitpay')->__('WeChatPay')
            ),
            array(
                'value' => 'alipay',
                'label' => Mage::helper('hitpay')->__('AliPay')
            ),
            array(
                'value' => 'shopeepay',
                'label' => Mage::helper('hitpay')->__('Shopee Pay')
            ),
        );
    }
}
