<?php
/**
 * Malaysia is booking-only (Mr Saeid, 15 Oct 2026): quotations, invoices and receipts are handled offline by the
 * Malaysia team, so a registration must never be invoiced in Magento (creating an invoice marks it paid).
 * Hides the admin "Invoice" button and blocks the invoice controller for Malaysia "registration" orders.
 */
class MMD_RegistrationOnly_Model_Observer
{
    public function blockInvoice(Varien_Event_Observer $observer)
    {
        $order = $observer->getEvent()->getOrder();
        if (!$order || !$order->getId() || $order->getStore()->getCode() !== 'malaysia') {
            return;
        }
        if ($order->getPayment() && $order->getPayment()->getMethod() === 'registration') {
            $order->setActionFlag(Mage_Sales_Model_Order::ACTION_FLAG_INVOICE, false);
        }
    }
}
