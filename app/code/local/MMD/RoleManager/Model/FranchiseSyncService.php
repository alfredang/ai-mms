<?php
/**
 * SG-side franchise sync: triggers a sync ON a franchisee (MY/GH) instance
 * from the Franchise Management page. The partner's
 * /courses/api_sync_trigger endpoint then runs the partner's own
 * pull-from-SG service — so the DATA still flows strictly SG -> partner
 * (the partner reads SG's export endpoints and writes its own DB); SG only
 * sends the "go" signal. Nothing in this class, or in the endpoints it
 * calls, can write to the SG database.
 *
 * Partner endpoints + keys are the same ones the Franchise Report uses:
 *   mmd/franchise_report/my_url, mmd/franchise_report/my_key
 *   mmd/franchise_report/gh_url, mmd/franchise_report/gh_key
 * Last successful sync per op/partner:
 *   mmd/franchise_sync/last_<op>_<cc>
 */
class MMD_RoleManager_Model_FranchiseSyncService
{
    const LOG_FILE = 'franchise-sync.log';

    /** @var string[] ops accepted by the partner trigger endpoint */
    public static $ops = array('courses', 'categories', 'schedules');

    /**
     * Trigger one sync op on one partner. Returns the partner's summary
     * array (fetched/created/updated/... from its sync service).
     */
    public function trigger($country, $op, $triggeredBy = 'admin')
    {
        $op = strtolower(trim((string) $op));
        if (!in_array($op, self::$ops, true)) {
            throw new Exception('Unknown sync op: ' . $op);
        }

        $partner = null;
        foreach (Mage::getModel('mmd_rolemanager/franchiseReportService')->getPartners() as $p) {
            if (strcasecmp($p['country'], $country) === 0) { $partner = $p; break; }
        }
        if ($partner === null) {
            throw new Exception(strtoupper($country) . ' is not connected — add its URL and API key in Partner Connection Settings first.');
        }

        $ch = curl_init($partner['url'] . '/courses/api_sync_trigger');
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS      => 5,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query(array('op' => $op)),
            // A full course sync on the partner runs synchronously and can
            // take several minutes — wait generously.
            CURLOPT_TIMEOUT        => 900,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; MMD-FranchiseSync/1.0)',
            CURLOPT_HTTPHEADER     => array(
                'X-API-Key: ' . $partner['key'],
                'Accept: application/json',
            ),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            throw new Exception('Partner unreachable: ' . ($err ?: 'no response') . ' — the sync may still be running on ' . $partner['country'] . '; check its sync log.');
        }
        $rsp = json_decode($raw, true);
        if ($code >= 400 || !is_array($rsp) || empty($rsp['success'])) {
            $msg = is_array($rsp) && isset($rsp['error']) ? $rsp['error']
                 : (is_array($rsp) && !empty($rsp['error_msgs']) ? implode('; ', (array) $rsp['error_msgs']) : ('HTTP ' . $code));
            throw new Exception('Partner sync failed: ' . $msg);
        }

        Mage::getConfig()->saveConfig(
            'mmd/franchise_sync/last_' . $op . '_' . strtolower($partner['country']),
            Mage::getModel('core/date')->gmtDate(), 'default', 0
        );
        Mage::getConfig()->reinit();

        Mage::log('FranchiseSync: ' . $op . ' on ' . $partner['country'] . ' by ' . $triggeredBy
            . ' — ' . json_encode(array_intersect_key($rsp, array_flip(array('fetched', 'created', 'updated', 'skipped', 'errors')))),
            Zend_Log::INFO, self::LOG_FILE, true);

        return $rsp;
    }
}
