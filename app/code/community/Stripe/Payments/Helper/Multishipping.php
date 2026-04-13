<?php

class Stripe_Payments_Helper_Multishipping extends Mage_Payment_Helper_Data
{
    public function __construct()
    {
        $this->helper = Mage::helper('stripe_payments');
        $this->paymentIntent = Mage::getSingleton('stripe_payments/paymentIntent');
        $this->cart = Mage::getSingleton('checkout/cart');
        $this->cache = Mage::app()->getCacheInstance();
    }

    public function getOrderIds()
    {
        $ids = Mage::getSingleton('core/session')->getOrderIds(true);
        $key = Mage::getSingleton('core/session')->getEncryptedSessionId() . "_multishipping_orders";
        $tags = ['stripe_multishipping_orders'];
        $lifetime = 6 * 60 * 60;

        if (empty($ids))
        {
            $ids = $this->cache->load($key);
        }

        if ($ids)
        {
            if (is_array($ids))
            {
                $this->cache->save($data = implode(', ', $ids), $key, $tags, $lifetime);
                return $ids;
            }
            else
            {
                $this->cache->save($data = $ids, $key, $tags, $lifetime);
                return explode(', ', $ids);
            }
        }

        return false;
    }

    public function getOrders()
    {
        $ids = $this->getOrderIds();

        if (empty($ids))
            return [];

        $orders = [];
        foreach ($ids as $orderId)
            $orders[] = Mage::getModel("sales/order")->loadByIncrementId($orderId);

        $ids = Mage::getSingleton('core/session')->getOrderIds(true);
        if (empty($ids))
        {
            $sessionOrders = [];
            foreach ($orders as $order)
                $sessionOrders[$order->getId()] = $order->getIncrementId();

            Mage::getSingleton('core/session')->setOrderIds($sessionOrders);
        }

        return $orders;
    }

    public function confirmPaymentsForSessionOrders()
    {
        $orders = $this->getOrders();
        $outcomes = ["hasErrors" => false];

        if (empty($orders))
            return [];

        foreach ($orders as $order)
        {
            try
            {
                $paymentIntent = $this->confirmPaymentFor($order);

                $transactionId = $paymentIntent->id;
                $transactionPending = $paymentIntent->charges->data[0]->captured;

                $order->getPayment()
                    ->setIsTransactionPending($transactionPending)
                    ->setLastTransId($transactionId)
                    ->save();

                $order->setState(Mage_Sales_Model_Order::STATE_PROCESSING)
                    ->setStatus($order->getConfig()->getStateDefaultStatus(Mage_Sales_Model_Order::STATE_PROCESSING))
                    ->addStatusToHistory($status = false, $comment = $this->__("Payment authentication succeeded."), $isCustomerNotified = false)
                    ->save();

                $this->paymentIntent->processAuthenticatedOrder($order, $paymentIntent);

                $outcomes["orders"][$order->getIncrementId()] = [
                    "success" => true,
                    "message" => $this->__("Order #%s has been placed successfully", $order->getIncrementId())
                ];
            }
            catch (\Exception $e)
            {
                $outcomes["hasErrors"] = true;

                $outcomes["orders"][$order->getIncrementId()] = [
                    "success" => false,
                    "message" => $this->__("Order #%s could not be placed: %s. Please try placing the order again.", $order->getIncrementId(), $e->getMessage())
                ];

                $comment = $this->__("The payment for this order could not be confirmed: %s.", $e->getMessage());
                $order->addStatusToHistory($status = Mage_Sales_Model_Order::STATE_CANCELED, $comment, $isCustomerNotified = false)
                    ->setState(Mage_Sales_Model_Order::STATE_CANCELED)
                    ->save();

                $this->restoreSessionQuoteFor($order);
            }
        }

        return $outcomes;
    }

    public function confirmPaymentFor($order)
    {
        $payment = $order->getPayment();
        if (empty($payment))
            throw new \Exception("Invalid payment for order #" . $order->getIncrementId());

        $paymentIntentId = $payment->getAdditionalInformation("payment_intent_id");
        if (empty($paymentIntentId))
            throw new \Exception("Payment Intent ID not found for order #" . $order->getIncrementId());

        $pi = \Stripe\PaymentIntent::retrieve($paymentIntentId);

        try
        {
            if ($this->paymentIntent->isSuccessfulStatus($pi))
                return $pi;

            $pi->confirm();

            if (!$this->paymentIntent->isSuccessfulStatus($pi))
            {
                // if (isset($pi->last_payment_error->message))
                //     throw new \Exception($pi->last_payment_error->message);

                throw new \Exception("Payment authentication failed");
            }
        }
        catch (\Exception $e)
        {
            throw new \Exception("Payment authentication failed");
        }

        return $pi;
    }

    public function restoreSessionQuoteFor($order)
    {
        $orderItems = $order->getAllItems();
        foreach ($orderItems as $orderItem) {
            $productIds[] = $orderItem->getProductId();
        }

        $quoteId = $order->getQuoteId();
        $quote = Mage::getModel('sales/quote')->load($quoteId);

        $items = $quote->getAllVisibleItems();

        foreach ($items as $item)
        {
            $productId = $item->getProductId();
            if (in_array($productId, $productIds))
            {
                $_product = $this->helper->loadProductById($productId);
                $options = $item->getProduct()->getTypeInstance(true)->getOrderOptions($item->getProduct());
                $info = $options['info_buyRequest'];
                $request = new Varien_Object();
                $request->setData($info);
                $this->cart->addProduct($_product, $request);
            }
        }
        $this->cart->save();
    }
}
