<?php

class Stripe_Payments_Model_Method_Ach extends Mage_Payment_Model_Method_Abstract
{
    protected $_isInitializeNeeded      = false;
    protected $_canUseForMultishipping  = false;
    protected $_isGateway               = true;
    protected $_canAuthorize            = true;
    protected $_canCapture              = true;
    protected $_canCapturePartial       = false;
    protected $_canRefund               = true;
    protected $_canRefundInvoicePartial = true;
    protected $_canVoid                 = true;
    protected $_canCancelInvoice        = true;
    protected $_canUseInternal          = false;
    protected $_canUseCheckout          = true;
    protected $_canSaveCc               = false;
    protected $_formBlockType           = 'stripe_payments/form_methodAch';

    public $stripe;
    public static $redirectUrl;

    protected $_code = 'stripe_payments_ach';
    protected $_name = 'Stripe ACH Payment';
    protected $_type = 'ach';

    public function __construct()
    {
        $this->helper = Mage::helper('stripe_payments');
        $this->stripe = Mage::getModel("stripe_payments/method");
        parent::__construct();
    }

    public function assignData($data)
    {
        if (empty($data['ach']['token']))
            Mage::throwException("An error has occured while trying to verify your account details!");

        $info = $this->getInfoInstance();
        $info->setAdditionalInformation('token', $data['ach']['token']);

        return $this;
    }

    public function authorize(Varien_Object $payment, $amount)
    {
        parent::authorize($payment, $amount);

        if ($amount > 0)
        {
            try
            {
                // Create the customer and add the bank account to the customer object
                $customer = $this->getStripeCustomer();
                $payment->setAdditionalInformation('customer_stripe_id', $customer->id);

                $token = \Stripe\Token::retrieve($payment->getAdditionalInformation('token'));
                $sourceId = $this->deduplicateBankAccounts($customer, $token);

                if (strstr($sourceId, 'btok_') !== false)
                {
                    if (isset($token->bank_account->fingerprint) && !$this->customerHasSavedBankAccount($customer, $token->bank_account->fingerprint))
                        $bankAccount = $customer->sources->create(array('source' => $sourceId));
                    else if (!empty($token->bank_account))
                        $bankAccount = $token->bank_account;
                    else
                        throw new Exception("Could not retrieve bank account.");

                    $payment->setAdditionalInformation('bank_account', $bankAccount->id);
                }
                else // Will start with ba_
                {
                    $payment->setAdditionalInformation('bank_account', $sourceId);
                    $bankAccount = $customer->sources->retrieve($sourceId);
                }

                $order = $payment->getOrder();

                if ($bankAccount->status == "new")
                {
                    $verificationUrl = rtrim(Mage::getBaseUrl(), "/") . "/stripe/verification/index/customer/{$customer->id}/account/{$bankAccount->id}";
                    $comment = "Your order will remain pending until your bank account is verified. " .
                        "To verify your bank account, we have sent 2 micro-deposits which may take 1-2 business days to appear in your online statement. " .
                        "Once the deposits appear, please enter them at <a href=\"%s\">this verification page</a> to complete your order. ";

                    $translatedComment = Mage::helper('stripe_payments')->__($comment, $verificationUrl);
                    $order->setCustomerNoteNotify(true);
                    $order->setCustomerNote($translatedComment);
                    $payment->setIsTransactionPending(true);
                }
                else
                {
                    $comment = "The bank account used for this order has already been verified.";
                    $translatedComment = Mage::helper('stripe_payments')->__($comment);
                    $order->addStatusHistoryComment($translatedComment);
                    Mage::helper('stripe_payments/webhooks')->chargeAch($order);
                }

                $customer->save();
            }
            catch (\Stripe\Error $e)
            {
                $this->log($e->getMessage());
                Mage::throwException($this->t($e->getMessage()));
            }
            catch (\Exception $e)
            {
                $this->log($e->getMessage());
                Mage::throwException($this->t($e->getMessage()));
            }
        }

        return $this;
    }

    public function customerHasSavedBankAccount($customer, $bankAccountFingerprint)
    {
        if (empty($customer->sources->data))
            return false;

        foreach ($customer->sources->data as $source)
        {
            if (isset($source->fingerprint) && $source->fingerprint == $bankAccountFingerprint)
                return true;
        }

        return false;
    }

    public function capture(Varien_Object $payment, $amount)
    {
        parent::capture($payment, $amount);

        return $this;
    }

    // If there is an already verified bank account for this token, return it and use it for the payment
    public function deduplicateBankAccounts($customer, $token)
    {
        $customerBankAccounts = $customer->sources->all(array('object' => 'bank_account'));
        $bankAccount = $token->bank_account;

        foreach ($customerBankAccounts->data as $item)
        {
            if ($item->fingerprint == $token->bank_account->fingerprint && $item->status != "new")
                return $item->id;
        }

        return $token->id;
    }

    public function getStripeCustomer()
    {
        $this->stripe->saveCards = 1;
        $this->stripe->allowedPaymentMethods[] = $this->_code;
        $this->stripe->ensureStripeCustomer();
        $customerStripeId = $this->stripe->getCustomerStripeId();

        if (empty($customerStripeId))
            Mage::throwException("Could not save the bank account details because the customer could not be created in Stripe!");

        $customer = $this->stripe->getStripeCustomer($customerStripeId);

        if (!$customer)
            Mage::throwException("Could not save the bank account details because the customer could not be created in Stripe!");

        return $customer;
    }

    public function log($msg)
    {
        Mage::log($this->_name . " - " . $msg);
    }

    public function t($str)
    {
        return $this->helper->__($str);
    }

    public function isAvailable($quote = null)
    {
        if (!$quote)
            return parent::isAvailable($quote);

        if ($quote->getGrandTotal() <= 0)
            return false;

        $store = $this->stripe->getStore();
        $allowedCurrencies = $store->getConfig("payment/{$this->_code}/allowed_currencies");

        if (!$allowedCurrencies)
            return parent::isAvailable($quote);

        $currency = $quote->getQuoteCurrencyCode();
        if ($currency != $allowedCurrencies)
            return false;

        return parent::isAvailable($quote);
    }

    public function refund(Varien_Object $payment, $amount)
    {
        parent::refund($payment, $amount);
        $this->cancel($payment, $amount);
        return $this;
    }

    public function void(Varien_Object $payment)
    {
        parent::void($payment);
        $this->cancel($payment);
        return $this;
    }

    public function cancel(Varien_Object $payment, $amount = null)
    {
        $this->stripe->cancel($payment, $amount);
    }

    public function isEmailValid($email)
    {
        if (filter_var($email, FILTER_VALIDATE_EMAIL))
            return true;

        return false;
    }
}
