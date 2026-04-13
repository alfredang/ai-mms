<?php

class Stripe_Payments_Block_Form_MethodAch extends Mage_Payment_Block_Form_Cc
{
    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('stripe/payments/form/method_ach.phtml');
    }

    public function getCountry()
    {
        $billingAddress = Mage::helper('stripe_payments')->getBillingAddress();

        return $billingAddress->getCountryId();
    }

    public function getCurrency()
    {
        $cart = Mage::getModel('checkout/cart')->getQuote();

        return strtolower($cart->getQuoteCurrencyCode());
    }
}
