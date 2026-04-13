<?php

require_once 'Stripe/init.php';

class Stripe_Payments_Helper_Data extends Mage_Payment_Helper_Data
{
    public static $isStripeInitialized = false;
    public $customerStripeId = null;
    public $customerEmail = null;
    public $customer = null;
    public $customerLastRetrieved = null;
    public $paymentMethodsCache = [];

    public function __construct()
    {
        $this->cache = Mage::app()->getCache();
        $this->initStripe();
    }

    public function isConfigured($store = null)
    {
        $apiSecretKey = $this->getSecretKey(null, $store);
        $apiPublicKey = $this->getPublishableKey(null, $store);

        return ($apiSecretKey && $apiPublicKey);
    }

    public function isEnabled()
    {
        $store = $this->getStore();
        $enabled = $store->getConfig('payment/stripe_payments/active');
        if (!$enabled)
            return false;

        return $this->isConfigured();
    }

    public function getSecretKey($mode = null, $store = null)
    {
        if (empty($store))
            $store = $this->getStore();

        if (empty($mode))
            $mode = $store->getConfig('payment/stripe_payments/stripe_mode');

        $path = "payment/stripe_payments/stripe_{$mode}_sk";
        return trim($store->getConfig($path));
    }

    public function getPublishableKey($mode = null, $store = null)
    {
        if (empty($store))
            $store = $this->getStore();

        if (empty($mode))
            $mode = $store->getConfig('payment/stripe_payments/stripe_mode');

        $path = "payment/stripe_payments/stripe_{$mode}_pk";
        return trim($store->getConfig($path));
    }

    public function initStripe($mode = null)
    {
        if ($this::$isStripeInitialized)
            return;

        $apiKey = $this->getSecretKey($mode);
        \Stripe\Stripe::setApiKey($apiKey);
        \Stripe\Stripe::setApiVersion(Stripe_Payments_Model_Method::STRIPE_API);
        \Stripe\Stripe::setAppInfo(
            Stripe_Payments_Model_Method::MODULE_NAME,
            Stripe_Payments_Model_Method::MODULE_VERSION,
            Stripe_Payments_Model_Method::MODULE_URL,
            Stripe_Payments_Model_Method::PARTNER_ID
        );
        $this::$isStripeInitialized = true;
    }

    public function reInitStripe($mode = null)
    {
        $this::$isStripeInitialized = false;
        $this->initStripe($mode);
    }

    // If the module is unconfigured, payment_action will be null, defaulting to authorize & capture, so this would still return the correct value
    public function isAuthorizeOnly()
    {
        return (Mage::getStoreConfig('payment/stripe_payments/payment_action') == Mage_Payment_Model_Method_Abstract::ACTION_AUTHORIZE);
    }

    public function isMultiShipping()
    {
        $quote = $this->getSessionQuote();
        if (empty($quote))
            return false;

        return $quote->getIsMultiShipping();
    }

    public static function module()
    {
        return Stripe_Payments_Model_Method::MODULE_NAME . " v" . Stripe_Payments_Model_Method::MODULE_VERSION;
    }

    public function isGuest()
    {
        $method = $this->getSessionQuote()->getCheckoutMethod();

        if ($method == "register")
            return false;
        else if ($method == "guest")
            return true;
        else if (empty($method))
            return true;

        return false;
    }

    public function ensureStripeCustomer()
    {
        $customerStripeId = $this->getCustomerStripeId();
        $retrievedSecondsAgo = (time() - $this->customerLastRetrieved);

        if (!$customerStripeId)
        {
            $customer = $this->createStripeCustomer();
        }
        // if the customer was retrieved from Stripe in the last 10 minutes, we're good to go
        // otherwise retrieve them now to make sure they were not deleted from Stripe somehow
        else if ((time() - $this->customerLastRetrieved) > (60 * 10))
        {
            if (!$this->getStripeCustomer($customerStripeId))
            {
                $this->reCreateStripeCustomer($customerStripeId);
            }
        }
    }

    public function reCreateStripeCustomer($customerStripeId, $params = null)
    {
        $this->deleteStripeCustomerId($customerStripeId);
        return $this->createStripeCustomer($params);
    }

    public function createStripeCustomer($params = null)
    {
        $quote = $this->getSessionQuote();
        $customerFirstname = $quote->getCustomerFirstname();
        $customerLastname = $quote->getCustomerLastname();
        $customerEmail = $quote->getCustomerEmail();
        $customerId = $quote->getCustomerId();

        // This may happen if we are creating an order from the back office
        if (empty($customerId) && empty($customerEmail))
            return;

        if (!filter_var($customerEmail, FILTER_VALIDATE_EMAIL))
            return;

        // When we are in guest or new customer checkout, we may have already created this customer
        if ($this->getCustomerStripeIdByEmail() !== false)
            return;

        // This is the case for new customer registrations and guest checkouts
        if (empty($customerId))
            $customerId = -1;

        try
        {
            if (empty($params))
                $params = [];

            $params["description"] = "$customerFirstname $customerLastname";
            $params["email"] = $customerEmail;

            $response = \Stripe\Customer::create($params);
            $response->save();

            $this->setStripeCustomerId($response->id, $customerId);

            return $this->customer = $response;
        }
        catch (\Exception $e)
        {
            $this->log('Could not set up customer profile: '.$e->getMessage());
            Mage::throwException($this->__('Could not set up customer profile: ').$this->__($e->getMessage()));
        }
    }

    public function getCustomerStripeIdByEmail($maxAge = null)
    {
        $email = $this->getCustomerEmail();

        if (empty($email))
            return false;

        $resource = Mage::getSingleton('core/resource');
        $connection = $resource->getConnection('core_read');
        $table = $resource->getTableName('stripe_customers');
        $query = $connection->select()
            ->from($table, array('*'))
            ->where($connection->quoteInto('customer_email=? and session_id=?', $email, Mage::getSingleton("core/session")->getEncryptedSessionId()));

        if (!empty($maxAge))
            $query = $query->where('last_retrieved >= ?', time() - $maxAge);

        $result = $connection->fetchRow($query);
        if (empty($result)) return false;
        return $this->customerStripeId = $result['stripe_id'];
    }

    public function getStripeCustomer($id = null)
    {
        if ($this->customer)
            return $this->customer;

        if (empty($id))
            $id = $this->getCustomerStripeId();

        if (empty($id))
            return false;

        if (!$this->isEnabled())
            return false;

        try
        {
            $this->customer = \Stripe\Customer::retrieve($id);

            if (!$this->customer || ($this->customer && isset($this->customer->deleted) && $this->customer->deleted))
                return false;

            $this->updateLastRetrieved($this->customer->id);
            return $this->customer;
        }
        catch (\Exception $e)
        {
            $this->log($this->__('Could not retrieve customer profile: '.$e->getMessage()));
            return false;
        }
    }

    public function updateLastRetrieved($stripeCustomerId)
    {
        try
        {
            $resource = Mage::getSingleton('core/resource');
            $connection = $resource->getConnection('core_write');
            $table = $resource->getTableName('stripe_customers');
            $fields = array();
            $fields['last_retrieved'] = time();
            $condition = array($connection->quoteInto('stripe_id=?', $stripeCustomerId));
            $result = $connection->update($table, $fields, $condition);
        }
        catch (\Exception $e)
        {
            $this->log($this->__('Could not update Stripe customers table: '.$e->getMessage()));
        }
    }

    public function deleteStripeCustomerId($stripeId)
    {
        try
        {
            $resource = Mage::getSingleton('core/resource');
            $connection = $resource->getConnection('core_write');
            $table = $resource->getTableName('stripe_customers');
            $condition = array($connection->quoteInto('stripe_id=?', $stripeId));
            $connection->delete($table, $condition);
        }
        catch (\Exception $e)
        {
            $this->log($this->__('Could not clear Stripe customers table: '.$e->getMessage()));
        }
    }

    public function setStripeCustomerId($stripeId, $forCustomerId)
    {
        try
        {
            $resource = Mage::getSingleton('core/resource');
            $connection = $resource->getConnection('core_write');
            $table = $resource->getTableName('stripe_customers');
            $connection->beginTransaction();
            $fields = array();
            $fields['stripe_id'] = $stripeId;
            $fields['customer_id'] = $forCustomerId;
            $fields['last_retrieved'] = time();
            $fields['customer_email'] = $this->getCustomerEmail();
            $fields['session_id'] = Mage::getSingleton("core/session")->getEncryptedSessionId();
            $condition = array($connection->quoteInto('customer_id=? OR customer_email=?', $forCustomerId, $fields['customer_email']));
            $connection->delete($table, $condition);
            $result = $connection->insert($table, $fields);
            $connection->commit();
        }
        catch (\Exception $e)
        {
            $this->log($this->__('Could not update Stripe customers table: '.$e->getMessage()));
        }
    }

    public function getMetadataFor($order)
    {
        $metadata = [
            "Module" => $this::module(),
            "Order #" => $order->getIncrementId()
        ];

        return $metadata;
    }

    public function getGuestCustomer($order = null)
    {
        if ($order)
        {
            $address = $this->getBillingAddress($order->getQuote());
            return $address;
        }
        else
            return null;
    }

    public function getStripeParamsFrom($order)
    {
        if (Mage::getStoreConfig('payment/stripe_payments/use_store_currency'))
        {
            $amount = $order->getGrandTotal();
            $currency = $order->getOrderCurrencyCode();
        }
        else
        {
            $amount = $order->getBaseGrandTotal();
            $currency = $order->getBaseCurrencyCode();
        }

        $cents = 100;
        if ($this->isZeroDecimal($currency))
            $cents = 1;

        $metadata = $this->getMetadataFor($order);

        if ($order->getCustomerIsGuest())
        {
            $customer = $this->getGuestCustomer($order);
            $customerName = $customer->getFirstname() . ' ' . $customer->getLastname();
            $metadata["Guest"] = "Yes";
        }
        else
            $customerName = $order->getCustomerName();

        if ($this->isMultiShipping())
            $description = "Multi-shipping Order #" . $order->getRealOrderId().' by ' . $customerName;
        else
            $description = "Order #" . $order->getRealOrderId().' by ' . $customerName;

        $params = array(
          "amount" => round($amount * $cents),
          "currency" => $currency,
          "description" => $description,
          "metadata" => $metadata
        );

        $email = $this->getCustomerEmail();
        if (filter_var($email, FILTER_VALIDATE_EMAIL))
            $params["receipt_email"] = $email;

        return $params;
    }

    public function getCustomerEmail()
    {
        if ($this->customerEmail)
            return $this->customerEmail;

        $quote = $this->getSessionQuote();

        if ($quote)
            $email = trim(strtolower($quote->getCustomerEmail()));

        // This happens with guest checkouts
        if (empty($email))
            $email = trim(strtolower($quote->getBillingAddress()->getEmail()));

        // We might be viewing a guest order from admin
        if (empty($email))
            $email = trim(strtolower($this->getAdminOrderGuestEmail()));

        return $this->customerEmail = $email;
    }

    public function getAdminOrderGuestEmail()
    {
        if (Mage::app()->getStore()->isAdmin())
        {
            if (Mage::app()->getRequest()->getParam('order_id'))
            {
                $orderId = Mage::app()->getRequest()->getParam('order_id');
                $order = Mage::getModel('sales/order')->load($orderId);

                if ($order)
                    return $order->getCustomerEmail();
            }
        }

        return null;
    }

    public function getCustomerStripeId($customerId = null)
    {
        if ($this->customerStripeId)
            return $this->customerStripeId;

        // Get the magento customer id
        if (empty($customerId))
            $customerId = $this->getCustomerId();

        if (!empty($customerId) && $customerId < 1)
            $customerId = null;

        if (empty($customerId) && !$this->getCustomerEmail())
             return false;

        $resource = Mage::getSingleton('core/resource');
        $connection = $resource->getConnection('core_read');
        $table = $resource->getTableName('stripe_customers');
        $query = $connection->select()
            ->from($table, array('*'));

        $guestSelect = $connection->quoteInto('customer_email=?', $this->getCustomerEmail());

        // Security measure for the front-end
        if (!Mage::app()->getStore()->isAdmin())
            $guestSelect .= ' and ' . $connection->quoteInto('session_id=?', Mage::getSingleton("core/session")->getEncryptedSessionId());

        if (!empty($customerId) && $this->getCustomerEmail())
            $query = $query->where('customer_id=?', $customerId)->orWhere($guestSelect);
        else if (!empty($customerId))
            $query = $query->where('customer_id=?', $customerId);
        else
            $query = $query->where($guestSelect);

        $result = $connection->fetchRow($query);
        if (empty($result)) return false;
        $this->customerLastRetrieved = $result['last_retrieved'];
        return $this->customerStripeId = $result['stripe_id'];
    }

    public function getCustomerId()
    {
        // If we are in the back office
        if (Mage::app()->getStore()->isAdmin())
        {
            return Mage::getSingleton('adminhtml/sales_order_create')->getQuote()->getCustomerId();
        }
        // If we are on the checkout page
        else if (Mage::getSingleton('customer/session')->isLoggedIn())
        {
            return Mage::getSingleton('customer/session')->getCustomer()->getId();
        }

        return null;
    }

    public function getAdminConfigStore()
    {
        if (strlen($code = Mage::getSingleton('adminhtml/config_data')->getStore())) // store level
        {
            $storeId = Mage::getModel('core/store')->load($code)->getId();
        }
        elseif (strlen($code = Mage::getSingleton('adminhtml/config_data')->getWebsite())) // website level
        {
            $websiteId = Mage::getModel('core/website')->load($code)->getId();
            $storeId = Mage::app()->getWebsite($websiteId)->getDefaultStore()->getId();
        }
        else // default level
        {
            $storeId = 0;
        }

        return Mage::getModel('core/store')->load($storeId);
    }

    public function getStore()
    {
        // Admins may be viewing an order placed on a specific store
        if (Mage::app()->getStore()->isAdmin())
        {
            try
            {
                if (Mage::app()->getRequest()->getParam('order_id'))
                {
                    $orderId = Mage::app()->getRequest()->getParam('order_id');
                    $order = Mage::getModel('sales/order')->load($orderId);
                    $store = $order->getStore();
                }
                elseif (Mage::app()->getRequest()->getParam('invoice_id'))
                {
                    $invoiceId = Mage::app()->getRequest()->getParam('invoice_id');
                    $invoice = Mage::getModel('sales/order_invoice')->load($invoiceId);
                    $store = $invoice->getStore();
                }
                elseif (Mage::app()->getRequest()->getParam('creditmemo_id'))
                {
                    $creditmemoId = Mage::app()->getRequest()->getParam('creditmemo_id');
                    $creditmemo = Mage::getModel('sales/order_creditmemo')->load($creditmemoId);
                    $store = $creditmemo->getStore();
                }
                else
                {
                    // We are creating a new order
                    $store = $this->getSessionQuote()->getStore();
                }

                if (!empty($store) && $store->getId())
                    return $store;
            }
            catch (\Exception $e)
            {
                Mage::logException($e);
            }
        }

        // Users get the store they are on
        return Mage::app()->getStore();
    }

    public function getSecurityMethod()
    {
        // Older security methods have been depreciated
        return 2;
    }

    public function isStripeRadarEnabled()
    {
        $riskLevel = Mage::getStoreConfig('payment/stripe_payments/radar_risk_level');

        return $riskLevel > 0 && !Mage::app()->getStore()->isAdmin();
    }

    public function getBillingAddress($quote = null)
    {
        $quote = $this->getSessionQuote();

        if (!empty($quote) && $quote->getBillingAddress())
            return $quote->getBillingAddress();

        return null;
    }

    public function getSessionQuote()
    {
        // If we are in the back office
        if (Mage::app()->getStore()->isAdmin())
        {
            return Mage::getSingleton('adminhtml/sales_order_create')->getQuote();
        }
        // If we are a user
        return Mage::getSingleton('checkout/session')->getQuote();
    }

    public function getSanitizedBillingInfo()
    {
        $billingAddress = $this->getBillingAddress();
        if (!$billingAddress) return null;

        $quote = $this->getSessionQuote();

        $postcode = $billingAddress->getData('postcode');
        $email = $billingAddress->getEmail();
        $name = $billingAddress->getName();
        $city = $billingAddress->getCity();
        $country = $billingAddress->getCountryId();
        $phone = $billingAddress->getTelephone();
        $state = $billingAddress->getRegion();

        if (empty($name) && $quote->getCustomerFirstname())
        {
            $name = $quote->getCustomerFirstname() . ' ' . $quote->getCustomerLastname();
        }

        if (empty($email))
        {
            if (Mage::getSingleton('customer/session')->isLoggedIn())
            {
                $customer = Mage::getSingleton('customer/session')->getCustomer();
                $email = $customer->getEmail();
            }
            else
            {
                if ($quote)
                    $email = $quote->getCustomerEmail();
            }
        }

        $line1 = null;
        $line2 = null;
        $street = $billingAddress->getStreet();
        if (!empty($street) && is_array($street) && count($street))
        {
            $line1 = $street[0];

            if (!empty($street[1]))
                $line2 = $street[1];
        }

        // Sanitization
        $line1 = preg_replace("/\r|\n/", " ", $line1);
        $line1 = addslashes($line1);
        if (empty($line1))
            $line1 = null;

        return array(
            'name' => $name,
            'line1' => $line1,
            'line2' => $line2,
            'postcode' => $postcode,
            'email' => $email,
            'city' => $city,
            'phone' => $phone,
            'state' => $state,
            'country' => $country
        );
    }

    // Removes decorative strings that Magento adds to the transaction ID
    public function cleanToken($token)
    {
        return preg_replace('/-.*$/', '', $token);
    }

    public function cancelOrder($orderId, $isIncremental = false)
    {
        try
        {
            if (!$orderId)
                throw new Exception("Could not load order ID from session data.");

            if ($isIncremental)
                $order = Mage::getModel('sales/order')->load($orderId, 'increment_id');
            else
                $order = Mage::getModel('sales/order')->load($orderId);

            if (!$order)
                throw new Exception("Could not load order with ID $orderId.");

            $this->cancelOrCloseOrder($order);
        }
        catch (Exception $e)
        {
            Mage::logException($e);
        }
    }

    public function isZeroDecimal($currency)
    {
        return in_array(strtolower($currency), array(
            'bif', 'djf', 'jpy', 'krw', 'pyg', 'vnd', 'xaf',
            'xpf', 'clp', 'gnf', 'kmf', 'mga', 'rwf', 'vuv', 'xof'));
    }

    public function cancelOrCloseOrder($order)
    {
        $cancelled = false;

        $transaction = Mage::getModel('core/resource_transaction');

        // When in Authorize & Capture, uncaptured invoices exist, so we should cancel them first
        $service = Mage::getModel('sales/service_order', $order);

        foreach($order->getInvoiceCollection() as $invoice)
        {
            if ($invoice->canCancel())
            {
                $invoice->cancel();
                $transaction->addObject($invoice);
                $cancelled = true;
            }
        }

        // When all invoices have been canceled, the order can be canceled
        if ($order->canCancel())
        {
            $order->cancel();
            $transaction->addObject($order);
            $cancelled = true;
        }

        $transaction->save();

        return $cancelled;
    }

    public function captureOrder($order)
    {
        foreach($order->getInvoiceCollection() as $invoice)
        {
            $invoice->setRequestedCaptureCase(Mage_Sales_Model_Order_Invoice::CAPTURE_ONLINE);
            $invoice->capture();
            $invoice->save();
        }
    }

    public function getInvoiceAmounts($invoice, $details)
    {
        $currency = strtolower($details['currency']);
        $cents = 100;
        if ($this->isZeroDecimal($currency))
            $cents = 1;
        $amount = ($details['amount'] / $cents);
        $baseAmount = round($amount * $invoice->getBaseToOrderRate(), 2);

        return [
            "amount" => $amount,
            "base_amount" => $baseAmount
        ];
    }

    // Used for partial invoicing triggered from a partial Stripe dashboard capture
    public function adjustInvoiceAmounts(&$invoice, $details)
    {
        if (!is_array($details))
            return;

        $amounts = $this->getInvoiceAmounts($invoice, $details);
        $amount = $amounts['amount'];
        $baseAmount = $amounts['base_amount'];

        if ($invoice->getGrandTotal() != $amount)
        {
            $invoice->setShippingAmount(0);
            $invoice->setSubtotal($amount);
            $invoice->setBaseSubtotal($baseAmount);
            $invoice->setGrandTotal($amount);
            $invoice->setBaseGrandTotal($baseAmount);
        }
    }

    public function invoiceOrder($order, $transactionId = null, $captureCase = Mage_Sales_Model_Order_Invoice::CAPTURE_ONLINE, $amount = null)
    {
        $transaction = Mage::getModel('core/resource_transaction');

        // This will kick in with "Authorize Only" mode and with subscription orders, but not with "Authorize & Capture"
        if ($order->canInvoice())
        {
            $invoice = Mage::getModel('sales/service_order', $order)->prepareInvoice();
            $invoice->setRequestedCaptureCase($captureCase);

            if ($transactionId)
            {
                $invoice->setTransactionId($transactionId);
                $order->getPayment()->setLastTransId($transactionId);
            }

            $this->adjustInvoiceAmounts($invoice, $amount);

            $invoice->register();

            $transaction->addObject($invoice)
                        ->addObject($order)
                        ->save();

            // try
            // {
            //     $invoice->sendEmail(true);
            // }
            // catch (Exception $e)
            // {
            //     Mage::logException($e);
            // }
        }
        // Invoices have already been generated with Authorize & Capture, but have not actually been captured because
        // the source is not chargeable yet. These should have a pending status.
        else
        {
            foreach($order->getInvoiceCollection() as $invoice)
            {
                if ($invoice->canCapture())
                {
                    $invoice->setRequestedCaptureCase($captureCase);

                    $this->adjustInvoiceAmounts($invoice, $amount);

                    $invoice->register();
                    $transaction->addObject($invoice);
                }
            }

            $transaction->addObject($order)->save();
        }

        return $invoice;
    }

    // Pending orders are the ones that were placed with an asynchronous payment method, such as SOFORT or SEPA Direct Debit,
    // which may finalize the charge after several days or weeks
    public function invoicePendingOrder($order, $captureCase = Mage_Sales_Model_Order_Invoice::CAPTURE_ONLINE, $transactionId = null)
    {
        if (!$order->canInvoice())
            throw new Exception("Order #" . $order->getIncrementId() . " cannot be invoiced.");

        $invoice = Mage::getModel('sales/service_order', $order)->prepareInvoice();

        $invoice->setRequestedCaptureCase($captureCase);

        if ($transactionId)
            $invoice->setTransactionId($transactionId);

        $invoice->register();

        $transactionSave = Mage::getModel('core/resource_transaction')
            ->addObject($invoice)
            ->addObject($order);

        $transactionSave->save();

        return $invoice;
    }

    public function getRefundIdFrom($charge)
    {
        $lastRefundDate = 0;
        $refundId = null;

        foreach ($charge->refunds->data as $refund)
        {
            // There might be multiple refunds, and we are looking for the most recent one
            if ($refund->created > $lastRefundDate)
            {
                $lastRefundDate = $refund->created;
                $refundId = $refund->id;
            }
        }

        return $refundId;
    }

    public function hasSubscriptionsIn($items)
    {
        foreach ($items as $item)
        {
            // Configurable products cannot be subscriptions. Also fixes a bug where if a configurable product
            // is added to the cart, and a bundled product already exists in the cart, Magento's core productModel->load()
            // method crashes with:
            // PHP Fatal error:  Uncaught Error: Call to undefined method Magento\Bundle\Model\Product\Type::getConfigurableAttributeCollection()
            if ($item->getProductType() == "configurable") continue;

            $product = $item->getProduct();
            if (is_object($product) && ($product->isRecurring()))
                return true;
        }

        return false;
    }

    public function hasSubscriptions()
    {
        if (isset($this->_hasSubscriptions) && $this->_hasSubscriptions)
            return true;

        $items = $this->getSessionQuote()->getAllItems();
        return $this->_hasSubscriptions = $this->hasSubscriptionsIn($items);
    }

    public function log($msg)
    {
        Mage::log("Stripe Payments - ".$msg);
    }

    public function isValidToken($token)
    {
        if (!is_string($token))
            return false;

        if (!strlen($token))
            return false;

        if (strpos($token, "_") === FALSE)
            return false;

        return true;
    }

    public function convertPaymentMethodToCard($paymentMethod)
    {
        if (!$paymentMethod || empty($paymentMethod->card))
            return null;

        $card = json_decode(json_encode($paymentMethod->card));
        $card->id = $paymentMethod->id;

        return $card;
    }

    public function cardType($code)
    {
        switch ($code)
        {
            case 'visa': return "Visa";
            case 'amex': return "American Express";
            case 'mastercard': return "MasterCard";
            case 'discover': return "Discover";
            case 'diners': return "Diners Club";
            case 'jcb': return "JCB";
            case 'unionpay': return "UnionPay";
            default:
                return ucfirst($code);
        }
    }

    public function findCard($customer, $last4, $expMonth, $expYear)
    {
        $cards = $this->listCards($customer->id);
        foreach ($cards as $card)
        {
            if ($last4 == $card->last4 &&
                $expMonth == $card->exp_month &&
                $expYear == $card->exp_year)
            {
                return $card;
            }
        }

        return false;
    }

    public function findCardByFingerprint($customer, $fingerprint)
    {
        $cards = $this->listCards($customer->id);
        foreach ($cards as $card)
        {
            if ($card->fingerprint == $fingerprint)
            {
                return $card;
            }
        }
        return false;
    }

    public function listCards($customerStripeId, $params = array())
    {
        try
        {
            $sources = $this->getStripeCustomer($customerStripeId)->sources;
            if (!empty($sources))
            {
                $cards = [];

                // Cards created through the Payment Methods API
                $data = \Stripe\PaymentMethod::all(['customer' => $customerStripeId, 'type' => 'card', 'limit' => 100]);
                foreach ($data->autoPagingIterator() as $pm)
                {
                    $cards[] = $this->convertPaymentMethodToCard($pm);
                }

                return $cards;
            }
            else
                return null;
        }
        catch (\Exception $e)
        {
            return null;
        }
    }

    public function addSavedCard($customer, $newcard)
    {
        if (!$customer)
            return null;

        if (!is_string($newcard))
            return null;

        // If we are adding a payment method, called from My Saved Cards section
        if (strpos($newcard, 'pm_') === 0)
        {
            $pm = \Stripe\PaymentMethod::retrieve($newcard);

            if (!isset($pm->card->fingerprint))
                return null;

            $card = $this->findCardByFingerprint($customer, $pm->card->fingerprint);

            if ($card)
                return $card;

            $pm->attach([ 'customer' => $customer->id ]);

            return $this->convertPaymentMethodToCard($pm);
        }
        // If we are adding a source
        else if (strpos($newcard, 'src_') === 0)
        {
            $source = $this->retrieveSource($newcard);
            // Card sources have been depreciated, we can only add Payment Method tokens pm_
            // if ($source->type == 'card')
            // {
            //     $card = $this->convertSourceToCard($source);
            // }
            if ($source->usage == 'reusable' && !isset($source->amount))
            {
                // SEPA Direct Debit with no amount set, no deduplication here
                $card = $customer->sources->create(array('source' => $source->id));
                $customer->default_source = $card->id;
                $customer->save();
                return $card;
            }
            else
            {
                // Bancontact, iDEAL etc cannot be added because they are not reusable
                return null;
            }

            if (isset($card->last4))
            {
                $last4 = $card->last4;
                $month = $card->exp_month;
                $year = $card->exp_year;
                $exists = $this->findCard($customer, $last4, $month, $year);
                if ($exists)
                {
                    $customer->default_source = $exists->id;
                    $customer->save();
                    return $exists;
                }
                else
                {
                    $card2 = $customer->sources->create(array('source' => $card->id));
                    $customer->default_source = $card2->id;
                    $customer->save();
                    return $card2;
                }
            }
        }

        return null;
    }

    public function retrieveSource($token)
    {
        if (isset($this->sources[$token]))
            return $this->sources[$token];

        $this->sources[$token] = \Stripe\Source::retrieve($token);

        return $this->sources[$token];
    }

    public function findCardByPaymentMethodId($paymentMethodId)
    {
        $customer = $this->getStripeCustomer();

        if (!$customer)
            return null;

        if (isset($this->paymentMethodsCache[$paymentMethodId]))
            $pm = $this->paymentMethodsCache[$paymentMethodId];
        else
            $pm = $this->paymentMethodsCache[$paymentMethodId] = \Stripe\PaymentMethod::retrieve($paymentMethodId);

        if (!isset($pm->card->fingerprint))
            return null;

        return $this->findCardByFingerprint($customer, $pm->card->fingerprint);
    }

    public function isAdmin()
    {
        return Mage::app()->getStore()->isAdmin();
    }

    public function loadProductById($id)
    {
        return Mage::getModel('catalog/product')->load($id);
    }

    public function addError($msg)
    {
        Mage::getSingleton('core/session')->addError($msg);
    }

    public function addSuccess($msg)
    {
        Mage::getSingleton('core/session')->addSuccess($msg);
    }

    public function maskException($e)
    {
        if (strpos($e->getMessage(), "Received unknown parameter: payment_method_options[card][moto]") === 0)
            Mage::throwException($this->__("You have enabled MOTO exemptions from the Stripe module configuration section, but your Stripe account has not been gated to use MOTO exemptions. Please contact support@stripe.com to request MOTO enabled for your Stripe account."));

        Mage::throwException($this->__($e->getMessage()));
    }

    // ACH Payment verification
    public function verify($customerId, $bankAccountId, $amount1, $amount2)
    {
        try
        {
            $customer = $this->getStripeCustomer($customerId);
            if (empty($customer))
                throw new Exception("Sorry, we could not find your customer account with Stripe", 200);

            $account = $customer->sources->retrieve($bankAccountId);
            if (!isset($account->id))
                throw new Exception("Sorry, we could not find your bank account with Stripe", 200);

            if ($account->status == "verified")
                return;

            $account->verify(array('amounts' => array($amount1, $amount2)));
        }
        catch (Exception $e)
        {
            Mage::getSingleton('core/session')->addError($e->getMessage());

            if ($e->getCode() != 200)
                Mage::logException($e);
        }
    }

    public function getChargeMetadataFrom($payment)
    {
        $metadata = array();

        $order = $payment->getOrder();
        $metadata["Order #"] = $order->getIncrementId();

        return $metadata;
    }
}
