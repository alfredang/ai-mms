<?php
/**
 * Auto-send certificates after class — daily 18:30 SGT.
 *
 * Mirrors LMS auto_create_certificates: scans completed classes within a
 * lookback window (including classes ending today — the 18:30 run fires after
 * the final PM session), and for every learner whose OVERALL session
 * attendance exceeds 70% and who has no certificate yet, generates + emails
 * one. Idempotent via the certificate table's unique (run_id, learner_email)
 * key.
 *
 * FAIL-SAFE: gated by mmd/certificate/auto_enabled. Absent config = OFF, so the
 * sweep ships inert and never fires until an admin enables it — even if Magento
 * cron is (re)enabled. Manual issuance is not affected by this flag.
 */
class MMD_Certificate_Model_Cron_AutoSend
{
    const LOG_FILE         = 'certificates.log';
    const DAYS_BACK        = 7;
    const LOCK_CONFIG_PATH = 'mmd/certificate_sweep/running';

    public function run()
    {
        /** @var MMD_Certificate_Helper_Data $h */
        $h = Mage::helper('mmd_certificate');

        if (!$h->isAutoEnabled()) {
            Mage::log('Certificate sweep skipped — auto-send disabled.', Zend_Log::INFO, self::LOG_FILE);
            return;
        }

        $running = Mage::getStoreConfig(self::LOCK_CONFIG_PATH);
        if ($running) {
            Mage::log('Certificate sweep skipped — previous run in progress.', Zend_Log::WARN, self::LOG_FILE);
            return;
        }

        try {
            Mage::getConfig()->saveConfig(self::LOCK_CONFIG_PATH, 1, 'default', 0);
            Mage::getConfig()->reinit();
            $this->_sweep($h);
        } catch (Exception $e) {
            Mage::log('Certificate sweep error: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
        } finally {
            Mage::getConfig()->saveConfig(self::LOCK_CONFIG_PATH, 0, 'default', 0);
            Mage::getConfig()->reinit();
        }
    }

    protected function _sweep(MMD_Certificate_Helper_Data $h)
    {
        $runIds = $h->getEligibleRuns(self::DAYS_BACK);
        $sent = 0; $skipped = 0; $errors = 0;

        foreach ($runIds as $runId) {
            $run = $h->loadRun((int)$runId);
            if (!$run) { continue; }
            foreach ($h->getEligibleLearners((int)$runId, $run) as $learner) {
                try {
                    $r = $h->issueAndSend($run, $learner, null);
                    if ($r['status'] === 'sent') $sent++;
                    elseif ($r['status'] === 'skipped') $skipped++;
                    else $errors++;
                } catch (Exception $e) {
                    $errors++;
                    Mage::log('Cert sweep error run=' . $runId . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
                }
            }
        }

        Mage::log(
            sprintf('Certificate sweep complete — sent:%d skipped:%d errors:%d (runs:%d)', $sent, $skipped, $errors, count($runIds)),
            Zend_Log::INFO, self::LOG_FILE
        );
    }
}
