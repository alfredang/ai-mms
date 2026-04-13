<?php

class MMD_Courses_Model_Mysql4_Providers_Collection extends Mage_Core_Model_Mysql4_Collection_Abstract
{
    public function _construct()
    {
        parent::_construct();
        $this->_init('courses/providers');
    }
}