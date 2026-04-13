<?php

class MMD_MagentoCaptcha_Model_Mysql4_MagentoCaptcha_Collection extends Mage_Core_Model_Mysql4_Collection_Abstract
{
    public function _construct()
    {
        parent::_construct();
        $this->_init('magentocaptcha/magentocaptcha');
    }
}