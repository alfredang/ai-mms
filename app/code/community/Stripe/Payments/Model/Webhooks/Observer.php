<?php

class Stripe_Payments_Model_Webhooks_Observer
{
    protected function orderAgeLessThan($minutes, $order)
    {
        $created = strtotime($order->getCreatedAt());
        $now = time();
        return (($now - $created) < ($minutes * 60));
    }

    // payment_intent.succeeded, creates an invoice when the payment is captured from the Stripe dashboard
    public function stripe_payments_webhook_payment_intent_succeeded($observer)
    {
        $event = $observer->getEvent();
        $object = $observer->getObject();
        $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);

        // The following can trigger when:
        // 1. A merchant uses the Stripe Dashboard to manually capture a payment intent that was Authorized Only
        // 2. When a normal order is placed at the checkout, in which case we need to ignore this
        // This is scenario 2 which we need to ignore
        if (empty($order) || $this->orderAgeLessThan($minutes = 3, $order))
            throw new Exception("Ignoring", 202);

        $paymentIntentId = $event['data']['object']['id'];
        $captureCase = Mage_Sales_Model_Order_Invoice::CAPTURE_OFFLINE;
        $params = [
            "amount" => $event['data']['object']['amount_received'],
            "currency" => $event['data']['object']['currency']
        ];

        Mage::helper('stripe_payments')->invoiceOrder($order, $paymentIntentId, $captureCase, $params);
    }

    // charge.refunded, creates a credit memo when the payment is refunded from the Stripe dashboard
    public function stripe_payments_webhook_charge_refunded_card($observer)
    {
        $event = $observer->getEvent();
        $object = $observer->getObject();
        $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);
        Mage::helper('stripe_payments/webhooks')->refund($order, $object);
    }

    public function addOrderCommentWithEmail($order, $comment)
    {
        $order->addStatusToHistory($status = false, $comment, $isCustomerNotified = true);
        $order->sendOrderUpdateEmail($notify = true, $comment);
        $order->save();
    }

    public function authorizationSucceeded($observer)
    {
        $event = $observer->getEvent();
        $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);
        Mage::helper('stripe_payments/webhooks')->charge($order, $event['data']['object']);
    }

    public function authorizationFailed($observer)
    {
        $event = $observer->getEvent();
        $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);
        Mage::helper('stripe_payments')->cancelOrCloseOrder($order);

        $this->addOrderCommentWithEmail($order, "Your order has been cancelled because the payment authorization failed.");
    }

    public function sourceCancelled($observer)
    {
        $event = $observer->getEvent();
        $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);
        $cancelled = Mage::helper('stripe_payments')->cancelOrCloseOrder($order);

        if ($cancelled)
        {
            $this->addOrderCommentWithEmail($order, "Sorry, your order has been cancelled because a payment request was sent to your bank, but we did not receive a response back. Please contact us or place your order again.");
        }
    }

    public function chargeSucceeded($observer)
    {
        $event = $observer->getEvent();
        $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);

        $invoiceCollection = $order->getInvoiceCollection();

        foreach ($invoiceCollection as $invoice)
        {
            if ($invoice->getState() != Mage_Sales_Model_Order_Invoice::STATE_PAID)
                $invoice->pay()->save();
        }

        $comment = Mage::helper("stripe_payments")->__("Payment succeeded.");
        $order->addStatusToHistory($status = false, $comment, $isCustomerNotified = false)
            ->setState(Mage_Sales_Model_Order::STATE_PROCESSING, true)
            ->save();
    }

    public function chargeFailed($observer)
    {
        $event = $observer->getEvent();
        $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);
        Mage::helper('stripe_payments')->cancelOrCloseOrder($order);

        $this->addOrderCommentWithEmail($order, "Your order has been cancelled. The payment authorization succeeded, however the authorizing provider declined the payment when a charge was attempted.");
    }

    /**************
     * Bancontact *
     **************/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_bancontact($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_bancontact($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_bancontact($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_bancontact($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_bancontact($observer)
    {
        $this->chargeFailed($observer);
    }

    /***********
     * Giropay *
     ***********/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_giropay($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_giropay($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_giropay($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_giropay($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_giropay($observer)
    {
        $this->chargeFailed($observer);
    }

    /*********
     * iDEAL *
     *********/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_ideal($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_ideal($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_ideal($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_ideal($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_ideal($observer)
    {
        $this->chargeFailed($observer);
    }

    /*********************
     * SEPA Direct Debit *
     *********************/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_sepa_debit($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_sepa_debit($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_sepa_debit($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_sepa_debit($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_sepa_debit($observer)
    {
        $this->chargeFailed($observer);
    }

    /**********
     * SOFORT *
     **********/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_sofort($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_sofort($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_sofort($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_sofort($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_sofort($observer)
    {
        $this->chargeFailed($observer);
    }

    /**************
     * Multibanco *
     **************/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_multibanco($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_multibanco($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_multibanco($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_multibanco($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_multibanco($observer)
    {
        $this->chargeFailed($observer);
    }

    /*************
     * P24        *
     *************/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_p24($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_p24($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_p24($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_p24($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_p24($observer)
    {
        $this->chargeFailed($observer);
    }

    /*********
     * EPS *
     *********/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_eps($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_eps($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_eps($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_eps($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_eps($observer)
    {
        $this->chargeFailed($observer);
    }

    /**********
     * Alipay *
     **********/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_alipay($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_alipay($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_alipay($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_alipay($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_alipay($observer)
    {
        $this->chargeFailed($observer);
    }

    /**************
     * WeChat Pay *
     **************/

    // source.chargeable
    public function stripe_payments_webhook_source_chargeable_wechat($observer)
    {
        $this->authorizationSucceeded($observer);
    }

    // source.canceled
    public function stripe_payments_webhook_source_canceled_wechat($observer)
    {
        $this->sourceCancelled($observer);
    }

    // source.failed
    public function stripe_payments_webhook_source_failed_wechat($observer)
    {
        $this->authorizationFailed($observer);
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_wechat($observer)
    {
        $this->chargeSucceeded($observer);
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_wechat($observer)
    {
        $this->chargeFailed($observer);
    }

    /**************
     * WeChat Pay *
     **************/

    public function chargeSucceededAch($observer)
    {
        $event = $observer->getEvent();
        $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);

        $invoiceCollection = $order->getInvoiceCollection();

        foreach ($invoiceCollection as $invoice)
        {
            if ($invoice->getState() != Mage_Sales_Model_Order_Invoice::STATE_PAID)
                $invoice->pay()->save();
        }

        $comment = "We have successfully received a payment by ACH bank transfer and will now be processing your order.";
        $translatedComment = Mage::helper('stripe_payments')->__($comment);

        $order->setState(Mage_Sales_Model_Order::STATE_PROCESSING, true);
        $order->addStatusToHistory($status = true, $translatedComment, $isCustomerNotified = true);
        $order->sendOrderUpdateEmail($notify = true, $translatedComment);
        $order->save();
    }

    public function chargeFailedAch($observer)
    {
        $event = $observer->getEvent();
        $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);
        $cancelled = Mage::helper('stripe_payments')->cancelOrCloseOrder($order);
        if ($cancelled)
        {
            $issue = $event['data']['object']['failure_message'];
            $last4 = $event['data']['object']['source']['last4'];
            $comment = "Sorry, your order has been canceled because your bank account ending $last4 could not be charged. The reason provided by the payment network was: %s. Please contact us or try to place your order again using a different payment method.";
            $translatedComment = Mage::helper('stripe_payments')->__($comment, $issue);
            $order->addStatusToHistory($status = false, $translatedComment, $isCustomerNotified = true);
            $order->sendOrderUpdateEmail($notify = true, $translatedComment);
            $order->save();
        }
    }

    // charge.succeeded
    public function stripe_payments_webhook_charge_succeeded_bank_account($observer)
    {
        try
        {
            $event = $observer->getEvent();
            $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);

            $this->chargeSucceededAch($observer);
        }
        catch (\Exception $e)
        {
            $order->addStatusToHistory($status = false, $e->getMessage(), $isCustomerNotified = false);
            $order->save();
            throw $e;
        }
    }

    // charge.failed
    public function stripe_payments_webhook_charge_failed_bank_account($observer)
    {
        try
        {
            $event = $observer->getEvent();
            $order = Mage::helper('stripe_payments/webhooks')->loadOrderFromEvent($event);

            $this->chargeFailedAch($observer);
        }
        catch (\Exception $e)
        {
            $order->addStatusToHistory($status = false, $e->getMessage(), $isCustomerNotified = false);
            $order->save();
            throw $e;
        }
    }

    // customer.source.updated, occurs when an ACH account is verified
    public function stripe_payments_webhook_customer_source_updated($observer)
    {
        try
        {
            $helper = Mage::helper('stripe_payments/webhooks');

            $event = $observer->getEvent();
            $data = $event['data'];
            if (!$helper->isACHBankAccountVerification($data))
                return;

            if (empty($data['object']['id']) || empty($data['object']['customer']))
                return;

            $orders = $helper->findOrdersFor($bankAccountId = $data['object']['id'], $customerId = $data['object']['customer']);
            foreach ($orders as $order)
            {
                Mage::app()->setCurrentStore($order->getStoreId());
                $comment = "Your bank account has been successfully verified.";
                $order->addStatusToHistory($status = false, $comment, $isCustomerNotified = true);
                $order->sendOrderUpdateEmail($notify = true, $comment);
                $helper->chargeAch($order);
            }
        }
        catch (\Exception $e)
        {
            $order->addStatusToHistory($status = false, "An error has occured while processing the payment: " . $e->getMessage(), $isCustomerNotified = false);
            $order->addStatusToHistory($status = false, $helper->__("There was a problem processing the payment for your order, please contact us for details"), $isCustomerNotified = true);
            $order->save();
            throw $e;
        }
    }
}
