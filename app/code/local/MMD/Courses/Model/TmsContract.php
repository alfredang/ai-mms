<?php
/** Pure validation, also used by the standalone integration contract tests. */
class MMD_Courses_Model_TmsContract
{
    public static function courseCode($value)
    {
        $code = strtoupper(trim((string) $value));
        if ($code === '' || strpos($code, 'TGS') === 0) {
            throw new InvalidArgumentException('Funded TGS courses and missing course codes are excluded from MMS handover.');
        }
        if (!preg_match('/^C[0-9][A-Z0-9-]*$/D', $code)) {
            throw new InvalidArgumentException('This non-funded course code needs MMS delivery support before import.');
        }
        return $code;
    }

    public static function validate(array $data)
    {
        $contentHash = self::contentHash($data);
        $data['course_code'] = self::courseCode(isset($data['course_code']) ? $data['course_code'] : '');
        if (!isset($data['course_title']) || !is_string($data['course_title'])
            || trim($data['course_title']) === '' || mb_strlen($data['course_title'], 'UTF-8') > 255) {
            throw new InvalidArgumentException('A valid course title is required for MMS catalogue verification.');
        }
        $data['course_title'] = trim($data['course_title']);
        if (($data['schema_version'] ?? null) !== 1 || ($data['roster_complete'] ?? null) !== true) {
            throw new InvalidArgumentException('Version 1 and a complete operational roster are required.');
        }
        foreach (array('source_provider_id' => 64, 'source_run_key' => 255, 'calendar_id' => 255) as $key => $max) {
            if (empty($data[$key]) || !is_string($data[$key]) || strlen($data[$key]) > $max) {
                throw new InvalidArgumentException('Invalid source identity: ' . $key);
            }
        }
        if (!isset($data['revision']) || !is_int($data['revision']) || $data['revision'] < 1
            || !preg_match('/^[a-f0-9]{64}$/D', (string) ($data['snapshot_hash'] ?? ''))) {
            throw new InvalidArgumentException('A positive revision and content hash are required.');
        }
        if (!is_bool($data['cancelled'] ?? null) || !is_int($data['website_id'] ?? null)) {
            throw new InvalidArgumentException('Invalid cancellation state or website scope.');
        }
        if (empty($data['sessions']) || !is_array($data['sessions']) || count($data['sessions']) > 100) {
            throw new InvalidArgumentException('Provide the exact class sessions (maximum 100).');
        }
        $keys = array();
        foreach ($data['sessions'] as $session) {
            $key = (string) ($session['key'] ?? '');
            $date = (string) ($session['date'] ?? '');
            $parsed = DateTimeImmutable::createFromFormat('!Y-m-d', $date);
            if (!preg_match('/^s[a-f0-9]{7}$/D', $key) || isset($keys[$key]) || !$parsed
                || $parsed->format('Y-m-d') !== $date || $date < '2000-01-01' || $date > '2100-12-31') {
                throw new InvalidArgumentException('Invalid or duplicated session identity/date.');
            }
            $keys[$key] = true;
            foreach (array('start_time','end_time') as $time) {
                if (!preg_match('/^([01][0-9]|2[0-3]):[0-5][0-9]$/D', (string) ($session[$time] ?? ''))) {
                    throw new InvalidArgumentException('Session times must use HH:MM.');
                }
            }
            if ($session['end_time'] <= $session['start_time']) throw new InvalidArgumentException('Session end must follow start.');
            if (!in_array($session['mode'] ?? null, array(1,2), true)) throw new InvalidArgumentException('Unsupported delivery mode.');
            self::url((string) ($session['virtual_link'] ?? ''));
        }
        usort($data['sessions'], function ($a, $b) { return strcmp($a['date'] . $a['start_time'], $b['date'] . $b['start_time']); });
        foreach (array('learners','trainers') as $role) {
            if (!isset($data[$role]) || !is_array($data[$role]) || count($data[$role]) > 1000) throw new InvalidArgumentException('Invalid participant list.');
            $emails = array(); $ids = array();
            foreach ($data[$role] as &$person) {
                $person['email'] = strtolower(trim((string) ($person['email'] ?? '')));
                $id = (string) ($person['source_id'] ?? '');
                if ($id === '' || strlen($id) > 255 || strlen($person['email']) > 128 || !filter_var($person['email'], FILTER_VALIDATE_EMAIL)) {
                    throw new InvalidArgumentException('Each participant needs a source identity and valid email.');
                }
                if (isset($emails[$person['email']]) || isset($ids[$id])) throw new InvalidArgumentException('Duplicate participant identity/email.');
                $emails[$person['email']] = true; $ids[$id] = true;
                if ($role === 'trainers' && !is_bool($person['confirmed'] ?? null)) throw new InvalidArgumentException('Explicit trainer confirmation is required.');
                if (array_key_exists('active',$person) && !is_bool($person['active'])) throw new InvalidArgumentException('Account eligibility must be a boolean.');
            }
            unset($person);
        }
        // Pilot is deliberately one trainer per class. Never discard extra trainers.
        if (count($data['trainers']) > 1) throw new InvalidArgumentException('Multiple trainers require delivery support before import.');
        self::url((string) ($data['feedback_url'] ?? ''));
        foreach (($data['courseware'] ?? array()) as $url) self::url((string) $url);
        if (empty($data['event_occurrences']) || !is_array($data['event_occurrences'])) throw new InvalidArgumentException('Calendar event identities are required.');
        foreach ($data['event_occurrences'] as $event) if (!is_string($event) || $event === '' || strlen($event) > 255) throw new InvalidArgumentException('Invalid Calendar occurrence identity.');
        if (!hash_equals($contentHash,$data['snapshot_hash'])) throw new InvalidArgumentException('Snapshot content does not match its hash.');
        return $data;
    }

    public static function contentHash(array $data)
    {
        foreach(array('revision','request_id','snapshot_hash','snapshot_at','dry_run') as $key)unset($data[$key]);
        if(isset($data['courseware']))$data['courseware']=(object)$data['courseware'];
        $canonical=function($value)use(&$canonical){
            if(is_object($value)){$values=get_object_vars($value);ksort($values,SORT_STRING);foreach($values as &$v)$v=$canonical($v);unset($v);return (object)$values;}
            if(is_array($value)){
                $isList=array_keys($value)===range(0,count($value)-1)||!$value;
                if(!$isList)ksort($value,SORT_STRING);
                foreach($value as &$v)$v=$canonical($v);unset($v);
            }
            return $value;
        };
        return hash('sha256',json_encode($canonical($data),JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_LINE_TERMINATORS|JSON_THROW_ON_ERROR));
    }

    private static function url($value)
    {
        if ($value !== '' && (strlen($value) > 1000 || !filter_var($value, FILTER_VALIDATE_URL) || !in_array(strtolower((string) parse_url($value, PHP_URL_SCHEME)), array('https','http'), true))) {
            throw new InvalidArgumentException('Resource URLs must be valid HTTP(S) URLs.');
        }
    }
}
