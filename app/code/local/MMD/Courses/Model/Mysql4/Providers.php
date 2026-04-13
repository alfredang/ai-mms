<?php

class MMD_Courses_Model_Mysql4_Providers extends Mage_Core_Model_Mysql4_Abstract
{
    public function _construct()
    {    
        // Note that the providers_id refers to the key field in your database table.
        $this->_init('courses/providers', 'providers_id');
    }
}