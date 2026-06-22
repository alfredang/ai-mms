<?php
class MMD_Hiring_Model_Mysql4_Lead extends Mage_Core_Model_Mysql4_Abstract
{
    protected function _construct() { $this->_init('mmd_hiring/lead', 'lead_id'); }
}
