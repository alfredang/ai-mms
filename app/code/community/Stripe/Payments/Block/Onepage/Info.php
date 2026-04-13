<?php

class Stripe_Payments_Block_Onepage_Info extends Mage_Core_Block_Template
{
    public function getCheckout()
    {
        return Mage::getSingleton('checkout/session');
    }

    public function isWechatMethod()
    {
        $order = $this->getCheckout()->getLastRealOrder();
        return $order->getPayment()->getMethod() === 'stripe_payments_wechat';
    }

    public function getWechatAddress()
    {
        $order = $this->getCheckout()->getLastRealOrder();
        return $order->getPayment()->getAdditionalInformation('wechat_qr_code_url');
    }

    public function getWechatFormattedAmount()
    {
        $order = $this->getCheckout()->getLastRealOrder();
        $amount = $order->getPayment()->getAdditionalInformation('wechat_amount');
        $currency = $order->getOrderCurrencyCode();
        $cents = 100;
        if (Mage::helper('stripe_payments')->isZeroDecimal($currency))
            $cents = 1;

        $finalAmount = $amount / $cents;

        return Mage::helper('core')->currency($finalAmount, true, false);
    }

    public function getQR()
    {
        $address = $this->getWechatAddress();
        return "https://chart.googleapis.com/chart?chs=300x300&cht=qr&chl={$address}&choe=UTF-8";
    }
}
