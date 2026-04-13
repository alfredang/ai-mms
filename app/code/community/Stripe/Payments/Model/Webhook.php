<?php

class Stripe_Payments_Model_Webhook extends Mage_Core_Model_Abstract
{
    public function _construct()
    {
        parent::_construct();
        $this->_init('stripe_payments/webhook');
    }

    public function pong()
    {
        $this->setLastEvent(time());
        return $this;
    }

    public function activate()
    {
        $this->setActive($this->getActive() + 1);
        return $this;
    }
}
