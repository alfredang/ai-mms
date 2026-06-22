<?php
/**
 * Runs a full reindex (every index process). Used by the scheduled cron job
 * and by the admin "Reindex Now" button. Each process is isolated in its own
 * try/catch so one failure does not abort the rest. Every run is persisted to
 * mmd_reindex_log (history, shown in System -> Reindex Logs), summarised in
 * core_config_data (for the Scheduler page), and logged to var/log/mmd_reindex.log.
 */
class MMD_Reindex_Model_Cron
{
    const LOG = 'mmd_reindex.log';

    /** Cron entry point — Magento passes the schedule object as the first arg. */
    public function reindexAll($schedule = null)
    {
        return $this->run('cron');
    }

    /**
     * Cron entry point — flush all caches. Scheduled hourly as a safety net so
     * prod never serves a stale config / block / full-page cache for long (the
     * recurring "live != local" symptom). Cheap; only the first requests after
     * each flush rebuild the cache.
     */
    public function flushCache($schedule = null)
    {
        try {
            Mage::app()->cleanCache();
            Mage::app()->getCacheInstance()->flush();
            Mage::log('cache flushed (scheduled hourly)', null, self::LOG);
        } catch (Exception $e) {
            Mage::logException($e);
        }
        return true;
    }

    /**
     * @param string $source 'cron' | 'manual'
     * @return array<string,string> indexer_code => 'ok' | 'fail: <message>'
     */
    public function run($source = 'manual')
    {
        $results   = array();
        $startedAt = date('Y-m-d H:i:s');
        $started   = microtime(true);
        try {
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
        } catch (Exception $e) {
            Mage::logException($e);
            $results['_fatal'] = 'fail: ' . $e->getMessage();
        }

        $duration = round(microtime(true) - $started, 1);
        $fail     = count(array_filter($results, function ($v) { return strpos($v, 'fail') === 0; }));
        $ok       = count($results) - $fail;
        $status   = $fail === 0 ? 'success' : ($ok === 0 ? 'failed' : 'partial');

        // Persist run history.
        try {
            Mage::getModel('mmd_reindex/log')
                ->setStartedAt($startedAt)
                ->setFinishedAt(date('Y-m-d H:i:s'))
                ->setDurationSeconds($duration)
                ->setSource($source)
                ->setStatus($status)
                ->setOkCount($ok)
                ->setFailCount($fail)
                ->setSummary(json_encode($results))
                ->save();
        } catch (Exception $e) {
            Mage::logException($e);
        }

        // Quick-glance summary for the Scheduler page.
        try {
            $cfg = Mage::getModel('core/config');
            $cfg->saveConfig('mmd_reindex/last_run/at', $startedAt, 'default', 0);
            $cfg->saveConfig('mmd_reindex/last_run/seconds', (string) $duration, 'default', 0);
            $cfg->saveConfig('mmd_reindex/last_run/result', json_encode($results), 'default', 0);
        } catch (Exception $e) {
            Mage::logException($e);
        }

        Mage::log(sprintf('[%s] %s in %ss — %s', $source, $status, $duration, json_encode($results)), null, self::LOG);
        return $results;
    }
}
