<?php

class Hitpay_Pay_Block_Awaiting extends Mage_Core_Block_Template
{
    public function getTemplateParams()
    {
        $order = Mage::helper('hitpay')->getOrder();
        if ($order && $order->getId()) {
            $paymentMethod = $order->getPayment()->getMethodInstance()->getCode();
            if ($paymentMethod == 'hitpay') {
                $params['order_id'] = $order->getId();
                $payment = Mage::getModel('hitpay/payment');
                $payment->load($order->getId(), 'order_id');
                $params['payment_id'] = $payment->getPaymentId();
                return $params;
            }
        }
        return false;
    }
}
