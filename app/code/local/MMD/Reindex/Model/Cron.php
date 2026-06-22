<?php
/**
 * Runs a full reindex (every index process). Used by the scheduled cron job
 * and by the admin "Reindex Now" button. Each process is isolated in its own
 * try/catch so one failure does not abort the rest; the run summary is stored
 * in core_config_data for the admin page and logged to var/log/mmd_reindex.log.
 */
class MMD_Reindex_Model_Cron
{
    const LOG = 'mmd_reindex.log';

    /** @return array<string,string> indexer_code => 'ok' | 'fail: <message>' */
    public function reindexAll($schedule = null)
    {
        $results = array();
        try {
            $started = microtime(true);
            foreach (Mage::getModel('index/indexer')->getProcessesCollection() as $process) {
                $code = $process->getIndexerCode();
                try {
                    $process->reindexEverything();
                    $results[$code] = 'ok';
                } catch (Exception $e) {
                    $results[$code] = 'fail: ' . $e->getMessage();
                    Mage::logException($e);
                }
            }
            $cfg = Mage::getModel('core/config');
            $cfg->saveConfig('mmd_reindex/last_run/at', date('Y-m-d H:i:s'), 'default', 0);
            $cfg->saveConfig('mmd_reindex/last_run/seconds', (string) round(microtime(true) - $started, 1), 'default', 0);
            $cfg->saveConfig('mmd_reindex/last_run/result', json_encode($results), 'default', 0);
            Mage::log('reindexAll: ' . json_encode($results), null, self::LOG);
        } catch (Exception $e) {
            Mage::logException($e);
        }
        return $results;
    }
}
