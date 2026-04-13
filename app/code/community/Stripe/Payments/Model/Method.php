<?php

class Stripe_Payments_Model_Method extends Mage_Payment_Model_Method_Abstract {
    protected $_code = 'stripe_payments';

    protected $_isInitializeNeeded      = false;
    protected $_canUseForMultishipping  = true;
    protected $_isGateway               = true;
    protected $_canAuthorize            = true;
    protected $_canCapture              = true;
    protected $_canCapturePartial       = true;
    protected $_canRefund               = true;
    protected $_canRefundInvoicePartial = true;
    protected $_canVoid                 = true;
    protected $_canCancelInvoice        = true;
    protected $_canUseInternal          = true;
    protected $_canUseCheckout          = true;
    protected $_canSaveCc               = false;
    protected $_formBlockType           = 'stripe_payments/form_method';
    protected $_addOns                  = [];
    protected $_urls                    = [];

    public $_hasRecurringProducts       = false; // Can be changed by Stripe Subscriptions
    public $saveCards                   = false; // Can be changed by Stripe Subscriptions
    public $sources                     = array();
    public $securityMethod              = null;
    public $paymentIntent               = null;

    public $allowedPaymentMethods       = array("stripe_payments");

    protected static $_creatingStripeCustomer = false;

    // Docs: http://docs.magentocommerce.com/Mage_Payment/Mage_Payment_Model_Method_Abstract.html
    // mixed $_canCreateBillingAgreement
    // mixed $_canFetchTransactionInfo
    // mixed $_canManageRecurringProfiles
    // mixed $_canOrder
    // mixed $_canReviewPayment
    // array $_debugReplacePrivateDataKeys
    // mixed $_infoBlockType

    // Stripe Modes
    const TEST = 'test';
    const LIVE = 'live';

    // Module Details
    const MODULE_NAME = "Magento1";
    const MODULE_VERSION = "1.1.7";
    const MODULE_URL = "https://stripe.com/docs/plugins/magento";
    const STRIPE_API = "2019-02-19";
    const PARTNER_ID = "pp_partner_Fs6iNUQypCPjXm";

    public function __construct()
    {
        $this->helper = Mage::helper('stripe_payments');
        $this->store = $this->getStore();
        $this->paymentIntent = Mage::getSingleton("stripe_payments/paymentIntent");
        $this->saveCards = $this->store->getConfig('payment/stripe_payments/ccsave');
        $this->ensureStripeCustomer();
    }

    public function getAdminOrderGuestEmail()
    {
        return $this->helper->getAdminOrderGuestEmail();
    }

    public function getStore()
    {
        return $this->helper->getStore();
    }

    public function ensureStripeCustomer($isAtCheckout = true)
    {
        if (!Mage::helper("stripe_payments")->isConfigured())
            return;

        // Idev OSC can get into an infinite loop here
        if (self::$_creatingStripeCustomer) return;
        self::$_creatingStripeCustomer = true;

        if ($isAtCheckout)
        {
            // If the payment method has not yet been selected, skip this step
            $quote = $this->getSessionQuote();
            $paymentMethod = $quote->getPayment()->getMethod();
            if (empty($paymentMethod) || !in_array($paymentMethod, $this->allowedPaymentMethods))
            {
                self::$_creatingStripeCustomer = false;
                return;
            }
        }

        $this->helper->ensureStripeCustomer();

        self::$_creatingStripeCustomer = false;
    }

    protected function reCreateStripeCustomer($customerStripeId)
    {
        return $this->helper->reCreateStripeCustomer($customerStripeId);
    }

    protected function getCustomerEmail()
    {
        return $this->helper->getCustomerEmail();
    }

    public function getCustomerId()
    {
        return $this->helper->getCustomerId();
    }

    protected function getSessionQuote()
    {
        return $this->helper->getSessionQuote();
    }

    protected function getAvsFields($card)
    {
        if (!is_array($card)) return $card; // Card is a token so AVS should have already been taken care of

        $billingInfo = $this->helper->getSanitizedBillingInfo($this);

        if (empty($billingInfo))
            throw new \Stripe\Error\Card("You must first enter your billing address.");
        else
        {
            $card['address_line1'] = $billingInfo['line1'];
            $card['address_zip'] = $billingInfo['postcode'];
        }

        return $card;
    }

    protected function resetPaymentData()
    {
        $info = $this->getInfoInstance();

        $info->setAdditionalInformation('stripejs_token', null)
             ->setAdditionalInformation('save_card', false)
             ->setAdditionalInformation('token', null);
    }

    public function assignData($data)
    {
        $info = $this->getInfoInstance();
        $session = Mage::getSingleton('core/session');

        // If using a saved card
        if (!empty($data['cc_saved']) && $data['cc_saved'] != 'new_card' && empty($data['cc_stripejs_token']))
        {
            $card = explode(':', $data['cc_saved']);

            $this->resetPaymentData();
            $info->setAdditionalInformation('token', $card[0]);
            $info->setAdditionalInformation('save_card', $data['cc_save']);

            return $this;
        }

        // Scenarios by OSC modules trying to prematurely save payment details
        if (empty($data['cc_stripejs_token']))
            return $this;

        $card = explode(':', $data['cc_stripejs_token']);
        $data['cc_stripejs_token'] = $card[0]; // To be used by Stripe Subscriptions

        if (!$this->helper->isValidToken($card[0]))
            Mage::throwException($this->t("Sorry, we could not perform a card security check. Please contact us to complete your purchase."));

        $this->resetPaymentData();
        $token = $card[0];
        $info->setAdditionalInformation('stripejs_token', $token);
        $info->setAdditionalInformation('save_card', $data['cc_save']);

        // Add the card to the customer
        if ($this->helper->isMultiShipping())
        {
            try
            {
                $card = $this->addCardToCustomer($token);
                $token = $card->id;
            }
            catch (\Stripe\Error\Card $e)
            {
                $this->resetPaymentData();
                Mage::throwException($this->t($e->getMessage()));
            }
            catch (\Stripe\Error $e)
            {
                $this->resetPaymentData();
                Mage::logException($e);
                Mage::throwException($this->t($e->getMessage()));
            }
            catch (\Exception $e)
            {
                $this->resetPaymentData();
                Mage::logException($e);
                Mage::throwException($this->t($e->getMessage()));
            }
        }

        $info->setAdditionalInformation('token', $token);

        return $this;
    }

    public function findCardFromCustomer($customer, $last4, $expMonth, $expYear)
    {
        return $this->helper->findCard($customer, $last4, $expMonth, $expYear);
    }

    public function addCardToCustomer($newcard)
    {
        if (empty($customerStripeId))
            $customerStripeId = $this->getCustomerStripeId();

        if (empty($customerStripeId))
            return null;

        $customer = $this->getStripeCustomer($customerStripeId);

        // Rare occation with stale test data && customerLastRetrieved < 10 mins
        if (!$customer)
            $customer = $this->reCreateStripeCustomer($customerStripeId);

        if (!$customer)
            throw new Exception("Could not save the customer's card because the customer could not be created in Stripe!");

        return $this->helper->addSavedCard($customer, $newcard);
    }

    public function retrieveSource($token)
    {
        return $this->helper->retrieveSource($token);
    }

    public function getMultiCurrencyAmount($payment, $baseAmount)
    {
        if (!Mage::getStoreConfig('payment/stripe_payments/use_store_currency'))
            return $baseAmount;

        $order = $payment->getOrder();
        $grandTotal = $order->getGrandTotal();
        $baseGrandTotal = $order->getBaseGrandTotal();

        $rate = $order->getStoreToOrderRate();

        // Full capture, ignore currency rate in case it changed
        if ($baseAmount == $baseGrandTotal)
            return $grandTotal;
        // Partial capture, consider currency rate but don't capture more than the original amount
        else if (is_numeric($rate))
            return min($baseAmount * $rate, $grandTotal);
        // Not a multicurrency capture
        else
            return $baseAmount;
    }

    public function authorize(Varien_Object $payment, $amount)
    {
        parent::authorize($payment, $amount);

        if ($amount > 0)
        {
            $this->paymentIntent->confirmAndAssociateWithOrder($payment->getOrder(), $payment);
        }

        return $this;
    }

    public function capture(Varien_Object $payment, $amount)
    {
        parent::capture($payment, $amount);

        if ($amount > 0)
        {
            // We get in here when the store is configured in Authorize Only mode and we are capturing a payment from the admin
            $token = $payment->getTransactionId();
            if (empty($token))
                $token = $payment->getLastTransId(); // In case where the transaction was not created during the checkout, i.e. with a Stripe Webhook redirect

            if ($token)
            {
                $token = $this->helper->cleanToken($token);
                try
                {
                    if (strpos($token, 'pi_') === 0)
                    {
                        $pi = \Stripe\PaymentIntent::retrieve($token);
                        $ch = $pi->charges->data[0];
                        $paymentObject = $pi;
                    }
                    else
                    {
                        $ch = \Stripe\Charge::retrieve($token);
                        $paymentObject = $ch;
                    }

                    $finalAmount = $this->getMultiCurrencyAmount($payment, $amount);

                    $currency = $payment->getOrder()->getOrderCurrencyCode();
                    $cents = 100;
                    if ($this->isZeroDecimal($currency))
                        $cents = 1;

                    if ($ch->captured)
                    {
                        // In theory this condition should never evaluate, but is added for safety
                        if ($ch->currency != strtolower($currency))
                            Mage::throwException("This invoice has already been captured in Stripe using a different currency ({$ch->currency}).");

                        $capturedAmount = $ch->amount - $ch->amount_refunded;

                        if ($capturedAmount != round($finalAmount * $cents))
                        {
                            $humanReadableAmount = strtoupper($ch->currency) . " " . round($capturedAmount / $cents, 2);
                            Mage::throwException("This invoice has already been captured in Stripe for a different amount ($humanReadableAmount). Please cancel and create a new offline invoice for the correct amount.");
                        }

                        // We return instead of trying to capture the payment to simulate an Offline capture
                        return $this;
                    }

                    $paymentObject->capture(array('amount' => round($finalAmount * $cents)));
                }
                catch (\Exception $e)
                {
                    $this->log($e->getMessage());
                    if (Mage::app()->getStore()->isAdmin() && $this->isAuthorizationExpired($e->getMessage()) && $this->retryWithSavedCard())
                        $this->createCharge($payment, true, true);
                    else
                        Mage::throwException($e->getMessage());
                }
            }
            else
            {
                $this->paymentIntent->confirmAndAssociateWithOrder($payment->getOrder(), $payment);
            }
        }

        return $this;
    }

    protected function isAuthorizationExpired($errorMessage)
    {
        return ((strstr($errorMessage, "cannot be captured because the charge has expired") !== false) ||
            (strstr($errorMessage, "could not be captured because it has a status of canceled") !== false));
    }

    protected function retryWithSavedCard()
    {
        return Mage::getStoreConfig('payment/stripe_payments/expired_authorizations');
    }

    public function isZeroDecimal($currency)
    {
        return Mage::helper('stripe_payments')->isZeroDecimal($currency);
    }

    public function getStripeParamsFrom($order)
    {
        return $this->helper->getStripeParamsFrom($order);
    }

    public function createCharge(Varien_Object $payment, $capture, $forceUseSavedCard = false)
    {
        $data = $this->loadFromPayment($payment);

        if ($forceUseSavedCard)
        {
            $token = $data['token'];
            $this->customerStripeId = $data['customer'];

            if (!$token || !$this->customerStripeId)
                Mage::throwException('The authorization has expired and the customer has no saved cards to re-create the order.');
        }
        else
            $token = $payment->getAdditionalInformation('token');

        try {
            $order = $payment->getOrder();

            $params = $this->getStripeParamsFrom($order);

            $params["source"] = $token;
            $params["capture"] = $capture;

            $customerStripeId = $data['customer'];

            // If this is a 3D Secure charge, pass the customer id
            if ($payment->getAdditionalInformation('customer_stripe_id'))
            {
                $params["customer"] = $payment->getAdditionalInformation('customer_stripe_id');
            }
            else if ($customerStripeId)
            {
                $params["customer"] = $customerStripeId;
                $payment->setAdditionalInformation('customer_stripe_id', $customerStripeId);
            }

            $this->validateParams($params);

            $params['metadata'] = $this->getChargeMetadataFrom($payment);

            $statementDescriptor = $this->getStore()->getConfig('payment/' . $this->_code . '/statement_descriptor');

            if (!empty($statementDescriptor))
                $params['statement_descriptor'] = $statementDescriptor;

            if (strpos($token, "pm_") === 0)
            {
                $this->paymentIntent = Mage::getSingleton("stripe_payments/paymentIntent");
                $quoteId = $payment->getOrder()->getQuoteId();

                if ($useSavedCard)
                {
                    // We get here if an existing authorization has expired, in which case
                    // we want to discard old Payment Intents and create a new one
                    $this->paymentIntent->refreshCache($quoteId);
                    $this->paymentIntent->destroy($quoteId, true);
                }

                $store = $this->helper->getStore();
                $quote = Mage::getModel('sales/quote')->setStore($store)->load($quoteId);
                $this->paymentIntent->quote = $quote;

                // This in theory should always be true
                if ($capture)
                    $this->paymentIntent->capture = Stripe_Payments_Model_PaymentIntent::CAPTURE_METHOD_AUTOMATIC;
                else
                    $this->paymentIntent->capture = Stripe_Payments_Model_PaymentIntent::CAPTURE_METHOD_MANUAL;

                $this->paymentIntent->create();
                $this->paymentIntent->setPaymentMethod($token);
                $pi = $this->paymentIntent->confirmAndAssociateWithOrder($payment->getOrder(), $payment);
                $charge = $this->retrieveCharge($pi->id);
            }
            else
                $charge = \Stripe\Charge::create($params);

            if ($this->isStripeRadarEnabled() &&
                isset($charge->outcome->type) &&
                $charge->outcome->type == 'manual_review')
            {
                $payment->setAdditionalInformation("stripe_outcome_type", $charge->outcome->type);
            }

            if (!$charge->captured && $this->getStore()->getConfig('payment/stripe_payments/automatic_invoicing'))
            {
                $payment->setIsTransactionPending(true);
                $invoice = $order->prepareInvoice();
                $invoice->register();
                $order->addRelatedObject($invoice);
            }

            $payment->setTransactionId($charge->id);
            $payment->setIsTransactionClosed(0);
        }
        catch (\Stripe\Error\Card $e)
        {
            $this->log($e->getMessage());
            Mage::throwException($this->t($e->getMessage()));
        }
        catch (\Stripe\Error $e)
        {
            Mage::logException($e);
            Mage::throwException($this->t($e->getMessage()));
        }
        catch (\Exception $e)
        {
            Mage::logException($e);
            Mage::throwException($this->t($e->getMessage()));
        }
    }

    public function getChargeMetadataFrom($payment)
    {
        return $this->helper->getChargeMetadataFrom($payment);
    }

    public function validateParams($params)
    {
        if (is_array($params) && isset($params['card']) && is_array($params['card']) && empty($params['card']['number']))
            Mage::throwException("Unable to use Stripe.js");
    }

    public function isStripeRadarEnabled()
    {
        return $this->helper->isStripeRadarEnabled();
    }

    public function loadFromPayment(Varien_Object $payment)
    {
        if (empty($payment))
            return null;

        $method = (string)$payment->getMethod();
        if (strpos($method, "stripe_") !== 0)
            return null;

        $token = $payment->getAdditionalInformation('token');

        if (empty($token))
            $sourceId = $payment->getAdditionalInformation('stripejs_token');

        if (empty($token))
            $sourceId = $payment->getAdditionalInformation('source_id');

        if (empty($token))
            return null;

        try
        {
            // Used by Bancontact, iDEAL etc
            if (strpos($sourceId, "src_") === 0)
                $object = \Stripe\Source::retrieve($sourceId);
            // Used by card payments
            else if (strpos($sourceId, "pm_") === 0)
                $object = \Stripe\PaymentMethod::retrieve($sourceId);
            else
                return null;

            if (empty($object->customer))
                return null;

            $stripeId = $object->customer;
        }
        catch (\Exception $e)
        {
            return null;
        }

        return ['customer' => $stripeId, 'token' => $token];
    }

    /**
     * Cancel payment
     *
     * @param   Varien_Object $invoicePayment
     * @return  Mage_Payment_Model_Abstract
     */
    public function cancel(Varien_Object $payment, $amount = null)
    {
        if (Mage::getStoreConfig('payment/stripe_payments/use_store_currency'))
        {
            // Captured
            $creditmemo = $payment->getCreditmemo();
            if (!empty($creditmemo))
            {
                $rate = $creditmemo->getStoreToOrderRate();
                if (!empty($rate) && is_numeric($rate))
                    $amount *= $rate;
            }
            // Authorized
            $amount = (empty($amount)) ? $payment->getOrder()->getTotalDue() : $amount;

            $currency = $payment->getOrder()->getOrderCurrencyCode();
        }
        else
        {
            // Authorized
            $amount = (empty($amount)) ? $payment->getOrder()->getBaseTotalDue() : $amount;

            $currency = $payment->getOrder()->getBaseCurrencyCode();
        }

        $transactionId = $payment->getParentTransactionId();

        // With asynchronous payment methods, the parent transaction may be empty
        if (empty($transactionId))
            $transactionId = $payment->getLastTransId();

        // Case where an invoice is in Pending status, with no transaction ID, receiving a source.failed event which cancels the invoice.
        if (empty($transactionId))
            return $this;

        $transactionId = $this->helper->cleanToken($transactionId);

        try {
            $cents = 100;
            if ($this->isZeroDecimal($currency))
                $cents = 1;

            $params = array(
                'amount' => round($amount * $cents)
            );

            if (strpos($transactionId, 'pi_') === 0)
            {
                $pi = \Stripe\PaymentIntent::retrieve($transactionId);
                if ($pi->status == Stripe_Payments_Model_PaymentIntent::AUTHORIZED)
                {
                    $pi->cancel();
                    return $this;
                }
                else
                    $charge = $pi->charges->data[0];
            }
            else
            {
                $charge = \Stripe\Charge::retrieve($transactionId);
            }

            // Magento's getStoreToOrderRate may result in a €45.9355 which will ROUND_UP to €45.94, even if the checkout order was €45.93
            if ($params["amount"] > $charge->amount)
                $params["amount"] = $charge->amount;

            // SEPA and SOFORT may have failed charges, refund those offline
            if ($charge->status == "failed")
            {
                return $this;
            }
            // This is true when an authorization has expired, when there was a refund through the Stripe account, or when a partial refund is performed
            if (!$charge->refunded)
            {
                $charge->refund($params);

                $refundId = $this->helper->getRefundIdFrom($charge);
                $payment->setAdditionalInformation('last_refund_id', $refundId);
            }
            else if ($payment->getAmountPaid() == 0)
            {
                // This is an expired authorized only order, which means that it cannot be refunded online or offline
                return $this;
            }
            else
            {
                Mage::throwException('This order has already been refunded in Stripe. To refund from Magento, please refund it offline.');
            }
        }
        catch (\Exception $e)
        {
            $this->log('Could not refund payment: '.$e->getMessage());
            Mage::throwException($this->t('Could not refund payment: ').$e->getMessage());
        }

        return $this;
    }

    /**
     * Refund money
     *
     * @param   Varien_Object $invoicePayment
     * @return  Mage_Payment_Model_Abstract
     */
    public function refund(Varien_Object $payment, $amount)
    {
        parent::refund($payment, $amount);
        $this->cancel($payment, $amount);

        return $this;
    }

    /**
     * Void payment
     *
     * @param   Varien_Object $invoicePayment
     * @return  Mage_Payment_Model_Abstract
     */
    public function void(Varien_Object $payment)
    {
        parent::void($payment);
        $this->cancel($payment);

        return $this;
    }

    public function getCustomerStripeId($customerId = null)
    {
        return $this->helper->getCustomerStripeId($customerId);
    }

    public function getCustomerStripeIdByEmail($maxAge = null)
    {
        return $this->helper->getCustomerStripeIdByEmail($maxAge);
    }

    protected function createStripeCustomer()
    {
        return $this->helper->createStripeCustomer();
    }

    public function getStripeCustomer($id = null)
    {
        return $this->helper->getStripeCustomer($id);
    }

    public function deleteCards($cards)
    {
        $customer = $this->getStripeCustomer();

        if ($customer)
        {
            foreach ($cards as $cardId)
            {
                try
                {
                    if (strpos($cardId, "pm_") === 0)
                        \Stripe\PaymentMethod::retrieve($cardId)->detach();
                    else if (strpos($cardId, "card_") === 0)
                        \Stripe\Customer::deleteSource($customer->id, $cardId);
                    else
                        $this->helper->retrieveSource($cardId)->delete();
                }
                catch (\Exception $e)
                {
                    Mage::logException($e);
                }
            }
            $customer->save();
        }
    }

    protected function updateLastRetrieved($stripeCustomerId)
    {
        $this->helper->updateLastRetrieved($stripeCustomerId);
    }

    protected function deleteStripeCustomerId($stripeId)
    {
        $this->helper->deleteStripeCustomerId($stripeId);
    }

    protected function setStripeCustomerId($stripeId, $forCustomerId)
    {
        $this->helper->setStripeCustomerId($stripeId, $forCustomerId);
    }

    public function getCustomerCards($isAdmin = false, $customerId = null)
    {
        if (!$this->saveCards && !$isAdmin)
            return null;

        if (!$customerId)
            $customerId = $this->getCustomerId();

        if (!$customerId)
            return null;

        $customerStripeId = $this->getCustomerStripeId($customerId);
        if (!$customerStripeId)
            return null;

        return $this->listCards($customerStripeId);
    }

    private function listCards($customerStripeId, $params = array())
    {
        return $this->helper->listCards($customerStripeId, $params);
    }

    protected function log($msg)
    {
        Mage::log("Stripe Payments - ".$msg);
    }

    protected function t($str) {
        return $this->helper->__($str);
    }

    public function isGuest()
    {
        return $this->helper->isGuest();
    }

    public function showSaveCardOption()
    {
        return ($this->saveCards && !$this->isGuest() && $this->helper->getSecurityMethod() > 0);
    }

    protected function hasRecurringProducts()
    {
        return $this->_hasRecurringProducts;
    }

    public function alwaysSaveCard()
    {
        return (($this->hasRecurringProducts() || $this->saveCards == 2 || $this->helper->isMultiShipping()) && $this->helper->getSecurityMethod() > 0);
    }

    public function getSecurityMethod()
    {
        return $this->helper->getSecurityMethod();
    }

    public function getAmountCurrencyFromQuote($quote, $useCents = true)
    {
        $params = array();
        $items = $quote->getAllItems();

        if (Mage::getStoreConfig('payment/stripe_payments/use_store_currency'))
        {
            $amount = $quote->getGrandTotal();
            $currency = $quote->getQuoteCurrencyCode();

            foreach ($items as $item)
                if ($item->getProduct()->isRecurring())
                    $amount += $item->getNominalRowTotal();
        }
        else
        {
            $amount = $quote->getBaseGrandTotal();;
            $currency = $quote->getBaseCurrencyCode();

            foreach ($items as $item)
                if ($item->getProduct()->isRecurring())
                    $amount += $item->getBaseNominalRowTotal();
        }

        if ($useCents)
        {
            $cents = 100;
            if ($this->isZeroDecimal($currency))
                $cents = 1;

            $fields["amount"] = round($amount * $cents);
        }
        else
        {
            // Used for Apple Pay only
            $fields["amount"] = number_format($amount, 2, '.', '');
        }

        $fields["currency"] = $currency;

        return $fields;
    }

    public function isApplePayEnabled()
    {
        return $this->getStore()->getConfig('payment/stripe_payments/apple_pay_checkout')
            && !Mage::app()->getStore()->isAdmin();
    }

    public function isPaymentRequestButtonEnabled()
    {
        return $this->isApplePayEnabled();
    }

    public function getApplePayParams($encode = true)
    {
        if (!$this->isApplePayEnabled())
            return 'null';

        $quote = $this->getSessionQuote();
        if (empty($quote))
            return 'null';

        $fields = $this->getAmountCurrencyFromQuote($quote, false);
        $email = $this->getCustomerEmail();
        $first = $quote->getCustomerFirstname();
        $last = $quote->getCustomerLastname();
        if (empty($email))
            $label = "Order by $first $last";
        else
            $label = "Order by $first $last <$email>";
        $countryCode = $quote->getBillingAddress()->getCountryId();

        $currency = strtolower($fields["currency"]);
        $cents = 100;
        if ($this->isZeroDecimal($currency))
            $cents = 1;

        $amount = round($fields["amount"] * $cents);

        $params = array(
            "country" => $countryCode,
            "currency" => $currency,
            "total" => array(
                "label" => $label,
                "amount" => $amount
            )
        );

        // We are likely not on the checkout page, might be the shopping cart or another page initializing the payment method
        if (empty($fields["currency"]) || empty($fields["amount"]))
            return 'null';

        if ($encode)
            return json_encode($params);

        return $params;
    }

    public function retrieveCharge($token)
    {
        if (strpos($token, 'pi_') === 0)
        {
            $pi = \Stripe\PaymentIntent::retrieve($token);

            if (empty($pi->charges->data[0]))
                return null;

            return $pi->charges->data[0];
        }

        return \Stripe\Charge::retrieve($token);
    }

    public function isAvailable($quote = null)
    {
        if (!Mage::helper("stripe_payments")->isEnabled())
            return false;

        if (empty($quote))
            return parent::isAvailable($quote);

        $minAmount = $this->getStore()->getConfig('payment/stripe_payments/minimum_order_amount');

        if (!is_numeric($minAmount) || $minAmount <= 0)
            $minAmount = 0.3;

        $fields = $this->getAmountCurrencyFromQuote($quote, false);
        $grandTotal = $fields['amount'];

        if ($grandTotal < $minAmount)
            return false;

        return parent::isAvailable($quote);
    }

    // Public logging method
    public function plog($msg)
    {
        return $this->log($msg);
    }

    // This method is used mainly for helping customers through support, to find out why Apple Pay does not display at the checkout
    public function getDebuggingInfo()
    {
        $info = array(
            "Active: " . (int)$this->store->getConfig('payment/stripe_payments/active'),
            "Apple Pay: " . (int)$this->store->getConfig('payment/stripe_payments/apple_pay_checkout'),
            "Location: " . (int)$this->store->getConfig('payment/stripe_payments/apple_pay_location'),
            "Invoice: " . (int)$this->store->getConfig('payment/stripe_payments/automatic_invoicing'),
            "Action: " . (int)$this->store->getConfig('payment/stripe_payments/payment_action'),
            "Countries: " . (int)$this->store->getConfig('payment/stripe_payments/allowspecific')
        );

        return implode(",\n", $info);
    }
}
