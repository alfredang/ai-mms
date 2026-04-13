<?php

class Stripe_Payments_ExpressController extends Mage_Core_Controller_Front_Action
{
    /**
     * @var Mage_Core_Model_Store
     */
    public $store;

    /**
     * @var bool
     */
    public $saveCards;


    public function indexAction()
    {
        //
    }

    /**
     * Estimate Shipping Rates for Cart
     */
    public function estimate_cartAction()
    {
        $cart = $this->_getCart();
        $quote = $cart->getQuote();
        $baseToQuoteRate = $quote->getBaseToQuoteRate();

        if ($quote->getItemsCount())
        {
            $cart->init();

            if (!$quote->isVirtual())
            {
                $address = json_decode($this->getRequest()->getParam('address'), true);
                $shippingAddress = $this->getHelper()->getShippingAddress($address);
                $quote->getShippingAddress()->addData($shippingAddress)->save();
            }

            $cart->save();
        }

        $currency = $cart->getQuote()->getQuoteCurrencyCode();

        $this->_getSession()->setEstimatedShippingAddressData(array(
            'country_id' => $address['country'],
            'postcode'   => $address['postalCode'],
            'city'       => $address['city'],
            'region_id'  => null,
            'region'     => $address['region']
        ));

        /** @var Mage_Checkout_Block_Cart_Shipping $block */
        $block = Mage::getBlockSingleton('checkout/cart_shipping');

        $result = array();
        $_shippingRateGroups = $block->getEstimateRates();
        foreach ($_shippingRateGroups as $code => $_rates)
        {
            // Get Carrier Name
            $carrierName = Mage::getStoreConfig('carriers/' . $code . '/title', $cart->getQuote()->getStore());

            foreach ($_rates as $_rate)
            {
                if ($_rate->getErrorMessage())
                    continue;

                $shippingPrice = $_rate->getPrice() * $baseToQuoteRate;

                $result[] = array(
                    'id' => $_rate->getCode(),
                    'label' => implode(" - ", array($carrierName, $_rate->getMethodTitle())),
                    //'detail' => $_rate->getMethodTitle(),
                    'amount' => Mage::helper('tax')->getShippingPrice(
                        $this->getHelper()->getAmountCents($shippingPrice, $currency),
                        $this->getHelper()->shouldCartPriceInclTax($quote->getStore()),
                        $block->getAddress(),
                        $block->getQuote()->getCustomerTaxClassId()
                    )
                );
            }
        }

        $this->getResponse()->setHeader('Content-type', 'application/json');
        $this->getResponse()->setBody(Zend_Json::encode([
            "paymentIntent" => Mage::getSingleton("stripe_payments/paymentIntent")->create()->getClientSecret(),
            "results" => $result
        ]));
    }

    /**
     * Estimate Shipping Rates for Single Product
     */
    public function estimate_singleAction()
    {
        $request = json_decode($this->getRequest()->getParam('request'), true);

        try {
            // Check Product
            $product = Mage::getModel('catalog/product')
                ->setStoreId(Mage::app()->getStore()->getId())
                ->load($request['product']);

            if (!$product || !$product->getId()) {
                Mage::throwException('Product unavailable');
            }

            // Prepare Quote
            /** @var Mage_Sales_Model_Quote $quote */
            $quote = Mage::getModel('sales/quote');
            $quote->setStore(Mage::app()->getStore())
                ->setStoreId(Mage::app()->getStore()->getId());

            // Add Product to Quote
            $request = $this->getHelper()->getProductRequest($request);
            $result = $quote->addProduct($product, $request);
            if (is_string($result)) {
                Mage::throwException($result);
            }

            Mage::dispatchEvent('checkout_cart_product_add_after', array('quote_item' => $result, 'product' => $product));

            $rates = array();
            if (!$quote->getIsVirtual())
            {
                $address = json_decode($this->getRequest()->getParam('address'), true);
                $shippingAddress = $this->getHelper()->getShippingAddress($address);
                $quote->getShippingAddress()->addData($shippingAddress)->setCollectShippingRates(true)->save();
                $quote->collectTotals();
                $_shippingRateGroups = $quote->getShippingAddress()->getGroupedAllShippingRates();

                foreach ($_shippingRateGroups as $code => $_rates) {
                    foreach ($_rates as $_rate) {
                        if ($_rate->getErrorMessage()) {
                            continue;
                        }

                        $rates[] = array(
                            'id' => $_rate->getCode(),
                            'label' => $_rate->getMethodTitle(),
                            'detail' => $_rate->getMethodTitle(),
                            'price' => $_rate->getPrice(),
                            'amount' => Mage::helper('tax')->getShippingPrice(
                                $_rate->getPrice(),
                                $this->getHelper()->shouldCartPriceInclTax($quote->getStore()),
                                $quote->getShippingAddress(),
                                $quote->getCustomerTaxClassId()
                            )
                        );
                    }
                }
            }

            $currency = $quote->getQuoteCurrencyCode();
            $rates = array_map(function ($value) use ($currency) {
                unset($value['price']);
                $value['amount'] = $this->getHelper()->getAmountCents($value['amount'], $currency);
                return $value;
            }, $rates);
        } catch (Exception $e) {
            $this->getResponse()->setHeader('Content-type', 'application/json');
            $this->getResponse()->setBody(Zend_Json::encode(array(
                'success' => false,
                'message' => $e->getMessage()
            )));
            return;
        }

        $this->getResponse()->setHeader('Content-type', 'application/json');
        $this->getResponse()->setBody(Zend_Json::encode([
            "paymentIntent" => Mage::getSingleton("stripe_payments/paymentIntent")->create()->getClientSecret(),
            "results" => $rates
        ]));
    }

    /**
     * Apply Shipping Method for Cart
     */
    public function apply_shippingAction()
    {
        $quote = $this->_getQuote();

        try {
            // Add address data
            if (!$quote->getIsVirtual())
            {
                $shipping_id = $this->getRequest()->getParam('shipping_id');

                // Set Shipping Address
                $address = json_decode($this->getRequest()->getParam('address'), true);
                $shippingAddress = $this->getHelper()->getShippingAddress($address);
                $quote->getShippingAddress()->setShippingMethod($shipping_id)->addData($shippingAddress)->save();

                // Update totals
                $quote->setTotalsCollectedFlag(false);
                $quote->collectTotals();
                $quote->save();
            }
        } catch (Exception $e) {
            $this->getResponse()->setHeader('Content-type', 'application/json');
            $this->getResponse()->setBody(Zend_Json::encode(array(
                'success' => false,
                'message' => $e->getMessage()
            )));
            return;
        }

        $result = $this->getHelper()->getCartItems($quote);
        $this->getResponse()->setHeader('Content-type', 'application/json');
        $this->getResponse()->setBody(Zend_Json::encode([
            "paymentIntent" => Mage::getSingleton("stripe_payments/paymentIntent")->create()->getClientSecret(),
            "results" => $result
        ]));
    }

    /**
     * Apply Shipping Method for Single Product
     */
    public function apply_shipping_singleAction()
    {
        $request = json_decode($this->getRequest()->getParam('request'), true);
        $address = json_decode($this->getRequest()->getParam('address'), true);
        $shipping_id = $this->getRequest()->getParam('shipping_id');

        try {
            $result = $this->getHelper()->getSingleItems($request, $address, $shipping_id);
        } catch (Exception $e) {
            $this->getResponse()->setHeader('Content-type', 'application/json');
            $this->getResponse()->setBody(Zend_Json::encode(array(
                'success' => false,
                'message' => $e->getMessage()
            )));
            return;
        }

        $this->getResponse()->setHeader('Content-type', 'application/json');
        $this->getResponse()->setBody(Zend_Json::encode([
            "paymentIntent" => Mage::getSingleton("stripe_payments/paymentIntent")->create()->getClientSecret(),
            "results" => $result
        ]));
    }

    public function set_billing_addressAction()
    {
        try {
            $data = json_decode($this->getRequest()->getParam('data'), true);

            $quote = $this->_getQuote();
            // Place Order
            $billingAddress = $this->getHelper()->getBillingAddress($data);
            // Set Billing Address
            $quote->getBillingAddress()
                  ->addData($billingAddress);
            $quote->setTotalsCollectedFlag(false);
            $quote->save();
        }
        catch (\Exception $e)
        {
            $this->getResponse()->setHeader('Content-type', 'application/json');
            $this->getResponse()->setBody(Zend_Json::encode(array(
                'success' => false,
                'message' => $e->getMessage()
            )));
            return;
        }

        $this->getResponse()->setHeader('Content-type', 'application/json');
        $this->getResponse()->setBody(Zend_Json::encode([
            "paymentIntent" => Mage::getSingleton("stripe_payments/paymentIntent")->create()->getClientSecret(),
            "results" => null
        ]));
    }

    /**
     * Place Order Action
     */
    public function place_orderAction()
    {
        $this->store = Mage::app()->getStore();
        $this->saveCards = $this->store->getConfig('payment/stripe_payments_express/ccsave');

        $result = json_decode($this->getRequest()->getParam('result'), true);
        $paymentMethod = $result['paymentMethod'];
        $paymentMethodId = $paymentMethod['id'];

        // At this point the PI is already captured, so we don't want to trigger any further quote updates
        Mage::getSingleton("stripe_payments/paymentIntent")->create()->stopUpdatesForThisSession = true;

        $quote = $this->_getQuote();
        $this->_getSession()->setQuoteId($quote->getId());

        try {
            // Set Payment Method
            $quote->setPaymentMethod('stripe_payments');

            // Create an Order ID for the customer's quote
            $quote->reserveOrderId()->save();

            // Set Quote as InActive
            $quote->setIsActive(false)->save();

            // Set Billing Address
            $billingAddress = $this->getHelper()->getBillingAddress($paymentMethod['billing_details']);
            $quote->getBillingAddress()->addData($billingAddress);

            // Set Shipping Method
            if (!$quote->getIsVirtual()) {
                // Set Shipping Address
                /** @var Mage_Sales_Model_Quote_Address $shipping */
                $shippingAddress = $this->getHelper()->getShippingAddressFromResult($result);
                $shipping = $quote->getShippingAddress()->addData($shippingAddress);
                $shipping->setShippingMethod($result['shippingOption']['id'])->save();
            }

            // Update totals
            $quote->setTotalsCollectedFlag(false);
            $quote->collectTotals();

            // Get Amount
            $use_store_currency = Mage::getStoreConfig('payment/stripe_payments/use_store_currency');
            if ($use_store_currency)  {
                $amount = $quote->getGrandTotal();
                $currency = $quote->getQuoteCurrencyCode();
            } else {
                $amount = $quote->getBaseGrandTotal();
                $currency = $quote->getBaseCurrencyCode();
            }

            // Calculate amount for Recurring Products - this code is kept for reference, but should never run
            if ($this->isFrontEndSubscriptionPurchase()) {
                $amount = 0;
                $profiles = $quote->prepareRecurringPaymentProfiles();
                foreach ($profiles as $profile) {
                    /** @var $profile Mage_Sales_Model_Recurring_Profile */
                    $amount += $profile->getBillingAmount() +
                        $profile->getTrialBillingAmount() +
                        $profile->getShippingAmount() +
                        $profile->getTaxAmount() +
                        $profile->getInitAmount();
                }

                if ($use_store_currency) {
                    $amount *= $quote->getStoreToQuoteRate();
                }
            }

            // Set Checkout Method
            if (!Mage::getSingleton('customer/session')->isLoggedIn()) {
                // Use Guest Checkout
                $quote->setCheckoutMethod('guest')
                    ->setCustomerId(null)
                    ->setCustomerEmail($quote->getBillingAddress()->getEmail())
                    ->setCustomerIsGuest(true)
                    ->setCustomerGroupId(Mage_Customer_Model_Group::NOT_LOGGED_IN_ID);
            } else {
                $customer = Mage::getSingleton('customer/session')->getCustomer();
                $quote
                    ->setCustomer($customer)
                    ->setCheckoutMethod($customer->getMode())
                    ->save();
            }

            $quote->getPayment()->setAdditionalInformation('token', $paymentMethodId);
            $quote->getPayment()->setAdditionalInformation('source_id', $paymentMethodId);
            $quote->getPayment()->setAdditionalInformation('customer_stripe_id', Mage::helper("stripe_payments")->getCustomerStripeId());
            $quote->getPayment()->importData(array('method' => 'stripe_payments'));

            // Save Quote
            $quote->save();

            // Place Order
            Mage::getSingleton("stripe_payments/paymentIntent")->setPaymentMethod($paymentMethodId);
            /** @var Mage_Sales_Model_Service_Quote $service */
            $service = Mage::getModel('sales/service_quote', $quote);
            if (method_exists($service, 'submitAll'))
            {
                $service->submitAll();
                $order = $service->getOrder();
            }
            else
            {
                $order = $service->submit();
            }

            if ($order)
            {
                Mage::dispatchEvent(
                    'checkout_type_onepage_save_order_after',
                    array('order' => $order, 'quote' => $quote)
                );

                try {
                    $order->queueNewOrderEmail();
                } catch (Exception $e) {
                    Mage::logException($e);
                }

                // add order information to the session
                $this->_getSession()->setLastOrderId($order->getId())
                    ->setLastRealOrderId($order->getIncrementId());
            }

            // add quote information to the session
            $this->_getSession()->setLastQuoteId($quote->getId())
                ->setLastSuccessQuoteId($quote->getId());

            // add recurring profiles information to the session
            $profiles = $service->getRecurringPaymentProfiles();
            if ($profiles) {
                $ids = array();
                foreach ($profiles as $profile) {
                    $ids[] = $profile->getId();
                }
                $this->_getSession()->setLastRecurringProfileIds($ids);
            }

            Mage::dispatchEvent(
                'checkout_submit_all_after',
                array('order' => $order, 'quote' => $quote, 'recurring_profiles' => $profiles)
            );
        }
        catch (Exception $e)
        {
            Mage::logException($e);

            // Set as Active
            $quote->setIsActive(true)->save();

            $this->getResponse()->setHeader('Content-type', 'application/json');
            $this->getResponse()->setBody(Zend_Json::encode(array(
                'success' => false,
                'message' => $e->getMessage()
            )));
            return;
        }

        $this->getResponse()->setHeader('Content-type', 'application/json');
        $this->getResponse()->setBody(Zend_Json::encode(array(
            'success' => true,
            'redirect' => Mage::getUrl('checkout/onepage/success', array('_secure' => true))
        )));
    }

    /**
     * Add To Cart Action
     */
    public function addtocartAction()
    {
        $_request = $this->getRequest()->getParam('request');
        $shipping_id = $this->getRequest()->getParam('shipping_id');

        $request = array();
        parse_str($_request, $request);

        $cart = $this->_getCart();
        $quote = $this->_getQuote();

        try {
            // Get Product
            $product = Mage::getModel('catalog/product')
                ->setStoreId(Mage::app()->getStore()->getId())
                ->load($request['product']);

            if (!$product || !$product->getId()) {
                Mage::throwException('Product unavailable');
            }

            Mage::dispatchEvent('stripe_payments_express_before_add_to_cart', array('product' => $product, 'request' => $request));

            // Check is update required
            $isUpdated = false;
            foreach ($quote->getAllItems() as $item) {
                if ($item->getProductId() == $request['product']) {
                    $item = $cart->updateItem($item->getId(), $this->getHelper()->getProductRequest($request));
                    if (is_string($item)) {
                        Mage::throwException($item);
                    }
                    if ($item->getHasError()) {
                        Mage::throwException($item->getMessage());
                    }
                    $isUpdated = true;
                    break;
                }
            }

            // Add Product to Cart
            if (!$isUpdated)
            {
                Mage::helper("stripe_payments/express")->addToCart($product, $request);
            }

            if (!empty($params['related_product'])) {
                $cart->addProductsByIds(explode(',', $params['related_product']));
            }
            $cart->save();
            $this->_getSession()->setCartWasUpdated(true);

            if ($shipping_id) {
                // Set Shipping Method
                if (!$quote->isVirtual()) {
                    $quote->getShippingAddress()
                        ->setShippingMethod($shipping_id)
                        ->save();
                }
            }

            // Update totals
            $quote->setTotalsCollectedFlag(false);
            $quote->collectTotals();
            $quote->save();

            $result = $this->getHelper()->getCartItems($cart->save()->getQuote());
            $this->getResponse()->setHeader('Content-type', 'application/json');
            $this->getResponse()->setBody(Zend_Json::encode([
                "paymentIntent" => Mage::getSingleton("stripe_payments/paymentIntent")->create()->getClientSecret(),
                "results" => $result
            ]));
        } catch (Exception $e) {
            $this->getResponse()->setHeader('Content-type', 'application/json');
            $this->getResponse()->setBody(Zend_Json::encode(array(
                'success' => false,
                'message' => $e->getMessage()
            )));
        }
    }


    /**
     * Retrieve shopping cart model object
     *
     * @return Mage_Checkout_Model_Cart
     */
    protected function _getCart()
    {
        return Mage::getSingleton('checkout/cart');
    }

    /**
     * Get current active quote instance
     *
     * @return Mage_Sales_Model_Quote
     */
    protected function _getQuote()
    {
        return $this->_getCart()->getQuote();
    }

    /**
     * Get checkout session model instance
     *
     * @return Mage_Checkout_Model_Session
     */
    protected function _getSession()
    {
        return Mage::getSingleton('checkout/session');
    }

    /**
     * Check is FrontEnd Subscription Purchase
     * @return bool
     * @throws Mage_Core_Model_Store_Exception
     */
    protected function isFrontEndSubscriptionPurchase()
    {
        return !Mage::app()->getStore()->isAdmin() && $this->_getQuote()->hasRecurringItems();
    }

    public function getHelper()
    {
        return Mage::helper('stripe_payments/express');
    }
}
