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

        // Store-scope filter by class_id prefix (mirrors the Classes grid).
        $branch  = Mage::helper('branchscope');
        $storeId = $branch ? (int) $branch->getActiveStoreId() : 1;
        $prefixMap = array(1=>'SG',2=>'MY',3=>'GH',4=>'NG',5=>'BT',6=>'IN',7=>'TI');
        $whereStore = isset($prefixMap[$storeId])
            ? " AND cr.class_id LIKE " . $read->quote($prefixMap[$storeId] . '%')
            : '';

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

        $enrolled = $email !== '' && (int) $read->fetchOne(
            "SELECT enrolment_id FROM `$enrolTbl` WHERE run_id = ? AND LOWER(learner_email) = ? LIMIT 1",
            array((int) $run['run_id'], $email)
        ) > 0;
        $present = $email !== '' && (int) $read->fetchOne(
            "SELECT is_present FROM `$attTbl` WHERE run_id = ? AND LOWER(learner_email) = ? LIMIT 1",
            array((int) $run['run_id'], $email)
        ) === 1;

        return array(
            'run'             => $run,
            'learner_email'   => $email,
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
        // Write the SAME row a trainer's manual "present" marking produces
        // (AttendanceController::saveAction): is_present=1, reason cleared,
        // marked_by_admin_id = the account that did the marking (here the
        // learner's own dashboard account). is_walkin stays 0 (enrolled learner).
        $write->insertOnDuplicate(
            $attTbl,
            array(
                'run_id'             => (int) $run['run_id'],
                'class_id'           => $run['class_id'] ?: null,
                'learner_email'      => $enrol ? $enrol['learner_email'] : $email,
                'learner_name'       => $enrol ? trim((string) $enrol['learner_name']) : '',
                'is_present'         => 1,
                'reason_of_absence'  => null,
                'marked_by_admin_id' => $this->getCurrentAdminId(),
            ),
            array('is_present', 'learner_name', 'reason_of_absence', 'marked_by_admin_id')
        );
        return array('success' => true, 'message' => 'You have been marked present. Thank you!');
    }
}
