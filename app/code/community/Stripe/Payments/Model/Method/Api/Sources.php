<?php

class Stripe_Payments_Model_Method_Api_Sources extends Mage_Payment_Model_Method_Abstract
{
    protected $_isInitializeNeeded      = false;
    protected $_canUseForMultishipping  = false;
    protected $_isGateway               = true;
    protected $_canAuthorize            = true;
    protected $_canCapture              = false;
    protected $_canCapturePartial       = false;
    protected $_canRefund               = true;
    protected $_canRefundInvoicePartial = true;
    protected $_canVoid                 = true;
    protected $_canCancelInvoice        = true;
    protected $_canUseInternal          = false;
    protected $_canUseCheckout          = true;
    protected $_canSaveCc               = false;
    protected $_formBlockType           = 'stripe_payments/form_methodRedirect';

    public $stripe;
    public static $redirectUrl;

    public function __construct()
    {
        $this->helper = Mage::helper('stripe_payments');
        $this->stripe = Mage::getModel('stripe_payments/method');
        parent::__construct();
    }

    // The Sources API oddly throws an error if an unknown parameter is passed.
    // Delete all non-allowed params
    protected function cleanParams(&$params)
    {
        $allowed = array_flip(array('type', 'amount', 'currency', 'owner', 'redirect', 'metadata', $this->_type));
        $params = array_intersect_key($params, $allowed);
    }

    public function getTestEmail()
    {
        return false;
    }

    public function getTestName()
    {
        return false;
    }

    public function authorize(Varien_Object $payment, $amount)
    {
        parent::authorize($payment, $amount);

        if ($amount > 0)
        {
            try
            {
                $order = $payment->getOrder();
                $billingInfo = $this->helper->getSanitizedBillingInfo();
                $params = $this->helper->getStripeParamsFrom($order);
                $params["type"] = $this->_type;

                $params["owner"] = array(
                    "name" => $order->getCustomerName(),
                    // "name" => "succeeding_charge",
                    // "name" => "failing_charge",
                    "email" => ($this->getTestEmail() ? $this->getTestEmail() : $billingInfo["email"])
                );
                $params["redirect"] = array(
                    "return_url" => Mage::getUrl('stripe_payments/return')
                );
                $params["metadata"] = array(
                    "Order #" => $order->getIncrementId(),
                );

                if ($this->_type == 'sepa_debit')
                {
                    unset($params['amount']); // This will make the source reusable
                    $iban = $payment->getAdditionalInformation('iban');
                    if (!empty($iban))
                        $params['sepa_debit'] = array('iban' => $iban);
                    else
                        throw new Exception($this->helper->__("No IBAN provided."));
                }

                $statementDescriptor = Mage::getStoreConfig('payment/' . $this->_code . '/statement_descriptor');
                if (!empty($statementDescriptor))
                    $params[$this->_type] = array("statement_descriptor" => $statementDescriptor);

                if ($this->_type == 'sofort')
                {
                    $address = $this->helper->getBillingAddress();
                    $params[$this->_type] = array("country" => $address->getCountry());
                }

                $this->cleanParams($params);

                $source = \Stripe\Source::create($params);

                $payment->setAdditionalInformation('captured', false);
                $payment->setAdditionalInformation('source_id', $source->id);

                if ($this->stripe->saveCards || $this->_type == 'sepa_debit')
                {
                    $this->stripe->addCardToCustomer($source->id);
                    $customerStripeId = $this->stripe->getCustomerStripeId();
                    $payment->setAdditionalInformation('customer_stripe_id', $customerStripeId);
                }
                $payment->save();

                $session = Mage::getSingleton('core/session');
                $session->setRedirectUrl(null);
                if (!empty($source->redirect->url))
                    $session->setRedirectUrl($source->redirect->url);
                else if (!empty($source->wechat->qr_code_url))
                {
                    $detect = Mage::getModel('stripe_payments/mobileDetect');
                    if ($detect->isMobile())
                    {
                        $session->setRedirectUrl($source->wechat->qr_code_url);
                    }
                    else
                    {
                        $payment->setAdditionalInformation('captured', false);
                        $payment->setAdditionalInformation('source_id', $source->id);
                        $payment->setAdditionalInformation('wechat_qr_code_url', $source->wechat->qr_code_url);
                        $payment->setAdditionalInformation('wechat_amount', $source->amount);
                        $payment->setAdditionalInformation('wechat_currency', $source->currency);
                    }
                }

                $session->setClientSecret($source->client_secret);
                $session->setOrderId($order->getId());
            }
            catch (\Stripe\Error\Card $e)
            {
                $this->log($e->getMessage());
                Mage::throwException($this->t($e->getMessage()));
            }
            catch (\Stripe\Error $e)
            {
                $this->log($e->getMessage());
                Mage::throwException($this->t($e->getMessage()));
            }
            catch (\Exception $e)
            {
                if (strstr($e->getMessage(), 'Invalid country') !== false)
                    Mage::throwException($this->t("Sorry, this payment method is not available in your country."));

                if (strstr($e->getMessage(), 'Invalid currency: ') !== false)
                    Mage::throwException($this->t("Sorry, the payment method %s cannot be used with the %s currency.", $this->_name, $params["currency"]));

                $this->log($e->getMessage());

                Mage::throwException($this->t($e->getMessage()));
            }
        }

        return $this;
    }

    public function log($msg)
    {
        Mage::log($this->_name . " - " . $msg);
    }

    public function t($str, $arg1 = null, $arg2 = null)
    {
        return $this->helper->__($str, $arg1, $arg2);
    }

    public function getOrderPlaceRedirectUrl()
    {
        $session = Mage::getSingleton('core/session');
        return $session->getRedirectUrl();
    }

    public function isAvailable($quote = null)
    {
        if (!parent::isAvailable($quote))
            return false;

        if (!$quote)
            return parent::isAvailable($quote);

        if ($quote->getGrandTotal() <= 0)
            return false;

        $store = $this->stripe->getStore();
        $allowCurrencies = $store->getConfig("payment/{$this->_code}/allow_currencies");
        $allowedCurrencies = $store->getConfig("payment/{$this->_code}/allowed_currencies");

        // This is the "All currencies" setting
        if (!$allowedCurrencies)
            return true;

        // This is the specific currencies setting
        if ($allowCurrencies && $allowedCurrencies)
        {
            $currency = $quote->getQuoteCurrencyCode();
            $currencies = explode(',', $allowedCurrencies);
            if (!in_array($currency, $currencies))
                return false;
        }

        $allowedCurrencies = explode(',', $allowedCurrencies);

        if (!in_array($quote->getQuoteCurrencyCode(), $allowedCurrencies))
            return false;

        return true;
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
