<?php

class Stripe_Payments_Helper_Express extends Mage_Payment_Helper_Data
{
    /**
     * Get Default Shipping Address
     * @return array
     */
    public function getDefaultShippingAddress()
    {
        $address = array();
        $address['country'] = Mage::getStoreConfig(Mage_Shipping_Model_Shipping::XML_PATH_STORE_COUNTRY_ID);
        $address['postalCode'] = Mage::getStoreConfig(Mage_Shipping_Model_Shipping::XML_PATH_STORE_ZIP);
        $address['city'] = Mage::getStoreConfig(Mage_Shipping_Model_Shipping::XML_PATH_STORE_CITY);
        $address['addressLine'] = array();
        $address['addressLine'][0] = Mage::getStoreConfig(Mage_Shipping_Model_Shipping::XML_PATH_STORE_ADDRESS1);
        $address['addressLine'][1] = Mage::getStoreConfig(Mage_Shipping_Model_Shipping::XML_PATH_STORE_ADDRESS2);
        if ($region_id = Mage::getStoreConfig(Mage_Shipping_Model_Shipping::XML_PATH_STORE_REGION_ID)) {
            $region = Mage::getModel('directory/region')->load($address['region_id']);
            $address['region_id'] = $region->getRegionId();
            $address['region'] = $region->getName();
        }

        return $address;
    }

    public function clean($str)
    {
        return strtolower(trim($str));
    }

    public function getRegionsForCountry($countryCode)
    {
        $values = array();

        $regions = Mage::getModel('directory/country')->load($countryCode)->getRegions();

        foreach ($regions as $region)
        {
            $values['byCode'][$this->clean($region->getCode())] = $region->getId();
            $values['byName'][$this->clean($region->getName())] = $region->getId();
        }

        return $values;
    }

    public function getRegionIdBy($regionName, $regionCountry)
    {
        $regions = $this->getRegionsForCountry($regionCountry);

        $regionName = $this->clean($regionName);

        if (isset($regions['byName'][$regionName]))
            return $regions['byName'][$regionName];
        else if (isset($regions['byCode'][$regionName]))
            return $regions['byCode'][$regionName];

        return null;
    }

    /**
     * Get Address Fields
     * @param array $address
     *
     * @return array
     */
    public function getShippingAddress($address)
    {
        $nameParts = explode(' ', $address['recipient']);
        if (empty($nameParts))
            throw new Exception("No recipient name specified");

        $firstName = array_shift($nameParts);
        $lastName = implode(" ", $nameParts);

        // Get region_id by region
        if (empty($address['region_id']))
        {
            $address['region_id'] = $this->getRegionIdBy($regionName = $address['region'], $regionCountry = $address['country']);
        }

        return array(
            'firstname' => $firstName,
            'lastname' => $lastName,
            'company' => $address['organization'],
            'email' => '',
            'street' => (empty($address['addressLine']) ? array("Unspecified Street") : $address['addressLine']),
            'city' => $address['city'],
            'region_id' => $address['region_id'],
            'region' => $address['region'],
            'postcode' => $address['postalCode'],
            'country_id' => $address['country'],
            'telephone' => $address['phone'],
            'fax' => '',
            'customer_password' => '',
            'confirm_password' => '',
            'save_in_address_book' => '1',
            'use_for_shipping' => '1',
        );
    }

    public function getShippingAddressFromResult($result)
    {
        $address = $this->getShippingAddress($result['shippingAddress']);
        $address['email'] = $result['payerEmail'];
        return $address;
    }

    public function getBillingAddress($data)
    {
        $nameParts = explode(" ", $data['name']);
        if (empty($nameParts))
            throw new Exception("No payer name specified");

        $firstName = array_shift($nameParts);
        $lastName = implode(" ", $nameParts);
        $street = [
            0 => (!empty($data['address']['line1']) ? $data['address']['line1'] : 'Unspecified Street'),
            1 => (!empty($data['address']['line2']) ? $data['address']['line2'] : '')
        ];
        $city = (!empty($data['address']['city']) ? $data['address']['city'] : 'Unspecified City');
        $region = (!empty($data['address']['state']) ? $data['address']['state'] : 'Unspecified Region');
        $postcode = (!empty($data['address']['postal_code']) ? $data['address']['postal_code'] : null);
        $country = (!empty($data['address']['country']) ? $data['address']['country'] : null);

        $regionId = $this->getRegionIdBy($region, $country);

        return [
            'firstname' => $firstName,
            'lastname' => $lastName,
            'company' => '',
            'email' => $data['email'],
            'street' => $street,
            'city' => $city,
            'region_id' => $regionId,
            'region' => $region,
            'postcode' => $postcode,
            'country_id' => $country,
            'telephone' => $data['phone'],
            'fax' => '',
        ];
    }

    /**
     * Prepare Request Info
     * @param Varien_Object|array|int $requestInfo
     *
     * @return Varien_Object
     */
    public function getProductRequest($requestInfo)
    {
        if ($requestInfo instanceof Varien_Object) {
            $request = $requestInfo;
        } elseif (is_numeric($requestInfo)) {
            $request = new Varien_Object(array('qty' => $requestInfo));
        } else {
            $request = new Varien_Object($requestInfo);
        }

        // Check Qty
        if (!$request->hasQty()) {
            /** @var Mage_Catalog_Helper_Product $helper */
            $helper  = Mage::helper('catalog/product');
            $request->setQty($helper->getDefaultQty($request->getProduct()));
        }

        $filter = new Zend_Filter_LocalizedToNormalized(
            array('locale' => Mage::app()->getLocale()->getLocaleCode())
        );
        $request->setQty($filter->filter($request->getQty()));

        return $request;
    }

    /**
     * Get Amount in Cents
     * @param $amount
     * @param $currency
     *
     * @return float
     */
    public function getAmountCents($amount, $currency)
    {
        $cents = (Mage::helper("stripe_payments")->isZeroDecimal($currency) ? 1 : 100);
        return round($amount * $cents);
    }

    /**
     * Get Customer Email
     * @return string
     */
    public function getCustomerEmail()
    {
        $quote = $this->getSessionQuote();

        if ($quote)
            $email = trim(strtolower($quote->getCustomerEmail()));

        // This happens with guest checkouts
        if (empty($email))
            $email = trim(strtolower($quote->getBillingAddress()->getEmail()));

        // We might be viewing a guest order from admin
        if (empty($email))
            $email = trim(strtolower($this->getAdminOrderGuestEmail()));

        return $email;
    }

    /**
     * Get Email from Order in admin area
     * @return string
     */
    public function getAdminOrderGuestEmail()
    {
        return Mage::helper("stripe_payments")->getAdminOrderGuestEmail();
    }

    /**
     * Get Quote from Checkout Session
     * @return Mage_Sales_Model_Quote
     * @throws Mage_Core_Model_Store_Exception
     */
    public function getSessionQuote()
    {
        // If we are in the back office
        if (Mage::app()->getStore()->isAdmin())  {
            return Mage::getSingleton('adminhtml/sales_order_create')->getQuote();
        }

        // If we are a user
        return Mage::getSingleton('checkout/session')->getQuote();
    }

    /**
     * Get Cart items
     * @param Mage_Sales_Model_Quote $quote
     *
     * @return array
     * @throws Mage_Core_Model_Store_Exception
     */
    public function getCartItems($quote = null)
    {
        if (!$quote) {
            $quote = $this->getSessionQuote();
        }

        // Get Currency and Amount
        $use_store_currency = Mage::getStoreConfig('payment/stripe_payments/use_store_currency');
        if ($use_store_currency) {
            $amount = $quote->getGrandTotal();
            $currency = $quote->getQuoteCurrencyCode();
        } else {
            $amount = $quote->getBaseGrandTotal();
            $currency = $quote->getBaseCurrencyCode();
        }

        // Calculate amount for Recurring Products
        if ($quote->hasRecurringItems()) {
            $amount = 0;
            $quote->collectTotals();
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

        // Get Quote Items
        $shouldInclTax = $this->shouldCartPriceInclTax($quote->getStore());
        $displayItems = array();
        $items = $quote->getAllVisibleItems();
        foreach ($items as $item)
        {
            /** @var $item Mage_Sales_Model_Quote_Item */
            if ($item->getParentItem())
                continue;

            if ($use_store_currency)
            {
                $rowTotal = $shouldInclTax ? $item->getRowTotalInclTax() : $item->getRowTotal();
                $price = $shouldInclTax ? $item->getPriceInclTax() : $item->getPrice();
                $price *= $quote->getBaseToQuoteRate();
            }
            else
            {
                $rowTotal = $shouldInclTax ? $item->getBaseRowTotalInclTax() : $item->getBaseRowTotal();
                $price = $shouldInclTax ? $item->getBasePriceInclTax() : $item->getBasePrice();
            }

            $label = $item->getName();
            if ($item->getQty() > 1)
            {
                $formattedPrice = Mage::app()->getLocale()->currency($currency)->toCurrency($price);
                $label .= " ({$item->getQty()} x $formattedPrice)";
            }

            $displayItems[] = array(
                'label' => $label,
                'amount' => $this->getAmountCents($rowTotal, $currency),
                'pending' => false
            );
        }

        // Add Shipping
        if (!$quote->getIsVirtual()) {
            $address = $quote->getShippingAddress();
            if ((float)$address->getShippingInclTax() >= 0.01) {
                if ($use_store_currency) {
                    $price = $shouldInclTax ? $address->getShippingInclTax() : $address->getShippingAmount();
                    $displayItems[] = array(
                        'label' => $this->__('Shipping'),
                        'amount' => $this->getAmountCents($price, $currency)
                    );
                } else {
                    $price = $shouldInclTax ? $address->getBaseShippingInclTax() : $address->getBaseShippingAmount();
                    $displayItems[] = array(
                        'label' => $this->__('Shipping'),
                        'amount' => $this->getAmountCents($price, $currency)
                    );
                }
            }
        }

        // Add Discount
        if ((float)$quote->getDiscountAmount() >= 0.01)
        {
            if ($use_store_currency)
                $discountAmount = $quote->getDiscountAmount();
            else
                $discountAmount = $quote->getBaseDiscountAmount();

            $displayItems[] = array(
                'label' => $this->__('Discount'),
                'amount' => $this->getAmountCents($discountAmount, $currency)
            );
        }

        // Add Tax Amount
        if (!$shouldInclTax) {
            if ($use_store_currency) {
                $taxAmount = $quote->getShippingAddress()->getTaxAmount();
            } else {
                $taxAmount = $quote->getShippingAddress()->getBaseTaxAmount();
            }

            if ((float)$taxAmount >= 0.01) {
                $displayItems[] = array(
                    'label' => $this->__('Tax'),
                    'amount' => $this->getAmountCents($taxAmount, $currency)
                );
            }
        }

        return array(
            'currency' => strtolower($currency),
            'total' => array(
                'label' => $this->getLabel(),
                'amount' => $this->getAmountCents($amount, $currency),
                'pending' => false
            ),
            'displayItems' => $displayItems
        );
    }

    /**
     * Get Items for Single Product
     * @param      $request
     * @param      $address
     * @param null $shipping_id
     *
     * @return array
     * @throws Mage_Core_Exception
     * @throws Mage_Core_Model_Store_Exception
     */
    public function getSingleItems($request, $address, $shipping_id = null) {
        $request = $this->getProductRequest($request);

        // Check Product
        $product = Mage::getModel('catalog/product')
            ->setStoreId(Mage::app()->getStore()->getId())
            ->load($request->getProduct());

        if (!$product || !$product->getId()) {
            Mage::throwException('Product unavailable');
        }

        // Prepare Quote
        /** @var Mage_Sales_Model_Quote $quote */
        $quote = Mage::getModel('sales/quote');

        $quote->setStore(Mage::app()->getStore())
            ->setStoreId(Mage::app()->getStore()->getId())
            ->setIsActive(1)
            ->setReservedOrderId(null)
            ->collectTotals()
            ->save();

        /** @var Mage_Sales_Model_Quote_Item $item */
        $item = $quote->addProduct($product, $request);
        if (is_string($item)) {
            Mage::throwException($item);
        }

        Mage::dispatchEvent('checkout_cart_product_add_after', array('quote_item' => $item, 'product' => $product));

        // Apply Shipping
        if ($shipping_id) {
            // Billing Address
            $billingAddress = $this->getAddressFields($address);

            // Set Billing Address
            $quote->getBillingAddress()
                ->addData($billingAddress);

            // Set Shipping Address
            $shipping = $quote->getShippingAddress()
                ->addData($billingAddress);

            // Set Shipping Method
            if (!$quote->isVirtual()) {
                $shipping->setShippingMethod($shipping_id)->save();
            }
        }

        // @todo Add Discount

        // Calculate
        $quote->getBillingAddress();
        $quote->getShippingAddress()->setCollectShippingRates(true);
        $quote->setTotalsCollectedFlag(false);
        $quote->collectTotals();
        $quote->save();

        // Get Currency
        $use_store_currency = Mage::getStoreConfig('payment/stripe_payments/use_store_currency');
        if ($use_store_currency) {
            $currency = $quote->getQuoteCurrencyCode();
        } else {
            $currency = Mage::app()->getStore()->getCurrentCurrencyCode();
        }

        // Get Quote Items
        $shouldInclTax = $this->shouldCartPriceInclTax($quote->getStore());
        $displayItems = array();
        $items = $quote->getAllVisibleItems();
        foreach ($items as $item) {
            /** @var $item Mage_Sales_Model_Quote_Item */
            if ($item->getParentItem()) {
                continue;
            }

            $qty = $item->getQty();

            if ($use_store_currency) {
                $price = $shouldInclTax ? $item->getPriceInclTax() : $item->getPrice();
                $displayItems[] = array(
                    'label' => $item->getName(),
                    'amount' => $this->getAmountCents($qty * $price, $currency),
                    'pending' => false
                );
            } else {
                $price = $shouldInclTax ? $item->getBasePriceInclTax() : $item->getBasePrice();
                $displayItems[] = array(
                    'label' => $item->getName(),
                    'amount' => $this->getAmountCents($qty * $price, $currency),
                    'pending' => false
                );
            }

        }

        // Add Shipping
        if (!$quote->getIsVirtual()) {
            $address = $quote->getShippingAddress();
            if ((float)$address->getShippingInclTax() >= 0.01) {
                if ($use_store_currency) {
                    $displayItems[] = array(
                        'label' => $this->__('Shipping'),
                        'amount' => $this->getAmountCents($address->getShippingInclTax(), $currency)
                    );
                } else {
                    $displayItems[] = array(
                        'label' => $this->__('Shipping'),
                        'amount' => $this->getAmountCents($address->getBaseShippingInclTax(), $currency)
                    );
                }
            }
        }

        // Add Tax Amount
        if (!$shouldInclTax) {
            if ($use_store_currency) {
                $taxAmount = $quote->getShippingAddress()->getTaxAmount();
            } else {
                $taxAmount = $quote->getShippingAddress()->getBaseTaxAmount();
            }

            if ((float)$taxAmount >= 0.01) {
                $displayItems[] = array(
                    'label' => $this->__('Tax'),
                    'amount' => $this->getAmountCents($taxAmount, $currency)
                );
            }
        }

        if ($use_store_currency) {
            $amount = $quote->getGrandTotal();
            $currency = $quote->getQuoteCurrencyCode();
        } else {
            $amount = $quote->getBaseGrandTotal();
            $currency = $quote->getBaseCurrencyCode();
        }

        return array(
            'currency' => strtolower($currency),
            'total' => array(
                'label' => $this->getLabel(),
                'amount' => $this->getAmountCents($amount, $currency),
                'pending' => false
            ),
            'displayItems' => $displayItems
        );
    }

    /**
     * Get Label
     * @param Mage_Sales_Model_Quote $quote
     *
     * @return string
     * @throws Mage_Core_Model_Store_Exception
     */
    public function getLabel($quote = null)
    {
        if (!$quote) {
            $quote = $this->getSessionQuote();
        }

        $email = $this->getCustomerEmail();
        $first = $quote->getCustomerFirstname();
        $last = $quote->getCustomerLastname();

        if (empty($email) && empty($first) && empty($last)) {
            return 'Order';
        } elseif (empty($email)) {
            return "Order by $first $last";
        }

        return "Order by $first $last <$email>";
    }

    /**
     * Should Cart Price Include Tax
     * @param mixed $store
     *
     * @return bool
     */
    public function shouldCartPriceInclTax($store = null)
    {
        /** @var Mage_Tax_Helper_Data $taxHelper */
        $taxHelper = Mage::helper('tax');
        if ($taxHelper->displayCartBothPrices($store)) {
            return true;
        } elseif ($taxHelper->displayCartPriceInclTax($store)) {
            return true;
        }

        return false;
    }

    public function isEnabled($location)
    {
        $active = Mage::getStoreConfig('payment/stripe_payments/active');
        $activeLocation = Mage::getStoreConfig('payment/stripe_payments_express/' . $location);

        $quoteHasSubscriptions = Mage::getSingleton('checkout/cart')->getQuote()->hasRecurringItems();
        $isCurrentProductRecurring = false;
        if (Mage::registry('current_product'))
            $isCurrentProductRecurring = Mage::registry('current_product')->getIsRecurring();

        return $active && $activeLocation && !$quoteHasSubscriptions && !$isCurrentProductRecurring;
    }

    public function addToCart($product, $params)
    {
        $cart = $this->cart = Mage::getSingleton('checkout/cart');
        if (isset($params['qty'])) {
            $filter = new Zend_Filter_LocalizedToNormalized(
                array('locale' => Mage::app()->getLocale()->getLocaleCode())
            );
            $params['qty'] = $filter->filter($params['qty']);
        }

        $related = $params['related_product'];

        /**
         * Check product availability
         */
        if (!$product)
        {
            throw new Exception("Cannot add the item to shopping cart.");
        }

        $cart->addProduct($product, $params);
        if (!empty($related)) {
            $cart->addProductsByIds(explode(',', $related));
        }

        $cart->save();

        Mage::getSingleton('checkout/session')->setCartWasUpdated(true);
    }
}
