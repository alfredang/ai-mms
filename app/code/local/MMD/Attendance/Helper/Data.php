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
        $ampm     = $hour < 12 ? 'am' : 'pm';                    // PM starts at 12:00 (see autoSessionKey)

        $day = 1;
        foreach ($sessions as $s) {
            if ($s['date'] !== '' && $s['date'] <= $today) {
                $day = (int) $s['day'];
            }
        }
        return 'd' . $day . ($this->isEveningRun($run) ? 'ev' : $ampm);
    }

    /**
     * Session for the class-wide (auto) check-in QR, picked by the clock on a class day:
     * AM 08:00-11:59, PM 12:00-17:59 (user rule 2026-11-26). '' outside those hours or on
     * a day the class does not run, so the scan is refused rather than marking a wrong
     * session. Imported timetables (TMS handover) and Malaysia evening classes keep their
     * own session times (currentSessionKey).
     */
    public function autoSessionKey($run)
    {
        if (Mage::helper('mmd_rolemanager/handover')->sessions(isset($run['run_id']) ? $run['run_id'] : 0)
            || $this->isEveningRun($run)) {
            return $this->currentSessionKey($run);
        }
        $now  = Mage::getModel('core/date')->date('H:i');
        $part = ($now >= '08:00' && $now < '12:00') ? 'AM' : (($now >= '12:00' && $now < '18:00') ? 'PM' : '');
        if ($part === '') return '';
        $today    = Mage::getModel('core/date')->date('Y-m-d');
        $sessions = $this->sessionsForRun($run);
        $dated    = false;
        foreach ($sessions as $s) {
            if ($s['date'] !== '') $dated = true;
            if ($s['date'] === $today && $s['ampm'] === $part) return $s['key'];
        }
        return $dated ? '' : 'd1' . strtolower($part);              // legacy run without dates
    }

    /**
     * Find a learner's storefront account by email, or create one (no email is sent). Used by the attendance page's
     * walk-in add and by the Agent API's add_learner. For an EXISTING account its own name is authoritative, so the
     * roster never disagrees with the account. Returns array('id' => int|null, 'name' => string).
     */
    public function ensureLearnerAccount($name, $email, $websiteId)
    {
        try {
            $customer = Mage::getModel('customer/customer')->setWebsiteId($websiteId);
            $customer->loadByEmail($email);
            if ($customer->getId()) {
                $existingName = trim($customer->getFirstname() . ' ' . $customer->getLastname());
                return array('id' => (int) $customer->getId(), 'name' => ($existingName !== '' ? $existingName : $name));
            }

            // Split name into first/last.
            $parts = preg_split('/\s+/', trim($name), 2);
            $first = $parts[0] !== '' ? $parts[0] : 'Learner';
            $last  = isset($parts[1]) && $parts[1] !== '' ? $parts[1] : '-';

            $store = Mage::app()->getWebsite($websiteId)->getDefaultStore();
            $customer = Mage::getModel('customer/customer');
            $customer->setWebsiteId($websiteId)
                     ->setStoreId($store ? $store->getId() : 0)
                     ->setFirstname($first)
                     ->setLastname($last)
                     ->setEmail($email)
                     ->setForceConfirmed(true);
            $customer->setPassword($customer->generatePassword(10));
            $customer->save();
            return array('id' => (int) $customer->getId(), 'name' => trim($first . ' ' . $last));
        } catch (Exception $e) {
            Mage::log('Attendance walk-in customer create failed: ' . $e->getMessage(), Zend_Log::WARN, 'attendance.log');
            return array('id' => null, 'name' => $name, 'error' => $e->getMessage());
        }
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

    /** Is the logged-in user the trainer assigned to this class? */
    public function isRunTrainer($runId)
    {
        $row = $this->getClassRow($runId);
        return $row && count($this->_filterToTrainer(array($row))) === 1;
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
     * or null if the run doesn't exist. $sessionKey = a specific session (the
     * per-session check-in QR); null = the session running right now.
     */
    public function getSelfMarkContext($runId, $email = null, $sessionKey = null)
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
        $sessionKey = $sessionKey !== null ? (string) $sessionKey : $this->currentSessionKey($run);

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
     * array(success, message). $markedByAdminId defaults to the dashboard
     * session's account; the native learner apps (no admin session) pass the
     * learner's own shadow admin_user id.
     */
    public function selfMarkPresent($runId, $email = null, $markedByAdminId = null, $sessionKey = null)
    {
        $ctx = $this->getSelfMarkContext($runId, $email, $sessionKey);
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
        // Marks ONE session: the given one, else the current (today's day index, AM/PM by time).
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
                'marked_by_admin_id' => $markedByAdminId !== null ? (int) $markedByAdminId : $this->getCurrentAdminId(),
            ),
            array('is_present', 'learner_name', 'reason_of_absence', 'marked_by_admin_id')
        );
        return array('success' => true, 'message' => 'You have been marked present. Thank you!');
    }

    /**
     * Class roster + saved attendance: enrolments (order history for classes
     * without enrolments) UNION walk-ins recorded only in attendance. Shared by
     * the E-Attendance screen (load) and the .xlsx download (export).
     * @return array rows: learner_name, learner_email, learner_phone, is_walkin,
     *               att => [session_key => [p (0|1), r (reason), m (minutes), t (updated_at)]]
     */
    public function rosterForRun($run)
    {
        $runId    = (int) $run['run_id'];
        $helper   = $this;
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $enrolTbl = $resource->getTableName('course_run_enrolments');
        $attTbl   = $resource->getTableName('mmd_course_run_attendance');

        // Roster = enrolments UNION walk-in attendance rows not in enrolments.
        // WSQ (TGS-) classes have no materialised enrolments (the class-
        // formation cron skips TGS SKUs) — fall back to the order history,
        // which IS the registration record.
        $enrol = $read->fetchAll(
            "SELECT learner_name, learner_email, learner_phone FROM `$enrolTbl`
              WHERE run_id = ? ORDER BY learner_name",
            array($runId)
        );
        if (empty($enrol)) {
            $enrol = $helper->orderRosterForRun($run);
        }
        $att = $read->fetchAll(
            "SELECT learner_email, session_key, learner_name, is_present, minutes_attended, reason_of_absence, is_walkin, updated_at
               FROM `$attTbl` WHERE run_id = ?",
            array($runId)
        );
        // attByEmail[email] = ['name'=>…, 'is_walkin'=>…, 'att'=>[session_key=>['p'=>…,'r'=>…]]]
        $attByEmail = array();
        foreach ($att as $a) {
            $key = strtolower((string)$a['learner_email']);
            if ($key === '') continue;
            if (!isset($attByEmail[$key])) {
                $attByEmail[$key] = array(
                    'name'      => (string)$a['learner_name'],
                    'is_walkin' => 0,
                    'att'       => array(),
                );
            }
            if ((int)$a['is_walkin'] === 1) $attByEmail[$key]['is_walkin'] = 1;
            $attByEmail[$key]['att'][(string)$a['session_key']] = array(
                'p' => (int)$a['is_present'],
                'r' => (string)$a['reason_of_absence'],
                'm' => $a['minutes_attended'] === null ? '' : (string)(int)$a['minutes_attended'],
                't' => (string)$a['updated_at'],
            );
        }

        $roster = array();
        $seen   = array();
        foreach ($enrol as $e) {
            $key = strtolower((string)$e['learner_email']);
            if ($key === '' || isset($seen[$key])) continue;
            $seen[$key] = true;
            $a = isset($attByEmail[$key]) ? $attByEmail[$key] : null;
            $roster[] = array(
                'learner_name'  => $e['learner_name'],
                'learner_email' => $e['learner_email'],
                'learner_phone' => isset($e['learner_phone']) ? (string) $e['learner_phone'] : '',
                'is_walkin'     => 0,
                'att'           => $a ? $a['att'] : new stdClass(),
            );
        }
        // Walk-ins recorded in attendance but absent from enrolments.
        foreach ($attByEmail as $key => $a) {
            if (isset($seen[$key])) continue;
            if (Mage::helper('mmd_rolemanager/handover')->isManaged($runId) && !(int)$a['is_walkin']) continue;
            $seen[$key] = true;
            $roster[] = array(
                'learner_name'  => $a['name'],
                'learner_email' => $key,
                'is_walkin'     => (int)$a['is_walkin'],
                'att'           => $a['att'],
            );
        }
        return $roster;
    }

    // ── .xlsx download ───────────────────────────────────────────────────────

    /**
     * Signed attendance sheet (PDF, A4 landscape): Name, Email, Tel, then each session's finger signature
     * from the TC LMS app (Day 1 AM, Day 1 PM, ...), with a closing row for the trainer's name and signature
     * per session. A learner marked present without a signature shows "Present"; unmarked shows "Absent".
     * @return array(filename, bytes)
     */
    public function signedAttendancePdf($runId)
    {
        $run = $this->getClassRow($runId);
        if (!$run) {
            throw new Exception('Class not found.');
        }
        $sessions = $this->sessionsForRun($run);
        $roster   = $this->rosterForRun($run);
        usort($roster, function ($a, $b) { return strcasecmp((string) $a['learner_name'], (string) $b['learner_name']); });

        // Every signature of the class, with its image.
        $learnerSig = array(); $trainerSig = array(); $images = array();
        try {
            $res = Mage::getSingleton('core/resource');
            foreach ($res->getConnection('core_read')->fetchAll(
                'SELECT signature_id, signer_role, signer_email, signer_name, session_key, image_png FROM '
                . $res->getTableName('mmd_attendance_signature') . ' WHERE run_id = ? ORDER BY signed_at',
                array((int) $runId)
            ) as $r) {
                $var = 'sig' . (int) $r['signature_id'];
                $images[$var] = $r['image_png'];
                if ($r['signer_role'] === 'trainer') {
                    $trainerSig[$r['session_key']] = array('var' => $var, 'name' => (string) $r['signer_name']);
                } else {
                    $learnerSig[strtolower((string) $r['signer_email'])][$r['session_key']] = $var;
                }
            }
        } catch (Exception $e) {
            // Table not migrated yet on this site: no signatures.
        }

        $esc  = function ($v) { return htmlspecialchars((string) $v, ENT_QUOTES, 'UTF-8'); };
        $fmtD = function ($d) { return ($d && $d !== '0000-00-00') ? date('d M Y', strtotime($d)) : ''; };
        $img  = function ($var) { return '<img src="var:' . $var . '" style="max-height:11mm;max-width:24mm;" />'; };
        $dates = trim($fmtD($run['course_start_date']) . ' to ' . $fmtD($run['course_end_date']), ' to');
        $org   = (string) Mage::getStoreConfig('general/store_information/name');
        // Letterhead: company name + UEN from Company Settings (mmd_company/details/*). SG falls back to
        // Tertiary Infotech Academy; a partner site shows its own store name and a UEN only if it set one.
        $isSg    = Mage::app()->getDefaultStoreView()->getCode() === 'singapore';
        $company = trim((string) Mage::getStoreConfig('mmd_company/details/name'));
        $uen     = trim((string) Mage::getStoreConfig('mmd_company/details/uen'));
        if ($company === '') $company = $isSg ? 'Tertiary Infotech Academy Pte. Ltd.' : $org;
        if ($uen === '' && $isSg) $uen = '201200696W';
        $logo = Mage::getModuleDir('', 'MMD_CourseImage') . DS . 'assets' . DS . 'tertiary-mark.png';
        $logoTag = is_readable($logo) ? '<img src="var:tia_logo" style="width:14mm;height:14mm;" />' : '';
        if ($logoTag !== '') $images['tia_logo'] = (string) file_get_contents($logo);
        $letterhead = '<table class="lh"><tr>'
            . ($logoTag !== '' ? '<td style="width:17mm;">' . $logoTag . '</td>' : '')
            . '<td><div class="co">' . $esc($company) . '</div>' . ($uen !== '' ? '<div class="uen">UEN: ' . $esc($uen) . '</div>' : '') . '</td>'
            . '<td class="ttl">Attendance Sheet</td></tr></table>';

        $css = '<style>
            body{font-family:sans-serif;font-size:9pt;color:#0f172a;}
            h1{font-size:15pt;margin:0 0 2mm;}
            table.lh{width:100%;border-collapse:collapse;margin:0 0 3mm;border-bottom:0.5mm solid #1e3a8a;}
            table.lh td{vertical-align:middle;padding:0 0 2mm;}
            .co{font-size:13pt;font-weight:bold;color:#1e3a8a;}
            .uen{font-size:9pt;color:#475569;margin-top:0.5mm;}
            td.ttl{text-align:right;font-size:15pt;font-weight:bold;color:#0f172a;}
            .meta td{padding:0.6mm 4mm 0.6mm 0;font-size:9pt;}
            .meta td.k{color:#475569;font-weight:bold;}
            table.sheet{border-collapse:collapse;width:100%;margin-top:4mm;}
            table.sheet th{background:#1e3a8a;color:#fff;font-size:8pt;padding:1.5mm;border:0.2mm solid #1e3a8a;text-align:left;}
            table.sheet th.s{text-align:center;}
            table.sheet td{border:0.2mm solid #94a3b8;padding:1.2mm;font-size:8pt;vertical-align:middle;}
            table.sheet td.s{text-align:center;height:13mm;}
            .muted{color:#64748b;font-size:7.5pt;}
            .absent{color:#b91c1c;font-size:7.5pt;}
            tr.trainer td{border-top:0.5mm solid #1e3a8a;}
        </style>';

        $html = $css;
        $chunks = array_chunk($sessions, 6);   // at most 6 session columns per page
        foreach ($chunks as $ci => $chunk) {
            if ($ci > 0) {
                $html .= '<pagebreak />';
            }
            // Course info in the same order as the check-in QR: title, code, Course Run ID.
            $html .= $letterhead . '<table class="meta">'
                . '<tr><td class="k">Course Title</td><td>' . $esc($run['course_title']) . '</td><td class="k">Trainer</td><td>' . $esc($run['trainer_name']) . '</td></tr>'
                . '<tr><td class="k">Course Code</td><td>' . $esc($run['course_sku']) . '</td><td class="k">Dates</td><td>' . $esc($dates) . '</td></tr>'
                . '<tr><td class="k">Course Run ID</td><td>' . $esc($run['class_id']) . '</td><td class="k">Learners</td><td>' . count($roster)
                . (count($chunks) > 1 ? ' &nbsp; <span class="muted">(sessions ' . ($ci * 6 + 1) . '-' . ($ci * 6 + count($chunk)) . ' of ' . count($sessions) . ')</span>' : '') . '</td></tr>'
                . '</table>';
            $html .= '<table class="sheet"><thead><tr><th style="width:7mm;">#</th><th style="width:38mm;">Name</th><th style="width:50mm;">Email</th><th style="width:26mm;">Tel</th>';
            foreach ($chunk as $sx) {
                $html .= '<th class="s">' . $esc('Day ' . $sx['day'] . ' ' . $sx['ampm'])
                    . (!empty($sx['date']) ? '<br /><span style="font-weight:normal;">' . $esc(date('D j M', strtotime($sx['date']))) . '</span>' : '') . '</th>';
            }
            $html .= '</tr></thead><tbody>';
            if (!$roster) {
                $html .= '<tr><td colspan="' . (4 + count($chunk)) . '" class="muted">No learners on this class roster.</td></tr>';
            }
            foreach ($roster as $i => $r) {
                $email = strtolower((string) $r['learner_email']);
                $att   = (array) $r['att'];
                $html .= '<tr><td>' . ($i + 1) . '</td><td>' . $esc($r['learner_name']) . '</td><td>' . $esc($r['learner_email'])
                    . '</td><td>' . $esc(isset($r['learner_phone']) ? $r['learner_phone'] : '') . '</td>';
                foreach ($chunk as $sx) {
                    $k = $sx['key'];
                    if (isset($learnerSig[$email][$k])) {
                        $cell = $img($learnerSig[$email][$k]);
                    } elseif (!empty($att[$k]) && !empty($att[$k]['p'])) {
                        $cell = '<span class="muted">Present<br />(no signature)</span>';
                    } else {
                        $cell = '<span class="absent">Absent</span>';
                    }
                    $html .= '<td class="s">' . $cell . '</td>';
                }
                $html .= '</tr>';
            }
            $html .= '<tr class="trainer"><td colspan="4"><b>Trainer Name &amp; Signature</b></td>';
            foreach ($chunk as $sx) {
                $t = isset($trainerSig[$sx['key']]) ? $trainerSig[$sx['key']] : null;
                $html .= '<td class="s">' . ($t
                    ? $img($t['var']) . '<br /><span style="font-size:7pt;">' . $esc($t['name'] ?: $run['trainer_name']) . '</span>'
                    : '<span class="muted">' . $esc($run['trainer_name']) . '<br />(not signed)</span>') . '</td>';
            }
            $html .= '</tr></tbody></table>';
        }

        if (!class_exists('\\Mpdf\\Mpdf')) {
            $autoload = Mage::getBaseDir() . '/vendor/autoload.php';
            if (is_file($autoload)) require_once $autoload;
        }
        if (!class_exists('\\Mpdf\\Mpdf')) {
            throw new Exception('mPDF is not available.');
        }
        $tmp = Mage::getBaseDir('var') . DS . 'tmp' . DS . 'mpdf';
        if (!is_dir($tmp)) @mkdir($tmp, 0777, true);
        $mpdf = new \Mpdf\Mpdf(array(
            'mode' => 'utf-8', 'format' => 'A4-L', 'tempDir' => $tmp,
            'margin_left' => 10, 'margin_right' => 10, 'margin_top' => 10, 'margin_bottom' => 14, 'margin_footer' => 6,
        ));
        $mpdf->SetTitle('Attendance Sheet - ' . $run['class_id']);
        $mpdf->showImageErrors = false;
        foreach ($images as $var => $bytes) {
            $mpdf->imageVars[$var] = $bytes;
        }
        $mpdf->SetHTMLFooter('<table width="100%" style="font-size:7pt;color:#64748b;"><tr><td>'
            . $esc(trim($company . ' · Signatures captured at check-in (QR form or TC LMS app)')) . ' · Downloaded '
            . $esc(Mage::getModel('core/date')->date('d M Y g:i A')) . '</td><td align="right">Page {PAGENO} of {nbpg}</td></tr></table>');
        $mpdf->WriteHTML($html);
        $name = 'Attendance-Sheet-' . preg_replace('/[^A-Za-z0-9._-]+/', '-', (string) ($run['class_id'] ?: $run['run_id'])) . '.pdf';
        return array($name, $mpdf->Output('', \Mpdf\Output\Destination::STRING_RETURN));
    }

    /**
     * Attendance workbook for a class: one session ($sessionKey), or every
     * session (null) = a Summary sheet (one column per session, sessions
     * present, attendance %) followed by one detail sheet per session.
     * Unmarked counts as Absent, the same as the E-Attendance screen.
     * @return array(filename, bytes)
     */
    public function attendanceWorkbook($runId, $sessionKey = null)
    {
        $run = $this->getClassRow($runId);
        if (!$run) {
            throw new Exception('Class not found.');
        }
        $sessions = $this->sessionsForRun($run);
        if ($sessionKey !== null) {
            $sessions = array_values(array_filter($sessions, function ($s) use ($sessionKey) { return $s['key'] === $sessionKey; }));
            if (!$sessions) {
                throw new Exception('Session not found.');
            }
        }
        $roster = $this->rosterForRun($run);
        usort($roster, function ($a, $b) { return strcasecmp((string) $a['learner_name'], (string) $b['learner_name']); });
        $isMy = $this->isMalaysiaSite();
        $date = Mage::getModel('core/date');
        $fmtD = function ($d) { return ($d && $d !== '0000-00-00') ? date('d M Y', strtotime($d)) : ''; };
        $cell = function ($r, $key) {
            $att = (array) $r['att'];
            return isset($att[$key]) ? (array) $att[$key] : array('p' => 0, 'r' => '', 'm' => '', 't' => '');
        };
        $B = MMD_Attendance_Model_Xlsx::S_BOLD;
        $H = MMD_Attendance_Model_Xlsx::S_HEAD;
        $C = MMD_Attendance_Model_Xlsx::S_CELL;
        $info = function ($extra) use ($run, $fmtD, $B, $date) {
            $rows = array(
                array(array('v' => 'E-Attendance', 's' => $B)),
                array(array('v' => 'Class', 's' => $B), $run['class_id'] . ' - ' . $run['course_title']),
                array(array('v' => 'Course code', 's' => $B), (string) $run['course_sku']),
                array(array('v' => 'Dates', 's' => $B), trim($fmtD($run['course_start_date']) . ' to ' . $fmtD($run['course_end_date']), ' to')),
                array(array('v' => 'Trainer', 's' => $B), (string) $run['trainer_name']),
            );
            foreach ($extra as $k => $v) {
                $rows[] = array(array('v' => $k, 's' => $B), $v);
            }
            $rows[] = array(array('v' => 'Downloaded', 's' => $B), $date->date('d M Y g:i A'));
            $rows[] = array();
            return $rows;
        };

        $xlsx  = new MMD_Attendance_Model_Xlsx();
        $total = count($roster);
        if ($sessionKey === null) {
            $head = array('#', 'Learner', 'Email', 'Phone');
            foreach ($sessions as $s) $head[] = $s['label'];
            $head[] = 'Sessions Present';
            $head[] = 'Attendance %';
            $rows = $info(array('Sessions' => count($sessions), 'Learners' => $total));
            $freeze = count($rows) + 2;
            $rows[] = array_map(function ($h) use ($H) { return array('v' => $h, 's' => $H); }, $head);
            foreach ($roster as $i => $r) {
                $row = array(array('v' => $i + 1, 's' => $C), array('v' => (string) $r['learner_name'], 's' => $C),
                    array('v' => (string) $r['learner_email'], 's' => $C), array('v' => isset($r['learner_phone']) ? (string) $r['learner_phone'] : '', 's' => $C));
                $present = 0;
                foreach ($sessions as $s) {
                    $p = (int) $cell($r, $s['key'])['p'] === 1;
                    $present += $p ? 1 : 0;
                    $row[] = array('v' => $p ? 'Present' : 'Absent', 's' => $C);
                }
                $row[] = array('v' => $present, 's' => $C);
                $row[] = array('v' => count($sessions) ? (int) round(100 * $present / count($sessions)) : 0, 's' => $C);
                $rows[] = $row;
            }
            $widths = array(5, 28, 34, 16);
            foreach ($sessions as $s) $widths[] = max(12, min(26, mb_strlen($s['label']) + 2));
            $widths[] = 16;
            $widths[] = 14;
            $xlsx->addSheet('Summary', $rows, $widths, $freeze);
        }

        foreach ($sessions as $s) {
            $present = 0;
            foreach ($roster as $r) $present += (int) $cell($r, $s['key'])['p'] === 1 ? 1 : 0;
            $head = array('#', 'Learner', 'Email', 'Phone', 'Attendance', 'Reason of Absence');
            if ($isMy) $head[] = 'Actual Minutes';
            $head[] = 'Walk-in';
            $head[] = 'Last Updated';
            $rows = $info(array('Session' => $s['label'], 'Present' => $present . ' of ' . $total));
            $freeze = count($rows) + 2;
            $rows[] = array_map(function ($h) use ($H) { return array('v' => $h, 's' => $H); }, $head);
            foreach ($roster as $i => $r) {
                $a = $cell($r, $s['key']);
                $p = (int) $a['p'] === 1;
                $row = array(array('v' => $i + 1, 's' => $C), array('v' => (string) $r['learner_name'], 's' => $C),
                    array('v' => (string) $r['learner_email'], 's' => $C), array('v' => isset($r['learner_phone']) ? (string) $r['learner_phone'] : '', 's' => $C),
                    array('v' => $p ? 'Present' : 'Absent', 's' => $C), array('v' => $p ? '' : (string) $a['r'], 's' => $C));
                if ($isMy) $row[] = array('v' => $a['m'] === '' ? '' : (int) $a['m'], 's' => $C);
                $row[] = array('v' => !empty($r['is_walkin']) ? 'Yes' : '', 's' => $C);
                $row[] = array('v' => !empty($a['t']) ? $date->date('d M Y g:i A', $a['t']) : '', 's' => $C);
                $rows[] = $row;
            }
            $widths = array(5, 28, 34, 16, 12, 34);
            if ($isMy) $widths[] = 15;
            $widths[] = 9;
            $widths[] = 20;
            $xlsx->addSheet(str_replace(' · ', ' ', $s['label']), $rows, $widths, $freeze);
        }

        $name = 'Attendance_' . preg_replace('/[^A-Za-z0-9_-]+/', '', (string) $run['class_id'])
            . '_' . ($sessionKey === null ? 'all-sessions' : preg_replace('/[^A-Za-z0-9]+/', '-', str_replace(' · ', ' ', $sessions[0]['label']))) . '.xlsx';
        return array($name, $xlsx->toString());
    }

    // ── Public QR check-in (no login) ────────────────────────────────────────

    /** Signature of a check-in link: per session ('d1am'); '' = the old class-wide link. */
    public function checkinSig($runId, $sessionKey = '')
    {
        $key = (string) Mage::getConfig()->getNode('global/crypt/key');
        return substr(hash_hmac('sha256', 'attendance-checkin:' . (int) $runId . ($sessionKey !== '' ? ':' . $sessionKey : ''), $key), 0, 24);
    }

    /** Signed check-in link. No $sessionKey = the class-wide QR, session picked by autoSessionKey(). */
    public function checkinUrl($runId, $sessionKey = '')
    {
        $base = Mage::app()->getDefaultStoreView()->getBaseUrl(Mage_Core_Model_Store::URL_TYPE_LINK, true);
        return $base . 'checkin/index/index/run/' . (int) $runId . ($sessionKey !== '' ? '/s/' . $sessionKey : '')
            . '/k/' . $this->checkinSig($runId, $sessionKey) . '/';
    }

    /** The session row ('key','day','ampm','date','label') of a run, or null. */
    public function sessionForRun($run, $key)
    {
        foreach ($this->sessionsForRun($run) as $s) {
            if ($s['key'] === (string) $key) return $s;
        }
        return null;
    }

    /** "Day 1 AM"-style name of a session for the check-in form. */
    public function sessionShortLabel(array $s)
    {
        return preg_match('/^d\d+(am|pm|ev)$/', (string) $s['key'])
            ? 'Day ' . (int) $s['day'] . ' ' . $s['ampm'] . (!empty($s['date']) ? ' · ' . date('D j M', strtotime($s['date'])) : '')
            : (string) $s['label'];
    }

    /**
     * The learner of THIS class whose saved phone number matches $phone (digits
     * only, so "+65 9780 3795" finds "97803795"). Null when nobody or more than
     * one learner matches. Scoped to the class roster on purpose.
     * @return array|null learner_name, learner_email
     */
    public function checkinLearnerByPhone($runId, $phone)
    {
        $digits = preg_replace('/\D+/', '', (string) $phone);
        if (strlen($digits) < 8) {
            return null;
        }
        $resource = Mage::getSingleton('core/resource');
        $rows = $resource->getConnection('core_read')->fetchAll(
            "SELECT learner_name, learner_email, learner_phone FROM `" . $resource->getTableName('course_run_enrolments') . "`
              WHERE run_id = ? AND learner_phone IS NOT NULL AND learner_phone <> ''",
            array((int) $runId)
        );
        $hits = array();
        foreach ($rows as $r) {
            $d = preg_replace('/\D+/', '', (string) $r['learner_phone']);
            if (strlen($d) < 8) continue;
            if ($d === $digits || substr($d, -strlen($digits)) === $digits || substr($digits, -strlen($d)) === $d) {
                $hits[strtolower((string) $r['learner_email'])] = $r;
            }
        }
        return count($hits) === 1 ? reset($hits) : null;
    }

    /** "Day 1 AM"-style label of a session key for this run. */
    public function sessionLabel($run, $key)
    {
        foreach ($this->sessionsForRun($run) as $s) {
            if ($s['key'] === $key) return $s['label'];
        }
        return '';
    }

    /**
     * Check-in from the public QR form. A learner not yet on the class roster is
     * registered first (learner account if they have none + roster row, flagged
     * walk-in), then marked present for $sessionKey (the session of the QR they
     * scanned; null = the session running right now, for the old class-wide link).
     * $signaturePng (decoded PNG bytes) is the learner's finger signature from the form; it is
     * saved for the session (a later signature for the same session replaces it).
     * @return array success, message, name, session_label, registered, already
     */
    public function publicCheckIn($runId, $name, $email, $phone = '', $sessionKey = null, $signaturePng = null)
    {
        $ctx = $this->getSelfMarkContext($runId, $email, $sessionKey);
        if (!$ctx) {
            return array('success' => false, 'message' => 'Class not found.');
        }
        if (!$ctx['within_window']) {
            return array('success' => false, 'message' => 'Check-in is not open for this class right now.');
        }
        if ($sessionKey !== null) {
            $sess = $this->sessionForRun($ctx['run'], $sessionKey);
            if (!$sess) {
                return array('success' => false, 'message' => 'This session is not part of the class.');
            }
            if (!empty($sess['date']) && $sess['date'] > Mage::getModel('core/date')->date('Y-m-d')) {
                return array('success' => false, 'message' => 'Check-in for this session is not open yet.');
            }
        }
        $run      = $ctx['run'];
        $email    = $ctx['learner_email'];
        // The class's own trainer is never registered or marked as a learner: they sign as the
        // trainer in the TC LMS app or on E-Attendance.
        if (Mage::helper('mmd_mobileapi/trainer')->teaches($email, (int) $run['run_id'])) {
            return array('success' => false, 'message' => 'You are the trainer of this class, so you are not checked in as a learner.'
                . ' Sign as the trainer in the TC LMS app or on the E-Attendance page.');
        }
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $enrolTbl = $resource->getTableName('course_run_enrolments');
        $attTbl   = $resource->getTableName('mmd_course_run_attendance');

        $registered = false;
        $customerId = null;
        if (!$ctx['enrolled']) {
            $acct = $this->ensureLearnerAccount($name, $email, (int) Mage::app()->getDefaultStoreView()->getWebsiteId());
            if (!$acct['id']) {
                // A mistyped email (bad domain, no mail server) is the learner's to fix: say so.
                $err = isset($acct['error']) ? (string) $acct['error'] : '';
                return array('success' => false, 'message' => stripos($err, 'email') !== false
                    ? 'Please check your email address. ' . $err
                    : 'We could not register you right now. Please ask your trainer.');
            }
            $customerId = $acct['id'];
            $name       = $acct['name'];
            $write->query(
                "INSERT IGNORE INTO `$enrolTbl` (product_id, run_id, learner_email, learner_name) VALUES (?, ?, ?, ?)",
                array((int) $run['product_id'], (int) $run['run_id'], $email, $name)
            );
            Mage::helper('mmd_rolemanager/handover')->noteIndependentMembership($run['run_id'], $email);
            $registered = true;
        }
        if ($phone !== '') {
            $write->query(
                "UPDATE `$enrolTbl` SET learner_phone = ? WHERE run_id = ? AND LOWER(learner_email) = ?",
                array($phone, (int) $run['run_id'], $email)
            );
        }

        // The learner's own dashboard account (if any) is recorded as the marker.
        $adminId = (int) $read->fetchOne(
            "SELECT user_id FROM `" . $resource->getTableName('admin_user') . "` WHERE email = ? LIMIT 1",
            array($email)
        );
        $res = $this->selfMarkPresent($runId, $email, $adminId ?: null, $sessionKey);
        if (empty($res['success'])) {
            return $res;
        }
        if ($registered) {
            $write->update($attTbl, array('is_walkin' => 1, 'customer_id' => $customerId),
                array('run_id = ?' => (int) $run['run_id'], 'learner_email = ?' => $email, 'session_key = ?' => $ctx['session_key']));
        }
        $rosterName = (string) $read->fetchOne(
            "SELECT learner_name FROM `$enrolTbl` WHERE run_id = ? AND LOWER(learner_email) = ? LIMIT 1",
            array((int) $run['run_id'], $email)
        );
        if ($signaturePng !== null) {
            Mage::helper('mmd_mobileapi/signature')->save($run, $ctx['session_key'], $email,
                $rosterName !== '' ? $rosterName : $name, 'learner', $signaturePng, $email);
        }
        return array(
            'success'       => true,
            'message'       => $ctx['already_present']
                ? ($signaturePng !== null ? 'You were already checked in for this session. Your signature is saved.' : 'You were already checked in for this session.')
                : ($signaturePng !== null ? 'You are checked in and your signature is saved. Thank you!' : 'You are checked in. Thank you!'),
            'name'          => $rosterName !== '' ? $rosterName : $name,
            'session_label' => $this->sessionLabel($run, $ctx['session_key']),
            'registered'    => $registered,
            'already'       => (bool) $ctx['already_present'],
        );
    }
}
