<?php

class Stripe_Payments_Block_Form_MethodRedirect extends Mage_Payment_Block_Form_Cc
{
    public $stripe;

    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('stripe/payments/form/method_redirect.phtml');

        $this->stripe = Mage::getModel('stripe_payments/method');

        $this->cardAutoDetect = $this->stripe->store->getConfig('payment/stripe_payments/card_autodetect');
    }

    public function getCompanyName()
    {
        try
        {
            if (empty($this->account))
                $this->account = \Stripe\Account::retrieve();

            if (empty($this->account->business_name))
                throw new Exception("No business name specified in Stripe account");

            return $this->account->business_name;
        }
        catch (Exception $e)
        {
            return Mage::app()->getWebsite()->getName();
        }
    }

    public function needsMandate()
    {
        return $this->getMethodCode() == 'stripe_payments_sepa';
    }

    public function getCustomerMandates()
    {
        if ($this->getMethodCode() != 'stripe_payments_sepa')
            return null;

        $customerId = $this->stripe->getCustomerId();
        if (!$customerId)
            return null;

        $customerStripeId = $this->stripe->getCustomerStripeId($customerId);
        if (!$customerStripeId)
            return null;

        return $this->listMandates($customerStripeId);
    }

    private function listMandates($customerStripeId, $params = array())
    {
        try
        {
            $customer = $this->stripe->getStripeCustomer($customerStripeId);
            if (!$customer)
                return null;

            $sources = $customer->sources;

            if (!empty($sources))
            {
                // Cards created through the Sources API
                $data = $sources->all()->data;
                $mandates = array();
                foreach ($data as $source) {
                    if ($source->type == 'sepa_debit')
                        $mandates[] = $source;
                }

                return $mandates;
            }
            else
                return null;
        }
        catch (\Exception $e)
        {
            return null;
        }
    }

    public function isReusableSource($source)
    {
        return $source->object == 'source' && $source->usage == 'reusable' && $source->type == 'sepa_debit';
    }

    public function formatSourceName($source)
    {
        $last4 = $source->sepa_debit->last4;
        $ref = $source->sepa_debit->mandate_reference;
        return "IBAN ending **** $last4 (Mandate Reference $ref)";
    }

    public function getMethodLabelAfterHtml()
    {
        // Add any html you like, like card images in the returned string
        return "";
    }
}
