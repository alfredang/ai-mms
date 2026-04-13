<?php
require_once Mage::getModuleDir('', 'Hitpay_Pay').'/vendor/autoload.php';

use HitPay\Client;

class Hitpay_Pay_Block_Adminhtml_Order_View extends Mage_Core_Block_Template
{
    public function getResponseValues()
    {
        $order_id = Mage::app()->getRequest()->getParam('order_id');
        $order = Mage::getModel('sales/order')->load($order_id);
        $payment = $order->getPayment();
        $model = $payment->getMethodInstance();
        $method = $model->getCode();
        if ($method == 'hitpay') {
            $hitpayment = Mage::getModel('hitpay/payment');
            $hitpayment->load($order->getId(), 'order_id');
            $payment_request_id = $hitpayment->getPaymentRequestId();
            if (!empty($payment_request_id)) {
                $payment_method = $hitpayment->getPaymentType();
                $fees = $hitpayment->getFees();
                if (empty($payment_method) || empty($fees)) {
                    $client = new Client(
                        Mage::helper('hitpay')->getStoreConfig("payment/hitpay/api_key"),
                        Mage::helper('hitpay')->getStoreConfig("payment/hitpay/mode")
                    );
                    
                    try {
                        $paymentStatus = $client->getPaymentStatus($payment_request_id);
                        if ($paymentStatus) {
                            $payments = $paymentStatus->payments;
                            if (isset($payments[0])) {
                                $payment = $payments[0];
                                $payment_method = $payment->payment_type;
                                $fees = $payment->fees;
                                $hitpayment->setPaymentType($payment_method);
                                $hitpayment->setFees($fees);
                                $hitpayment->save();
                            }
                        }
                    } catch (\Exception $e) {
                        $payment_method = $e->getMessage();
                    }
                }
                $response['payment_method'] = ucwords(str_replace("_", " ", $payment_method));
                $response['hitpay_fee'] = Mage::helper('core')->currency($fees, true, false);
                return $response;
            }
        }
        return false;
    }
}
