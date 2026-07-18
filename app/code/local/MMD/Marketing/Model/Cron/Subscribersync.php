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
    const CFG_LAST_RUN    = 'mmd_marketing/mailerlite/subscriber_sync_last_run';
    const CFG_LAST_STATUS = 'mmd_marketing/mailerlite/subscriber_sync_last_status';

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
            $this->_recordStatus(array(
                'ok' => false, 'ran_at' => $startedAt, 'since' => $since,
                'error' => $e->getMessage(),
            ));
            $this->_alert('MailerLite sync FAILED', 'The 4am subscriber sync threw an exception:'
                . "\n\n" . $e->getMessage() . "\n\nWindow since: " . $since);
            return;
        }

        Mage::getConfig()->saveConfig(self::CFG_LAST_RUN, $startedAt, 'default', 0);

        // Persist a machine-readable result so "did it actually run today, and
        // did anything reach MailerLite?" is answerable without SSH-ing to read
        // a log file. Surfaced on the Marketing dashboard.
        $this->_recordStatus(array(
            'ok'                 => ($stats['failed'] === 0),
            'ran_at'             => $startedAt,
            'since'              => $since,
            'store_id'           => $stats['store_id'],
            'group_id'           => $stats['group_id'],
            'candidates'         => $stats['candidates'],
            'added'              => $stats['added'],
            'skipped_suppressed' => $stats['skipped_suppressed'],
            'failed'             => $stats['failed'],
            'errors'             => array_slice($stats['errors'], 0, 5),
        ));

        // Alert only on REAL failures. A run that adds 0 is normal (no orders
        // yesterday), and "unsubscribed and cannot be imported" is MailerLite
        // correctly refusing an opt-out — neither is worth waking anyone up.
        $realErrors = array();
        foreach ($stats['errors'] as $e) {
            if (stripos($e, 'unsubscribed') === false) { $realErrors[] = $e; }
        }
        if ($realErrors) {
            $this->_alert(
                'MailerLite sync: ' . count($realErrors) . ' subscriber(s) failed',
                'The 4am subscriber sync completed but some addresses were rejected.'
                . "\n\nAdded: {$stats['added']}   Failed: {$stats['failed']}"
                . "\n\n" . implode("\n", array_slice($realErrors, 0, 10))
            );
        }

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
     * Persist the last run's outcome as JSON in core_config_data so the admin
     * (and a human asking "did it run today?") can read it without SSH.
     */
    protected function _recordStatus(array $status)
    {
        try {
            Mage::getConfig()->saveConfig(
                self::CFG_LAST_STATUS, json_encode($status), 'default', 0
            );
        } catch (Exception $e) { /* status is best-effort, never break the run */ }
    }

    /**
     * Email the marketing reviewers when a run genuinely fails.
     *
     * Transport order matches the newsletter/blog crons — Gmail OAuth, then the
     * SMTPPro transport, then bare Zend_Mail. Raw Zend_Mail alone bypasses
     * SMTPPro and silently fails on prod (real incident), so it is the LAST
     * resort, not the first.
     */
    protected function _alert($subject, $bodyText)
    {
        try {
            $recipients = Mage::helper('mmd_marketing/blastguard')->reviewers();
        } catch (Exception $e) {
            $recipients = array();
        }
        if (!$recipients) { return; }

        $html = '<div style="font-family:-apple-system,Segoe UI,Arial,sans-serif;max-width:640px">'
              . '<p style="font-size:15px;color:#0a1020;white-space:pre-wrap;">'
              . htmlspecialchars($bodyText) . '</p>'
              . '<p style="font-size:12px;color:#7c8aa3;">MailerLite subscriber sync — daily 04:00.</p></div>';

        $gmail = null;
        try {
            $gh = Mage::helper('mmd_email/gmail');
            if ($gh && $gh->isConfigured()) { $gmail = $gh; }
        } catch (Exception $e) { /* fall through to SMTP */ }
        $transport = null;
        if (!$gmail) {
            try {
                if (Mage::helper('core')->isModuleEnabled('Aschroder_SMTPPro')) {
                    $transport = Mage::helper('smtppro')->getTransport();
                }
            } catch (Exception $e) { /* fall through to bare Zend_Mail */ }
        }

        foreach ($recipients as $to) {
            try {
                if ($gmail) {
                    $gmail->send($to, '[MMS] ' . $subject, $html, 'Tertiary Marketing');
                } else {
                    $mail = new Zend_Mail('utf-8');
                    $mail->setBodyHtml($html)
                         ->setFrom(Mage::getStoreConfig('trans_email/ident_general/email'), 'Tertiary Marketing')
                         ->addTo($to)
                         ->setSubject('[MMS] ' . $subject);
                    $transport ? $mail->send($transport) : $mail->send();
                }
            } catch (Exception $e) {
                $this->_log('alert mail to ' . $to . ' failed: ' . $e->getMessage());
            }
        }
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
