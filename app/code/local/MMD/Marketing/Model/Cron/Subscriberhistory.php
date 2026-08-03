<?php
/**
 * Monthly rebuild of the reconstructed months behind the subscriber growth
 * chart on the Marketing Dashboard.
 *
 * Runs on the 28th at 03:00 (see MMD_Marketing/etc/config.xml). The 28th is the
 * last day every month is guaranteed to have, so the job fires 12 times a year
 * including February.
 *
 * Why a cron at all: daily snapshots only began 2026-07-13 (migration 302), so
 * the earlier months of a rolling 12-month chart have no recorded data.
 * MailerLite exposes no historical count, so those months are reconstructed
 * from subscriber signup dates — a ~36-page API walk taking ~40s, which must
 * never happen inside a dashboard page render. This persists the result into
 * mmd_marketing_subscriber_snapshot as is_estimated rows so the dashboard just
 * reads the table.
 *
 * Genuine daily snapshots are never overwritten — see
 * MMD_Marketing_Helper_Mailerlite::backfillEstimatedHistory(). As real
 * snapshots accumulate they progressively replace the reconstructed bars, and
 * this job becomes a no-op for those months.
 */
class MMD_Marketing_Model_Cron_Subscriberhistory
{
    const CFG_LAST_RUN = 'mmd_marketing/mailerlite/history_backfill_last_run';

    public function run()
    {
        $helper = Mage::helper('mmd_marketing/mailerlite');
        if (!$helper->isConfigured()) {
            $this->_log('skipped — MailerLite API key not configured');
            return;
        }

        // This site's own group. Falls back to the SG constant only when the
        // Company Setting is unset, matching the dashboard's own default; a
        // partner who has set their group gets their own list, never SG's.
        $groupId = $helper->getSyncGroupId();

        try {
            // 15 > the 13 months the chart reads, so the oldest bar is always
            // covered even if a run is missed and the window has rolled on.
            $written = $helper->backfillEstimatedHistory($groupId ?: null, 15);
            $msg     = $written . ' month(s) rebuilt';
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_log('FAILED — ' . $e->getMessage());
            return;
        }

        Mage::getModel('core/config')->saveConfig(self::CFG_LAST_RUN, date('Y-m-d H:i:s'));
        $this->_log($msg);
    }

    protected function _log($msg)
    {
        Mage::log('[subscriber-history] ' . $msg, Zend_Log::INFO, 'mmd_marketing.log', true);
    }
}
