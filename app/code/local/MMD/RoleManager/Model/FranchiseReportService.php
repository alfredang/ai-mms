<?php
/**
 * SG-side franchise reporting: pulls COMPLETED classes from the MY/GH partner
 * instances' /courses/api_completed_classes endpoints and upserts them into
 * the local mmd_franchise_completed_classes table (migration 336) for the
 * Super Admin dashboard card.
 *
 * One-way and read-only towards the partners — this service only GETs their
 * API; partner DBs are never written. Partner endpoints + keys live in
 * core_config_data (set from the dashboard card's settings):
 *   mmd/franchise_report/my_url,  mmd/franchise_report/my_key
 *   mmd/franchise_report/gh_url,  mmd/franchise_report/gh_key
 * Last successful pull timestamp: mmd/franchise_report/last_pull.
 *
 * Mirrors CourseSyncService in structure (curl, paging, summary array).
 */
class MMD_RoleManager_Model_FranchiseReportService
{
    const LOG_FILE       = 'franchise-report.log';
    const LAST_PULL_PATH = 'mmd/franchise_report/last_pull';
    const TABLE          = 'mmd_franchise_completed_classes';

    /** Configured partners: array of array(country, url, key) — skips blanks. */
    public function getPartners()
    {
        $partners = array();
        foreach (array('MY', 'GH') as $cc) {
            $lc  = strtolower($cc);
            $url = rtrim(trim((string) Mage::getStoreConfig('mmd/franchise_report/' . $lc . '_url')), '/');
            $key = trim((string) Mage::getStoreConfig('mmd/franchise_report/' . $lc . '_key'));
            if ($url !== '' && $key !== '') {
                $partners[] = array('country' => $cc, 'url' => $url, 'key' => $key);
            }
        }
        return $partners;
    }

    public function isConfigured()
    {
        return count($this->getPartners()) > 0;
    }

    /**
     * Pull all configured partners. Returns a summary array.
     */
    public function pullAll($triggeredBy = 'cron')
    {
        $summary = array(
            'partners' => 0, 'fetched' => 0, 'upserted' => 0,
            'errors' => 0, 'error_msgs' => array(), 'success' => true,
        );

        foreach ($this->getPartners() as $p) {
            $summary['partners']++;
            try {
                $n = $this->_pullPartner($p['country'], $p['url'], $p['key'], $summary);
                Mage::log('FranchiseReport: pulled ' . $n . ' classes from ' . $p['country']
                    . ' (' . $triggeredBy . ')', Zend_Log::INFO, self::LOG_FILE, true);
            } catch (Exception $e) {
                $summary['errors']++;
                $summary['error_msgs'][] = $p['country'] . ': ' . $e->getMessage();
                Mage::log('FranchiseReport: ' . $p['country'] . ' failed — ' . $e->getMessage(),
                    Zend_Log::ERR, self::LOG_FILE, true);
            }
        }

        $summary['success'] = $summary['errors'] === 0;
        if ($summary['partners'] > 0 && $summary['errors'] < $summary['partners']) {
            // Record the last pull that brought at least one partner in.
            Mage::getConfig()->saveConfig(self::LAST_PULL_PATH, Mage::getModel('core/date')->gmtDate(), 'default', 0);
            Mage::getConfig()->reinit();
        }
        return $summary;
    }

    /** Pull one partner (paginated) and upsert its rows. Returns row count. */
    protected function _pullPartner($country, $baseUrl, $apiKey, array &$summary)
    {
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $table = Mage::getSingleton('core/resource')->getTableName(self::TABLE);

        $count = 0;
        $page  = 1;
        do {
            $payload = $this->_fetchPage($baseUrl, $apiKey, $page, 200);
            $classes = isset($payload['classes']) ? (array) $payload['classes'] : array();
            $summary['fetched'] += count($classes);

            foreach ($classes as $c) {
                $classCode = trim((string) ($c['class_code'] ?? ''));
                if ($classCode === '') {
                    continue;
                }
                $write->query(
                    "INSERT INTO `$table`
                        (source_country, class_code, course_title, course_code,
                         start_date, end_date, trainer_name, learners_attended)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                     ON DUPLICATE KEY UPDATE
                        course_title = VALUES(course_title),
                        course_code = VALUES(course_code),
                        start_date = VALUES(start_date),
                        end_date = VALUES(end_date),
                        trainer_name = VALUES(trainer_name),
                        learners_attended = VALUES(learners_attended)",
                    array(
                        $country,
                        $classCode,
                        (string) ($c['course_title'] ?? ''),
                        (string) ($c['course_code'] ?? ''),
                        ($c['start_date'] ?? null) ?: null,
                        ($c['end_date'] ?? null) ?: null,
                        (string) ($c['trainer_name'] ?? ''),
                        (int) ($c['learners_attended'] ?? 0),
                    )
                );
                $count++;
                $summary['upserted']++;
            }

            $totalPages = isset($payload['total_pages']) ? (int) $payload['total_pages'] : 1;
            $page++;
        } while ($page <= $totalPages);

        return $count;
    }

    /** GET one page from a partner's completed-classes endpoint. */
    protected function _fetchPage($baseUrl, $apiKey, $page, $pageSize)
    {
        $url = $baseUrl . '/courses/api_completed_classes?page=' . $page . '&page_size=' . $pageSize;
        $ch  = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS      => 5,
            CURLOPT_TIMEOUT        => 60,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; MMD-FranchiseReport/1.0)',
            CURLOPT_HTTPHEADER     => array(
                'X-API-Key: ' . $apiKey,
                'Accept: application/json',
            ),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            throw new Exception('Partner unreachable: ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($raw, true);
        if ($code >= 400 || !is_array($rsp) || empty($rsp['success'])) {
            $msg = is_array($rsp) && isset($rsp['error']) ? $rsp['error'] : ('HTTP ' . $code);
            throw new Exception('Partner export failed: ' . $msg);
        }
        return $rsp;
    }
}
