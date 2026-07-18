<?php
/**
 * Daily push of NEW SG order emails into the MailerLite Singapore group.
 *
 * Runs at 04:00 (see MMD_Marketing/etc/config.xml). Each run only looks at
 * orders created since the last successful run — the watermark is stored in
 * core_config_data so a missed day is picked up on the next run rather than
 * silently skipped. First run with no watermark falls back to the previous
 * 2 days rather than the whole order history: the full backfill is the
 * one-shot scripts/maintenance/mailerlite-import-order-emails.php, and we
 * don't want a cron accidentally replaying years of orders.
 *
 * Addresses that already unsubscribed are never sent — see
 * MMD_Marketing_Helper_Mailerlite::getSuppressedEmails().
 */
class MMD_Marketing_Model_Cron_Subscribersync
{
    const CFG_LAST_RUN = 'mmd_marketing/mailerlite/subscriber_sync_last_run';

    public function run()
    {
        $helper = Mage::helper('mmd_marketing/mailerlite');
        // Default OFF so the job is inert on every partner install until that
        // partner enables it and points it at their own group.
        if (!$helper->isSyncEnabled()) {
            return;
        }
        if (!$helper->isConfigured()) {
            $this->_log('skipped — MailerLite API key not configured');
            return;
        }

        $since = trim((string) Mage::getStoreConfig(self::CFG_LAST_RUN));
        if ($since === '') {
            $since = date('Y-m-d H:i:s', strtotime('-2 days'));
        }
        // Overlap the window by an hour so an order placed while the previous
        // run was mid-flight is not missed. Re-sending is harmless: MailerLite
        // upserts on email, so a duplicate is a no-op.
        $since = date('Y-m-d H:i:s', strtotime($since . ' -1 hour'));

        // Stamp BEFORE the run: if the sync dies halfway the next run still
        // advances, and the 1-hour overlap plus upsert semantics cover the gap.
        $startedAt = date('Y-m-d H:i:s');

        try {
            $stats = $helper->syncOrderEmails($since, false);
        } catch (Exception $e) {
            $this->_log('FAILED since=' . $since . ' error=' . $e->getMessage());
            return;
        }

        Mage::getConfig()->saveConfig(self::CFG_LAST_RUN, $startedAt, 'default', 0);

        $this->_log(sprintf(
            'since=%s store=%d group=%s candidates=%d added=%d skipped_unsubscribed=%d failed=%d%s',
            $since,
            $stats['store_id'],
            $stats['group_id'],
            $stats['candidates'],
            $stats['added'],
            $stats['skipped_suppressed'],
            $stats['failed'],
            $stats['errors'] ? ' errors=' . implode(' | ', $stats['errors']) : ''
        ));
    }

    /**
     * Mage::log silently drops writes when dev/log/allowedFileExtensions is
     * empty (the default on this install), so write the file directly.
     */
    protected function _log($msg)
    {
        @file_put_contents(
            Mage::getBaseDir('var') . '/log/mailerlite.log',
            '[' . date('Y-m-d H:i:s') . '] subscriber-sync: ' . $msg . "\n",
            FILE_APPEND
        );
    }
}
