<?php
/**
 * Thin wrapper over the MailerLite REST API for the Marketing Dashboard
 * KPI tiles. Each method returns scalar / small-array data that the
 * dashboard template renders directly.
 *
 * Bearer key is sourced from MMD_RoleManager_Helper_Data::getMarketingApiConfig()
 * which already resolves the Credentials-page-saved value (config path
 * mmd_marketing/api/mailerlite_key).
 *
 * Responses are cached in Magento's core/cache backend for 300s so the
 * dashboard render doesn't make 4 HTTP round-trips on every page load.
 *
 * If the key is missing or any call fails the helper returns a sentinel
 * (null / 0 / empty array) so the tiles fall back to "—" placeholders —
 * the page must never fatal because of a network blip.
 */
class MMD_Marketing_Helper_Mailerlite extends Mage_Core_Helper_Abstract
{
    const API_BASE        = 'https://connect.mailerlite.com/api';
    const CACHE_TTL       = 300;   // 5 min
    const CACHE_TAG       = 'MMD_MARKETING_MAILERLITE';
    // MailerLite group IDs (one MailerLite account, two country groups).
    // Update here if a group is renamed/recreated; readable via
    // GET /api/groups with the saved key.
    const GROUP_ID_SG     = '97171109342873057';
    const GROUP_ID_MY     = '97171116217337309';

    protected $_keyChecked = false;
    protected $_key        = '';

    public function isConfigured()
    {
        return $this->_getKey() !== '';
    }

    /**
     * Subscriber group id for THIS site's order-email sync.
     *
     * Franchise model = one store per site, same codebase everywhere, so this
     * MUST be configuration rather than a constant: SG points at the Singapore
     * group, MY at Malaysia, GH at its own. Set in Company Setting →
     * Integrations → MailerLite on each partner's own admin.
     *
     * Returns '' when unconfigured — callers MUST treat that as "do not sync".
     * There is deliberately NO fallback to the SG group: defaulting would push
     * a franchisee's learners into Singapore's list, which is both wrong and
     * unrecoverable (you cannot un-send a subscriber import).
     */
    public function getSyncGroupId()
    {
        return trim((string) Mage::getStoreConfig('mmd_company/mailerlite/group_id'));
    }

    /**
     * Store id whose orders feed the sync. One store per site under the
     * franchise model, but the id differs per partner DB (SG=1, MY=2, GH=3),
     * so it is configurable. Defaults to this install's current store.
     */
    public function getSyncStoreId()
    {
        $cfg = trim((string) Mage::getStoreConfig('mmd_company/mailerlite/store_id'));
        if ($cfg !== '' && ctype_digit($cfg)) {
            return (int) $cfg;
        }
        return (int) Mage::app()->getStore()->getId();
    }

    /** Master on/off for the daily order-email sync cron. Default OFF. */
    public function isSyncEnabled()
    {
        return (string) Mage::getStoreConfig('mmd_company/mailerlite/sync_enabled') === '1';
    }

    public function getSubscribersSG()
    {
        return $this->getGroupSubscriberCount(self::GROUP_ID_SG);
    }

    public function getSubscribersMY()
    {
        return $this->getGroupSubscriberCount(self::GROUP_ID_MY);
    }

    /**
     * Active subscriber count for a given group.
     *
     * MailerLite's /groups response includes an active_count integer per row,
     * so one /groups call gives us both countries — cheaper than two
     * /groups/{id} round-trips.
     *
     * @return int|null  null if not configured / API failure
     */
    public function getGroupSubscriberCount($groupId)
    {
        $groups = $this->_getCached('groups_index', function () {
            return $this->_getJson('/groups?limit=100');
        });
        if (!is_array($groups) || empty($groups['data'])) {
            return null;
        }
        foreach ($groups['data'] as $g) {
            if ((string)$g['id'] === (string)$groupId) {
                return isset($g['active_count']) ? (int) $g['active_count'] : 0;
            }
        }
        return 0;
    }

    /**
     * Record today's active subscriber count for SG (and MY) into the snapshot
     * table so the dashboard can chart GROWTH — the MailerLite API only ever
     * returns the CURRENT count, never history. Idempotent per day (UNIQUE key on
     * snap_date+group_id), so it is safe to call on every dashboard load.
     */
    public function snapshotSubscribers()
    {
        if (!$this->isConfigured()) { return; }
        try {
            $res  = Mage::getSingleton('core/resource');
            $conn = $res->getConnection('core_write');
            $tbl  = $res->getTableName('mmd_marketing_subscriber_snapshot');
            $today = date('Y-m-d');
            foreach (array(self::GROUP_ID_SG, self::GROUP_ID_MY) as $gid) {
                $count = $this->getGroupSubscriberCount($gid);
                if ($count === null) { continue; }
                $conn->query(
                    'INSERT INTO ' . $tbl . ' (snap_date, group_id, active_count) VALUES (?,?,?)'
                  . ' ON DUPLICATE KEY UPDATE active_count = VALUES(active_count)',
                    array($today, (string) $gid, (int) $count)
                );
            }
        } catch (Exception $e) { /* snapshot is best-effort */ }
    }

    /**
     * Daily active-subscriber series for a group over the last $days days,
     * oldest→newest: [['date'=>'Y-m-d','count'=>int], ...]. Drives the growth chart.
     */
    public function getSubscriberSnapshots($groupId = null, $days = 30)
    {
        $groupId = $groupId ?: self::GROUP_ID_SG;
        try {
            $res  = Mage::getSingleton('core/resource');
            $conn = $res->getConnection('core_read');
            $tbl  = $res->getTableName('mmd_marketing_subscriber_snapshot');
            $rows = $conn->fetchAll(
                'SELECT snap_date, active_count FROM ' . $tbl
              . ' WHERE group_id = ? AND snap_date >= ? ORDER BY snap_date ASC',
                array((string) $groupId, date('Y-m-d', strtotime('-' . (int) $days . ' days')))
            );
        } catch (Exception $e) { return array(); }
        $out = array();
        foreach ($rows as $r) { $out[] = array('date' => $r['snap_date'], 'count' => (int) $r['active_count']); }
        return $out;
    }

    /**
     * True when a campaign payload row targets the SG audience — sent to the
     * Singapore group, or to all active subscribers (no group targeting, e.g.
     * the API-created flyer blasts). The MailerLite account is shared with
     * other countries, so campaigns aimed exclusively at another group
     * (Malaysia) are excluded from every dashboard campaign panel.
     */
    protected function _isSgCampaign(array $c)
    {
        $groups = isset($c['basic_filter_for_humans']['included_groups'])
            && is_array($c['basic_filter_for_humans']['included_groups'])
            ? $c['basic_filter_for_humans']['included_groups'] : array();
        if (!$groups) { return true; }
        foreach ($groups as $g) {
            if (isset($g['id']) && (string) $g['id'] === self::GROUP_ID_SG) { return true; }
        }
        return false;
    }

    /**
     * Number of SG campaigns with status "sent" delivered in the last 30 days.
     *
     * @return int|null
     */
    public function getCampaignsSentLast30Days()
    {
        $data = $this->_getCached('campaigns_sent', function () {
            return $this->_getJson('/campaigns?filter[status]=sent&limit=100');
        });
        if (!is_array($data) || empty($data['data'])) {
            return ($data === null) ? null : 0;
        }
        $since = strtotime('-30 days');
        $count = 0;
        foreach ($data['data'] as $c) {
            if (!$this->_isSgCampaign($c)) continue;
            $ts = isset($c['finished_at']) ? strtotime((string)$c['finished_at']) : null;
            if (!$ts && isset($c['created_at'])) $ts = strtotime((string)$c['created_at']);
            if ($ts && $ts >= $since) $count++;
        }
        return $count;
    }

    /**
     * Next scheduled / ready campaign — earliest scheduled_for in the future.
     * Returns ['name'=>..., 'scheduled_for'=>'YYYY-MM-DD HH:MM:SS UTC'] or null.
     *
     * MailerLite uses "ready" for campaigns that have a scheduled send time
     * and "draft" for unscheduled drafts. We surface "ready" only.
     *
     * @return array|null
     */
    public function getNextCampaign()
    {
        // limit must be one of MailerLite's allowed values; 20 (and 15)
        // are rejected with HTTP 422 "The selected limit is invalid."
        // Allowed: 10, 25, 50, 100. We use 25 here — enough headroom
        // to find the soonest upcoming campaign without paging.
        $data = $this->_getCached('campaigns_ready', function () {
            return $this->_getJson('/campaigns?filter[status]=ready&limit=25');
        });
        if (!is_array($data) || empty($data['data'])) {
            return null;
        }
        // MailerLite returns scheduled_for as a naive UTC timestamp.
        // PHP's strtotime() interprets naive strings in the runtime's
        // default TZ — Asia/Singapore here — which would shift a UTC
        // timestamp 8 hours into the past, causing the "in the future?"
        // check to drop legitimately-upcoming campaigns. Parse with an
        // explicit UTC zone so the comparison is honest.
        $best = null;
        $bestTs = PHP_INT_MAX;
        $utc = new DateTimeZone('UTC');
        foreach ($data['data'] as $c) {
            if (!$this->_isSgCampaign($c)) continue;
            $when = isset($c['scheduled_for']) ? (string)$c['scheduled_for'] : '';
            if ($when === '') continue;
            try {
                $ts = (new DateTime($when, $utc))->getTimestamp();
            } catch (Exception $e) {
                continue;
            }
            if (!$ts || $ts < time()) continue;
            if ($ts < $bestTs) {
                $bestTs = $ts;
                $best = array(
                    'name'          => (string) ($c['name'] ?? 'Unnamed'),
                    'scheduled_for' => $when,
                    'subject'       => (string) ($c['emails'][0]['subject'] ?? ''),
                );
            }
        }
        return $best;
    }

    /** Recent SG sent campaigns with performance stats (opens, clicks, rates). */
    public function getSentCampaigns($limit = 6)
    {
        $data = $this->_getCached('camp_sent_stats', function () {
            return $this->_getJson('/campaigns?filter[status]=sent&limit=25');
        });
        if (!is_array($data) || empty($data['data'])) { return array(); }
        $out = array();
        foreach ($data['data'] as $c) {
            if (!$this->_isSgCampaign($c)) { continue; }
            $s = isset($c['stats']) && is_array($c['stats']) ? $c['stats'] : array();
            $sent   = isset($s['sent']) ? (int) $s['sent'] : 0;
            $opens  = isset($s['opens_count'])  ? (int) $s['opens_count']  : (isset($s['unique_opens_count'])  ? (int) $s['unique_opens_count']  : 0);
            $clicks = isset($s['clicks_count']) ? (int) $s['clicks_count'] : (isset($s['unique_clicks_count']) ? (int) $s['unique_clicks_count'] : 0);
            // MailerLite returns *_rate.float as a fraction (0..1); show as %.
            $openR  = isset($s['open_rate']['float'])  ? (float) $s['open_rate']['float']  * 100 : ($sent ? $opens  / $sent * 100 : 0);
            $clickR = isset($s['click_rate']['float']) ? (float) $s['click_rate']['float'] * 100 : ($sent ? $clicks / $sent * 100 : 0);
            $out[] = array(
                'name'       => (string) (isset($c['name']) ? $c['name'] : ''),
                'sent_at'    => (string) (isset($c['finished_at']) ? $c['finished_at'] : (isset($c['created_at']) ? $c['created_at'] : '')),
                'recipients' => $sent,
                'opens'      => $opens,
                'clicks'     => $clicks,
                'open_rate'  => round($openR, 1),
                'click_rate' => round($clickR, 1),
            );
            if (count($out) >= $limit) { break; }
        }
        return $out;
    }

    /** Upcoming scheduled ("ready") campaigns. */
    public function getScheduledCampaigns()
    {
        $data = $this->_getCached('camp_scheduled', function () {
            return $this->_getJson('/campaigns?filter[status]=ready&limit=25');
        });
        if (!is_array($data) || empty($data['data'])) { return array(); }
        $out = array();
        foreach ($data['data'] as $c) {
            if (!$this->_isSgCampaign($c)) { continue; }
            $out[] = array(
                'name'          => (string) (isset($c['name']) ? $c['name'] : ''),
                'scheduled_for' => (string) (isset($c['scheduled_for']) ? $c['scheduled_for'] : ''),
                'subject'       => (string) (isset($c['emails'][0]['subject']) ? $c['emails'][0]['subject'] : ''),
            );
        }
        return $out;
    }

    /** Top-line marketing performance for the dashboard header tiles. */
    public function getPerformanceSummary()
    {
        $camps = $this->getSentCampaigns(50);
        $n = count($camps); $orSum = 0; $crSum = 0; $reached = 0;
        foreach ($camps as $c) { $orSum += $c['open_rate']; $crSum += $c['click_rate']; $reached += $c['recipients']; }
        return array(
            'subscribers_sg' => $this->getSubscribersSG(),
            'subscribers_my' => $this->getSubscribersMY(),
            'campaigns_30d'  => $this->getCampaignsSentLast30Days(),
            'scheduled'      => count($this->getScheduledCampaigns()),
            'avg_open_rate'  => $n ? round($orSum / $n, 1) : 0,
            'avg_click_rate' => $n ? round($crSum / $n, 1) : 0,
            'total_reached'  => $reached,
        );
    }

    // ---------- subscriber sync (order emails → SG group) ----------

    /**
     * Every email in the account that has opted out (status unsubscribed), plus
     * those MailerLite bounced/marked as spam — lowercased for set comparison.
     *
     * Why this exists: POST /subscribers is an UPSERT. Posting an address that
     * previously unsubscribed re-adds it to the group, which resurrects people
     * who explicitly opted out — a spam-compliance breach, not just noise.
     * MailerLite does preserve the unsubscribed status on its side, but we
     * refuse to send them at all so the opt-out is never even attempted.
     *
     * Paged via cursor; capped so a runaway account can't spin forever.
     */
    public function getSuppressedEmails()
    {
        $out = array();
        foreach (array('unsubscribed', 'bounced', 'junk') as $status) {
            $cursor = null;
            for ($page = 0; $page < 120; $page++) {
                $path = '/subscribers?filter[status]=' . $status . '&limit=100'
                      . ($cursor ? '&cursor=' . rawurlencode($cursor) : '');
                $data = $this->_getJson($path);
                if (!is_array($data) || empty($data['data'])) { break; }
                foreach ($data['data'] as $s) {
                    if (!empty($s['email'])) { $out[strtolower(trim($s['email']))] = true; }
                }
                $cursor = isset($data['meta']['next_cursor']) ? $data['meta']['next_cursor'] : null;
                if (!$cursor) { break; }
            }
        }
        return $out;
    }

    /**
     * Look one subscriber up by email. Returns the subscriber array (with its
     * status + group memberships) or null when MailerLite has never seen it.
     *
     * This is the independent "did the email REALLY land?" check — the sync's
     * own success counter proves only that a POST returned 2xx.
     */
    public function findSubscriber($email)
    {
        $data = $this->_getJson('/subscribers/' . rawurlencode(strtolower(trim($email))));
        return (is_array($data) && !empty($data['data'])) ? $data['data'] : null;
    }

    /**
     * Subscribe a form lead (any model exposing getEmail/getName and a
     * mailerlite_status column) to this site's configured group. Never
     * throws — the outcome is recorded on the lead as mailerlite_status
     * ('sent' / 'skipped' / 'failed') and the lead is saved.
     *
     * Franchise-safe: when no group is configured on this install the
     * lead is marked 'skipped' (no fallback to the SG group). Opt-out
     * guard: POST /subscribers is an upsert that would resurrect an
     * unsubscribed address, so unsubscribed / bounced / junk subscribers
     * are skipped, never re-added.
     */
    public function subscribeLead(Mage_Core_Model_Abstract $lead)
    {
        $label = get_class($lead) . ' #' . $lead->getId();
        try {
            $email   = strtolower(trim((string) $lead->getEmail()));
            $groupId = $this->getSyncGroupId();
            if (!$this->isConfigured() || $groupId === '' || $email === '') {
                $this->_saveLeadStatus($lead, 'skipped');
                return;
            }

            $existing = $this->findSubscriber($email);
            $status   = is_array($existing) && isset($existing['status']) ? $existing['status'] : '';
            if ($status === 'unsubscribed') {
                Mage::log($label . ': ' . $email . ' is unsubscribed — not re-adding', null, 'mailerlite.log');
                $this->_saveLeadStatus($lead, 'unsubscribed');
                return;
            }
            if (in_array($status, array('bounced', 'junk'), true)) {
                Mage::log($label . ': ' . $email . ' is ' . $status . ' — blocked, not re-adding', null, 'mailerlite.log');
                $this->_saveLeadStatus($lead, 'blocked');
                return;
            }

            $this->addSubscriber($email, $groupId, array('name' => (string) $lead->getName()));
            Mage::log($label . ': subscribed ' . $email . ' to group ' . $groupId, null, 'mailerlite.log');
            $this->_saveLeadStatus($lead, 'sent');
        } catch (Exception $e) {
            Mage::logException($e);
            Mage::log($label . ': subscribe failed — ' . $e->getMessage(), null, 'mailerlite.log');
            $this->_saveLeadStatus($lead, 'failed');
        }
    }

    /** Persist mailerlite_status without letting a save error bubble up. */
    protected function _saveLeadStatus(Mage_Core_Model_Abstract $lead, $status)
    {
        try {
            $lead->setMailerliteStatus($status)->save();
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /**
     * Add one subscriber to a group. Returns true on success.
     * MailerLite treats POST /subscribers as an upsert keyed on email.
     */
    public function addSubscriber($email, $groupId, array $fields = array())
    {
        $body = array(
            'email'  => $email,
            'groups' => array((string) $groupId),
        );
        if ($fields) { $body['fields'] = $fields; }
        $this->_send('POST', '/subscribers', $body);
        return true;
    }

    /**
     * Push this site's order emails into its configured subscriber group.
     *
     * @param string|null $since   'Y-m-d H:i:s' lower bound on sales_flat_order.created_at
     * @param bool        $dryRun  when true, resolve + filter but send nothing
     * @param string|null $groupId override the configured group
     * @param int|null    $storeId override the configured store
     * @return array stats
     */
    public function syncOrderEmails($since = null, $dryRun = false, $groupId = null, $storeId = null)
    {
        $stats = array(
            'candidates' => 0, 'skipped_suppressed' => 0,
            'added' => 0, 'failed' => 0, 'errors' => array(),
            'group_id' => '', 'store_id' => 0,
        );
        if (!$this->isConfigured()) {
            $stats['errors'][] = 'MailerLite API key not configured';
            return $stats;
        }
        $groupId = $groupId ?: $this->getSyncGroupId();
        if ($groupId === '') {
            // No silent default — see getSyncGroupId().
            $stats['errors'][] = 'No MailerLite subscriber group configured'
                . ' (Company Setting → Integrations → MailerLite → Subscriber Group ID)';
            return $stats;
        }
        $storeId = $storeId === null ? $this->getSyncStoreId() : (int) $storeId;
        $stats['group_id'] = (string) $groupId;
        $stats['store_id'] = $storeId;

        // Scope to this site's single live store. Any other store_id in the DB
        // is orphaned data from the retired multi-store setup and must not leak
        // into a partner's subscriber group.
        $conn = Mage::getSingleton('core/resource')->getConnection('core_read');
        $sql  = "SELECT LOWER(TRIM(customer_email)) AS email,"
              . " MAX(customer_firstname) AS fname, MAX(customer_lastname) AS lname"
              . " FROM " . Mage::getSingleton('core/resource')->getTableName('sales/order')
              . " WHERE store_id = ? AND customer_email IS NOT NULL AND customer_email <> ''";
        $bind = array($storeId);
        if ($since) { $sql .= " AND created_at >= ?"; $bind[] = $since; }
        $sql .= " GROUP BY LOWER(TRIM(customer_email))";
        $rows = $conn->fetchAll($sql, $bind);

        $suppressed = $this->getSuppressedEmails();
        foreach ($rows as $r) {
            $email = (string) $r['email'];
            if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) { continue; }
            $stats['candidates']++;
            if (isset($suppressed[$email])) { $stats['skipped_suppressed']++; continue; }
            if ($dryRun) { $stats['added']++; continue; }
            try {
                $fields = array();
                if (!empty($r['fname'])) { $fields['name']      = (string) $r['fname']; }
                if (!empty($r['lname'])) { $fields['last_name'] = (string) $r['lname']; }
                $this->addSubscriber($email, $groupId, $fields);
                $stats['added']++;
            } catch (Exception $e) {
                $stats['failed']++;
                if (count($stats['errors']) < 20) {
                    $stats['errors'][] = $email . ': ' . $e->getMessage();
                }
            }
            usleep(120000); // ~8 req/s — MailerLite allows 120/min
        }
        return $stats;
    }

    // ---------- internal ----------

    protected function _getKey()
    {
        if (!$this->_keyChecked) {
            $this->_keyChecked = true;
            // Company Setting (Integrations → MailerLite) WINS. It is the
            // operator-facing field, so a key pasted there must take effect —
            // if the legacy Credentials-page path won instead, rotating the key
            // in the admin would silently keep using the old one.
            $this->_key = trim((string) Mage::getStoreConfig('mmd_company/mailerlite/api_key'));
            if ($this->_key === '') {
                try {
                    $cfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
                    $this->_key = isset($cfg['mailerlite_key']) ? trim((string)$cfg['mailerlite_key']) : '';
                } catch (Exception $e) {
                    // Fallback: read the legacy config path directly.
                    $this->_key = trim((string) Mage::getStoreConfig('mmd_marketing/api/mailerlite_key'));
                }
            }
        }
        return $this->_key;
    }

    protected function _getJson($path)
    {
        $key = $this->_getKey();
        if ($key === '') {
            return null;
        }
        $ch = curl_init(self::API_BASE . $path);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 12,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_HTTPHEADER     => array(
                'Authorization: Bearer ' . $key,
                'Accept: application/json',
            ),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '' || $code < 200 || $code >= 300) {
            // Mage::log silently drops writes to non-default log files
            // when dev/log/allowedFileExtensions is empty (OpenMage default
            // on this install). Write directly so a future bug like "the
            // limit param was wrong" is visible immediately, not a silent
            // null return.
            @file_put_contents(
                Mage::getBaseDir('var') . '/log/mailerlite.log',
                '[' . date('Y-m-d H:i:s') . '] '
              . 'MailerLite GET ' . $path . ' http=' . $code
              . ' err=' . $err . ' body=' . substr((string) $raw, 0, 600) . "\n",
                FILE_APPEND
            );
            return null;
        }
        $data = json_decode($raw, true);
        return is_array($data) ? $data : null;
    }

    protected function _getCached($cacheKey, $cb)
    {
        $fullKey = self::CACHE_TAG . '_' . $cacheKey;
        $cache   = Mage::app()->getCache();
        $cached  = $cache ? $cache->load($fullKey) : false;
        if ($cached !== false && $cached !== '') {
            $decoded = @unserialize($cached);
            if ($decoded !== false || $cached === serialize(false)) {
                return $decoded;
            }
        }
        $val = $cb();
        if ($val !== null && $cache) {
            $cache->save(serialize($val), $fullKey, array(self::CACHE_TAG), self::CACHE_TTL);
        }
        return $val;
    }

    /** POST/PUT JSON to the MailerLite API. Returns decoded array or throws. */
    protected function _send($method, $path, array $body)
    {
        $key = $this->_getKey();
        if ($key === '') { throw new Exception('MailerLite key not configured'); }
        $ch = curl_init(self::API_BASE . $path);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CUSTOMREQUEST  => $method,
            CURLOPT_POSTFIELDS     => json_encode($body),
            CURLOPT_TIMEOUT        => 20,
            CURLOPT_HTTPHEADER     => array(
                'Authorization: Bearer ' . $key,
                'Content-Type: application/json',
                'Accept: application/json',
            ),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        @file_put_contents(Mage::getBaseDir('var') . '/log/mailerlite.log',
            '[' . date('Y-m-d H:i:s') . "] {$method} {$path} http={$code} body=" . substr((string) $raw, 0, 500) . "\n", FILE_APPEND);
        $data = json_decode((string) $raw, true);
        if ($code < 200 || $code >= 300) {
            throw new Exception('MailerLite ' . $method . ' ' . $path . ' HTTP ' . $code
                . ': ' . (isset($data['message']) ? $data['message'] : substr((string) $raw, 0, 200)));
        }
        return is_array($data) ? $data : array();
    }

    /**
     * Wrap a flyer HTML fragment into a complete, MailerLite-valid email document.
     * MailerLite silently blanks campaign content that is not a full <html> document
     * OR that lacks an unsubscribe link — so both are mandatory here. The {$unsubscribe}
     * placeholder + business identity are what stop MailerLite from rejecting the body.
     */
    protected function _wrapEmailHtml($subject, $fragment)
    {
        $unsub = '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#eef2f7;">'
            . '<tr><td align="center" style="padding:18px 14px;font:400 11px -apple-system,Segoe UI,Arial,sans-serif;color:#8593ad;line-height:1.6;">'
            . 'Tertiary Infotech Academy Pte Ltd · 1 Commonwealth Lane #08-22, Singapore 149544<br>'
            . 'You are receiving this because you subscribed to Tertiary Courses updates.<br>'
            . '<a href="{$unsubscribe}" style="color:#2563eb;">Unsubscribe</a>'
            . '</td></tr></table>';
        // HARD RULE (admin, 2026-07-04): every flyer design carries its own
        // {$unsubscribe} footer (Helper_Flyer::render()); append the fallback only
        // when it's missing so the sent email never shows two footers — and never
        // zero. Refuse outright if the final document still lacks the tag.
        $hasUnsub = strpos((string) $fragment, '{$unsubscribe}') !== false;
        $doc = '<!doctype html><html><head><meta charset="utf-8">'
            . '<meta name="viewport" content="width=device-width,initial-scale=1">'
            . '<title>' . htmlspecialchars((string) $subject, ENT_QUOTES, 'UTF-8') . '</title></head>'
            . '<body style="margin:0;padding:0;background:#eef2f7;">' . $fragment . ($hasUnsub ? '' : $unsub) . '</body></html>';
        if (strpos($doc, '{$unsubscribe}') === false) {
            throw new Exception('HARD RULE violated: flyer email has no MailerLite {$unsubscribe} link - refusing to create the campaign.');
        }
        return $doc;
    }

    /**
     * Create a MailerLite DRAFT campaign for $groupId with the flyer HTML, and return
     * its id. Does NOT schedule or send — safe to call for verification. The HTML is
     * set in TWO steps because the Connect API ignores emails[].content on create for
     * HTML campaigns: create the shell, then PUT the content explicitly.
     * NOTE: setting HTML content via API requires the MailerLite account to be on the
     * Advanced plan; on lower plans the body stays empty. verifyContent() detects this.
     */
    public function createDraft($subject, $html, $groupId = null)
    {
        $groupId  = $groupId ?: self::GROUP_ID_SG;
        $cfg      = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $fromName = $cfg['from_name']  ?: 'Tertiary Courses';
        $fromMail = $cfg['from_email'] ?: 'noreply@tertiaryinfotech.com';
        $doc      = $this->_wrapEmailHtml($subject, $html);
        $email    = array('subject' => $subject, 'from_name' => $fromName, 'from' => $fromMail, 'content' => $doc);

        $create = $this->_send('POST', '/campaigns', array(
            'name'   => $subject,
            'type'   => 'regular',
            'groups' => array((string) $groupId),
            'emails' => array($email),
        ));
        $id = isset($create['data']['id']) ? (string) $create['data']['id'] : '';
        if ($id === '') { throw new Exception('MailerLite create returned no campaign id'); }

        // Explicit content set — the step the create silently drops for HTML bodies.
        $this->_send('PUT', '/campaigns/' . rawurlencode($id), array(
            'name'   => $subject,
            'emails' => array($email),
        ));
        return $id;
    }

    /** Fetch a campaign back (used to verify content actually stored). */
    public function getCampaign($id)
    {
        return $this->_getJson('/campaigns/' . rawurlencode($id));
    }

    /** Delete a campaign (cleanup after a verification draft). */
    public function deleteCampaign($id)
    {
        return $this->_send('DELETE', '/campaigns/' . rawurlencode($id), array());
    }

    /**
     * Create a throwaway draft, read it back, confirm the HTML body actually stored,
     * then delete it. Returns [ok, message] — the safe pre-flight before a real blast.
     * Never schedules or sends.
     */
    public function verifyContent($subject, $html, $groupId = null)
    {
        $id = $this->createDraft($subject, $html, $groupId);
        $back = $this->getCampaign($id);
        $stored = isset($back['data']['emails'][0]['content']) ? (string) $back['data']['emails'][0]['content'] : '';
        $screenshot = isset($back['data']['emails'][0]['screenshot_url']) ? (string) $back['data']['emails'][0]['screenshot_url'] : '';
        $ok = (strlen($stored) > 500) || ($screenshot !== '');
        try { $this->deleteCampaign($id); } catch (Exception $e) { /* leave the draft if delete fails */ }
        return array($ok, $ok
            ? 'Content stored OK (' . strlen($stored) . ' bytes).'
            : 'Body did NOT store — the MailerLite account likely is not on the Advanced plan (HTML-via-API needs it).');
    }

    /**
     * Create a campaign for the SG group and schedule it for $sendAt (a local
     * Asia/Singapore DateTime). Returns the MailerLite campaign id.
     */
    public function createAndSchedule($subject, $html, DateTime $sendAt, $groupId = null)
    {
        $id = $this->createDraft($subject, $html, $groupId);
        // Schedule: MailerLite takes date/hours/minutes in the account timezone.
        $this->_send('POST', '/campaigns/' . rawurlencode($id) . '/schedule', array(
            'delivery' => 'scheduled',
            'schedule' => array(
                'date'    => $sendAt->format('Y-m-d'),
                'hours'   => $sendAt->format('H'),
                'minutes' => $sendAt->format('i'),
            ),
        ));
        return $id;
    }
}
