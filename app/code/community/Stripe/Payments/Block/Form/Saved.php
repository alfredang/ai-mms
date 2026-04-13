<?php

class Stripe_Payments_Block_Form_Saved extends Mage_Core_Block_Template
{
    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('stripe/payments/form/saved.phtml');
        $this->stripe = Mage::getModel('stripe_payments/method');
        $this->helper = Mage::helper('stripe_payments');
    }

    public function getCustomerCards()
    {
        return $this->stripe->getCustomerCards();
    }

    public function isReusableSource($source)
    {
        // SEPA Direct Debit cannot be used for arbitrary amounts in the admin, it must be the exact
        // amount agreed with the bank.
        return false;//$source->object == 'source' && $source->usage == 'reusable' && $source->type == 'sepa_debit';
    }

    public function formatSourceName($source)
    {
        return "SEPA Direct Debit Ref. " . $source->sepa_debit->mandate_reference;
    }

    public function isAdmin()
    {
        return Mage::app()->getStore()->isAdmin();
    }

    public function cardType($code)
    {
        return $this->helper->cardType($code);
    }
}
