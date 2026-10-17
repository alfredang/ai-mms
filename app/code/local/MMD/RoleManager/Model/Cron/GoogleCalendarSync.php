<?php
/**
 * Google Calendar sync — every 15 min, links each upcoming class (course_runs)
 * to an event on this site's class calendar, creating the event when none
 * exists.
 *
 * Calendar = the src= of the site's Credentials → Calendar Embed URL
 * (mmd_company/google/calendar_url), else the site mailbox's primary calendar
 * (mmd_email/google/user — sales@ of the site). Auth = the same domain-wide-
 * delegated service account the Gmail sender uses (mmd_email/google/sa_key),
 * impersonating that mailbox with the calendar scope. No SA key = no-op, so a
 * site without credentials is simply skipped.
 *
 * Per class (start date within the next WINDOW_DAYS, gcal_event_id still NULL):
 *  1. Look for an existing event that day whose title contains the course
 *     title or the class id (ops' own "[VIRTUAL] <title>" events count) and
 *     adopt it — the event itself is never modified.
 *  2. Otherwise create one: title, venue or link, description, the trainer as
 *     attendee (they get the invite), daily recurrence for consecutive days.
 *     A virtual class (mode != 1, same rule as the class page) with no link
 *     gets a Google Meet link generated on the event.
 *  3. A virtual class with no saved link takes the event's link (location URL
 *     or Meet) into course_runs.virtual_link, so the class page shows it.
 *
 * Co-host: the Calendar API cannot assign Meet co-hosts (that needs the Meet
 * API with a meetings.* scope, not delegated). The trainer is invited as an
 * attendee; co-host is granted from the Meet call itself.
 *
 * Kill switch: mmd/gcal_sync/enabled = 0.
 */
class MMD_RoleManager_Model_Cron_GoogleCalendarSync
{
    const LOG_FILE    = 'gcal-sync.log';
    const SCOPE       = 'https://www.googleapis.com/auth/calendar';
    const API         = 'https://www.googleapis.com/calendar/v3';
    const WINDOW_DAYS = 60;
    const BATCH       = 25;

    protected $_token;
    protected $_calendarId;
    protected $_tz;

    public function run()
    {
        $c = Mage::getStoreConfig('mmd/gcal_sync/enabled');
        if ($c !== null && $c !== '' && !(int) $c) {
            return;
        }
        try {
            $this->sync();
        } catch (Exception $e) {
            Mage::log('sync error: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
        }
    }

    /**
     * @param bool     $dryRun true = report what would happen, write nothing
     * @param int|null $runId  sync just this run (ignores window / already-synced)
     * @return array one line per class processed
     */
    public function sync($dryRun = false, $runId = null)
    {
        $gmail = Mage::helper('mmd_email/gmail');
        if (!$gmail->hasServiceAccount()) {
            return array('skipped: no service-account key (mmd_email/google/sa_key)');
        }
        $this->_calendarId = $this->_calendarId();
        if ($this->_calendarId === '') {
            return array('skipped: no calendar (mmd_company/google/calendar_url / mmd_email/google/user)');
        }
        $this->_tz    = Mage::getStoreConfig('general/locale/timezone') ?: 'Asia/Singapore';
        $this->_token = $gmail->getServiceAccountToken(self::SCOPE);

        $res   = Mage::getSingleton('core/resource');
        $read  = $res->getConnection('core_read');
        $runs  = $res->getTableName('course_runs');
        $today = Mage::getModel('core/date')->date('Y-m-d');
        if ($runId) {
            $rows = $read->fetchAll("SELECT * FROM `$runs` WHERE run_id = ?", array((int) $runId));
        } else {
            $rows = $read->fetchAll(
                "SELECT * FROM `$runs`
                  WHERE (gcal_event_id IS NULL OR gcal_event_id = '')
                    AND course_start_date BETWEEN ? AND DATE_ADD(?, INTERVAL " . self::WINDOW_DAYS . " DAY)
                  ORDER BY course_start_date, run_id LIMIT " . self::BATCH,
                array($today, $today)
            );
        }

        $out = array();
        foreach ($rows as $r) {
            try {
                $out[] = $this->_syncRun($r, $dryRun);
            } catch (Exception $e) {
                $out[] = $r['class_id'] . ': ERROR ' . $e->getMessage();
            }
        }
        if (!$dryRun) {
            foreach ($out as $line) {
                Mage::log($line, Zend_Log::INFO, self::LOG_FILE);
            }
        }
        return $out;
    }

    protected function _syncRun(array $r, $dryRun)
    {
        $res   = Mage::getSingleton('core/resource');
        $write = $res->getConnection('core_write');
        $read  = $res->getConnection('core_read');
        $runs  = $res->getTableName('course_runs');

        $title = trim((string) (isset($r['course_title']) ? $r['course_title'] : '')); // column absent on some DBs
        if ($title === '') {
            $title = (string) Mage::getResourceModel('catalog/product')
                ->getAttributeRawValue((int) $r['product_id'], 'name', 0);
        }
        $virtual = (int) $r['mode_of_training'] !== 1;
        $link    = trim((string) $r['virtual_link']);
        if ($link === '') {
            $link = trim((string) $read->fetchOne(
                "SELECT google_meet_url FROM " . $res->getTableName('course_courseware') . " WHERE product_id = ? LIMIT 1",
                array((int) $r['product_id'])
            ));
        }

        $event  = $this->_findEvent($r, $title);
        $action = 'linked existing';
        if (!$event) {
            $action = 'created';
            if ($dryRun) {
                return $r['class_id'] . ' ' . $r['course_start_date'] . ' "' . $title . '": WOULD CREATE'
                    . ($virtual && $link === '' ? ' + Meet link' : '');
            }
            $event = $this->_createEvent($r, $title, $virtual, $link, $read, $res);
        }

        $set = array('gcal_event_id' => (string) $event['id']);
        if ($virtual && trim((string) $r['virtual_link']) === '') {
            $evLink = $link;
            if ($evLink === '' && preg_match('#^https?://\S+$#', trim((string) (isset($event['location']) ? $event['location'] : '')))) {
                $evLink = trim($event['location']);
            }
            if ($evLink === '' && !empty($event['hangoutLink'])) {
                $evLink = $event['hangoutLink'];
            }
            if ($evLink !== '') {
                $set['virtual_link'] = $evLink;
            }
        }
        $summary = $r['class_id'] . ' ' . $r['course_start_date'] . ' "' . $title . '": ' . $action
            . ' "' . (isset($event['summary']) ? $event['summary'] : '') . '"'
            . (isset($set['virtual_link']) ? ' link=' . $set['virtual_link'] : '');
        if ($dryRun) {
            return $summary . ' (dry run)';
        }
        $write->update($runs, $set, array('run_id = ?' => (int) $r['run_id']));
        return $summary;
    }

    /** An event on the class's start date whose title names the course or class id. */
    protected function _findEvent(array $r, $title)
    {
        $day = new DateTime($r['course_start_date'], new DateTimeZone($this->_tz));
        $rsp = $this->_api('GET', '/calendars/' . rawurlencode($this->_calendarId) . '/events?' . http_build_query(array(
            'singleEvents' => 'true',
            'maxResults'   => 250,
            'timeMin'      => $day->format(DateTime::RFC3339),
            'timeMax'      => $day->modify('+1 day')->format(DateTime::RFC3339),
        )));
        $norm = function ($s) {
            return trim(preg_replace('/[^a-z0-9]+/', ' ', strtolower((string) $s)));
        };
        $want = $norm($title);
        $cid  = strtolower((string) $r['class_id']);
        foreach (isset($rsp['items']) ? $rsp['items'] : array() as $ev) {
            if (isset($ev['status']) && $ev['status'] === 'cancelled') continue;
            $have = $norm(isset($ev['summary']) ? $ev['summary'] : '');
            if (($want !== '' && strpos($have, $want) !== false) || ($cid !== '' && strpos($have, $cid) !== false)) {
                // A recurring-series instance → adopt the series itself.
                if (!empty($ev['recurringEventId'])) {
                    $ev['id'] = $ev['recurringEventId'];
                }
                return $ev;
            }
        }
        return null;
    }

    protected function _createEvent(array $r, $title, $virtual, $link, $read, $res)
    {
        $start = (string) $r['course_start_date'];
        $end   = $r['course_end_date'] ? (string) $r['course_end_date'] : $start;
        $span  = (int) round((strtotime($end) - strtotime($start)) / 86400) + 1;
        $n     = (int) $r['num_sessions'];

        $venue = trim(implode(' ', array_filter(array(
            $r['venue_block'], $r['venue_street'], $r['venue_building'],
            $r['venue_floor'] ? '#' . $r['venue_floor'] . ($r['venue_unit'] ? '-' . $r['venue_unit'] : '') : '',
            $r['postal_code'],
        ))));
        $lms = Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB) . 'lmslogin';
        $desc = array(
            'Class ID: ' . $r['class_id'],
            'Course: ' . $title . ' (' . $r['course_sku'] . ')',
        );
        if ($span > 1) {
            $desc[] = 'Dates: ' . $start . ' to ' . $end . ($n && $n !== $span ? ' (' . $n . ' sessions — see the class schedule)' : '');
        }
        if ($virtual && $link !== '') {
            $desc[] = 'Virtual Training Link: ' . $link;
        }
        $desc[] = 'LMS: ' . $lms;

        $ev = array(
            'summary'     => ($virtual ? '[VIRTUAL] ' : '') . $title . ' (' . $r['class_id'] . ')',
            'location'    => $virtual ? ($link !== '' ? $link : 'Virtual Class') : $venue,
            'description' => implode("\n", $desc),
        );
        if ($r['course_start_time'] && $r['course_end_time']) {
            $ev['start'] = array('dateTime' => $start . 'T' . substr($r['course_start_time'], 0, 8), 'timeZone' => $this->_tz);
            $ev['end']   = array('dateTime' => $start . 'T' . substr($r['course_end_time'], 0, 8), 'timeZone' => $this->_tz);
        } else {
            $ev['start'] = array('date' => $start);
            $ev['end']   = array('date' => date('Y-m-d', strtotime($start . ' +1 day')));
        }
        // Consecutive multi-day class → one daily series. Non-consecutive
        // sessions (num_sessions < span) stay a single first-day event.
        if ($span > 1 && (!$n || $n === $span)) {
            $ev['recurrence'] = array('RRULE:FREQ=DAILY;COUNT=' . $span);
        }
        if ((int) $r['trainer_user_id']) {
            $email = (string) $read->fetchOne(
                "SELECT email FROM " . $res->getTableName('admin_user') . " WHERE user_id = ?",
                array((int) $r['trainer_user_id'])
            );
            if ($email !== '') {
                $ev['attendees'] = array(array('email' => $email));
            }
        }
        $qs = array('sendUpdates' => 'all');
        if ($virtual && $link === '') {
            $ev['conferenceData'] = array('createRequest' => array(
                'requestId'             => $r['class_id'] . '-' . time(),
                'conferenceSolutionKey' => array('type' => 'hangoutsMeet'),
            ));
            $qs['conferenceDataVersion'] = 1;
        }
        return $this->_api('POST', '/calendars/' . rawurlencode($this->_calendarId) . '/events?' . http_build_query($qs), $ev);
    }

    /** src= of the Calendar Embed URL, else the site mailbox's primary calendar. */
    protected function _calendarId()
    {
        $url = trim((string) Mage::getStoreConfig('mmd_company/google/calendar_url'));
        if ($url !== '') {
            parse_str((string) parse_url($url, PHP_URL_QUERY), $q);
            if (!empty($q['src'])) {
                return (string) (is_array($q['src']) ? reset($q['src']) : $q['src']);
            }
        }
        return trim((string) Mage::getStoreConfig('mmd_email/google/user'));
    }

    protected function _api($method, $path, array $body = null)
    {
        $ch = curl_init(self::API . $path);
        $headers = array('Authorization: Bearer ' . $this->_token, 'Accept: application/json');
        $opts = array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 20,
            CURLOPT_CONNECTTIMEOUT => 8,
            CURLOPT_CUSTOMREQUEST  => $method,
        );
        if ($body !== null) {
            $headers[] = 'Content-Type: application/json';
            $opts[CURLOPT_POSTFIELDS] = json_encode($body);
        }
        $opts[CURLOPT_HTTPHEADER] = $headers;
        curl_setopt_array($ch, $opts);
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);
        $rsp = json_decode((string) $raw, true);
        if ($raw === false || $code >= 400 || !is_array($rsp)) {
            throw new Exception('Calendar API ' . $method . ' HTTP ' . $code . ': ' . ($err ?: substr((string) $raw, 0, 300)));
        }
        return $rsp;
    }
}
