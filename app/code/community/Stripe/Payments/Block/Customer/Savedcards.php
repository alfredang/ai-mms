<?php

class Stripe_Payments_Block_Customer_Savedcards extends Mage_Customer_Block_Account_Dashboard
{
    public $billingInfo;

    protected function _construct()
    {
        parent::_construct();
        $this->stripe = Mage::getModel('stripe_payments/method');
        $this->form = Mage::app()->getLayout()->createBlock('payment/form_cc');
        $this->helper = Mage::helper('stripe_payments');
        $this->billingInfo = $this->helper->getSessionQuote()->getBillingAddress();
    }

    public function getPublishableKey()
    {
        $mode = $this->stripe->store->getConfig('payment/stripe_payments/stripe_mode');
        $path = "payment/stripe_payments/stripe_{$mode}_pk";
        return trim($this->stripe->store->getConfig($path));
    }

    public function getCcMonths()
    {
        return $this->form->getCcMonths();
    }

    public function getParam($str)
    {
        $newcard = $this->getRequest()->getParam('newcard', null);
        if (empty($newcard) || empty($newcard[$str])) return null;

        return $newcard[$str];
    }

    public function getCcYears()
    {
        return $this->form->getCcYears();
    }

    public $cardBrandToPfClass = array(
        'Visa' => 'pf-visa',
        'MasterCard' => 'pf-mastercard',
        'American Express' => 'pf-american-express',
        'Discover' => 'pf-discover',
        'Diners Club' => 'pf-diners',
        'JCB' => 'pf-jcb',
        'UnionPay' => 'pf-unionpay'
    );

    public function pfIconClassFor($cardBrand)
    {
        if (isset($this->cardBrandToPfClass[$cardBrand]))
            return $this->cardBrandToPfClass[$cardBrand];

        return "pf-credit-card";
    }

    public function cardType($code)
    {
        return $this->helper->cardType($code);
    }
}
