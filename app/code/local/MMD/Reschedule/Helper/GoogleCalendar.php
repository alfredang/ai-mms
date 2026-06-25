<?php
/**
 * Google Calendar attendee sync for reschedule requests.
 *
 * On a class-reschedule form submission, removes the learner from Calendar
 * events on the original date and adds them to events on the new date,
 * matching events by course title keyword against the event summary.
 *
 * All HTTP calls use Zend_Http_Client (already available in Magento).
 * Credentials are read from core_config_data paths seeded by migration 275.
 *
 * Usage:
 *   Mage::helper('mmd_reschedule/googleCalendar')->syncRescheduleLead($lead);
 */
class MMD_Reschedule_Helper_GoogleCalendar extends Mage_Core_Helper_Abstract
{
    const TOKEN_URL  = 'https://oauth2.googleapis.com/token';
    const EVENTS_URL = 'https://www.googleapis.com/calendar/v3/calendars/%s/events';
    const EVENT_URL  = 'https://www.googleapis.com/calendar/v3/calendars/%s/events/%s';

    /** @return string */
    protected function _getConfig(string $path): string
    {
        return (string) Mage::getStoreConfig($path);
    }

    /**
     * Exchange the stored refresh_token for a short-lived access_token.
     *
     * @return string
     * @throws Exception if the token endpoint returns no access_token
     */
    protected function _refreshAccessToken(): string
    {
        $client = new Zend_Http_Client(self::TOKEN_URL, array('timeout' => 30));
        $client->setParameterPost(array(
            'grant_type'    => 'refresh_token',
            'client_id'     => $this->_getConfig('mmd_googlecalendar/oauth/client_id'),
            'client_secret' => $this->_getConfig('mmd_googlecalendar/oauth/client_secret'),
            'refresh_token' => $this->_getConfig('mmd_googlecalendar/oauth/refresh_token'),
        ));
        $response = $client->request(Zend_Http_Client::POST);
        $data = json_decode($response->getBody(), true);
        if (empty($data['access_token'])) {
            throw new Exception('Google OAuth token refresh failed: ' . $response->getBody());
        }
        return (string) $data['access_token'];
    }

    /**
     * Parse a loose date string into Y-m-d, or return null on failure.
     *
     * @param  string $raw
     * @return string|null
     */
    protected function _toDateIso(string $raw): ?string
    {
        if ($raw === '') {
            return null;
        }
        $ts = strtotime($raw);
        if ($ts === false) {
            return null;
        }
        return date('Y-m-d', $ts);
    }

    /**
     * List calendar events around $dateIso whose summary contains $keyword.
     *
     * Searches a ±2-day window around the target date to cover timezone offsets
     * (the calendar may be UTC while the course date is local).
     *
     * @param  string $calendarId
     * @param  string $token
     * @param  string $dateIso    Y-m-d
     * @param  string $keyword
     * @return array<int, array{id: string, summary: string}>
     * @throws Exception on API error
     */
    protected function _findEventsOnDate(string $calendarId, string $token, string $dateIso, string $keyword): array
    {
        $timeMin = date('Y-m-d', strtotime($dateIso . ' -1 day')) . 'T00:00:00Z';
        $timeMax = date('Y-m-d', strtotime($dateIso . ' +2 days')) . 'T00:00:00Z';

        $url    = sprintf(self::EVENTS_URL, rawurlencode($calendarId));
        $client = new Zend_Http_Client($url, array('timeout' => 30));
        $client->setHeaders('Authorization', 'Bearer ' . $token);
        $client->setParameterGet(array(
            'timeMin'      => $timeMin,
            'timeMax'      => $timeMax,
            'singleEvents' => 'true',
            'maxResults'   => 50,
        ));
        $response = $client->request(Zend_Http_Client::GET);

        $data = json_decode($response->getBody(), true);
        if (!is_array($data) || !isset($data['items'])) {
            throw new Exception('Google Calendar events.list failed: ' . $response->getBody());
        }

        $keywordLower = strtolower($keyword);
        $matched      = array();
        foreach ($data['items'] as $event) {
            if (isset($event['summary']) && strpos(strtolower((string) $event['summary']), $keywordLower) !== false) {
                $matched[] = array('id' => (string) $event['id'], 'summary' => (string) $event['summary']);
            }
        }
        return $matched;
    }

    /**
     * Add or remove $email from the attendees list of a single event via PATCH.
     *
     * GETs the current event state first so existing attendees are preserved.
     * Uses sendUpdates=none to suppress notification emails.
     *
     * @param  string $calendarId
     * @param  string $token
     * @param  string $eventId
     * @param  string $email
     * @param  string $action   'add' | 'remove'
     * @return void
     * @throws Exception on API error
     */
    protected function _patchAttendees(string $calendarId, string $token, string $eventId, string $email, string $action): void
    {
        // GET current event to preserve existing attendees
        $eventUrl = sprintf(self::EVENT_URL, rawurlencode($calendarId), rawurlencode($eventId));
        $getClient = new Zend_Http_Client($eventUrl, array('timeout' => 30));
        $getClient->setHeaders('Authorization', 'Bearer ' . $token);
        $getResponse = $getClient->request(Zend_Http_Client::GET);

        $event     = json_decode($getResponse->getBody(), true);
        $attendees = (is_array($event) && isset($event['attendees']) && is_array($event['attendees']))
            ? $event['attendees']
            : array();

        $emailLower = strtolower($email);

        if ($action === 'add') {
            $found = false;
            foreach ($attendees as $a) {
                if (isset($a['email']) && strtolower((string) $a['email']) === $emailLower) {
                    $found = true;
                    break;
                }
            }
            if (!$found) {
                $attendees[] = array('email' => $email);
            }
        } elseif ($action === 'remove') {
            $attendees = array_values(array_filter($attendees, function (array $a) use ($emailLower): bool {
                return !(isset($a['email']) && strtolower((string) $a['email']) === $emailLower);
            }));
        }

        // PATCH the event with the updated attendees list
        $patchClient = new Zend_Http_Client($eventUrl, array('timeout' => 30));
        $patchClient->setHeaders('Authorization', 'Bearer ' . $token);
        $patchClient->setParameterGet('sendUpdates', 'none');
        $patchClient->setRawData(json_encode(array('attendees' => $attendees)), 'application/json');
        $patchResponse = $patchClient->request('PATCH');

        if (!$patchResponse->isSuccessful()) {
            throw new Exception(sprintf(
                'Google Calendar PATCH failed for event %s: %s',
                $eventId,
                $patchResponse->getBody()
            ));
        }
    }

    /**
     * Sync a reschedule lead with Google Calendar: remove from old date, add to new date.
     *
     * - Skips TGS- courses (sets gcal_status = 'skipped').
     * - On success sets gcal_status = 'synced' and saves.
     * - Throws on any API failure; the caller is responsible for catching and
     *   setting gcal_status = 'error'.
     *
     * @param  MMD_Reschedule_Model_Lead $lead
     * @return void
     * @throws Exception
     */
    public function syncRescheduleLead(MMD_Reschedule_Model_Lead $lead): void
    {
        $courseCode = (string) $lead->getCourseCode();

        // TGS- courses are managed by an external system — skip entirely
        if (strpos($courseCode, 'TGS-') === 0) {
            $lead->setGcalStatus('skipped')->save();
            return;
        }

        $calendarId = $this->_getConfig('mmd_googlecalendar/calendar/calendar_id');
        $token      = $this->_refreshAccessToken();

        // Match events by course title; fall back to course code
        $keyword = trim((string) $lead->getCourse());
        if ($keyword === '') {
            $keyword = $courseCode;
        }

        $currentIso = $this->_toDateIso((string) $lead->getCourseStartDate());
        $nextIso    = $this->_toDateIso((string) $lead->getNextCourseStartDate());
        $email      = (string) $lead->getEmail();

        // Remove learner from events on the original date
        if ($currentIso !== null) {
            foreach ($this->_findEventsOnDate($calendarId, $token, $currentIso, $keyword) as $event) {
                $this->_patchAttendees($calendarId, $token, $event['id'], $email, 'remove');
            }
        }

        // Add learner to events on the requested new date
        if ($nextIso !== null) {
            foreach ($this->_findEventsOnDate($calendarId, $token, $nextIso, $keyword) as $event) {
                $this->_patchAttendees($calendarId, $token, $event['id'], $email, 'add');
            }
        }

        $lead->setGcalStatus('synced')->save();
    }
}
