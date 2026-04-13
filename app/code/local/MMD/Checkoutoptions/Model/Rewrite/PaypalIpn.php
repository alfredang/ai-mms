<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
class MMD_Checkoutoptions_Model_Rewrite_PaypalIpn extends Mage_Paypal_Model_Ipn
{
    /**
     * Overwrite this method to copy custom fields values to orders created by recurring profile
     */
    protected function _registerRecurringProfilePaymentCapture()
    {
        $price = $this->getRequestData('mc_gross') - $this->getRequestData('tax') -  $this->getRequestData('shipping');
        $productItemInfo = new Varien_Object;
        $type = trim($this->getRequestData('period_type'));
        if ($type == 'Trial') {
            $productItemInfo->setPaymentType(Mage_Sales_Model_Recurring_Profile::PAYMENT_TYPE_TRIAL);
        } elseif ($type == 'Regular') {
            $productItemInfo->setPaymentType(Mage_Sales_Model_Recurring_Profile::PAYMENT_TYPE_REGULAR);
        }
        $productItemInfo->setTaxAmount($this->getRequestData('tax'));
        $productItemInfo->setShippingAmount($this->getRequestData('shipping'));
        $productItemInfo->setPrice($price);

        $order = $this->_recurringProfile->createOrder($productItemInfo);

        $payment = $order->getPayment();
        $payment->setTransactionId($this->getRequestData('txn_id'))
            ->setPreparedMessage($this->_createIpnComment(''))
            ->setIsTransactionClosed(0);
        $order->save();
        $this->_recurringProfile->addOrderRelation($order->getId());
        $payment->registerCaptureNotification($this->getRequestData('mc_gross'));
        $order->save();

        // notify customer
        if ($invoice = $payment->getCreatedInvoice()) {
            $message = Mage::helper('paypal')->__('Notified customer about invoice #%s.', $invoice->getIncrementId());
            $comment = $order->sendNewOrderEmail()->addStatusHistoryComment($message)
                ->setIsCustomerNotified(true)
                ->save();
        }
		
		
		//start mmd modification
		Mage::getModel('checkoutoptions/checkoutoptions')->copyRecProfileFieldsToOrderFields($this->_recurringProfile->getId(), $order->getId());
		//end mmd modification
    }
}