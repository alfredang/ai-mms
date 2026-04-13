<?php

class Stripe_Payments_Model_Observer
{
    public function updateOrderState($observer)
    {
        $payment = $observer->getPayment();
        if (empty($payment) || strpos((string)$payment->getMethod(), 'stripe_payments') !== 0)
            return;

        $order = $payment->getOrder();
        if ($payment->getAdditionalInformation('stripe_outcome_type') == "manual_review")
        {
            $order->setHoldBeforeState($order->getState());
            $order->setHoldBeforeStatus($order->getStatus());
            $order->setState(Mage_Sales_Model_Order::STATE_HOLDED)
                ->setStatus($order->getConfig()->getStateDefaultStatus(Mage_Sales_Model_Order::STATE_HOLDED));
            $comment = Mage::helper("stripe_payments")->__("Order placed under manual review by Stripe Radar");
            $order->addStatusToHistory(false, $comment, false);
            $order->save();
        }

        // Add this comment to all orders except card payments, PRAPI payments and ACH payments
        if (!in_array((string)$payment->getMethod(), array("stripe_payments", "stripe_payments_ach")))
        {
            $comment = Mage::helper("stripe_payments")->__("The customer has been redirected for payment authorization, pending authorization outcome.");
            $order->addStatusToHistory($status = false, $comment, $isCustomerNotified = false);
            $order->save();
        }
    }

    public function updateStripeCustomer($observer)
    {
        $customer = $observer->getPayment()->getOrder()->getCustomer();
        if (!$customer) return;
        $customerId = $customer->getId();
        $customerEmail = $customer->getEmail();

        if (!empty($customerId) && !empty($customerEmail))
        {
            try
            {
                $resource = Mage::getSingleton('core/resource');
                $connection = $resource->getConnection('core_write');
                $table = $resource->getTableName('stripe_customers');
                $fields = array();
                $fields['customer_id'] = $customerId;
                $guestSelect = $connection->quoteInto('customer_email=?', $customerEmail) . ' and ' . $connection->quoteInto('session_id=?', Mage::getSingleton("core/session")->getEncryptedSessionId());
                $result = $connection->update($table, $fields, $guestSelect);
            }
            catch (\Exception $e) {}
        }
    }

    public function sales_order_payment_place_end($observer)
    {
        $this->updateOrderState($observer);
        $this->updateStripeCustomer($observer);
    }

    public function sales_order_invoice_pay($observer)
    {
        $store = Mage::app()->getStore();

        // In the admin area, there is a checkbox dictating whether to send an invoice or not
        if ($store->isAdmin())
            return;

        $shouldSendInvoice = $store->getConfig('payment/stripe_payments/email_invoice');
        if (!$shouldSendInvoice)
            return;

        try
        {
            $invoice = $observer->getEvent()->getInvoice();
            $invoice->save();
            $invoice->sendEmail(true, '');
        }
        catch (Exception $e)
        {
            Mage::logException($e);
        }
    }

    public function sales_order_invoice_cancel($observer)
    {
        $invoice = $observer->getEvent()->getInvoice();
        if (empty($invoice))
            return;

        $payment = $invoice->getOrder()->getPayment();
        if (strpos((string)$payment->getMethod(), 'stripe_') === 0)
        {
            $payment->getMethodInstance()->cancel($payment);
        }
    }
}
