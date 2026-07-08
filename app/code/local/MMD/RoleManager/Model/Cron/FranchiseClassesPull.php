<?php
/**
 * Weekly franchise completed-classes pull — Sunday 10:00 SGT via config.xml
 * <crontab>. SG-only: country instances skip silently (they are the SOURCE
 * of this data, not consumers). Delegates to FranchiseReportService, which
 * GETs the MY/GH /courses/api_completed_classes endpoints and upserts into
 * mmd_franchise_completed_classes for the Super Admin dashboard card.
 *
 * FAIL-SAFE: a no-op until partner URL+key are configured in
 * mmd/franchise_report/* (set from the dashboard card's settings).
 */
class MMD_RoleManager_Model_Cron_FranchiseClassesPull
{
    const LOG_FILE = 'franchise-report.log';

    public function run()
    {
        if (strtolower((string) getenv('MMS_MODE')) === 'country') {
            return; // partner instances are the data source, never the puller
        }

        /** @var MMD_RoleManager_Model_FranchiseReportService $svc */
        $svc = Mage::getModel('mmd_rolemanager/franchiseReportService');
        if (!$svc->isConfigured()) {
            Mage::log('Franchise pull skipped — no partner URL/key configured.',
                Zend_Log::INFO, self::LOG_FILE, true);
            return;
        }

        try {
            $summary = $svc->pullAll('cron');
            Mage::log('Franchise pull: ' . json_encode($summary), Zend_Log::INFO, self::LOG_FILE, true);
        } catch (Exception $e) {
            Mage::log('Franchise pull error: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE, true);
        }
    }
}
