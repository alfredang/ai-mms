<?php
class Hitpay_Pay_Model_Mysql4_Payment_Collection extends Mage_Core_Model_Mysql4_Collection_Abstract 
{
    protected function _construct()
    {
        parent::_construct();
        $this->_init('hitpay/payment');
    }
}
