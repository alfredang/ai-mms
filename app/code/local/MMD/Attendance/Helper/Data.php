<?php
class MMD_Attendance_Helper_Data extends Mage_Core_Helper_Abstract
{
    /** Roles allowed to take/view attendance. */
    public function allowedRoles()
    {
        return array('trainer', 'training_provider', 'admin', 'developer');
    }

    public function isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed($this->allowedRoles());
    }

    public function getCurrentAdminId()
    {
        $u = Mage::getSingleton('admin/session')->getUser();
        return $u ? (int) $u->getId() : null;
    }

    // ── Sessions (per-day AM/PM) ─────────────────────────────────────────────

    /**
     * Session list for a run: every class day has an AM and a PM session, so a
     * 2-day class yields d1am, d1pm, d2am, d2pm. Class days come from the
     * order items' explicit day list when one exists ("18/19/25/26 Jul 2026"
     * — weekend classes are NOT contiguous), else the contiguous
     * course_start_date..course_end_date span; no usable dates -> one day.
     *
     * @param array $run row with product_id / course_start_date / course_end_date
     * @return array rows: key ('d1am'), day (1), ampm ('AM'), date ('Y-m-d'|''), label
     */
    public function sessionsForRun($run)
    {
        $imported = Mage::helper('mmd_rolemanager/handover')->sessions(isset($run['run_id']) ? $run['run_id'] : 0);
        if ($imported) {
            $rows = array(); $days = array();
            foreach ($imported as $s) {
                if (!isset($days[$s['date']])) $days[$s['date']] = count($days) + 1;
                $rows[] = array('key'=>$s['key'],'day'=>$days[$s['date']],'ampm'=>$s['start_time']<'12:00'?'AM':'PM','date'=>$s['date'],'start_time'=>$s['start_time'],'end_time'=>$s['end_time'],'label'=>date('D j M',strtotime($s['date'])) . ' ' . $s['start_time'] . '-' . $s['end_time']);
            }
            return $rows;
        }
        $days = $this->classDaysForRun($run);
        if (empty($days)) {
            $start   = isset($run['course_start_date']) ? (string) $run['course_start_date'] : '';
            $end     = isset($run['course_end_date'])   ? (string) $run['course_end_date']   : '';
            $startTs = ($start !== '' && $start !== '0000-00-00') ? strtotime($start) : 0;
            $endTs   = ($end !== '' && $end !== '0000-00-00') ? strtotime($end) : $startTs;
            $count   = 1;
            if ($startTs && $endTs && $endTs >= $startTs) {
                $count = (int) floor(($endTs - $startTs) / 86400) + 1;
            }
            if ($count < 1)  $count = 1;
            if ($count > 14) $count = 14; // sanity cap for bad legacy date ranges
            for ($d = 0; $d < $count; $d++) {
                $days[] = $startTs ? date('Y-m-d', strtotime('+' . $d . ' days', $startTs)) : '';
            }
        }

        // Malaysia: an evening class is ONE session per evening (partner rule,
        // Oct 2026). Day classes, and every class on other sites, keep AM + PM.
        $parts = $this->isEveningRun($run) ? array('ev' => 'Evening') : array('am' => 'AM', 'pm' => 'PM');

        $sessions = array();
        foreach ($days as $i => $date) {
            $d = $i + 1;
            foreach ($parts as $k => $lbl) {
                $sessions[] = array(
                    'key'   => 'd' . $d . $k,
                    'day'   => $d,
                    'ampm'  => $lbl,
                    'date'  => $date,
                    'label' => 'Day ' . $d . ($date ? ' · ' . date('D j M', strtotime($date)) : '') . ' · ' . $lbl,
                );
            }
        }
        return $sessions;
    }

    /**
     * The actual class days of a run as 'Y-m-d' dates, from the "Course Date"
     * custom option on its orders — the only place the explicit day list
     * ("18/19/25/26 Jul 2026", i.e. two weekends) survives; course_runs only
     * stores the start/end span. Empty when no order carries an explicit
     * same-month day list for this run's start date.
     */
    public function classDaysForRun($run)
    {
        $imported = Mage::helper('mmd_rolemanager/handover')->sessions(isset($run['run_id']) ? $run['run_id'] : 0);
        if ($imported) return array_values(array_unique(array_column($imported, 'date')));
        $productId = (int) (isset($run['product_id']) ? $run['product_id'] : 0);
        $startYmd  = isset($run['course_start_date']) ? (string) $run['course_start_date'] : '';
        if ($productId <= 0 || $startYmd === '' || $startYmd === '0000-00-00') {
            return array();
        }
        foreach ($this->_courseDateOptionsForProduct($productId) as $raw => $parsed) {
            if ($parsed === null || $parsed[0] !== $startYmd) continue;
            // Same-month multi-day list: "18/19/25/26 Jul 2026", "21.22 Feb
            // 2019", "4 & 11 July 2015". Ranges/cross-month fall through to
            // the contiguous span.
            if (!preg_match('/^(\d{1,2}(?:\s*[\/&.,]\s*\d{1,2})+)\s*([A-Za-z]{3,9})\s+(\d{4})/', trim((string) $raw), $m)) {
                continue;
            }
            $monthTs = strtotime('1 ' . $m[2] . ' ' . $m[3]);
            if (!$monthTs) continue;
            $days = array();
            foreach (preg_split('/[\/&.,]/', $m[1]) as $tok) {
                $tok = (int) trim($tok);
                if ($tok < 1 || $tok > 31) { $days = array(); break; }
                $days[] = date('Y-m-d', mktime(0, 0, 0, (int) date('n', $monthTs), $tok, (int) date('Y', $monthTs)));
            }
            if (count($days) >= 2 && count($days) <= 14 && $days === array_values(array_unique($days))
                && $days[0] === $startYmd) {
                return $days;
            }
        }
        return array();
    }

    /**
     * Distinct raw "Course Date" option values on this product's orders,
     * mapped to their parsed [start, end] (or null). Cached per request.
     */
    protected $_courseDateOptCache = array();

    protected function _courseDateOptionsForProduct($productId)
    {
        $productId = (int) $productId;
        if (isset($this->_courseDateOptCache[$productId])) {
            return $this->_courseDateOptCache[$productId];
        }
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $rows     = $read->fetchAll(
            "SELECT oi.product_options
               FROM " . $resource->getTableName('sales/order_item') . " oi
              WHERE oi.product_id = ? AND oi.parent_item_id IS NULL
              ORDER BY oi.item_id DESC
              LIMIT 2000",
            array($productId)
        );
        $svc = Mage::getSingleton('mmd_rolemanager/courseRunEnrolmentService');
        $out = array();
        foreach ($rows as $r) {
            $opts = @unserialize((string) $r['product_options']);
            if (!is_array($opts) || !isset($opts['options'])) continue;
            foreach ($opts['options'] as $o) {
                if (!isset($o['label']) || trim((string) $o['label']) !== 'Course Date') continue;
                $raw = isset($o['print_value']) && (string) $o['print_value'] !== ''
                    ? (string) $o['print_value']
                    : (isset($o['value']) ? (string) $o['value'] : '');
                if ($raw !== '' && !array_key_exists($raw, $out)) {
                    $out[$raw] = $svc ? $svc->_parseDate($raw) : null;
                }
            }
        }
        return $this->_courseDateOptCache[$productId] = $out;
    }

    /**
     * The session a learner self-marking "right now" belongs to: the last
     * class day on or before today (clamped to the class window), AM before
     * 13:00 store time.
     */
    public function currentSessionKey($run)
    {
        $imported = Mage::helper('mmd_rolemanager/handover')->sessions(isset($run['run_id']) ? $run['run_id'] : 0);
        if ($imported) {
            $now = Mage::getModel('core/date')->date('Y-m-d H:i');
            foreach ($imported as $s) {
                if ($now >= $s['date'] . ' ' . $s['start_time'] && $now <= $s['date'] . ' ' . $s['end_time']) return $s['key'];
            }
            return '';
        }
        $sessions = $this->sessionsForRun($run);
        $today    = Mage::getModel('core/date')->date('Y-m-d');
        $hour     = (int) Mage::getModel('core/date')->date('H');
        $ampm     = $hour < 13 ? 'am' : 'pm';

        $day = 1;
        foreach ($sessions as $s) {
            if ($s['date'] !== '' && $s['date'] <= $today) {
                $day = (int) $s['day'];
            }
        }
        return 'd' . $day . ($this->isEveningRun($run) ? 'ev' : $ampm);
    }

    // ── Malaysia class timetable (attendance by training hours) ──────────────

    /** True on the Malaysia site — the hours-based attendance rule is MY-only. */
    public function isMalaysiaSite()
    {
        return Mage::app()->getDefaultStoreView()->getCode() === 'malaysia';
    }

    /**
     * Class start/end times as 'HH:MM' ('' when unknown). Callers pass run rows
     * built by different SELECTs, so fetch the times when the row lacks them.
     */
    protected function _runTimes($run)
    {
        if (!array_key_exists('course_start_time', $run) && !empty($run['run_id'])) {
            $run += Mage::getSingleton('core/resource')->getConnection('core_read')->fetchRow(
                'SELECT course_start_time, course_end_time FROM '
                . Mage::getSingleton('core/resource')->getTableName('course_runs') . ' WHERE run_id = ?',
                array((int) $run['run_id'])
            ) ?: array();
        }
        $fmt = function ($t) { return preg_match('/^(\d{2}):(\d{2})/', (string) $t, $m) ? $m[1] . ':' . $m[2] : ''; };
        return array(
            $fmt(isset($run['course_start_time']) ? $run['course_start_time'] : ''),
            $fmt(isset($run['course_end_time'])   ? $run['course_end_time']   : ''),
        );
    }

    /**
     * Malaysia: the class has finished (its end date is before today, store time). Attendance changes after this
     * point are corrections and need a recorded reason (AttendanceController::saveAction). Always false elsewhere.
     */
    public function isFinishedRun($run)
    {
        if (!$this->isMalaysiaSite()) {
            return false;
        }
        $end = isset($run['course_end_date']) ? (string) $run['course_end_date'] : (string) Mage::getSingleton('core/resource')
            ->getConnection('core_read')->fetchOne('SELECT course_end_date FROM '
                . Mage::getSingleton('core/resource')->getTableName('course_runs') . ' WHERE run_id = ?', array((int) $run['run_id']));
        return $end !== '' && $end !== '0000-00-00' && $end < Mage::getModel('core/date')->date('Y-m-d');
    }

    /** Malaysia evening class (starts 17:00 or later) → one session per evening. */
    public function isEveningRun($run)
    {
        if (!$this->isMalaysiaSite()) {
            return false;
        }
        list($start) = $this->_runTimes($run);
        return $start !== '' && $start >= '17:00';
    }

    /**
     * Malaysia standard class times (partner rule, 22 Oct 2026). Daytime: 9:30-12:30 + 13:30-18:00 = 7.5 training
     * hours, for a course whose daily training hours (course duration ÷ class days) are 7.5; lunch 12:30-13:30 falls
     * between the sessions, so it is excluded. Evening: 17:30-21:30 = 4 hours per evening (the number of evenings
     * covers the course duration). Short 15-minute breaks stay inside the sessions and are not deducted. Any other
     * daytime hours are an exception (null): the class's timetable is entered on the E-Attendance page.
     *
     * @return array|null { kind: 'day'|'evening', daily_hours: float }
     */
    public function standardDayForRun($run)
    {
        if (!$this->isMalaysiaSite()) {
            return null;
        }
        if ($this->isEveningRun($run)) {
            return array('kind' => 'evening', 'daily_hours' => 4.0);
        }
        $pid = isset($run['product_id']) ? (int) $run['product_id'] : (int) Mage::getSingleton('core/resource')
            ->getConnection('core_read')->fetchOne('SELECT product_id FROM '
                . Mage::getSingleton('core/resource')->getTableName('course_runs') . ' WHERE run_id = ?', array((int) $run['run_id']));
        $raw   = $pid ? Mage::getResourceModel('catalog/product')->getAttributeRawValue($pid, 'duration', Mage::app()->getDefaultStoreView()->getId()) : '';
        $hours = (float) str_replace(array(' ', ','), array('', '.'), is_array($raw) ? '' : (string) $raw);
        $days  = count(array_unique(array_column($this->sessionsForRun($run), 'day')));
        if ($hours <= 0 || $days < 1) {
            return null;
        }
        return abs($hours / $days - 7.5) < 0.01 ? array('kind' => 'day', 'daily_hours' => 7.5) : null;
    }

    /**
     * The class timetable: every session with its start/end, non-training break and training minutes. Saved rows
     * (entered on the E-Attendance page) win. Otherwise a Malaysia class on the standard daytime or evening times
     * uses the standard timetable (standardDayForRun) with no action needed. Anything else is an exception: only the
     * class start / end are pre-filled and the rest is entered — break times are never assumed.
     *
     * @return array { sessions: [{key,label,date,start,end,break_minutes,training_minutes,confirmed}],
     *                 confirmed: bool (every session confirmed), total_minutes: int|null,
     *                 source: 'entered'|'standard'|'needed', daily_hours: float|null, exception: string }
     */
    public function timetableForRun($run)
    {
        list($classStart, $classEnd) = $this->_runTimes($run);
        $saved = array();
        foreach (Mage::getSingleton('core/resource')->getConnection('core_read')->fetchAll(
            'SELECT * FROM ' . Mage::getSingleton('core/resource')->getTableName('mmd_course_run_session') . ' WHERE run_id = ?',
            array((int) $run['run_id'])
        ) as $r) {
            $saved[$r['session_key']] = $r;
        }
        $hm  = function ($t) { return $t === null ? '' : substr((string) $t, 0, 5); };
        $std = $saved ? null : $this->standardDayForRun($run);

        $rows = array(); $allOk = true; $total = 0;
        foreach ($this->sessionsForRun($run) as $s) {
            $sv = isset($saved[$s['key']]) ? $saved[$s['key']] : null;
            $part = substr($s['key'], -2);
            if ($std) {
                $times = array('am' => array('09:30', '12:30', 180), 'pm' => array('13:30', '18:00', 270), 'ev' => array('17:30', '21:30', 240));
                $sv = array('start_time' => $times[$part][0], 'end_time' => $times[$part][1], 'break_minutes' => 0,
                            'training_minutes' => $times[$part][2], 'is_confirmed' => 1);
            }
            $ok = $sv && (int) $sv['is_confirmed'] === 1 && (int) $sv['training_minutes'] > 0;
            $rows[] = array(
                'key'              => $s['key'],
                'label'            => $s['label'],
                'date'             => $s['date'],
                'start'            => $sv ? $hm($sv['start_time']) : ($part === 'pm' ? '' : $classStart),
                'end'              => $sv ? $hm($sv['end_time'])   : ($part === 'am' ? '' : $classEnd),
                'break_minutes'    => $sv && $sv['break_minutes'] !== null ? (int) $sv['break_minutes'] : null,
                'training_minutes' => $ok ? (int) $sv['training_minutes'] : null,
                'confirmed'        => $ok,
            );
            $allOk = $allOk && $ok;
            $total += $ok ? (int) $sv['training_minutes'] : 0;
        }
        $allOk = $allOk && !empty($rows);
        return array('sessions' => $rows, 'confirmed' => $allOk, 'total_minutes' => $allOk ? $total : null,
            'source' => $saved ? 'entered' : ($std ? 'standard' : 'needed'),
            'kind' => $std ? $std['kind'] : null, 'daily_hours' => $std ? $std['daily_hours'] : null,
            'exception' => (!$saved && !$std) ? 'Not a standard 7.5-hour day' : '');
    }

    /**
     * Validate and save (confirm) the whole timetable of a class. Every session
     * must be given: start and end ('HH:MM', end after start), break minutes
     * (0 or more) leaving positive training time, and a morning that ends before
     * its afternoon starts. Training minutes = end - start - break.
     *
     * @param array $rows [{key, start, end, break_minutes}]
     * @throws Exception with a learner-readable message naming the session
     */
    public function saveTimetable($runId, array $rows, $adminId)
    {
        $res  = Mage::getSingleton('core/resource');
        $db   = $res->getConnection('core_write');
        $run  = $db->fetchRow('SELECT * FROM ' . $res->getTableName('course_runs') . ' WHERE run_id = ?', array((int) $runId));
        if (!$run) throw new Exception('Class not found.');

        $byKey = array();
        foreach ($rows as $r) {
            $byKey[strtolower(trim((string) (isset($r['key']) ? $r['key'] : '')))] = $r;
        }
        $toMin = function ($t) {
            return preg_match('/^([01]\d|2[0-3]):([0-5]\d)$/', trim((string) $t), $m) ? (int) $m[1] * 60 + (int) $m[2] : null;
        };

        $clean = array(); $dayWindow = array();
        foreach ($this->sessionsForRun($run) as $s) {
            $r = isset($byKey[$s['key']]) ? $byKey[$s['key']] : null;
            $start = $r ? $toMin(isset($r['start']) ? $r['start'] : '') : null;
            $end   = $r ? $toMin(isset($r['end']) ? $r['end'] : '') : null;
            $brk   = $r && isset($r['break_minutes']) && trim((string) $r['break_minutes']) !== '' ? $r['break_minutes'] : null;
            if ($start === null || $end === null) throw new Exception($s['label'] . ': enter a start and end time.');
            if ($end <= $start) throw new Exception($s['label'] . ': the end time must be after the start time.');
            if ($brk === null || !ctype_digit((string) $brk)) throw new Exception($s['label'] . ': enter the break in minutes (0 if none).');
            $brk = (int) $brk;
            if ($end - $start - $brk <= 0) throw new Exception($s['label'] . ': the break is longer than the session.');
            $part = substr($s['key'], -2);
            if ($part === 'am') $dayWindow[$s['day']]['am_end'] = $end;
            if ($part === 'pm') $dayWindow[$s['day']]['pm_start'] = $start;
            if (isset($dayWindow[$s['day']]['am_end'], $dayWindow[$s['day']]['pm_start'])
                && $dayWindow[$s['day']]['am_end'] > $dayWindow[$s['day']]['pm_start']) {
                throw new Exception('Day ' . $s['day'] . ': the morning must end before the afternoon starts.');
            }
            $clean[] = array(
                'run_id'                => (int) $runId,
                'session_key'           => $s['key'],
                'session_date'          => $s['date'] !== '' ? $s['date'] : null,
                'start_time'            => sprintf('%02d:%02d:00', intdiv($start, 60), $start % 60),
                'end_time'              => sprintf('%02d:%02d:00', intdiv($end, 60), $end % 60),
                'break_minutes'         => $brk,
                'training_minutes'      => $end - $start - $brk,
                'is_confirmed'          => 1,
                'confirmed_by_admin_id' => $adminId ?: null,
                'confirmed_at'          => Varien_Date::now(),
            );
        }
        if (!$clean) throw new Exception('This class has no sessions.');

        $tbl = $res->getTableName('mmd_course_run_session');
        foreach ($clean as $row) {
            $db->insertOnDuplicate($tbl, $row, array('session_date', 'start_time', 'end_time', 'break_minutes',
                'training_minutes', 'is_confirmed', 'confirmed_by_admin_id', 'confirmed_at'));
        }
        return $this->timetableForRun($run);
    }

    /* ensureRun() (WSQ/TGS run materialisation) was removed: classes are
       C-prefix-only since migration 846 — non-C course codes must never
       materialise a course_runs row, and every remaining caller was dropped
       with that change. */

    /**
     * Roster derived from order history: order items of the run's product
     * whose "Course Date" custom option parses to the run's start date. Used
     * when course_run_enrolments has no rows for the run — WSQ (TGS-) classes,
     * which the class-formation cron skips. Order = registration (axiom 4);
     * this is read-only on the sales tables.
     *
     * @return array rows: learner_name, learner_email (deduped by email)
     */
    public function orderRosterForRun($run)
    {
        $productId = (int) (isset($run['product_id']) ? $run['product_id'] : 0);
        $startYmd  = isset($run['course_start_date']) ? (string) $run['course_start_date'] : '';
        if ($productId <= 0 || $startYmd === '' || $startYmd === '0000-00-00') {
            return array();
        }

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $rows     = $read->fetchAll(
            "SELECT oi.product_options, o.customer_email, o.customer_firstname, o.customer_lastname
               FROM " . $resource->getTableName('sales/order_item') . " oi
               JOIN " . $resource->getTableName('sales/order') . " o ON o.entity_id = oi.order_id
              WHERE oi.product_id = ?
                AND oi.parent_item_id IS NULL
                AND o.state NOT IN ('canceled', 'closed')
              ORDER BY oi.item_id DESC
              LIMIT 2000",
            array($productId)
        );

        $svc = Mage::getSingleton('mmd_rolemanager/courseRunEnrolmentService');
        $out = array();
        foreach ($rows as $r) {
            $opts = @unserialize((string) $r['product_options']);
            if (!is_array($opts) || !isset($opts['options'])) continue;
            $rawDate = '';
            foreach ($opts['options'] as $o) {
                if (isset($o['label']) && trim((string) $o['label']) === 'Course Date') {
                    $rawDate = isset($o['print_value']) && (string) $o['print_value'] !== ''
                        ? (string) $o['print_value']
                        : (isset($o['value']) ? (string) $o['value'] : '');
                    break;
                }
            }
            if ($rawDate === '') continue;
            $dates = $svc ? $svc->_parseDate($rawDate) : null;
            if ($dates === null || $dates[0] !== $startYmd) continue;
            $email = strtolower(trim((string) $r['customer_email']));
            if ($email === '' || isset($out[$email])) continue;
            $out[$email] = array(
                'learner_name'  => trim((string) $r['customer_firstname'] . ' ' . (string) $r['customer_lastname']),
                'learner_email' => $email,
            );
        }
        return array_values($out);
    }

    /**
     * One class by run_id — same row shape as getClassList() but with NO
     * bucket / store / trainer filtering. Used when the attendance page is
     * opened from a class detail page with ?run_id=N: the trainer already
     * chose the class there, so it must load even if the list filters would
     * have hidden it (wrong bucket, store prefix, or trainer mapping gap).
     *
     * @param int $runId
     * @return array|null
     */
    public function getClassRow($runId)
    {
        $runId = (int) $runId;
        if ($runId <= 0) {
            return null;
        }
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $runsTbl  = $resource->getTableName('course_runs');
        $enrolTbl = $resource->getTableName('course_run_enrolments');
        $pVarchar = $resource->getTableName('catalog_product_entity_varchar');
        $eavOptVal= $resource->getTableName('eav_attribute_option_value');
        $eavAttr  = $resource->getTableName('eav_attribute');
        $eavType  = $resource->getTableName('eav_entity_type');
        $auTbl    = $resource->getTableName('admin_user');

        $nameAttrId = (int) $read->fetchOne(
            "SELECT a.attribute_id FROM `$eavAttr` a
               JOIN `$eavType` t ON t.entity_type_id = a.entity_type_id
              WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name'"
        );

        $row = $read->fetchRow(
            "SELECT cr.run_id, cr.class_id, cr.course_sku, cr.product_id,
                    cr.course_start_date, cr.course_end_date,
                    cr.course_start_time, cr.course_end_time,
                    COALESCE(pn.value, cr.course_sku) AS course_title,
                    COALESCE(en.enrolled, 0) AS enrolled,
                    COALESCE(
                        NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))), ''),
                        tov.value, ''
                    ) AS trainer_name
               FROM `$runsTbl` cr
               LEFT JOIN `$pVarchar` pn
                    ON pn.entity_id = cr.product_id AND pn.store_id = 0 AND pn.attribute_id = $nameAttrId
               LEFT JOIN (SELECT run_id, COUNT(*) AS enrolled FROM `$enrolTbl` GROUP BY run_id) en
                    ON en.run_id = cr.run_id
               LEFT JOIN `$auTbl` au
                    ON au.user_id = cr.trainer_user_id
               LEFT JOIN `$eavOptVal` tov
                    ON tov.option_id = cr.trainer_option_id AND tov.store_id = 0
              WHERE cr.run_id = ?",
            array($runId)
        );
        return $row ?: null;
    }

    /**
     * Classes for the selector.
     *
     * @param string $bucket 'active' (ongoing + upcoming) | 'completed'
     * @return array rows: run_id, class_id, course_sku, course_title, product_id,
     *               course_start_date, course_end_date, enrolled, trainer_name
     */
    public function getClassList($bucket = 'active')
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $runsTbl  = $resource->getTableName('course_runs');
        $enrolTbl = $resource->getTableName('course_run_enrolments');
        $pVarchar = $resource->getTableName('catalog_product_entity_varchar');
        $eavOptVal= $resource->getTableName('eav_attribute_option_value');
        $eavAttr  = $resource->getTableName('eav_attribute');
        $eavType  = $resource->getTableName('eav_entity_type');
        $auTbl    = $resource->getTableName('admin_user');

        $nameAttrId = (int) $read->fetchOne(
            "SELECT a.attribute_id FROM `$eavAttr` a
               JOIN `$eavType` t ON t.entity_type_id = a.entity_type_id
              WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name'"
        );
        if (!$nameAttrId) {
            return array();
        }

        $today = Mage::getModel('core/date')->date('Y-m-d');
        if ($bucket === 'completed') {
            $where   = "cr.course_end_date < " . $read->quote($today);
            $orderBy = "cr.course_end_date DESC, cr.course_start_date DESC";
        } else {
            // active = ongoing + upcoming
            $where   = "(cr.course_end_date IS NULL OR cr.course_end_date >= " . $read->quote($today) . ")";
            $orderBy = "cr.course_start_date ASC, cr.course_start_time ASC";
        }

        // No store-scope filter: class_ids use the uniform 'C' prefix on every
        // site (one store per site), so every run in this DB belongs here.
        $whereStore = '';

        $rows = $read->fetchAll(
            "SELECT cr.run_id, cr.class_id, cr.course_sku, cr.product_id,
                    cr.course_start_date, cr.course_end_date,
                    cr.course_start_time, cr.course_end_time,
                    COALESCE(pn.value, cr.course_sku) AS course_title,
                    COALESCE(en.enrolled, 0) AS enrolled,
                    -- Phase 2: account-confirmed trainer (trainer_user_id) wins,
                    -- legacy EAV (trainer_option_id) is the fallback.
                    COALESCE(
                        NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))), ''),
                        tov.value, ''
                    ) AS trainer_name
               FROM `$runsTbl` cr
               LEFT JOIN `$pVarchar` pn
                    ON pn.entity_id = cr.product_id AND pn.store_id = 0 AND pn.attribute_id = $nameAttrId
               LEFT JOIN (SELECT run_id, COUNT(*) AS enrolled FROM `$enrolTbl` GROUP BY run_id) en
                    ON en.run_id = cr.run_id
               LEFT JOIN `$auTbl` au
                    ON au.user_id = cr.trainer_user_id
               LEFT JOIN `$eavOptVal` tov
                    ON tov.option_id = cr.trainer_option_id AND tov.store_id = 0
              WHERE cr.course_start_date IS NOT NULL
                AND $where
                $whereStore
              ORDER BY $orderBy"
        );

        // Trainer role: restrict to classes assigned to this trainer.
        $roleCode = Mage::helper('mmd_rolemanager')->getActiveRoleCode();
        if ($roleCode === 'trainer') {
            $rows = $this->_filterToTrainer($rows);
        }
        return $rows;
    }

    /**
     * Keep only rows whose trainer matches the logged-in trainer (by email via
     * courses_trainers, or by full-name fallback against admin_user).
     */
    protected function _filterToTrainer(array $rows)
    {
        $session = Mage::getSingleton('admin/session');
        $user    = $session->getUser();
        if (!$user) return array();
        $uid   = (int) $user->getId();
        $email = strtolower(trim((string) $user->getEmail()));
        $name  = strtolower(trim($user->getFirstname() . ' ' . $user->getLastname()));

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $ctTbl    = $resource->getTableName('courses_trainers');

        // option_ids whose courses_trainers.email matches this trainer
        $myOptionIds = array();
        try {
            $ids = $read->fetchCol(
                "SELECT relation_id FROM `$ctTbl` WHERE LOWER(TRIM(email)) = ?",
                array($email)
            );
            foreach ($ids as $id) $myOptionIds[(int)$id] = true;
        } catch (Exception $e) { /* non-fatal */ }

        $out = array();
        foreach ($rows as $r) {
            $run = $read->fetchRow(
                "SELECT trainer_option_id, trainer_user_id FROM " . $resource->getTableName('course_runs') . " WHERE run_id = ?",
                array((int)$r['run_id'])
            );
            $optId   = (int) (isset($run['trainer_option_id']) ? $run['trainer_option_id'] : 0);
            $runUid  = (int) (isset($run['trainer_user_id'])   ? $run['trainer_user_id']   : 0);
            // Phase 2: account-confirmed assignment to THIS trainer wins; then
            // the legacy EAV email match; then the name fallback.
            $matchAccount = $uid > 0 && $runUid === $uid;
            $matchEmail   = $optId && isset($myOptionIds[$optId]);
            $matchName    = $name !== '' && strtolower(trim((string)$r['trainer_name'])) === $name;
            if ($matchAccount || $matchEmail || $matchName) {
                $out[] = $r;
            }
        }
        return $out;
    }

    // ── Learner self-mark (dashboard, login-based) ───────────────────────────

    /** Email of the logged-in dashboard user (the self-marking learner). */
    public function getActiveLearnerEmail()
    {
        $u = Mage::getSingleton('admin/session')->getUser();
        return $u ? strtolower(trim((string) $u->getEmail())) : '';
    }

    /**
     * Self-mark is allowed only within the class window: start date through end
     * date + 1 day grace (end-of-day / next-morning still works). No usable
     * dates -> can't gate, so allow. Mirrors the MMS-native attendance window.
     */
    public function isWithinAttendanceWindow($run)
    {
        if (!Mage::helper('mmd_rolemanager/handover')->isActive(isset($run['run_id']) ? $run['run_id'] : 0)) return false;
        if (Mage::helper('mmd_rolemanager/handover')->isManaged(isset($run['run_id']) ? $run['run_id'] : 0)) return $this->currentSessionKey($run) !== '';
        $start = isset($run['course_start_date']) ? (string) $run['course_start_date'] : '';
        $end   = isset($run['course_end_date'])   ? (string) $run['course_end_date']   : '';
        if ($start === '' || $start === '0000-00-00') {
            return true;
        }
        $today = Mage::getModel('core/date')->date('Y-m-d');
        if ($today < $start) {
            return false;
        }
        $base = ($end !== '' && $end !== '0000-00-00') ? $end : $start;
        return $today <= date('Y-m-d', strtotime($base . ' +1 day'));
    }

    /** Load a run (+ course title + trainer) for the self-mark confirm page. */
    public function loadRunForSelfMark($runId)
    {
        $runId = (int) $runId;
        if ($runId <= 0) {
            return null;
        }
        $resource  = Mage::getSingleton('core/resource');
        $read      = $resource->getConnection('core_read');
        $runsTbl   = $resource->getTableName('course_runs');
        $pVarchar  = $resource->getTableName('catalog_product_entity_varchar');
        $auTbl     = $resource->getTableName('admin_user');
        $eavOptVal = $resource->getTableName('eav_attribute_option_value');
        $nameAttrId = (int) $read->fetchOne(
            "SELECT a.attribute_id FROM " . $resource->getTableName('eav_attribute') . " a
               JOIN " . $resource->getTableName('eav_entity_type') . " t ON t.entity_type_id = a.entity_type_id
              WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name'"
        );
        $run = $read->fetchRow(
            "SELECT cr.run_id, cr.class_id, cr.course_sku, cr.product_id,
                    cr.course_start_date, cr.course_end_date,
                    COALESCE(pn.value, cr.course_sku) AS course_title,
                    COALESCE(NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))),''), tov.value, '') AS trainer_name
               FROM `$runsTbl` cr
               LEFT JOIN `$pVarchar` pn ON pn.entity_id = cr.product_id AND pn.store_id = 0 AND pn.attribute_id = $nameAttrId
               LEFT JOIN `$auTbl` au ON au.user_id = cr.trainer_user_id
               LEFT JOIN `$eavOptVal` tov ON tov.option_id = cr.trainer_option_id AND tov.store_id = 0
              WHERE cr.run_id = ?",
            array($runId)
        );
        return $run ?: null;
    }

    /**
     * Self-mark context for the confirm page: the run + this learner's status.
     * Returns array(run, learner_email, enrolled, within_window, already_present)
     * or null if the run doesn't exist.
     */
    public function getSelfMarkContext($runId, $email = null)
    {
        $run = $this->loadRunForSelfMark($runId);
        if (!$run) {
            return null;
        }
        $email    = ($email === null) ? $this->getActiveLearnerEmail() : strtolower(trim((string) $email));
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $enrolTbl = $resource->getTableName('course_run_enrolments');
        $attTbl   = $resource->getTableName('mmd_course_run_attendance');
        $sessionKey = $this->currentSessionKey($run);

        $enrolled = $email !== '' && (int) $read->fetchOne(
            "SELECT enrolment_id FROM `$enrolTbl` WHERE run_id = ? AND LOWER(learner_email) = ? LIMIT 1",
            array((int) $run['run_id'], $email)
        ) > 0;
        if (!$enrolled && $email !== '') {
            // WSQ (TGS-) classes have no materialised enrolments — the order
            // itself is the registration, so an order for this run counts.
            foreach ($this->orderRosterForRun($run) as $r) {
                if ($r['learner_email'] === $email) { $enrolled = true; break; }
            }
        }
        // Present for the CURRENT session (each day has an AM and a PM session).
        $present = $email !== '' && (int) $read->fetchOne(
            "SELECT is_present FROM `$attTbl` WHERE run_id = ? AND LOWER(learner_email) = ? AND session_key = ? LIMIT 1",
            array((int) $run['run_id'], $email, $sessionKey)
        ) === 1;

        return array(
            'run'             => $run,
            'learner_email'   => $email,
            'session_key'     => $sessionKey,
            'enrolled'        => $enrolled,
            'within_window'   => $this->isWithinAttendanceWindow($run),
            'already_present' => $present,
        );
    }

    /**
     * Mark the logged-in learner present for $runId. Guards: must be enrolled in
     * the run AND within the date window. Idempotent upsert. Returns
     * array(success, message).
     */
    public function selfMarkPresent($runId, $email = null)
    {
        $ctx = $this->getSelfMarkContext($runId, $email);
        if (!$ctx) {
            return array('success' => false, 'message' => 'Class not found.');
        }
        if ($ctx['learner_email'] === '') {
            return array('success' => false, 'message' => 'Your account has no email on file.');
        }
        if (!$ctx['enrolled']) {
            return array('success' => false, 'message' => 'You are not on this class roster. Please contact your trainer.');
        }
        if (!$ctx['within_window']) {
            return array('success' => false, 'message' => 'Check-in is not open for this class right now.');
        }

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $enrolTbl = $resource->getTableName('course_run_enrolments');
        $attTbl   = $resource->getTableName('mmd_course_run_attendance');
        $run      = $ctx['run'];
        $email    = $ctx['learner_email'];

        $enrol = $read->fetchRow(
            "SELECT learner_name, learner_email FROM `$enrolTbl` WHERE run_id = ? AND LOWER(learner_email) = ? LIMIT 1",
            array((int) $run['run_id'], $email)
        );
        $name = $enrol ? trim((string) $enrol['learner_name']) : '';
        if ($name === '') {
            // WSQ classes have no enrolment row — take the name off the order.
            foreach ($this->orderRosterForRun($run) as $r) {
                if ($r['learner_email'] === $email) { $name = $r['learner_name']; break; }
            }
        }
        // Write the SAME row a trainer's manual "present" marking produces
        // (AttendanceController::saveAction): is_present=1, reason cleared,
        // marked_by_admin_id = the account that did the marking (here the
        // learner's own dashboard account). is_walkin stays 0 (enrolled learner).
        // Marks the CURRENT session only (today's day index, AM/PM by time).
        $write->insertOnDuplicate(
            $attTbl,
            array(
                'run_id'             => (int) $run['run_id'],
                'class_id'           => $run['class_id'] ?: null,
                'learner_email'      => $enrol ? $enrol['learner_email'] : $email,
                'session_key'        => $ctx['session_key'],
                'learner_name'       => $name,
                'is_present'         => 1,
                'reason_of_absence'  => null,
                'marked_by_admin_id' => $this->getCurrentAdminId(),
            ),
            array('is_present', 'learner_name', 'reason_of_absence', 'marked_by_admin_id')
        );
        return array('success' => true, 'message' => 'You have been marked present. Thank you!');
    }
}
