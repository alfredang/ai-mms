<?php

class MMD_Courses_Model_Providers extends Mage_Core_Model_Abstract
{
    public function _construct()
    {
        parent::_construct();
        $this->_init('courses/providers');
    }
}