<?php
class Hitpay_Pay_Model_Payment extends Mage_Core_Model_Abstract
{
    protected function _construct()
    {
        parent::_construct();
        $this->_init('hitpay/payment');
    }
}
