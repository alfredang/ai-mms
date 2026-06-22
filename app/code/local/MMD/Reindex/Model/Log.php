<?php
/**
 * @method string getStartedAt()
 * @method string getFinishedAt()
 * @method string getSource()
 * @method string getStatus()
 * @method int getOkCount()
 * @method int getFailCount()
 * @method string getSummary()
 */
class MMD_Reindex_Model_Log extends Mage_Core_Model_Abstract
{
    protected function _construct() { $this->_init('mmd_reindex/log'); }
}
