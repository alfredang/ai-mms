<?php
/**
 * The signed-in trainer's classes for the native apps: the class list, one
 * class (sessions, roster with attendance, courseware, check-in link) and
 * taking attendance.
 *
 * A class belongs to a trainer by the same three rules as the web LMS
 * (MMD_Attendance_Helper_Data::_filterToTrainer) so the app and the website
 * always list the same classes: the run's trainer account, the legacy trainer
 * option whose courses_trainers email is the trainer's, or the full name.
 * Every SKU is included (WSQ and non-WSQ). Every read and write is limited to
 * the trainer's own classes.
 */
class MMD_MobileApi_Helper_Trainer extends Mage_Core_Helper_Abstract
{
    const PAST_DAYS  = 365;   // how far back the Past list goes
    const PAST_LIMIT = 100;

    /** Courseware a trainer sees: the trainer-only links, then the learner ones. */
    protected $_materials = array(
        'trainer_slides_url'    => 'Trainer Slides',
        'facilitator_guide_url' => 'Facilitator Guide',
        'assessment_plan_url'   => 'Assessment Plan',
        'learner_slides_url'    => 'Learner Slides',
        'learner_guide_url'     => 'Learner Guide',
        'lesson_plan_url'       => 'Lesson Plan',
        'lab_url'               => 'Activities / Labs',
        'lab_simulator_url'     => 'Lab Simulator',
        'practice_exam_url'     => 'Practice Exam',
    );

    protected $_modes = array(1 => 'Classroom', 2 => 'Live Online', 3 => 'Hybrid');

    /** @return array{current:array, upcoming:array, past:array} */
    public function classes($email)
    {
        $today = $this->_h()->today();
        $out   = array('current' => array(), 'upcoming' => array(), 'past' => array());
        $att   = Mage::helper('mmd_attendance');
        $images = $this->_imagesByProduct();

        $runs = $this->_runs($email);
        $counts = $this->_enrolmentCounts(array_map(function ($r) { return (int) $r['run_id']; }, $runs));
        foreach ($runs as $run) {
            $row = $this->_classRow($run, $today, $images);
            $n   = isset($counts[(int) $run['run_id']]) ? $counts[(int) $run['run_id']] : 0;
            // WSQ classes keep no enrolment rows; their roster comes from the orders.
            if ($n === 0 && $row['bucket'] !== 'past') {
                try {
                    $n = count($att->rosterForRun($run));
                } catch (Exception $e) {
                    $n = 0;
                }
            }
            $row['learner_count'] = $n;
            $out[$row['bucket']][] = $row;
        }
        $byStart = function ($a, $b) { return strcmp($a['start_date'], $b['start_date']); };
        usort($out['current'], $byStart);
        usort($out['upcoming'], $byStart);
        usort($out['past'], function ($a, $b) { return strcmp($b['end_date'], $a['end_date']); });
        $out['past'] = array_slice($out['past'], 0, self::PAST_LIMIT);
        return $out;
    }

    const HOURS_PAST_DAYS = 1095;   // training hours history: three years

    /**
     * Training hours the trainer has delivered: one row per class with the days
     * taught so far, plus totals per month. A day counts its class time
     * (start to end) less a one-hour lunch when the day runs longer than five
     * hours. Only days up to today count, so a running class grows day by day.
     */
    public function trainingHours($email)
    {
        $today = $this->_h()->today();
        $att   = Mage::helper('mmd_attendance');
        $classes = array(); $months = array(); $total = 0.0;
        foreach ($this->_runs($email, self::HOURS_PAST_DAYS) as $run) {
            $perDay = $this->_dayHours($run['course_start_time'], $run['course_end_time']);
            if ($perDay <= 0) {
                continue;
            }
            $days = array();
            foreach ($att->sessionsForRun($run) as $s) {
                $d = (string) $s['date'];
                if ($d !== '' && $d <= $today) $days[$d] = true;
            }
            if (!$days) {
                continue;
            }
            foreach (array_keys($days) as $d) {
                $m = substr($d, 0, 7);
                $months[$m] = (isset($months[$m]) ? $months[$m] : 0) + $perDay;
            }
            $hours  = $perDay * count($days);
            $total += $hours;
            $dates  = array_keys($days);
            sort($dates);
            $classes[] = array(
                'run_id'     => (int) $run['run_id'],
                'title'      => trim((string) $run['course_title']),
                'sku'        => (string) $run['course_sku'],
                'start_date' => $dates[0],
                'end_date'   => $dates[count($dates) - 1],
                'days'       => count($days),
                'hours'      => round($hours, 1),
            );
        }
        usort($classes, function ($a, $b) { return strcmp($b['end_date'], $a['end_date']); });
        krsort($months);
        $byMonth = array();
        foreach ($months as $m => $h) {
            $byMonth[] = array('month' => $m, 'hours' => round($h, 1));
        }
        return array('total_hours' => round($total, 1), 'months' => $byMonth, 'classes' => $classes);
    }

    /**
     * SSG's TRAQOM survey: Singapore only, and only for an SSG-funded class
     * (a TGS- course code). Empty everywhere else, so the apps show nothing.
     */
    protected function _traqomUrl($sku)
    {
        if ($this->_h()->countryCode() !== 'SG' || stripos(trim($sku), 'TGS-') !== 0) {
            return '';
        }
        $url = trim((string) Mage::getStoreConfig('mmd_mobileapi/general/traqom_url'));
        return $url !== '' ? $url : 'https://ssgtraqom.qualtrics.com/jfe/form/SV_3K9i7rTJ9OLsauW?Q_CHL=qr';
    }

    protected function _dayHours($start, $end)
    {
        $a = strtotime('1970-01-01 ' . (string) $start . ' UTC');
        $b = strtotime('1970-01-01 ' . (string) $end . ' UTC');
        if (!$a || !$b || $b <= $a) {
            return 0;
        }
        $h = ($b - $a) / 3600;
        return $h > 5 ? $h - 1 : $h;
    }

    /**
     * The trainer's completed payouts, read from the LMS/TMS (where Payroll
     * records them) over a server-to-server call. `available` is false on a site
     * with no bridge configured (env LMSTMS_BRIDGE_URL + MOBILE_BRIDGE_SECRET),
     * or when the LMS/TMS cannot be reached; the app then says so instead of
     * showing an empty history.
     */
    public function payouts($email)
    {
        $url    = rtrim((string) getenv('LMSTMS_BRIDGE_URL'), '/');
        $secret = (string) getenv('MOBILE_BRIDGE_SECRET');
        if ($url === '' || $secret === '' || stripos($url, 'https://') !== 0) {
            return array('available' => false, 'payouts' => array(), 'total' => 0, 'currency' => 'SGD');
        }
        $ch = curl_init($url . '/api/internal/trainer-payouts');
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode(array('email' => strtolower($email))),
            CURLOPT_HTTPHEADER     => array('Content-Type: application/json', 'Authorization: Bearer ' . $secret),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_TIMEOUT        => 12,
        ));
        $body = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        $json = is_string($body) ? json_decode($body, true) : null;
        if ($code !== 200 || !is_array($json) || empty($json['success']) || !isset($json['data']) || !is_array($json['data'])) {
            Mage::log('mobile payouts bridge: HTTP ' . $code, null, 'mmd_mobileapi.log');
            return array('available' => false, 'payouts' => array(), 'total' => 0, 'currency' => 'SGD');
        }
        $rows = array(); $total = 0.0;
        foreach ($json['data'] as $r) {
            $amount = isset($r['actual_payout']) ? (float) $r['actual_payout'] : 0.0;
            $total += $amount;
            $rows[] = array(
                'id'           => (string) (isset($r['source']) ? $r['source'] : '') . '-' . (string) (isset($r['id']) ? $r['id'] : ''),
                'title'        => trim((string) (isset($r['course_title']) ? $r['course_title'] : '')),
                'course_code'  => (string) (isset($r['course_code']) ? $r['course_code'] : ''),
                'learners'     => isset($r['num_learners']) ? (int) $r['num_learners'] : null,
                'amount'       => round($amount, 2),
                'payment_date' => $this->_ymd(isset($r['payment_date']) ? $r['payment_date'] : ''),
                'start_date'   => $this->_ymd(isset($r['start_date']) ? $r['start_date'] : ''),
                'end_date'     => $this->_ymd(isset($r['end_date']) ? $r['end_date'] : ''),
            );
        }
        return array('available' => true, 'payouts' => $rows, 'total' => round($total, 2), 'currency' => 'SGD');
    }

    /** Full detail of one of the trainer's classes, or null if not theirs. */
    public function classDetail($email, $runId)
    {
        $run = $this->_run($email, $runId);
        if (!$run) {
            return null;
        }
        $att   = Mage::helper('mmd_attendance');
        $today = $this->_h()->today();
        $row   = $this->_classRow($run, $today, $this->_imagesByProduct());
        unset($row['days'], $row['status'], $row['order_no'], $row['certificate'], $row['survey_submitted'], $row['role'], $row['product_id']);

        $sessions = array();
        $keys     = array();
        foreach ($att->sessionsForRun($run) as $s) {
            $keys[$s['key']] = true;
            $sessions[] = array(
                'key'   => (string) $s['key'],
                'day'   => (int) $s['day'],
                'part'  => (string) $s['ampm'],
                'date'  => (string) $s['date'],
                'label' => (string) $s['label'],
            );
        }

        $open       = $this->_attendanceOpen($run) === '';
        $currentKey = $open ? (string) $att->currentSessionKey($run) : '';
        if (!isset($keys[$currentKey])) {
            $currentKey = '';
        }
        $currentLbl = '';
        foreach ($sessions as $s) {
            if ($s['key'] === $currentKey) { $currentLbl = $s['label']; break; }
        }

        $roster = array();
        foreach ($att->rosterForRun($run) as $r) {
            $present = array();
            foreach ((array) $r['att'] as $key => $a) {
                if (is_array($a) && (int) $a['p'] === 1) $present[] = (string) $key;
            }
            $roster[] = array(
                'name'    => trim((string) $r['learner_name']) !== '' ? trim((string) $r['learner_name']) : (string) $r['learner_email'],
                'email'   => strtolower(trim((string) $r['learner_email'])),
                'phone'   => isset($r['learner_phone']) ? (string) $r['learner_phone'] : '',
                'walkin'  => !empty($r['is_walkin']),
                'present' => $present,
            );
        }
        usort($roster, function ($a, $b) { return strcasecmp($a['name'], $b['name']); });

        $row['sessions']              = $sessions;
        $row['current_session']       = $currentKey;
        $row['current_session_label'] = $currentLbl;
        $row['attendance_open']       = $open;
        $row['checkin_url']           = ($open && $currentKey !== '') ? $att->checkinUrl((int) $run['run_id'], $currentKey) : '';
        $row['roster']                = $roster;
        $row['materials']             = $this->_materialsFor((int) $run['product_id']);
        $row['documents']             = $this->_documents((int) $run['product_id']);
        $row['survey_responses']      = $this->_surveyResponses((int) $run['run_id']);
        // Links the trainer shows the class (as a QR code or shared link).
        $native = rtrim(Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB), '/') . '/feedback/respond/index?run_id=' . (int) $run['run_id'];
        $row['feedback_url'] = (string) Mage::helper('mmd_rolemanager/handover')->feedbackUrl((int) $run['run_id'], $native);
        $row['traqom_url']   = $this->_traqomUrl((string) $run['course_sku']);
        return $row;
    }

    /**
     * Mark learners present / absent for one session of the trainer's class.
     * Only while the class is running: corrections to a finished class go
     * through the website, where the reason is recorded.
     *
     * @param array $records [{email, name?, present}]
     * @return array(success, message)
     */
    public function saveAttendance($email, $runId, $sessionKey, array $records)
    {
        $run = $this->_run($email, $runId);
        if (!$run) {
            return array('success' => false, 'message' => 'This class is not on your account.');
        }
        $att        = Mage::helper('mmd_attendance');
        $sessionKey = strtolower(trim((string) $sessionKey));
        if (!preg_match('/^[a-z0-9]{2,16}$/', $sessionKey) || !$att->sessionForRun($run, $sessionKey)) {
            return array('success' => false, 'message' => 'Please choose a session of this class.');
        }
        $closed = $this->_attendanceOpen($run);
        if ($closed !== '') {
            return array('success' => false, 'message' => $closed);
        }
        // A class handed over from the TMS runs timed sessions: only the one in progress can be marked.
        if (Mage::helper('mmd_rolemanager/handover')->isManaged((int) $run['run_id'])
            && $sessionKey !== (string) $att->currentSessionKey($run)) {
            return array('success' => false, 'message' => 'Only the session in progress can be marked for this class.');
        }

        $names = array();
        foreach ($att->rosterForRun($run) as $r) {
            $names[strtolower(trim((string) $r['learner_email']))] = trim((string) $r['learner_name']);
        }
        $identity = $this->_h()->trainerIdentity($email);
        $adminId  = $identity && $identity['user_id'] ? (int) $identity['user_id'] : null;
        $classId  = (string) $run['class_id'];
        $rows     = array();
        foreach ($records as $r) {
            if (!is_array($r)) continue;
            $learner = strtolower(trim((string) (isset($r['email']) ? $r['email'] : '')));
            if ($learner === '' || !array_key_exists($learner, $names)) continue;   // roster members only
            $rows[$learner] = array(
                'run_id'             => (int) $run['run_id'],
                'class_id'           => $classId !== '' ? $classId : null,
                'learner_email'      => $learner,
                'session_key'        => $sessionKey,
                'learner_name'       => $names[$learner],
                'is_present'         => !empty($r['present']) ? 1 : 0,
                'minutes_attended'   => null,
                'reason_of_absence'  => null,
                'marked_by_admin_id' => $adminId,
            );
        }
        if (!$rows) {
            return array('success' => false, 'message' => 'There is nobody on this class roster to mark.');
        }

        $write = $this->_write();
        $write->beginTransaction();
        try {
            foreach ($rows as $row) {
                $write->insertOnDuplicate($this->_table('mmd_course_run_attendance'), $row,
                    array('learner_name', 'is_present', 'minutes_attended', 'reason_of_absence', 'marked_by_admin_id', 'class_id'));
            }
            $write->commit();
        } catch (Exception $e) {
            $write->rollBack();
            throw $e;
        }
        return array('success' => true, 'message' => 'Attendance saved.');
    }

    // ── Internals ────────────────────────────────────────────────────────────

    /** '' when the trainer may take attendance now, else why not. */
    protected function _attendanceOpen(array $run)
    {
        $att = Mage::helper('mmd_attendance');
        if ($att->isFinishedRun($run)) {
            return 'This class has finished. Please correct its attendance on the website, where the reason is recorded.';
        }
        $conf = $att->isMalaysiaSite() ? Mage::helper('mmd_certificate')->confirmationForRun((int) $run['run_id']) : null;
        if ($conf && $conf['status'] === 'confirmed') {
            return 'The final attendance of this class was confirmed. Please change it on the website.';
        }
        if (!$att->isWithinAttendanceWindow($run)) {
            return 'Attendance opens on the first day of class and closes the day after it ends.';
        }
        return '';
    }

    protected function _runSelect(array $identity, array &$bind)
    {
        $nameAttr = (int) $this->_read()->fetchOne(
            "SELECT a.attribute_id FROM " . $this->_table('eav_attribute') . " a
               JOIN " . $this->_table('eav_entity_type') . " t ON t.entity_type_id = a.entity_type_id
              WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name'"
        );
        $trainerName = "COALESCE(NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))),''), tov.value, '')";

        $match = array();
        $bind  = array();
        if ($identity['user_id'] > 0) {
            $match[] = 'cr.trainer_user_id = ?';
            $bind[]  = (int) $identity['user_id'];
        }
        if ($identity['option_ids']) {
            $match[] = 'cr.trainer_option_id IN (' . implode(',', array_map('intval', $identity['option_ids'])) . ')';
        }
        if ($identity['name'] !== '') {
            $match[] = "LOWER(TRIM($trainerName)) = ?";
            $bind[]  = $identity['name'];
        }
        // Co-trainers of a class handed over from the TMS (the web LMS rule, Handover::canAccessRun).
        $shared = $identity['user_id'] > 0 ? $this->_handoverRunIds((int) $identity['user_id']) : array();
        if ($shared) {
            $match[] = 'cr.run_id IN (' . implode(',', $shared) . ')';
        }
        if (!$match) {
            $match[] = '1 = 0';
        }

        return "SELECT cr.run_id, cr.class_id, cr.product_id, TRIM(cr.course_sku) AS course_sku,
                       cr.course_start_date, COALESCE(cr.course_end_date, cr.course_start_date) AS course_end_date,
                       cr.course_start_time, cr.course_end_time, cr.mode_of_training, cr.virtual_link,
                       cr.venue_block, cr.venue_street, cr.venue_building, cr.venue_floor, cr.venue_unit,
                       cr.postal_code, cr.room, cr.trainer_user_id, cr.trainer_option_id,
                       COALESCE(pn.value, cr.course_sku) AS course_title,
                       $trainerName AS trainer_name
                  FROM " . $this->_table('course_runs') . " cr
             LEFT JOIN " . $this->_table('catalog_product_entity_varchar') . " pn
                       ON pn.entity_id = cr.product_id AND pn.store_id = 0 AND pn.attribute_id = $nameAttr
             LEFT JOIN " . $this->_table('admin/user') . " au ON au.user_id = cr.trainer_user_id
             LEFT JOIN " . $this->_table('eav_attribute_option_value') . " tov
                       ON tov.option_id = cr.trainer_option_id AND tov.store_id = 0
                 WHERE (" . implode(' OR ', $match) . ")";
    }

    /** Runs whose TMS handover names this account as one of the trainers. */
    protected function _handoverRunIds($userId)
    {
        $handover = Mage::helper('mmd_rolemanager/handover');
        if (!$handover->available()) {
            return array();
        }
        $out = array();
        foreach ($this->_read()->fetchAll(
            'SELECT run_id, result_json FROM ' . $this->_table('mmd_tms_run_link') . ' WHERE active = 1'
        ) as $link) {
            $result = json_decode((string) $link['result_json'], true) ?: array();
            $ids    = isset($result['trainer_user_ids']) ? array_map('intval', (array) $result['trainer_user_ids']) : array();
            if (in_array((int) $userId, $ids, true)) {
                $out[] = (int) $link['run_id'];
            }
        }
        return $out;
    }

    protected function _runs($email, $pastDays = self::PAST_DAYS)
    {
        $identity = $this->_h()->trainerIdentity($email);
        if (!$identity) {
            return array();
        }
        $bind   = array();
        $sql    = $this->_runSelect($identity, $bind);
        $bind[] = date('Y-m-d', strtotime($this->_h()->today() . ' -' . (int) $pastDays . ' days'));
        $handover = Mage::helper('mmd_rolemanager/handover');
        $rows = array();
        foreach ($this->_read()->fetchAll(
            $sql . " AND (cr.course_start_date IS NULL OR COALESCE(cr.course_end_date, cr.course_start_date) >= ?)
                     ORDER BY cr.course_start_date",
            $bind
        ) as $r) {
            if ($handover->isActive((int) $r['run_id'])) {
                $rows[] = $r;
            }
        }
        return $rows;
    }

    protected function _run($email, $runId)
    {
        $runId    = (int) $runId;
        $identity = $this->_h()->trainerIdentity($email);
        if ($runId <= 0 || !$identity || !Mage::helper('mmd_rolemanager/handover')->isActive($runId)) {
            return null;
        }
        $bind   = array();
        $sql    = $this->_runSelect($identity, $bind);
        $bind[] = $runId;
        return $this->_read()->fetchRow($sql . ' AND cr.run_id = ? LIMIT 1', $bind) ?: null;
    }

    protected function _enrolmentCounts(array $runIds)
    {
        $runIds = array_filter(array_map('intval', $runIds));
        if (!$runIds) {
            return array();
        }
        $out = array();
        foreach ($this->_read()->fetchAll(
            'SELECT run_id, COUNT(DISTINCT LOWER(TRIM(learner_email))) AS n FROM ' . $this->_table('course_run_enrolments') .
            ' WHERE run_id IN (' . implode(',', $runIds) . ') GROUP BY run_id'
        ) as $r) {
            $out[(int) $r['run_id']] = (int) $r['n'];
        }
        return $out;
    }

    protected function _classRow(array $r, $today, array $images)
    {
        $start = $this->_ymd($r['course_start_date']);
        $end   = $this->_ymd($r['course_end_date']) ?: $start;
        $mode  = (int) $r['mode_of_training'];
        $venue = array_filter(array_map('trim', array(
            (string) $r['venue_block'], (string) $r['venue_street'],
            trim(($r['venue_floor'] ? '#' . $r['venue_floor'] : '') . ($r['venue_unit'] ? '-' . $r['venue_unit'] : '')),
            (string) $r['venue_building'], (string) $r['postal_code'],
        )));
        $link = trim((string) $r['virtual_link']);
        if ($link === '') {
            $link = (string) $this->_read()->fetchOne(
                'SELECT google_meet_url FROM ' . $this->_table('course_courseware') . ' WHERE product_id = ?',
                array((int) $r['product_id'])
            );
        }
        $days = array();
        foreach (Mage::helper('mmd_attendance')->sessionsForRun($r) as $s) {
            if ((string) $s['date'] !== '') $days[$s['date']] = true;
        }
        if ($start === '') {
            $bucket = 'upcoming';
        } elseif ($start > $today) {
            $bucket = 'upcoming';
        } else {
            $bucket = $end < $today ? 'past' : 'current';
        }
        return array(
            'run_id'       => (int) $r['run_id'],
            'class_id'     => (string) $r['class_id'],
            'product_id'   => (int) $r['product_id'],
            'sku'          => (string) $r['course_sku'],
            'title'        => trim((string) $r['course_title']),
            'start_date'   => $start,
            'end_date'     => $end,
            'start_time'   => $this->_hm($r['course_start_time']),
            'end_time'     => $this->_hm($r['course_end_time']),
            'mode'         => isset($this->_modes[$mode]) ? $this->_modes[$mode] : 'Classroom',
            'venue'        => $mode === 2 ? '' : implode(', ', $venue),
            'room'         => (string) $r['room'],
            'virtual_link' => $mode === 1 ? '' : $link,
            'trainer'      => trim((string) $r['trainer_name']),
            'status'       => 'confirmed',
            'order_no'     => null,
            'bucket'       => $bucket,
            'days'         => array_keys($days),
            'image_url'    => isset($images[(int) $r['product_id']]) ? $images[(int) $r['product_id']] : '',
            'certificate'  => null,
            'survey_submitted' => null,
            'role'         => 'trainer',
        );
    }

    protected function _materialsFor($productId)
    {
        // Only columns this site's table has: a link type added later must never break the class screen.
        $table = $this->_table('course_courseware');
        $cols  = array_values(array_intersect(array_keys($this->_materials), array_keys($this->_read()->describeTable($table))));
        $row   = $cols ? $this->_read()->fetchRow(
            'SELECT ' . implode(',', $cols) . ' FROM ' . $table . ' WHERE product_id = ?',
            array((int) $productId)
        ) : null;
        $out = array();
        foreach ($this->_materials as $col => $label) {
            $url = ($row && isset($row[$col])) ? trim((string) $row[$col]) : '';
            if ($url !== '' && preg_match('#^https?://#i', $url)) {
                $out[] = array('key' => $col, 'title' => $label, 'url' => $url);
            }
        }
        return $out;
    }

    protected function _documents($productId)
    {
        $out = array();
        foreach ($this->_read()->fetchAll(
            'SELECT filename, file_url FROM ' . $this->_table('course_documents') .
            ' WHERE product_id = ? ORDER BY created_at DESC LIMIT 50',
            array((int) $productId)
        ) as $d) {
            $url = trim((string) $d['file_url']);
            if ($url === '') continue;
            if (!preg_match('#^https?://#i', $url)) {
                $url = rtrim(Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB), '/') . '/' . ltrim($url, '/');
            }
            $out[] = array('key' => null, 'title' => (string) $d['filename'], 'url' => $url);
        }
        return $out;
    }

    protected function _surveyResponses($runId)
    {
        try {
            return (int) $this->_read()->fetchOne(
                'SELECT COUNT(*) FROM ' . $this->_table('mmd_feedback_review_run') . ' WHERE run_id = ?', array((int) $runId)
            );
        } catch (Exception $e) {
            return 0;
        }
    }

    protected function _imagesByProduct()
    {
        try {
            $out = array();
            foreach (Mage::helper('mmd_mobileapi/catalog')->courses()['courses'] as $c) {
                if (!empty($c['image_url'])) $out[(int) $c['id']] = (string) $c['image_url'];
            }
            return $out;
        } catch (Exception $e) {
            return array();
        }
    }

    protected function _ymd($v)
    {
        $v = (string) $v;
        return ($v === '' || strpos($v, '0000-00-00') === 0) ? '' : substr($v, 0, 10);
    }

    protected function _hm($v)
    {
        $v = (string) $v;
        return ($v === '' || $v === '00:00:00') ? '' : substr($v, 0, 5);
    }

    /** @return MMD_MobileApi_Helper_Data */
    protected function _h()
    {
        return Mage::helper('mmd_mobileapi');
    }

    protected function _read()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    protected function _write()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_write');
    }

    protected function _table($name)
    {
        return Mage::getSingleton('core/resource')->getTableName($name);
    }
}
