<?php
/**
 * SG-side Franchise Control Center collector.
 *
 * Collects the franchise statistics of EVERY site — SG itself straight from
 * the local DB, MY/GH over their /courses/api_franchise_stats endpoint — and
 * upserts them into mmd_franchise_classes + mmd_franchise_orders (migration
 * 1893). Then refreshes the per-class fee ledger (mmd_franchise_class_fee):
 *
 *   fee per class = billable learners x the partner's per-learner fee
 *   billable learners = learners marked present if attendance was taken,
 *                       otherwise the enrolled roster
 *   a class is billable once it is CONFIRMED (trainer assigned) and its start
 *   date has passed (i.e. delivered). Partners with a zero fee (MY) get no
 *   ledger rows. A row already marked completed (paid) is never recomputed.
 *
 * One-way and read-only towards the partners. Partner endpoints + keys are the
 * same mmd/franchise_report/{my,gh}_{url,key} used by FranchiseReportService.
 * Fee config: mmd/franchise_fee/{my,gh}_per_learner + _currency.
 */
class MMD_RoleManager_Model_FranchiseStatsService
{
    const LOG_FILE       = 'franchise-report.log';
    const LAST_PULL_PATH = 'mmd/franchise_stats/last_pull';
    const SINCE_MONTHS   = 13;

    public function partnerCodes()
    {
        return array('MY', 'GH');
    }

    /** Per-partner fee settings: array(cc => array(per_learner, currency)). */
    public function feeConfig()
    {
        $cfg = array();
        foreach ($this->partnerCodes() as $cc) {
            $lc = strtolower($cc);
            $cfg[$cc] = array(
                'per_learner' => round((float) Mage::getStoreConfig('mmd/franchise_fee/' . $lc . '_per_learner'), 2),
                'currency'    => strtoupper(trim((string) Mage::getStoreConfig('mmd/franchise_fee/' . $lc . '_currency'))) ?: 'USD',
            );
        }
        return $cfg;
    }

    /** Collect every site. Returns a summary array. */
    public function pullAll($triggeredBy = 'cron')
    {
        $summary = array('sites' => array(), 'errors' => 0, 'error_msgs' => array(), 'success' => true);
        $since   = date('Y-m-d', strtotime('-' . self::SINCE_MONTHS . ' months'));

        // SG — the control site, read locally.
        try {
            $stats   = Mage::getModel('courses/franchiseStats');
            $classes = $orders = array();
            for ($p = 1; $p <= 50; $p++) { $rows = $stats->classes($since, $p, 500); $classes = array_merge($classes, $rows); if (count($rows) < 500) break; }
            for ($p = 1; $p <= 100; $p++) { $rows = $stats->orders($since, $p, 500); $orders = array_merge($orders, $rows); if (count($rows) < 500) break; }
            $summary['sites']['SG'] = array('classes' => $this->_upsertClasses('SG', $classes), 'orders' => $this->_upsertOrders('SG', $orders));
        } catch (Exception $e) {
            $summary['errors']++; $summary['error_msgs'][] = 'SG: ' . $e->getMessage();
        }

        // Partners — over their API.
        /** @var MMD_RoleManager_Model_FranchiseReportService $report */
        $report = Mage::getModel('mmd_rolemanager/franchiseReportService');
        foreach ($report->getPartners() as $p) {
            $cc = $p['country'];
            try {
                $classes = $this->_fetchAll($p['url'], $p['key'], 'classes', $since);
                $orders  = $this->_fetchAll($p['url'], $p['key'], 'orders', $since);
                $summary['sites'][$cc] = array('classes' => $this->_upsertClasses($cc, $classes), 'orders' => $this->_upsertOrders($cc, $orders));
                Mage::log("FranchiseStats: $cc " . json_encode($summary['sites'][$cc]) . " ($triggeredBy)", Zend_Log::INFO, self::LOG_FILE, true);
            } catch (Exception $e) {
                $summary['errors']++;
                $summary['error_msgs'][] = $cc . ': ' . $e->getMessage();
                Mage::log("FranchiseStats: $cc failed — " . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE, true);
            }
        }

        $summary['fees']    = $this->refreshFees();
        $summary['success'] = $summary['errors'] === 0;
        if (!empty($summary['sites'])) {
            Mage::getConfig()->saveConfig(self::LAST_PULL_PATH, Mage::getModel('core/date')->gmtDate(), 'default', 0);
            Mage::getConfig()->reinit();
        }
        return $summary;
    }

    /** Recompute pending fee rows from the collected classes. Returns count of rows written. */
    public function refreshFees()
    {
        $write = $this->_write();
        $n = 0;
        foreach ($this->feeConfig() as $cc => $fee) {
            if ($fee['per_learner'] <= 0) continue;
            $rows = $write->fetchAll(
                "SELECT class_code, course_code, course_title, start_date, enrolled, attended
                   FROM mmd_franchise_classes
                  WHERE source_country = ? AND status IN ('confirmed','completed') AND start_date <= CURDATE()",
                array($cc)
            );
            foreach ($rows as $r) {
                $billable = (int) $r['attended'] > 0 ? (int) $r['attended'] : (int) $r['enrolled'];
                if ($billable <= 0) continue;
                $amount = round($billable * $fee['per_learner'], 2);
                $write->query(
                    "INSERT INTO mmd_franchise_class_fee
                        (source_country, class_code, course_code, course_title, start_date,
                         billable_learners, unit_fee, currency, amount, status)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
                     ON DUPLICATE KEY UPDATE
                        course_code = VALUES(course_code), course_title = VALUES(course_title),
                        start_date = VALUES(start_date),
                        billable_learners = IF(status = 'completed', billable_learners, VALUES(billable_learners)),
                        unit_fee = IF(status = 'completed', unit_fee, VALUES(unit_fee)),
                        currency = IF(status = 'completed', currency, VALUES(currency)),
                        amount = IF(status = 'completed', amount, VALUES(amount))",
                    array($cc, $r['class_code'], $r['course_code'], $r['course_title'], $r['start_date'] ?: null,
                          $billable, $fee['per_learner'], $fee['currency'], $amount)
                );
                $n++;
            }
        }
        return $n;
    }

    protected function _upsertClasses($cc, array $rows)
    {
        $write = $this->_write();
        $n = 0;
        foreach ($rows as $c) {
            $code = trim((string) ($c['class_code'] ?? ''));
            if ($code === '') continue;
            $write->query(
                "INSERT INTO mmd_franchise_classes
                    (source_country, class_code, course_code, course_title, start_date, end_date,
                     trainer_name, status, enrolled, attended, certs_issued)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE
                    course_code = VALUES(course_code), course_title = VALUES(course_title),
                    start_date = VALUES(start_date), end_date = VALUES(end_date),
                    trainer_name = VALUES(trainer_name), status = VALUES(status),
                    enrolled = VALUES(enrolled), attended = VALUES(attended), certs_issued = VALUES(certs_issued)",
                array($cc, $code, (string) ($c['course_code'] ?? ''), (string) ($c['course_title'] ?? ''),
                      ($c['start_date'] ?? null) ?: null, ($c['end_date'] ?? null) ?: null,
                      (string) ($c['trainer_name'] ?? ''), (string) ($c['status'] ?? 'upcoming'),
                      (int) ($c['enrolled'] ?? 0), (int) ($c['attended'] ?? 0), (int) ($c['certs_issued'] ?? 0))
            );
            $n++;
        }
        return $n;
    }

    protected function _upsertOrders($cc, array $rows)
    {
        $write = $this->_write();
        $n = 0;
        foreach ($rows as $o) {
            $no = trim((string) ($o['order_no'] ?? ''));
            if ($no === '' || empty($o['ordered_at'])) continue;
            $write->query(
                "INSERT INTO mmd_franchise_orders
                    (source_country, order_no, item_id, ordered_at, status, course_code, course_title,
                     class_date, learners, amount, currency)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE
                    ordered_at = VALUES(ordered_at), status = VALUES(status),
                    course_code = VALUES(course_code), course_title = VALUES(course_title),
                    class_date = VALUES(class_date), learners = VALUES(learners),
                    amount = VALUES(amount), currency = VALUES(currency)",
                array($cc, $no, (int) ($o['item_id'] ?? 0), $o['ordered_at'], (string) ($o['status'] ?? ''),
                      (string) ($o['course_code'] ?? ''), (string) ($o['course_title'] ?? ''),
                      ($o['class_date'] ?? null) ?: null, max(1, (int) ($o['learners'] ?? 1)),
                      round((float) ($o['amount'] ?? 0), 2), strtoupper(substr((string) ($o['currency'] ?? ''), 0, 3)))
            );
            $n++;
        }
        return $n;
    }

    /** Fetch every page of one dataset from a partner. */
    protected function _fetchAll($baseUrl, $apiKey, $dataset, $since)
    {
        $all = array();
        $page = 1;
        do {
            $url = $baseUrl . '/courses/api_franchise_stats?dataset=' . $dataset . '&since=' . $since . '&page=' . $page . '&page_size=500';
            $ch  = curl_init($url);
            curl_setopt_array($ch, array(
                CURLOPT_RETURNTRANSFER => true, CURLOPT_FOLLOWLOCATION => true, CURLOPT_MAXREDIRS => 5,
                CURLOPT_TIMEOUT => 90, CURLOPT_CONNECTTIMEOUT => 15,
                CURLOPT_USERAGENT => 'Mozilla/5.0 (compatible; MMD-FranchiseStats/1.0)',
                CURLOPT_HTTPHEADER => array('X-API-Key: ' . $apiKey, 'Accept: application/json'),
            ));
            $raw  = curl_exec($ch);
            $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $err  = curl_error($ch);
            curl_close($ch);
            if ($raw === false || $raw === '') throw new Exception('Partner unreachable: ' . ($err ?: 'no response'));
            $rsp = json_decode($raw, true);
            if ($code >= 400 || !is_array($rsp) || empty($rsp['success'])) {
                $msg = is_array($rsp) && isset($rsp['error']) ? $rsp['error'] : ('HTTP ' . $code . ' — partner has not deployed /courses/api_franchise_stats yet?');
                throw new Exception('Partner export failed: ' . $msg);
            }
            $all = array_merge($all, isset($rsp['rows']) ? (array) $rsp['rows'] : array());
            $totalPages = isset($rsp['total_pages']) ? (int) $rsp['total_pages'] : 1;
            $page++;
        } while ($page <= $totalPages && $page <= 200);
        return $all;
    }

    protected function _write()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_write');
    }
}
