<?php

class Stripe_Payments_WebhooksController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        Mage::helper('stripe_payments/webhooks')->dispatchEvent();
    }
}
