<?php

class Stripe_Payments_Block_Authorization_Multishipping extends Mage_Core_Block_Template
{
    public $helper;
    public $orders = [];
    public $paymentIntentClientSecrets = [];

    protected function _construct()
    {
        parent::_construct();
        $this->helper = Mage::helper('stripe_payments');
        $this->session = Mage::getSingleton('core/session');
        $this->multishippingHelper = Mage::helper('stripe_payments/multishipping');
        $orders = $this->multishippingHelper->getOrders();

        foreach ($orders as $order)
        {
            $this->orders[] = $order;

            $payment = $order->getPayment();
            if (empty($payment))
                continue;

            $paymentIntentClientSecret = $payment->getAdditionalInformation("payment_intent_client_secret");
            if (!empty($paymentIntentClientSecret))
                $this->paymentIntentClientSecrets[] = $paymentIntentClientSecret;
        }
    }

    public function getConfirmationUrl()
    {
        return Mage::getUrl('stripe_payments/authorization_confirm/index');
    }

    public function hasErrors()
    {
        if ($this->session->getAddressErrors())
            return (string)'true';
        else
            return (string)'false';
    }

    public function getFormattedAmountFor($order)
    {
        return $order->formatPrice($order->getGrandTotal());
    }
}
