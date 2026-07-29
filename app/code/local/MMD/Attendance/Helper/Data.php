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

        $sessions = array();
        foreach ($days as $i => $date) {
            $d = $i + 1;
            foreach (array('am' => 'AM', 'pm' => 'PM') as $k => $lbl) {
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
        return 'd' . $day . $ampm;
    }

    // ── WSQ (TGS-) run materialisation ───────────────────────────────────────

    /**
     * Find the course_runs row for (product, start date) — or, for TGS-
     * prefixed SKUs ONLY, create it. The class-formation cron intentionally
     * skips TGS SKUs, so WSQ classes never get a run row and the E-Attendance
     * / feedback cards had nothing to link to. Creating here is safe for TGS
     * (nothing else will ever create it -> no duplicate-run race); for other
     * SKUs the cron owns creation, so this only ever finds.
     *
     * @return int run_id, or 0 when nothing exists and creation isn't allowed
     */
    public function ensureRun($productId, $sku, $startYmd, $endYmd = '')
    {
        $productId = (int) $productId;
        $sku       = strtoupper(trim((string) $sku));
        if ($productId <= 0 || !preg_match('/^\d{4}-\d{2}-\d{2}$/', (string) $startYmd)) {
            return 0;
        }
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', (string) $endYmd)) {
            $endYmd = $startYmd;
        }

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $table    = $resource->getTableName('course_runs');

        $find = "SELECT run_id FROM `$table` WHERE product_id = ? AND course_start_date = ? LIMIT 1";
        $runId = (int) $read->fetchOne($find, array($productId, $startYmd));
        if ($runId || substr($sku, 0, 4) !== 'TGS-') {
            return $runId;
        }

        $write   = $resource->getConnection('core_write');
        $classId = MMD_RoleManager_Helper_Data::nextClassId($write, $table, MMD_RoleManager_Helper_Data::CLASS_ID_PREFIX);
        try {
            $write->insert($table, array(
                'class_id'          => $classId,
                'product_id'        => $productId,
                'course_sku'        => $sku,
                'course_start_date' => $startYmd,
                'course_end_date'   => $endYmd,
                'course_start_time' => '09:30:00',
                'course_end_time'   => '18:30:00',
                'mode_of_training'  => 1,
                'vacancy'           => 'A',
                'created_at'        => now(),
                'created_by'        => 'E-Attendance',
            ));
            return (int) $write->lastInsertId();
        } catch (Exception $e) {
            // Concurrent create (class_id UNIQUE) — reselect.
            return (int) $read->fetchOne($find, array($productId, $startYmd));
        }
    }

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
