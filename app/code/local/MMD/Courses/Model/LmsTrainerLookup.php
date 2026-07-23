<?php
/**
 * LMS-TMS trainer lookup via shared Google Calendar cross-reference — fallback source
 * for trainer reminders on MMS-only (typically non-WSQ) courses that have no matching
 * LMS course_run at all. LmsTmsCourseRun's Phase 2 fallback matches by exact course_sku
 * against LMS's own course_run table, so it can only ever help SKUs LMS also knows
 * about (WSQ). This queries a different signal instead: the shared Google Calendar
 * event for this course_sku + date, cross-referenced against LMS's Trainer role — no
 * LMS course_run needs to exist at all.
 *
 * Confirmed 2026-07-23 (6-month backtest, 126 non-WSQ class occurrences): 81% resolve
 * this way, because a large share of MMS's non-WSQ trainers also teach WSQ classes and
 * are therefore discoverable as Trainer-role LMS accounts via calendar attendance, even
 * though MMS's own trainer_user_id / trainer_option_id / course_run_trainer_invitations
 * data is essentially unpopulated for this segment.
 *
 * Opt-in only, gated by RemindersController's ?use_lms_trainer_lookup=1 — kept off by
 * default so MMS's own trainer-assignment data stays authoritative if/when it's properly
 * adopted; the caller just stops passing the flag at that point, no code change here.
 *
 * Read-only. No writes. Failure is non-fatal — returns null on any error/non-match and
 * the caller continues without a match for that class. Reuses the SAME LMS-TMS API
 * credentials already configured for LmsTmsCourseRun (mmd/trainer_import/lms_url + api_key)
 * — no new secret to provision.
 */
class MMD_Courses_Model_LmsTrainerLookup
{
    const URL_CONFIG_PATH = 'mmd/trainer_import/lms_url';
    const KEY_CONFIG_PATH = 'mmd/trainer_import/api_key';
    const LOG_FILE        = 'lms-tms-fallback.log';

    /**
     * @param string $courseCode  MMS course_sku
     * @param string $date        YYYY-MM-DD
     * @param string $courseTitle optional — used as a fuzzy-title fallback signal on the LMS side
     *                            only when the course_code match finds no calendar event
     * @return array{name:string,email:string}|null  null on any failure or non-confident result
     */
    public function lookup($courseCode, $date, $courseTitle = '')
    {
        $url = rtrim(trim((string) Mage::getStoreConfig(self::URL_CONFIG_PATH)), '/');
        $key = trim((string) Mage::getStoreConfig(self::KEY_CONFIG_PATH));
        if ($url === '' || $key === '') return null;

        $qs = http_build_query(array(
            'course_code'  => (string) $courseCode,
            'date'         => (string) $date,
            'course_title' => (string) $courseTitle,
        ));
        $ch = curl_init($url . '/api/external/trainer-lookup?' . $qs);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_HTTPHEADER     => array('x-api-key: ' . $key, 'Accept: application/json'),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            $this->_log("lookup($courseCode, $date) unreachable: " . ($err ?: 'no response'));
            return null;
        }
        if ($code >= 400) {
            $this->_log("lookup($courseCode, $date) HTTP $code: " . substr($raw, 0, 200));
            return null;
        }

        $rsp = json_decode($raw, true);
        if (!is_array($rsp) || ($rsp['source'] ?? '') !== 'gcal_role_match' || empty($rsp['trainer']['email'])) {
            return null;
        }

        return array(
            'name'  => (string) $rsp['trainer']['name'],
            'email' => (string) $rsp['trainer']['email'],
        );
    }

    private function _log($msg)
    {
        Mage::log('[lms-trainer-lookup] ' . $msg, Zend_Log::INFO, self::LOG_FILE, true);
    }
}
