<?php

class Stripe_Payments_Block_Verification extends Mage_Core_Block_Template
{
    public static $account = null;
    public static $customer = null;

    public $customerId = null;
    public $bankAccountId = null;

    public function __construct()
    {
        $request = $this->getRequest();
        $this->customerId = $request->getParam("customer", null);
        $this->bankAccountId = $request->getParam("account", null);
    }
    public function getBankAccountLast4()
    {
        return $this->account->last4;
    }

    public function accountExists()
    {
        if (!empty($this->account))
            return true;

        try
        {
            if (empty($this->customer))
                $this->customer = Mage::helper("stripe_payments")->getStripeCustomer($this->customerId);

            $account = $this->customer->sources->retrieve($this->bankAccountId);
            if (isset($account->id))
                $this->account = $account;

            return true;
        }
        catch (Exception $e)
        {
            Mage::logException($e);
        }

        return false;
    }

    public function accountVerified()
    {
        return $this->account->status == "verified";
    }
}
