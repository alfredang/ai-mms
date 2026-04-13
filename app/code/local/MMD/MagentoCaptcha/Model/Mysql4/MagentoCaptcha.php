<?php

class MMD_MagentoCaptcha_Model_Mysql4_MagentoCaptcha extends Mage_Core_Model_Mysql4_Abstract
{
    public function _construct()
    {    
        // Note that the magentocaptcha_id refers to the key field in your database table.
        $this->_init('magentocaptcha/magentocaptcha', 'magentocaptcha_id');
    }
}