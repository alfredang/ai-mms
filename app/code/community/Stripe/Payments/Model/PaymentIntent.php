<?php

class Stripe_Payments_Model_PaymentIntent
{
    public $paymentIntent = null;
    public $paymentIntentsCache = [];
    public $params = [];
    public $stopUpdatesForThisSession = false;
    public $quote = null; // Overwrites default quote
    public $capture = null; // Overwrites default capture method

    const CAPTURED = "succeeded";
    const AUTHORIZED = "requires_capture";
    const CAPTURE_METHOD_MANUAL = "manual";
    const CAPTURE_METHOD_AUTOMATIC = "automatic";
    const REQUIRES_ACTION = "requires_action";

    public function __construct()
    {
        $this->helper = Mage::helper('stripe_payments');
        $this->cache = Mage::app()->getCacheInstance();
    }

    // If we already created any payment intents for this quote, load them
    public function loadFromCache($quote)
    {
        if (empty($quote))
            return null;

        $quoteId = $quote->getId();

        if (empty($quoteId))
            $quoteId = $quote->getQuoteId(); // Admin order quotes

        if (empty($quoteId))
            return null;

        $key = 'payment_intent_' . $quoteId;
        $paymentIntentId = $this->cache->load($key);
        if (!empty($paymentIntentId) && strpos($paymentIntentId, "pi_") === 0)
        {
            if (isset($this->paymentIntentsCache[$paymentIntentId]) && $this->paymentIntentsCache[$paymentIntentId] instanceof \Stripe\PaymentIntent)
                $this->paymentIntent = $this->paymentIntentsCache[$paymentIntentId];
            else
            {
                $this->paymentIntent = \Stripe\PaymentIntent::retrieve($paymentIntentId);
                $this->updateCache($quoteId);
            }
        }
        else
            return null;

        if ($this->isInvalid($quote) || $this->hasPaymentActionChanged())
        {
            $this->destroy($quoteId, true);
            return null;
        }

        return $this->paymentIntent;
    }

    public function loadFromPayment($payment)
    {
        if (empty($payment))
            Mage::throwException("Unhandled attempt to place multi-shipping order without a payment object");

        $paymentIntentId = $payment->getAdditionalInformation("payment_intent_id");

        if (empty($paymentIntentId))
        {
            $this->paymentIntent = null;
            return null;
        }

        try
        {
            $this->paymentIntent = \Stripe\PaymentIntent::retrieve($paymentIntentId);
            $this->updateCache($paymentIntentId); // We sent a $paymentIntentId and not a $quoteId intentionally!
            return $this->paymentIntent;
        }
        catch (\Exception $e)
        {
            $this->paymentIntent = null;
            return null;
        }
    }

    protected function hasPaymentActionChanged()
    {
        $captureMethod = $this->getCaptureMethod();
        return ($captureMethod != $this->paymentIntent->capture_method);
    }

    public function create($quote = null, $payment = null)
    {
        if (!$this->shouldUsePaymentIntents())
            return $this;

        if (empty($quote))
            $quote = $this->getQuote();

        // We don't want to be creating a payment intent if there is no cart/quote
        if (!$quote)
        {
            $this->paymentIntent = null;
            return $this;
        }

        $this->getParamsFrom($quote, $payment);

        if ($this->helper->isMultiShipping())
            $this->loadFromPayment($payment);
        else
            $this->loadFromCache($quote);

        if (!isset($this->params['amount']) || $this->params['amount'] == 0)
            return null;

        if (!$this->paymentIntent)
        {
            $this->paymentIntent = \Stripe\PaymentIntent::create($this->params);
            $this->updateCache($quote->getId());

            if ($payment)
            {
                $payment->setAdditionalInformation("payment_intent_id", $this->paymentIntent->id);
                $payment->setAdditionalInformation("payment_intent_client_secret", $this->paymentIntent->client_secret);
            }
        }
        else if ($this->differentFrom($quote))
        {
            $this->updateFrom($quote);
        }

        return $this;
    }

    protected function updateCache($quoteId)
    {
        $key = 'payment_intent_' . $quoteId;
        $data = $this->paymentIntent->id;
        $tags = ['stripe_payments_payment_intents'];
        $lifetime = 12 * 60 * 60; // 12 hours
        $this->cache->save($data, $key, $tags, $lifetime);
        $this->paymentIntentsCache[$this->paymentIntent->id] = $this->paymentIntent;
    }

    protected function getParamsFrom($quote, $payment = null)
    {
        if (Mage::getStoreConfig('payment/stripe_payments/use_store_currency'))
        {
            if ($this->helper->isMultiShipping())
                $amount = $payment->getOrder()->getGrandTotal();
            else
                $amount = $quote->getGrandTotal();

            $currency = $quote->getQuoteCurrencyCode();
        }
        else
        {
            if ($this->helper->isMultiShipping())
                $amount = $payment->getOrder()->getBaseGrandTotal();
            else
                $amount = $quote->getBaseGrandTotal();

            $currency = $quote->getBaseCurrencyCode();
        }

        $cents = 100;
        if ($this->helper->isZeroDecimal($currency))
            $cents = 1;

        $this->params['amount'] = round($amount * $cents);
        $this->params['currency'] = strtolower((string)$currency);
        $this->params['capture_method'] = $this->getCaptureMethod();
        $this->params["payment_method_types"] = ["card"]; // For now
        $this->params['confirmation_method'] = 'manual';

        $statementDescriptor = Mage::getStoreConfig('payment/stripe_payments/statement_descriptor');
        if (!empty($statementDescriptor))
            $this->params["statement_descriptor"] = $statementDescriptor;
        else
            unset($this->params['statement_descriptor']);

        $shipping = $this->getShippingAddressFrom($quote);
        if ($shipping)
            $this->params['shipping'] = $shipping;
        else
            unset($this->params['shipping']);

        return $this->params;
    }

    // Returns true if we have already created a paymentIntent with these parameters
    protected function alreadyCreated($amount, $currency, $methods)
    {
        return (!empty($this->paymentIntent) &&
            $this->paymentIntent->amount == $amount &&
            $this->paymentIntent->currency == $currency &&
            $this->samePaymentMethods($methods)
            );
    }

    // Checks if the payment methods in the parameter are the same with the payment methods on $this->paymentMethods
    protected function samePaymentMethods($methods)
    {
        $currentMethods = $this->paymentIntent->payment_method_types;
        $set1 = array_diff($methods, $currentMethods);
        $set2 = array_diff($currentMethods, $methods);
        return (empty($set1) && empty($set2));
    }

    public function getClientSecret()
    {
        if (empty($this->paymentIntent))
            return null;

        if (!$this->shouldUsePaymentIntents())
            return null;

        return $this->paymentIntent->client_secret;
    }

    public function getStatus()
    {
        if (empty($this->paymentIntent))
            return null;

        if (!$this->shouldUsePaymentIntents())
            return null;

        return $this->paymentIntent->status;
    }

    public function getPaymentIntentID()
    {
        if (empty($this->paymentIntent))
            return null;

        return $this->paymentIntent->id;
    }

    protected function getQuote()
    {
        // Capturing an expired authorization
        if ($this->quote)
            return $this->quote;

        return $this->helper->getSessionQuote();
    }

    public function isInvalid($quote)
    {
        if (!isset($this->params['amount']))
            $this->getParamsFrom($quote);

        if ($this->params['amount'] <= 0)
            return true;

        if ($this->paymentIntent->status == $this::REQUIRES_ACTION)
        {
            if ($this->paymentIntent->amount != $this->params['amount'])
                return true;
        }

        $this->helper->ensureStripeCustomer();
        $customerId = $this->helper->getCustomerStripeId();
        if (!empty($this->paymentIntent->customer) && $this->paymentIntent->customer != $customerId)
            return true;

        return false;
    }

    public function updateFrom($quote)
    {
        if (empty($quote))
            return $this;

        if (!$this->shouldUsePaymentIntents())
            return $this;

        if ($this->stopUpdatesForThisSession)
            return $this;

        $this->getParamsFrom($quote);
        $this->loadFromCache($quote);
        $this->refreshCache($quote->getId());

        if (!$this->paymentIntent)
            return $this;

        if ($this->isSuccessful(false))
            return $this;

        if ($this->differentFrom($quote))
        {
            $params = $this->getFilteredParamsForUpdate();

            foreach ($params as $key => $value)
                $this->paymentIntent->{$key} = $value;

            $this->updatePaymentIntent($quote);
        }
    }

    // Performs an API update of the PI
    public function updatePaymentIntent($quote)
    {
        try
        {
            $this->paymentIntent->save();
            $this->updateCache($quote->getId());
        }
        catch (\Exception $e)
        {
            Mage::logException($e);
            throw $e;
        }
    }

    public function destroy($quoteId, $cancelPaymentIntent = false)
    {
        $key = 'payment_intent_' . $quoteId;
        $this->cache->remove($key);

        if ($this->paymentIntent && $cancelPaymentIntent)
            $this->paymentIntent->cancel();

        $this->paymentIntent = null;
        $this->params = [];

        if (isset($this->paymentIntentsCache[$key]))
            unset($this->paymentIntentsCache[$key]);
    }

    // At the final place order step, if the amount and currency has not changed, Magento will not call
    // the quote observer. But the customer may have changed the shipping address, in which case a
    // payment intent update is needed. We want to unset the amount and currency in this case because
    // the Stripe API will throw an error, because the PI has already been authorized at the checkout
    protected function getFilteredParamsForUpdate()
    {
        $params = $this->params; // clones the array
        $allowedParams = ["amount", "currency", "description", "metadata", "shipping"];

        foreach ($params as $key => $value) {
            if (!in_array($key, $allowedParams))
                unset($params[$key]);
        }

        if ($params["amount"] == $this->paymentIntent->amount)
            unset($params["amount"]);

        if ($params["currency"] == $this->paymentIntent->currency)
            unset($params["currency"]);

        if (empty($params["shipping"]))
            $params["shipping"] = null; // Unsets it through the API

        return $params;
    }

    public function differentFrom($quote)
    {
        $isAmountDifferent = ($this->paymentIntent->amount != $this->params['amount']);
        $isCurrencyDifferent = ($this->paymentIntent->currency != $this->params['currency']);
        $isPaymentMethodDifferent = !$this->samePaymentMethods($this->params['payment_method_types']);
        $isAddressDifferent = $this->isAddressDifferentFrom($quote);

        return ($isAmountDifferent || $isCurrencyDifferent || $isPaymentMethodDifferent || $isAddressDifferent);
    }

    public function isAddressDifferentFrom($quote)
    {
        $newShipping = $this->getShippingAddressFrom($quote);

        // If both are empty, they are the same
        if (empty($this->paymentIntent->shipping) && empty($newShipping))
            return false;

        // If one of them is empty, they are different
        if (empty($this->paymentIntent->shipping) && !empty($newShipping))
            return true;

        if (!empty($this->paymentIntent->shipping) && empty($newShipping))
            return true;

        $comparisonKeys1 = ["name", "phone"];
        $comparisonKeys2 = ["city", "country", "line1", "line2", "postal_code", "state"];

        foreach ($comparisonKeys1 as $key) {
            if ($this->paymentIntent->shipping->{$key} != $newShipping[$key])
                return true;
        }

        foreach ($comparisonKeys2 as $key) {
            if ($this->paymentIntent->shipping->address->{$key} != $newShipping["address"][$key])
                return true;
        }

        return false;
    }

    public function getShippingAddressFrom($quote)
    {
        $address = $quote->getShippingAddress();

        if (empty($quote) || $quote->getIsVirtual() || empty($address))
            return null;

        $addressId = $address->getAddressId();
        if (empty($addressId))
            return null;

        $firstName = $address->getFirstname();
        if (empty($firstName))
        {
            $address = Mage::getModel('customer/address')->load($address->getAddressId());
            if (!empty($address))
                $firstName = $address->getFirstname();
        }

        if (empty($firstName))
            return null;

        $street = $address->getStreet();

        return [
            "address" => [
                "city" => $address->getCity(),
                "country" => $address->getCountryId(),
                "line1" => $street[0],
                "line2" => (!empty($street[1]) ? $street[1] : null),
                "postal_code" => $address->getPostcode(),
                "state" => $address->getRegion()
            ],
            "carrier" => null,
            "name" => $address->getFirstname() . " " . $address->getLastname(),
            "phone" => $address->getTelephone(),
            "tracking_number" => null
        ];
    }

    public function shouldUsePaymentIntents()
    {
        $isModuleEnabled = Mage::helper("stripe_payments")->isEnabled();
        // $hasSubscriptions = $this->helper->hasSubscriptions();

        return $isModuleEnabled;
    }

    public function isSuccessful($fetchFromAPI = true)
    {
        if (!$this->shouldUsePaymentIntents())
            return false;

        $quote = $this->getQuote();
        if (!$quote)
            return false;

        $this->loadFromCache($quote);

        if (!$this->paymentIntent)
            return false;

        // Refresh the object from the API
        try
        {
            if ($fetchFromAPI)
                $this->refreshCache($quote->getId());
        }
        catch (\Exception $e)
        {
            return false;
        }

        return $this->isSuccessfulStatus();
    }

    public function isSuccessfulStatus($paymentIntent = null)
    {
        if (empty($paymentIntent))
            $paymentIntent = $this->paymentIntent;

        return ($paymentIntent->status == Stripe_Payments_Model_PaymentIntent::CAPTURED ||
            $paymentIntent->status == Stripe_Payments_Model_PaymentIntent::AUTHORIZED);
    }

    public function refreshCache($quoteId)
    {
        if (!$this->paymentIntent)
            return;

        $this->paymentIntent = \Stripe\PaymentIntent::retrieve($this->paymentIntent->id);
        $this->updateCache($quoteId);
    }

    public function getCaptureMethod()
    {
        // Overwrite for when capturing an expired authorization
        if ($this->capture)
            return $this->capture;

        if ($this->helper->isAuthorizeOnly())
            return Stripe_Payments_Model_PaymentIntent::CAPTURE_METHOD_MANUAL;

        return Stripe_Payments_Model_PaymentIntent::CAPTURE_METHOD_AUTOMATIC;
    }

    public function requiresAction()
    {
        return (
            !empty($this->paymentIntent->status) &&
            $this->paymentIntent->status == $this::REQUIRES_ACTION
        );
    }

    public function triggerAuthentication($piSecrets, $order, $payment)
    {
        if (count($piSecrets) > 0)
        {
            if ($this->helper->isAdmin())
                Mage::throwException("This card cannot be used because it requires a 3D Secure authentication by the customer.");

            // Front-end checkout case, this will trigger the 3DS modal.
            Mage::throwException("Authentication Required: " . implode(",", $piSecrets));
        }
    }

    public function redirectToMultiShippingAuthorizationPage($payment, $paymentIntentId)
    {
        $session = Mage::getSingleton('checkout/type_multishipping')->getCheckoutSession();
        $session->setAuthorizationRedirect("stripe_payments/authorization_multishipping");
        $payment->setIsTransactionPending(true);
        $payment->setIsTransactionClosed(0);
        $payment->setIsFraudDetected(false);
        $payment->setAdditionalInformation('authentication_pending', true);
        $payment->setTransactionId($paymentIntentId);
        $payment->setLastTransId($paymentIntentId);
        return $this->paymentIntent;
    }

    public function confirmAndAssociateWithOrder($order, $payment)
    {
        $piSecrets = [];

        $quote = $order->getQuote();
        $this->create($quote, $payment); // Load or create the Payment Intent

        if (!$this->paymentIntent)
            Mage::throwException($this->helper->__("Unable to create payment intent"));

        if (!$this->isSuccessfulStatus())
        {
            $save = ($this->helper->isMultiShipping() || $payment->getAdditionalInformation("save_card"));
            $this->setPaymentMethod($payment->getAdditionalInformation("token"), $save, false);
            $params = $this->helper->getStripeParamsFrom($order);
            $this->paymentIntent->description = $params['description'];
            $this->paymentIntent->metadata = $params['metadata'];

            if ($this->helper->isMultiShipping())
                $this->paymentIntent->amount = $params['amount'];

            $this->updatePaymentIntent($quote);

            try
            {
                $confirmParams = [];
                if ($this->helper->isAdmin() && Mage::getStoreConfig('payment/stripe_payments/moto_exemptions'))
                    $confirmParams = ["payment_method_options" => ["card" => ["moto" => "true"]]];

                $this->paymentIntent->confirm($confirmParams);
            }
            catch (Exception $e)
            {
                $this->helper->maskException($e);
            }

            if ($this->requiresAction())
                $piSecrets[] = $this->getClientSecret();

            if (count($piSecrets) > 0 && $this->helper->isMultiShipping())
                return $this->redirectToMultiShippingAuthorizationPage($payment, $this->paymentIntent->id);
        }

        $this->triggerAuthentication($piSecrets, $order, $payment);

        $this->processAuthenticatedOrder($order, $this->paymentIntent);

        // If this method is called, we should also clear the PI from cache because it cannot be reused
        $object = clone $this->paymentIntent;
        $this->destroy($quote->getId());

        // This makes sure that if another quote observer is triggered, we do not update the PI
        $this->stopUpdatesForThisSession = true;

        return $object;
    }

    public function processAuthenticatedOrder($order, $paymentIntent)
    {
        $payment = $order->getPayment();
        $payment->setTransactionId($paymentIntent->id);
        $payment->setLastTransId($paymentIntent->id);
        $payment->setIsTransactionClosed(0);
        $payment->setIsFraudDetected(false);

        $charge = $paymentIntent->charges->data[0];

        if ($this->helper->isStripeRadarEnabled() &&
            isset($charge->outcome->type) &&
            $charge->outcome->type == 'manual_review')
        {
            $payment->setAdditionalInformation("stripe_outcome_type", $charge->outcome->type);
        }

        if (!$charge->captured && Mage::getStoreConfig('payment/stripe_payments/automatic_invoicing'))
        {
            $payment->setIsTransactionPending(true);
            $invoice = $order->prepareInvoice();
            $invoice->register();
            $order->addRelatedObject($invoice);
        }
    }

    protected function setOrderState($order, $state)
    {
        $status = $order->getConfig()->getStateDefaultStatus($state);
        $order->setState($state)->setStatus($status);
    }

    public function getDescription()
    {
        if (empty($this->paymentIntent->description))
            return null;

        return $this->paymentIntent->description;
    }

    public function setSource($sourceId)
    {
        if (!$this->shouldUsePaymentIntents())
            return $this;

        $quote = $this->getQuote();

        if (!$quote)
        {
            $this->paymentIntent = null;
            return $this;
        }

        if (!$this->loadFromCache($quote))
            return $this;

        $this->paymentIntent->source = $sourceId;
        $this->updatePaymentIntent($quote);
    }

    public function setPaymentMethod($paymentMethodId, $save = false, $update = true)
    {
        $newPaymentMethod = null;

        if (!$this->shouldUsePaymentIntents())
            return $this;

        $quote = $this->getQuote();

        if (!$quote)
        {
            $this->paymentIntent = null;
            return $this;
        }

        if (!$this->helper->isMultiShipping() && !$this->loadFromCache($quote))
            return $this;

        $changed = false;

        if (!isset($this->paymentIntent->payment_method) ||
            $this->paymentIntent->payment_method != $paymentMethodId)
        {
            $newPaymentMethod = $paymentMethodId;
        }

        if (!$save && isset($this->paymentIntent->save_payment_method) && $this->paymentIntent->save_payment_method)
        {
            $this->paymentIntent->save_payment_method = false;
            $changed = true;
        }

        if ($save && (!isset($this->paymentIntent->save_payment_method) || !$this->paymentIntent->save_payment_method))
        {
            // Make sure that the card is not already saved
            $card = $this->helper->findCardByPaymentMethodId($paymentMethodId);
            if (!$card)
            {
                $this->paymentIntent->save_payment_method = true;
                $changed = true;
            }
            else if ($paymentMethodId != $card->id && strpos($card->id, "pm_") === 0)
            {
                // If the card exists as a payment method, and has a different ID, use the saved card instead
                $newPaymentMethod = $card->id;
            }
            else if ($paymentMethodId != $card->id)
            {
                // If it exists as not a Payment Method, add it as a duplicate saved card again
                $this->paymentIntent->save_payment_method = true;
                $changed = true;
            }

        }

        if ($newPaymentMethod && (!isset($this->paymentIntent->payment_method) || $this->paymentIntent->payment_method != $newPaymentMethod))
        {
            $this->paymentIntent->payment_method = $newPaymentMethod;
            $changed = true;
            $this->setCustomer();
        }

        if ($changed && $update)
            $this->updatePaymentIntent($quote);

        return $this;
    }

    public function setCustomer()
    {
        $this->helper->ensureStripeCustomer();
        $customerId = $this->helper->getCustomerStripeId();

        if (!$customerId)
            throw new \Exception("Could not find a Stripe customer ID");

        if (!empty($this->paymentIntent->customer) && $this->paymentIntent->customer == $customerId)
            return;

        if (!empty($this->paymentIntent->customer) && $this->paymentIntent->customer != $customerId)
            throw new \Exception("Cannot update Stripe customer once set on the Payment Intent");

        $this->paymentIntent->customer = $customerId;
    }
}
