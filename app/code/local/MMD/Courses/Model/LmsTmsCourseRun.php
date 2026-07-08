<?php
/**
 * LMS-TMS course-runs fetcher (read-only fallback source for trainer reminders).
 *
 * The WhatsApp trainer-reminders bot hits /courses/api_reminders?target_date=X
 * to pull "which trainer is teaching which class on date X". The primary
 * source is MMS course_runs (Phase 2 admin_user-account trainers + legacy
 * EAV-option trainers). LMS-TMS is the secondary source — used when:
 *
 *  (a) MMS knows about the class but has no trainer assigned, OR
 *  (b) LMS knows about a class on that date that MMS doesn't track at all.
 *
 * In both cases we use the LMS-assigned trainer name + email so the bot can
 * still send a reminder. Reuses the same LMS-TMS API credentials already
 * configured for the roster import (mmd/trainer_import/lms_url + api_key).
 *
 * Read-only. No writes. Failure is non-fatal — if LMS is unreachable the
 * caller gets an empty result and continues with MMS-only data.
 *
 * == LMS-TMS API quirks (discovered 2026-06-08) ==
 *
 * 1. The endpoint's `?date=YYYY-MM-DD` query param is IGNORED — it returns
 *    every record regardless. We paginate through the full dataset and
 *    filter client-side.
 *
 * 2. Dates are stored as ISO 8601 UTC strings, e.g. "2026-06-11T16:00:00.000Z".
 *    The "T16:00:00.000Z" suffix is midnight Singapore time the NEXT day.
 *    So a class on 12 June 2026 (SGT) appears as "2026-06-11T16:00:00.000Z".
 *    We MUST convert to Asia/Singapore before comparing dates, otherwise
 *    every reminder lands a day early.
 *
 * 3. Many rows have assigned_trainer_email = null even when the LMS admin
 *    UI shows an assigned trainer. The external endpoint only surfaces
 *    "published" assignments. We drop nulls — there's no one to remind.
 */
class MMD_Courses_Model_LmsTmsCourseRun
{
    const URL_CONFIG_PATH  = 'mmd/trainer_import/lms_url';
    const KEY_CONFIG_PATH  = 'mmd/trainer_import/api_key';
    const CACHE_TAG        = 'MMD_LMS_TMS_COURSE_RUNS';
    const CACHE_TTL_SECS   = 3600;        // 1 hour — full dataset is ~5775 rows
    const PAGE_LIMIT       = 200;         // ask for 200 per page
    const MAX_PAGES        = 50;          // safety cap → 10000 rows max
    const SGT_TZ           = 'Asia/Singapore';
    const LOG_FILE         = 'lms-tms-fallback.log';

    /** Last-call diagnostic state, surfaced into the API's fallback_check block. */
    protected $_lastAttempted    = false;
    protected $_lastSuccess      = false;
    protected $_lastErrorMessage = '';
    protected $_lastTotalRows    = 0;

    public function isConfigured()
    {
        return $this->_url() !== '' && $this->_key() !== '';
    }

    public function getLastCallStats()
    {
        return array(
            'attempted'    => $this->_lastAttempted,
            'success'      => $this->_lastSuccess,
            'rows_returned'=> (int) $this->_lastTotalRows,
            'error'        => $this->_lastErrorMessage,
            'configured'   => $this->isConfigured(),
        );
    }

    /**
     * Return all LMS course-runs whose Singapore-time start date matches
     * the given YYYY-MM-DD. Filters server-trip via cache so the bot's
     * daily poll only hits LMS once per hour.
     *
     * Result is keyed by course_code (SKU), normalised:
     *   [
     *     'name'                 => 'Iris Wang Yan Hong',
     *     'email'                => 'angss@tertiaryinfotech.com',
     *     'course_title'         => 'WSQ - Tax Computations ...',
     *     'mode'                 => 'Physical' | 'Online' | 'Hybrid' | '',
     *     'lms_course_run_id'    => '1131882',
     *     'lms_course_run_uuid'  => '93562a7b-…',
     *     'enrolled_count'       => 7,
     *     'class_status'         => 'Confirmed',
     *     'start_date_sgt'       => '2026-06-12',
     *   ]
     *
     * Returns [] on any error (network, auth, JSON), and stashes the error
     * for the caller to surface in the diagnostic.
     *
     * @param string $date YYYY-MM-DD (Singapore-time calendar date)
     * @return array<string, array>
     */
    public function getRunsByDate($date)
    {
        $this->_lastAttempted    = true;
        $this->_lastSuccess      = false;
        $this->_lastErrorMessage = '';
        $this->_lastTotalRows    = 0;

        $date = trim((string) $date);
        if ($date === '' || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            $this->_lastErrorMessage = 'invalid_date_param';
            return array();
        }

        if (!$this->isConfigured()) {
            $this->_lastAttempted    = false;
            $this->_lastErrorMessage = 'not_configured';
            return array();
        }

        try {
            $allRuns = $this->_loadAllRunsFromCacheOrFetch();
        } catch (Exception $e) {
            $this->_lastErrorMessage = $e->getMessage();
            $this->_log('getRunsByDate(' . $date . ') failed: ' . $e->getMessage());
            return array();
        }

        // Filter the cached/fetched list to rows starting on the SGT calendar date.
        // Drops Cancelled/Postponed/Pending, drops rows without a trainer email,
        // and keeps first-write-wins by course_code (multiple runs on same date
        // for the same SKU are extremely rare in practice).
        $byCode = array();
        foreach ($allRuns as $r) {
            if ($r['start_date_sgt'] !== $date) continue;
            if ($r['email'] === '')             continue;
            if (strcasecmp($r['class_status'], 'Confirmed') !== 0) continue;
            $code = $r['course_code'];
            if ($code === '' || isset($byCode[$code])) continue;
            $byCode[$code] = $r;
        }

        $this->_lastSuccess   = true;
        $this->_lastTotalRows = count($byCode);
        return $byCode;
    }

    /**
     * Pull every page of LMS course-runs and cache the normalised dataset.
     * Cached for CACHE_TTL_SECS so the once-daily bot poll doesn't trigger
     * 30 cURL calls every time.
     */
    protected function _loadAllRunsFromCacheOrFetch()
    {
        $cacheKey = 'mmd_lms_tms_runs_all_v2';
        $cache    = Mage::app()->getCache();
        $cached   = $cache->load($cacheKey);
        if ($cached !== false) {
            $decoded = @unserialize($cached);
            if (is_array($decoded)) {
                return $decoded;
            }
        }

        $all = array();
        $offset = 0;
        for ($page = 0; $page < self::MAX_PAGES; $page++) {
            $rows = $this->_fetchPage($offset, self::PAGE_LIMIT);
            if (empty($rows)) break;

            foreach ($rows as $r) {
                $normalised = $this->_normaliseRow($r);
                if ($normalised !== null) {
                    $all[] = $normalised;
                }
            }
            if (count($rows) < self::PAGE_LIMIT) break;
            $offset += self::PAGE_LIMIT;
        }

        $cache->save(serialize($all), $cacheKey, array(self::CACHE_TAG), self::CACHE_TTL_SECS);
        return $all;
    }

    /**
     * Normalise one raw API row → our internal shape. Returns null if the
     * row is missing critical fields. Converts the UTC start_date to a
     * Singapore-time calendar date.
     */
    protected function _normaliseRow(array $r)
    {
        $code  = trim((string) ($r['course_code'] ?? ''));
        if ($code === '') return null;

        $email    = trim((string) ($r['assigned_trainer_email'] ?? ''));
        $name     = trim((string) ($r['assigned_trainer_name']  ?? ''));
        $startSgt = $this->_utcStringToSgtDate((string) ($r['start_date'] ?? ''));
        $endSgt   = $this->_utcStringToSgtDate((string) ($r['end_date']   ?? ''));

        return array(
            'course_code'         => $code,
            'name'                => $name,
            'email'               => $email,
            'course_title'        => (string) ($r['course_title'] ?? ''),
            'mode'                => (string) ($r['mode_of_learning'] ?? ''),
            'lms_course_run_id'   => (string) ($r['course_run_id']   ?? ''),
            'lms_course_run_uuid' => (string) ($r['course_run_uuid'] ?? ''),
            'enrolled_count'      => (int)    ($r['enrolled_count']  ?? 0),
            'class_status'        => (string) ($r['class_status']    ?? ''),
            'start_date_sgt'      => $startSgt,
            'end_date_sgt'        => $endSgt,
        );
    }

    /**
     * "2026-06-11T16:00:00.000Z" (UTC) → "2026-06-12" (SGT calendar date).
     * Empty or unparseable input → ''.
     */
    protected function _utcStringToSgtDate($utcString)
    {
        $utcString = trim((string) $utcString);
        if ($utcString === '') return '';
        try {
            $dt = new DateTime($utcString, new DateTimeZone('UTC'));
            $dt->setTimezone(new DateTimeZone(self::SGT_TZ));
            return $dt->format('Y-m-d');
        } catch (Exception $e) {
            return '';
        }
    }

    /**
     * Fetch one page from the LMS course-runs endpoint. Note: the API's
     * `?date=` filter is ignored upstream, so we don't pass it — we pull
     * the full dataset and filter client-side after timezone-correcting.
     */
    protected function _fetchPage($offset, $limit)
    {
        $url  = $this->_url() . '/api/external/course-runs?offset=' . (int) $offset . '&limit=' . (int) $limit;
        $ch   = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 20,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_HTTPHEADER     => array('x-api-key: ' . $this->_key(), 'Accept: application/json'),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            throw new Exception('LMS unreachable: ' . ($err ?: 'no response'));
        }
        if ($code >= 400) {
            throw new Exception('LMS HTTP ' . $code . ': ' . substr($raw, 0, 200));
        }
        $rsp = json_decode($raw, true);
        if (!is_array($rsp) || empty($rsp['success'])) {
            $msg = is_array($rsp) && isset($rsp['error']) ? (string) $rsp['error'] : 'bad envelope';
            throw new Exception('LMS error: ' . $msg);
        }
        return isset($rsp['data']) && is_array($rsp['data']) ? $rsp['data'] : array();
    }

    protected function _url()
    {
        return rtrim(trim((string) Mage::getStoreConfig(self::URL_CONFIG_PATH)), '/');
    }

    protected function _key()
    {
        return trim((string) Mage::getStoreConfig(self::KEY_CONFIG_PATH));
    }

    protected function _log($msg)
    {
        Mage::log('[lms-tms-fallback] ' . $msg, Zend_Log::INFO, self::LOG_FILE, true);
    }
}
