<?php

class Stripe_Payments_ApiController extends Mage_Core_Controller_Front_Action
{
    public function get_payment_intentAction()
    {
        Mage::getSingleton("stripe_payments/paymentIntent")->create();
        $this->getResponse()->setHeader('Content-type', 'application/json');
        $this->getResponse()->setBody(Zend_Json::encode([
            "paymentIntent" => Mage::getSingleton("stripe_payments/paymentIntent")->getClientSecret()
        ]));
    }
}
