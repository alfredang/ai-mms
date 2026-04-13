<?php

class Stripe_Payments_Model_Resource_Webhook extends Mage_Core_Model_Resource_Db_Abstract
{
    public function _construct()
    {
        $this->_init('stripe_payments/webhook', 'id');
    }
}
