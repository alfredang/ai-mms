<?php

class Stripe_Payments_Block_ApplePay_Abstract extends Mage_Core_Block_Template
{
    public function __construct()
    {
        parent::__construct();

        $this->stripe = Mage::getModel('stripe_payments/method');
        $this->applePayEnabled = $this->stripe->isApplePayEnabled();
        $this->location = $this->stripe->store->getConfig('payment/stripe_payments/apple_pay_location');
    }

    public function shouldDisplay()
    {
        return $this->applePayEnabled;
    }

    public function location()
    {
        return $this->location;
    }
}
