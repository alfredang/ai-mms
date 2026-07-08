<?php
/**
 * Daily maintenance sweep — 02:00 SGT via config.xml <crontab>.
 *
 * Born from the 2026-07-06 blank-admin incident: runaway migrations inserted
 * a spurious Malaysia store into SG's DB and the admin dashboard rendered an
 * empty 200 for hours with no alarm. This cron makes that class of corruption
 * visible within a day, and does the small hygiene work no other job owns.
 *
 * What it does (identical on every instance — SG + franchise partners):
 *   1. Verifies the one-store-per-site topology invariant (exactly one
 *      non-admin core_website + core_store row). Violations are shouted to
 *      error_log (lands in `docker logs`) since they mean a corrupted DB.
 *   2. Garbage-collects expired core_session rows (session lifetime is a
 *      year, so PHP's own GC never prunes; the table grows unbounded).
 *   3. Prunes var/report error dumps older than 30 days.
 *   4. Publishes the results to /media/health.json (public, like
 *      migrations-status.json) so external monitoring needs no DB access.
 *
 * Read-mostly; the only writes are session/report pruning and the JSON file.
 * No storefront code path runs this.
 */
class MMD_RoleManager_Model_Cron_Maintenance
{
    const LOG_FILE = 'maintenance.log';
    const REPORT_MAX_AGE_DAYS = 30;
    const SESSION_DELETE_BATCH = 20000;

    /**
     * Cron entry point — wired from config.xml <crontab>.
     */
    public function run()
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');

        $status = array(
            'timestamp' => gmdate('c'),
            'topology_ok' => null,
            'websites' => null,
            'stores' => null,
            'sessions_purged' => 0,
            'reports_pruned' => 0,
            'migrations_applied' => null,
        );

        // 1. Store-topology invariant (franchise model: one store per site).
        try {
            $status['websites'] = (int) $read->fetchOne(
                'SELECT COUNT(*) FROM ' . $resource->getTableName('core/website') . ' WHERE website_id <> 0'
            );
            $status['stores'] = (int) $read->fetchOne(
                'SELECT COUNT(*) FROM ' . $resource->getTableName('core/store') . ' WHERE store_id <> 0'
            );
            $status['topology_ok'] = ($status['websites'] === 1 && $status['stores'] === 1);
            if (!$status['topology_ok']) {
                // error_log lands in docker logs even when Mage::log is broken.
                error_log(sprintf(
                    'MMD MAINTENANCE ALERT: store topology violated — %d website(s), %d store(s). '
                    . 'One-store-per-site invariant broken (see 2026-07-06 incident).',
                    $status['websites'],
                    $status['stores']
                ));
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }

        // 2. Expired-session GC, batched so a first run over a huge backlog
        //    can't hold long locks.
        try {
            $sessionTbl = $resource->getTableName('core/session');
            do {
                $deleted = $write->delete(
                    $sessionTbl,
                    array('session_expires < ?' => time())
                );
                $status['sessions_purged'] += $deleted;
            } while ($deleted >= self::SESSION_DELETE_BATCH);
        } catch (Exception $e) {
            Mage::logException($e);
        }

        // 3. Prune old var/report dumps.
        try {
            $reportDir = Mage::getBaseDir('var') . DS . 'report';
            $cutoff = time() - self::REPORT_MAX_AGE_DAYS * 86400;
            foreach (glob($reportDir . DS . '*') ?: array() as $file) {
                if (is_file($file) && filemtime($file) < $cutoff && @unlink($file)) {
                    $status['reports_pruned']++;
                }
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }

        // 4. Migration ledger count for the health snapshot.
        try {
            $status['migrations_applied'] = (int) $read->fetchOne('SELECT COUNT(*) FROM schema_migrations');
        } catch (Exception $e) {
            // ledger may not exist on a fresh install — non-fatal
        }

        // 5. Publish to /media/health.json (public; DB-less monitoring).
        try {
            $mediaDir = Mage::getBaseDir('media');
            if (is_dir($mediaDir) && is_writable($mediaDir)) {
                file_put_contents(
                    $mediaDir . DS . 'health.json',
                    json_encode($status) . "\n"
                );
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }

        Mage::log('daily maintenance: ' . json_encode($status), null, self::LOG_FILE, true);
        return $this;
    }
}
