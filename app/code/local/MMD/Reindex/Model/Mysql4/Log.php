<?php
class MMD_Reindex_Model_Mysql4_Log extends Mage_Core_Model_Mysql4_Abstract
{
    protected function _construct() { $this->_init('mmd_reindex/log', 'log_id'); }
}
