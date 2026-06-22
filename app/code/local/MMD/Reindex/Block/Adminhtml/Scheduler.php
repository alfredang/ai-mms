<?php
class MMD_Reindex_Block_Adminhtml_Scheduler extends Mage_Adminhtml_Block_Template
{
    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('mmd_reindex/scheduler.phtml');
    }

    public function getScheduleOptions()
    {
        return array(
            '0 3 * * *'    => $this->__('Daily at 03:00'),
            '0 3,15 * * *' => $this->__('Twice daily (03:00 & 15:00)'),
            '0 3 * * 0'    => $this->__('Weekly (Sunday 03:00)'),
            '0 * * * *'    => $this->__('Hourly'),
            ''             => $this->__('Disabled'),
        );
    }

    public function getScheduleExpr()
    {
        return (string) $this->_cfg('crontab/mmd_reindex/schedule');
    }

    public function getScheduleLabel()
    {
        $opts = $this->getScheduleOptions();
        $e    = $this->getScheduleExpr();
        return isset($opts[$e]) ? $opts[$e] : ($e !== '' ? $e : $this->__('Disabled'));
    }

    public function getLastRunAt()
    {
        $at = $this->_cfg('mmd_reindex/last_run/at');
        return $at ? $this->formatDate($at, 'medium', true) : $this->__('Never');
    }

    public function getLastRunSeconds()
    {
        return $this->_cfg('mmd_reindex/last_run/seconds');
    }

    public function getProcesses()
    {
        return Mage::getModel('index/indexer')->getProcessesCollection();
    }

    public function getRunUrl()
    {
        return $this->getUrl('*/*/run');
    }

    public function getSaveUrl()
    {
        return $this->getUrl('*/*/saveSchedule');
    }

    /** Read straight from the DB so a save in the same request isn't masked by the config cache. */
    protected function _cfg($path)
    {
        $res = Mage::getSingleton('core/resource');
        return $res->getConnection('core_read')->fetchOne(
            'SELECT value FROM ' . $res->getTableName('core/config_data') . " WHERE path = ? AND scope = 'default' AND scope_id = 0",
            array($path)
        );
    }
}
