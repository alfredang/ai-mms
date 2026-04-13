<?php

class Stripe_Payments_Configure_WebhooksController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $webhooksSetup = Mage::helper('stripe_payments/webhooksSetup');
        $webhooksSetup->configure();
        $this->getResponse()->setHeader('Content-type', 'application/json');
        $this->getResponse()->setBody(Zend_Json::encode([
            ['success' => true, 'errors' => count($webhooksSetup->errorMessages)]
        ]));
    }
}
