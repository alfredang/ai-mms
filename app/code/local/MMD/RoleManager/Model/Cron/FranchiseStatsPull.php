<?php
/**
 * Daily Franchise Control Center collection — 02:30 UTC via config.xml
 * <crontab>. SG-only: country instances skip silently (they are the SOURCE of
 * this data). Delegates to FranchiseStatsService (SG local + MY/GH API pull +
 * fee ledger refresh).
 */
class MMD_RoleManager_Model_Cron_FranchiseStatsPull
{
    const LOG_FILE = 'franchise-report.log';

    public function run()
    {
        if (strtolower((string) getenv('MMS_MODE')) === 'country') {
            return;
        }
        try {
            $summary = Mage::getModel('mmd_rolemanager/franchiseStatsService')->pullAll('cron');
            Mage::log('Franchise stats pull: ' . json_encode($summary), Zend_Log::INFO, self::LOG_FILE, true);
        } catch (Exception $e) {
            Mage::log('Franchise stats pull error: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE, true);
        }
    }
}
