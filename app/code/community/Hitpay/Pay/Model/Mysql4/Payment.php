<?php
class Hitpay_Pay_Model_Mysql4_Payment extends Mage_Core_Model_Mysql4_Abstract
{
    protected function _construct()
    {
        $this->_init('hitpay/payment','id');
    }
}
