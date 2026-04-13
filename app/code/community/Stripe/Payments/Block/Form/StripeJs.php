<?php

class Stripe_Payments_Block_Form_StripeJs extends Mage_Core_Block_Template
{
    public $billingInfo;
    public $paymentIntent;

    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('stripe/payments/form/stripejs.phtml');
        $this->stripe = Mage::getModel('stripe_payments/method');
        $this->billingInfo = Mage::helper('stripe_payments')->getSanitizedBillingInfo();
    }

    public function getPublishableKey()
    {
        $mode = $this->stripe->store->getConfig('payment/stripe_payments/stripe_mode');
        $path = "payment/stripe_payments/stripe_{$mode}_pk";
        return trim($this->stripe->store->getConfig($path));
    }

    public function hasBillingAddress()
    {
        return isset($this->billingInfo) && !empty($this->billingInfo);
    }

    public function getIsAdmin()
    {
        if (Mage::app()->getStore()->isAdmin())
            return 'true';

        return 'false';
    }
}
