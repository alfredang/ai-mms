<?php
/**
 * Capability: edit course schedule.
 *
 *   op: add_class      { course_sku, start_date, end_date?, start_time?, end_time?, mode?, venue?, vacancy? }
 *   op: update_class   { class_id, start_date?, end_date?, start_time?, end_time?, mode?, venue?, vacancy? }
 *   op: remove_class   { class_id, force? }
 *   op: assign_trainer { class_id, trainer }        (name or trainer_option_id)
 *
 * ...and, for courses that keep no class records, the date-only ops:
 *
 *   op: add_date       { course_sku, start_date, end_date?, start_time?, end_time? }
 *   op: update_date    { course_sku, start_date, end_date?, new_start_date, new_end_date? }
 *   op: remove_date    { course_sku, start_date, end_date?, force? }
 *
 * TWO FAMILIES, SPLIT BY SKU PREFIX - a course is reachable by exactly one:
 *
 *   C-prefix (non-WSQ)   -> class ops. The class record is authoritative and the
 *                           learner-facing date is kept in sync with it.
 *   TGS- / M- (WSQ etc.) -> date ops. These courses have no class records at all
 *                           (see _assertDateOpsAllowed), so the Course Date value
 *                           IS the schedule and there is no class_id to address.
 *
 * Keeping them exclusive is what stops the date list drifting out of step with
 * course_runs: nothing can edit a C-course's date without going through its
 * class, and nothing creates a class for a course that is not supposed to have one.
 *
 * There is deliberately no per-course "generate a range" op: to add several
 * dates to one course the agent calls add_class/add_date once per date (each is
 * an admin-managed, durable entry). Bulk schedule generation across ALL products
 * is a template-level operation (see api_template), not a per-course one.
 *
 * Class identity is (course, start date); a new date is a new class. Edits that
 * affect people already signed up are applied + audited but do NOT notify them in
 * v1 - the preview surfaces the count (enrolments for classes, orders for dates)
 * so the agent can tell the user before they confirm.
 */
class MMD_AgentApi_Model_Schedule extends MMD_AgentApi_Model_Abstract
{
    const COURSE_DATE_OPTION = 'Course Date';
    const COURSE_TIME_OPTION = 'Course Time';

    /* Upper bound on a single class's start-to-end span. See _assertSpanSane(). */
    const MAX_SPAN_DAYS = 120;

    /* mode_of_training TINYINT: 1 = Physical Classroom, 2 = Virtual. */
    protected $_modeToInt = array('physical classroom' => 1, 'physical' => 1, 'classroom' => 1, 'virtual' => 2, 'online' => 2);
    protected $_intToMode = array(1 => 'Physical Classroom', 2 => 'Virtual');

    public function preview($op, array $body)
    {
        switch ($op) {
            case 'add_class':      return $this->_previewAdd($body);
            case 'update_class':   return $this->_previewUpdate($body);
            case 'remove_class':   return $this->_previewRemove($body);
            case 'assign_trainer': return $this->_previewAssignTrainer($body);
            case 'add_date':       return $this->_previewAddDate($body);
            case 'update_date':    return $this->_previewUpdateDate($body);
            case 'remove_date':    return $this->_previewRemoveDate($body);
            case 'generate_range':
                $this->_err('validation_error',
                    'Adding several dates to one course is done with add_class (one call per date). '
                    . 'Bulk generation across all products is a template operation (api_template).', 400);
            default:
                $this->_err('validation_error', 'Unsupported op "' . $op . '" for api_schedule.', 400);
        }
    }

    public function commit($op, array $body, array $preview)
    {
        switch ($op) {
            case 'add_class':      return $this->_commitAdd($preview);
            case 'update_class':   return $this->_commitUpdate($preview);
            case 'remove_class':   return $this->_commitRemove($preview);
            case 'assign_trainer': return $this->_commitAssignTrainer($preview);
            case 'add_date':       return $this->_commitAddDate($preview);
            case 'update_date':    return $this->_commitUpdateDate($preview);
            case 'remove_date':    return $this->_commitRemoveDate($preview);
            default:
                $this->_err('validation_error', 'Unsupported op "' . $op . '" for api_schedule.', 400);
        }
    }

    /* ------------------------------------------------------------------ add */

    protected function _previewAdd(array $body)
    {
        $sku       = $this->_courseSku($body);
        $startDate = $this->_date(isset($body['start_date']) ? $body['start_date'] : '', 'start_date');
        $endDate   = $this->_date($this->_opt($body, 'end_date', $startDate), 'end_date');
        $startTime = (string) $this->_opt($body, 'start_time', '');
        $endTime   = (string) $this->_opt($body, 'end_time', '');
        $mode      = $this->_modeInt($this->_opt($body, 'mode', 'Physical Classroom'));
        $venue     = (string) $this->_opt($body, 'venue', '');
        $vacancy   = $this->_vacancy($this->_opt($body, 'vacancy', 'A'));

        if (strtotime($endDate) < strtotime($startDate)) {
            $this->_err('validation_error', 'end_date cannot be before start_date.', 400);
        }
        $this->_assertSpanSane($startDate, $endDate);

        $product = $this->_loadAdmin($sku);

        // Classes can only be created for non-WSQ / unfunded C-prefix course
        // codes (C010, C6…). WSQ TGS- runs are managed in the external SSG
        // system; M- partner codes are legacy.
        if (!preg_match('/^C[0-9]/i', $sku)) {
            $this->_err('validation_error',
                'Classes can only be created for C-prefix (non-WSQ / unfunded) course codes — "'
                . $sku . '" is not eligible. WSQ (TGS-) classes are managed in the external system.', 422);
        }

        // If the course has no "Course Date" list yet it is not schedule-enabled.
        // Rather than refuse, bootstrap it: this first class creates its Course
        // Date + Course Time lists (a one-off, admin-managed schedule, NOT tied to
        // any template). Bootstrapping needs an explicit time (no template to
        // inherit one from) - so start_time + end_time are required in that case.
        // The agent should ask the user "put it on a template, or just add this
        // one date?" first; this is the "one date" branch.
        $bootstrap = !$this->_courseDateOptionId($product->getId());
        if ($bootstrap && ($startTime === '' || $endTime === '')) {
            $this->_err('course_not_scheduled',
                'Course ' . $sku . ' has no schedule set up yet. To create it with this first class, '
                . 'also provide start_time and end_time. (Or add the course to a schedule template instead.)', 422);
        }
        // The template decides how many days the class runs, so resolve the shape
        // BEFORE the duplicate check - an amended end date changes what counts as
        // a clash.
        $shape    = $this->_resolveShape($product->getId(), $startDate, $endDate);
        $endDate  = $shape['end'];
        $label    = $shape['label'];
        $warnings = $shape['warnings'];

        if ($this->_runExists($product->getId(), $startDate, $endDate)) {
            $this->_err('conflict', 'A class for ' . $sku . ' already exists on ' . $startDate . '.', 409);
        }
        if ($bootstrap) {
            $warnings[] = 'This course has no schedule yet - confirming creates its date + time lists (a one-off, not a shared template) and adds this first class.';
        }

        $details = $this->_courseFacts($product);
        $details['New class on']  = $label;
        $details['Runs for']      = $this->_spanText($startDate, $endDate);
        $details['Delivered as']  = $this->_intToMode[$mode] . ($venue !== '' ? ' at ' . $venue : '');
        $details['Places']        = array('A' => 'available', 'L' => 'limited', 'F' => 'full');
        $details['Places']        = $details['Places'][$vacancy];
        if ($bootstrap) {
            $details['Class times'] = $startTime . ' - ' . $endTime . ' (being set up now)';
        }
        $details['Trainer']  = 'not set - assign separately once the class exists';
        $details['Class id'] = 'assigned when you confirm';

        return array(
            'target'        => $sku,
            'diff'          => array(array('field' => 'class', 'from' => null,
                'to' => $label . ' - ' . $this->_intToMode[$mode] . ($venue ? ' @ ' . $venue : ''))),
            'human_summary' => 'A new class for "' . $product->getName() . '" (' . $sku . ') will be added on '
                                . $label . ' - ' . $this->_spanText($startDate, $endDate) . ', '
                                . $this->_intToMode[$mode] . ($venue ? ' at ' . $venue : '')
                                . '. A new class id is assigned on confirm.'
                                . ($bootstrap ? ' This course has no schedule yet, so this also sets it up ('
                                    . $startTime . '-' . $endTime . ').' : ''),
            'details'       => $details,
            'warnings'      => $warnings,
            'token_payload' => array('sku' => $sku, 'product_id' => (int) $product->getId(),
                'start' => $startDate, 'end' => $endDate, 'start_time' => $startTime, 'end_time' => $endTime,
                'mode' => $mode, 'venue' => $venue, 'vacancy' => $vacancy, 'label' => $label,
                'bootstrap' => $bootstrap),
        );
    }

    protected function _commitAdd(array $preview)
    {
        $p = $preview['token_payload'];

        // 0. Bootstrap: if this course has no schedule yet, create its Course Time
        //    (from the given time) + empty Course Date options so the date below is
        //    bookable. One-off + admin-managed; not tied to any template.
        if (!empty($p['bootstrap'])) {
            $this->_bootstrapScheduleOptions($p['product_id'], $p['start_time'], $p['end_time']);
        }

        // 1. Add the learner-facing Course Date option value (bookable) via direct
        //    SQL - the MMD_CustomOptions option model has bespoke per-value fields
        //    (reg_course, customoptions_qty, ...), so we write the option-value
        //    tables directly and let those columns take their defaults.
        $optionId = $this->_courseDateOptionId($p['product_id']);
        if (!$optionId) {
            $this->_err('course_not_scheduled',
                'Course ' . $p['sku'] . ' is not set up for scheduled class dates (no date list). '
                . 'Add it to a schedule template and apply first.', 422);
        }
        $this->_appendCourseDateValueSql($optionId, $p['label'], $p['product_id']);
        $this->_resortCourseDateValues($optionId);
        $this->_touchProduct($p['product_id']);

        // 2. Insert the authoritative class record.
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        $table = $resource->getTableName('course_runs');
        $classId = MMD_RoleManager_Helper_Data::nextClassId($write, $table, MMD_RoleManager_Helper_Data::CLASS_ID_PREFIX);
        $write->insert($table, array(
            'class_id'          => $classId,
            'product_id'        => $p['product_id'],
            'course_sku'        => $p['sku'],
            'course_start_date' => $p['start'],
            'course_end_date'   => $p['end'],
            'course_start_time' => $p['start_time'] !== '' ? $p['start_time'] : null,
            'course_end_time'   => $p['end_time'] !== '' ? $p['end_time'] : null,
            'mode_of_training'  => $p['mode'],
            'venue_building'    => $p['venue'] !== '' ? $p['venue'] : null,
            'vacancy'           => $p['vacancy'],
            'created_at'        => now(),
            'created_by'        => 'Agent',
        ));
        return array('target' => $classId, 'reindexed' => array('option_value'),
            'after' => array('class_id' => $classId, 'course_date' => $p['label']),
            'extra' => array('class_id' => $classId));
    }

    /* --------------------------------------------------------------- update */

    protected function _previewUpdate(array $body)
    {
        $classId = $this->_classId($body);
        $run     = $this->_loadRunByClassId($classId);
        $this->_assertCourseEligible($run);

        $fields = array();
        $diff   = array();
        $map = array(
            'start_date' => 'course_start_date', 'end_date' => 'course_end_date',
            'start_time' => 'course_start_time', 'end_time' => 'course_end_time',
            'venue'      => 'venue_building',
        );
        foreach ($map as $in => $col) {
            if (array_key_exists($in, $body) && $body[$in] !== '') {
                $new = ($in === 'start_date' || $in === 'end_date')
                    ? $this->_date($body[$in], $in) : (string) $body[$in];
                if ((string) $new !== (string) $run[$col]) {
                    $fields[$col] = $new;
                    $diff[] = array('field' => $in, 'from' => $run[$col], 'to' => $new);
                }
            }
        }
        if (array_key_exists('mode', $body) && $body['mode'] !== '') {
            $new = $this->_modeInt($body['mode']);
            if ((int) $new !== (int) $run['mode_of_training']) {
                $fields['mode_of_training'] = $new;
                $diff[] = array('field' => 'mode', 'from' => $this->_intToMode[(int) $run['mode_of_training']] ?? (int) $run['mode_of_training'],
                    'to' => $this->_intToMode[$new]);
            }
        }
        if (array_key_exists('vacancy', $body) && $body['vacancy'] !== '') {
            $new = $this->_vacancy($body['vacancy']);
            if ($new !== $run['vacancy']) {
                $fields['vacancy'] = $new;
                $diff[] = array('field' => 'vacancy', 'from' => $run['vacancy'], 'to' => $new);
            }
        }
        if (!$diff) {
            $this->_err('validation_error', 'No changes - the supplied values already match class ' . $classId . '.', 400);
        }

        $warnings = array();

        // Moving a class gets the same shape treatment as creating one: the
        // course's template decides how many days it runs, so a move given only
        // a new start date is extended to the full class rather than silently
        // shortened to one day.
        $dateChanged = isset($fields['course_start_date']) || isset($fields['course_end_date']);
        if ($dateChanged) {
            $newStart = isset($fields['course_start_date']) ? $fields['course_start_date'] : $run['course_start_date'];
            $newEnd   = isset($fields['course_end_date'])   ? $fields['course_end_date']   : $run['course_end_date'];
            // Only a new start with no new end is an incomplete instruction; when
            // both were given, honour them and let the shape check judge the pair.
            if (isset($fields['course_start_date']) && !isset($fields['course_end_date'])) {
                $newEnd = $newStart;
            }
            $shape = $this->_resolveShape((int) $run['product_id'], $newStart, $newEnd);
            if ($shape['end'] !== $run['course_end_date']) {
                $fields['course_end_date'] = $shape['end'];
            } else {
                unset($fields['course_end_date']);
            }
            $diff = array_values(array_filter($diff, function ($d) { return $d['field'] !== 'end_date'; }));
            if (isset($fields['course_end_date'])) {
                $diff[] = array('field' => 'end_date', 'from' => $run['course_end_date'], 'to' => $shape['end']);
            }
            $warnings = array_merge($warnings, $shape['warnings']);
        }

        $enrol = $this->_enrolmentCount($run['run_id']);
        if ($dateChanged && $enrol > 0) {
            $warnings[] = $enrol . ' learner(s) are enrolled on this class; they will NOT be auto-notified of the date change.';
        }

        $product = $this->_loadAdmin(null, (int) $run['product_id']);
        $details = $this->_courseFacts($product);
        $details['Class id']  = $classId;
        $details['Runs now']  = $run['course_start_date'] . ' to ' . $run['course_end_date']
                                . '  (' . $this->_spanText($run['course_start_date'], $run['course_end_date']) . ')';
        if ($dateChanged) {
            $ns = isset($fields['course_start_date']) ? $fields['course_start_date'] : $run['course_start_date'];
            $ne = isset($fields['course_end_date'])   ? $fields['course_end_date']   : $run['course_end_date'];
            $details['Changing to'] = $ns . ' to ' . $ne . '  (' . $this->_spanText($ns, $ne) . ')';
        }
        $details['Changing'] = implode('; ', array_map(
            function ($d) { return $d['field'] . ': ' . $this->_disp($d['from']) . ' -> ' . $this->_disp($d['to']); }, $diff));
        $details['Learners enrolled'] = $enrol === 0
            ? 'nobody'
            : $enrol . ' - NOT notified automatically';

        return array(
            'target'        => $classId,
            'diff'          => $diff,
            'human_summary' => 'Class ' . $classId . ' on "' . $product->getName() . '" (' . $run['course_sku'] . '): '
                                . implode('; ', array_map(function ($d) { return $d['field'] . ' ' . $this->_disp($d['from']) . ' -> ' . $this->_disp($d['to']); }, $diff)) . '.'
                                . ($enrol > 0 ? ' ' . $enrol . ' learner(s) enrolled.' : ' Nobody is enrolled.'),
            'details'       => $details,
            'warnings'      => $warnings,
            'token_payload' => array('class_id' => $classId, 'run_id' => (int) $run['run_id'],
                'product_id' => (int) $run['product_id'], 'fields' => $fields,
                'old_start' => $run['course_start_date'], 'old_end' => $run['course_end_date'],
                'snapshot' => $this->_runSnapshot($run)),
        );
    }

    protected function _commitUpdate(array $preview)
    {
        $p = $preview['token_payload'];
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        $table = $resource->getTableName('course_runs');
        $write->update($table, $p['fields'], array('run_id = ?' => $p['run_id']));

        $reindexed = array();
        // If the date changed, keep the learner-facing Course Date value in sync.
        if (isset($p['fields']['course_start_date']) || isset($p['fields']['course_end_date'])) {
            $newStart = isset($p['fields']['course_start_date']) ? $p['fields']['course_start_date'] : $p['old_start'];
            $newEnd   = isset($p['fields']['course_end_date'])   ? $p['fields']['course_end_date']   : $p['old_end'];
            $optionId = $this->_courseDateOptionId($p['product_id']);
            $synced   = $optionId ? $this->_updateCourseDateTitleSql($optionId, $p['old_start'], $p['old_end'], $this->_shapedDateLabel($p['product_id'], $newStart, $newEnd)) : false;
            if ($synced) { $this->_resortCourseDateValues($optionId); $this->_touchProduct($p['product_id']); }
            $reindexed[] = $synced ? 'option_value' : 'run_only';
        }
        return array('target' => $p['class_id'], 'reindexed' => $reindexed, 'after' => $p['fields']);
    }

    /* --------------------------------------------------------------- remove */

    protected function _previewRemove(array $body)
    {
        $classId = $this->_classId($body);
        $force   = !empty($body['force']);
        $run     = $this->_loadRunByClassId($classId);
        $this->_assertCourseEligible($run);
        $enrol   = $this->_enrolmentCount($run['run_id']);

        if ($enrol > 0 && !$force) {
            $this->_err('enrolments_exist',
                'Class ' . $classId . ' has ' . $enrol . ' enrolled learner(s). Re-issue with "force": true to remove it anyway.', 422);
        }
        $warnings = $enrol > 0
            ? array($enrol . ' enrolled learner(s) will be affected; they are NOT auto-notified in v1.')
            : array();

        $product = $this->_loadAdmin(null, (int) $run['product_id']);
        $details = $this->_courseFacts($product);
        $details['Class id']  = $classId;
        $details['Runs']      = $run['course_start_date'] . ' to ' . $run['course_end_date']
                                . '  (' . $this->_spanText($run['course_start_date'], $run['course_end_date']) . ')';
        $details['Learners enrolled'] = $enrol === 0
            ? 'nobody'
            : $enrol . ' - they are NOT refunded or told; handle that separately';
        $details['Also removed'] = 'the matching date from the course page, so it can no longer be booked';

        return array(
            'target'        => $classId,
            'diff'          => array(array('field' => 'class', 'from' => $run['course_start_date'], 'to' => null)),
            'human_summary' => 'Class ' . $classId . ' on "' . $product->getName() . '" (' . $run['course_sku']
                                . '), running ' . $run['course_start_date'] . ' to ' . $run['course_end_date']
                                . ', will be removed and its date taken off the course page'
                                . ($enrol > 0 ? ' - ' . $enrol . ' learner(s) are enrolled' : ', and nobody is enrolled') . '.',
            'details'       => $details,
            'warnings'      => $warnings,
            'token_payload' => array('class_id' => $classId, 'run_id' => (int) $run['run_id'],
                'product_id' => (int) $run['product_id'], 'start' => $run['course_start_date'],
                'end' => $run['course_end_date'], 'snapshot' => $this->_runSnapshot($run)),
        );
    }

    protected function _commitRemove(array $preview)
    {
        $p = $preview['token_payload'];
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        $table = $resource->getTableName('course_runs');

        // Remove the learner-facing date value first, then the class record.
        $optionId = $this->_courseDateOptionId($p['product_id']);
        $removed  = $optionId ? $this->_removeCourseDateValueSql($optionId, $p['start'], $p['end']) : false;
        if ($removed) { $this->_touchProduct($p['product_id']); }
        $write->delete($table, array('run_id = ?' => $p['run_id']));

        return array('target' => $p['class_id'], 'reindexed' => array($removed ? 'option_value' : 'run_only'),
            'after' => array('removed_class_id' => $p['class_id']));
    }

    /* -------------------------------------------------------- assign_trainer */

    protected function _previewAssignTrainer(array $body)
    {
        $classId = $this->_classId($body);
        $trainer = $this->_require($body, 'trainer');
        $emailIn = trim((string) $this->_opt($body, 'trainer_email', ''));
        $run     = $this->_loadRunByClassId($classId);
        $this->_assertCourseEligible($run);

        $res     = $this->_resolveTrainer($trainer, $emailIn);
        $oldName = $this->_currentTrainerName($run);

        if ($res['mode'] === 'existing' && (int) $res['user_id'] === (int) $run['trainer_user_id']) {
            $this->_err('validation_error', 'Class ' . $classId . ' is already assigned to ' . $res['name'] . '.', 400);
        }

        $warnings = array();
        // An account that already exists is never modified (_resolveTrainer refuses
        // with trainer_account_exists), so there is no "link" case to warn about here.
        if ($res['mode'] === 'existing' && !$this->_isAccountActive($res['user_id'])) {
            $warnings[] = $res['name'] . "'s MMS login is currently disabled, so they cannot sign in to see "
                . 'this class until an admin enables their account. The assignment itself still applies.';
        }
        if ($res['mode'] === 'create') {
            if ($res['source'] === 'legacy') {
                $warnings[] = $res['name'] . ' is not set up as an MMS trainer yet - assigning them will set up their trainer account (email ' . $res['email'] . ').';
            } else {
                $warnings[] = $res['name'] . ' is a new trainer - assigning them will create their MMS trainer account (email ' . $res['email'] . '). A brand-new account starts with login disabled until an admin enables it.';
            }
        }

        return array(
            'target'        => $classId,
            'diff'          => array(array('field' => 'trainer', 'from' => $oldName ?: null, 'to' => $res['name'])),
            'human_summary' => 'Class ' . $classId . ' (' . $run['course_sku'] . ') trainer: '
                                . ($oldName ?: '(none)') . ' -> ' . $res['name']
                                . ($res['mode'] === 'create' ? ' (a trainer account will be set up for them)' : '') . '.',
            'warnings'      => $warnings,
            'token_payload' => array('class_id' => $classId, 'run_id' => (int) $run['run_id'],
                'mode' => $res['mode'], 'user_id' => isset($res['user_id']) ? (int) $res['user_id'] : 0,
                'name' => $res['name'], 'email' => isset($res['email']) ? $res['email'] : '',
                'current' => (int) $run['trainer_user_id']),
        );
    }

    protected function _commitAssignTrainer(array $preview)
    {
        $p = $preview['token_payload'];
        $userId = (int) $p['user_id'];
        $extra  = array();
        if ($p['mode'] === 'create') {
            $acc    = $this->_ensureTrainerAccount($p['name'], $p['email']);
            $userId = $acc['user_id'];
            $extra['trainer_account'] = $acc['created']
                ? 'new inactive trainer account created (login disabled until an admin enables it)'
                : 'linked to an existing account and granted the trainer role';
        }
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        $table = $resource->getTableName('course_runs');
        $write->update($table, array('trainer_user_id' => $userId), array('run_id = ?' => $p['run_id']));
        return array('target' => $p['class_id'], 'reindexed' => array(),
            'after' => array('trainer_user_id' => $userId, 'trainer' => $p['name']),
            'extra' => $extra);
    }


    /* ---------------------------------------------------- date-only ops */

    /**
     * WSQ (TGS-) and partner (M-) courses have no class records. Since commit
     * 6c8cec43 (2026-07-29) classes are formed ONLY for non-WSQ C-prefix course
     * codes, and the funded/partner runs that predated it were purged. On those
     * courses the learner-facing "Course Date" value IS the whole schedule -
     * there is no class_id to address, so the class ops cannot reach them at all.
     *
     * add_date / update_date / remove_date address a date by the date itself and
     * touch only the Course Date list, mirroring the admin Course Schedule tab.
     *
     * The two families are mutually exclusive by SKU prefix, so every course is
     * reachable by exactly one of them and the date list can never drift out of
     * step with course_runs. Keying on the SKU rather than "does it have runs
     * yet" matters: a brand-new C-course has no runs, and must still route to the
     * class ops instead of picking up a class-less date here.
     */
    protected function _assertDateOpsAllowed($sku)
    {
        $sku = trim((string) $sku);
        if (preg_match('/^C[0-9]/i', $sku)) {
            $this->_err('use_class_ops',
                'Course ' . $sku . ' keeps class records, so its dates are managed as classes - use '
                . 'add_class / update_class / remove_class. The date ops are for WSQ (TGS-) and '
                . 'partner courses, which have no class records.', 422);
        }
    }

    /**
     * The SkillsFuture reminder for a funded course.
     *
     * The website date and the SSG course run are two separate steps and this
     * API only does the first. Saying so at the moment of the change is what
     * stops the second being forgotten - the schedule audit found 165 website
     * dates with no SSG run behind them, every one of them this same gap.
     *
     * Deliberately NOT an automatic hand-off: creating the SSG run is a separate
     * agent capability, and whether to do it stays a human decision.
     */
    protected function _ssgWarnings($sku, $state)
    {
        if (stripos(trim((string) $sku), 'TGS-') !== 0) {
            return array();
        }
        return array(
            'This is a WSQ course. The website date is ' . $state . ', but the matching SkillsFuture '
            . '(SSG) course run is NOT - that is a separate step and has not been done.',
        );
    }

    /**
     * Locate one Course Date value by start date (and end date when given).
     *
     * end_date is optional because a person says "the 18 Nov date" - but a start
     * date alone can match both a single-day and a multi-day value on the same
     * course, and silently picking one would edit the wrong date. Refuse and ask
     * instead. Returns null when nothing matches.
     */
    protected function _locateCourseDateValue($optionId, $start, $end = null)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $tv = $resource->getTableName('catalog/product_option_type_value');
        $tt = $resource->getTableName('catalog/product_option_type_title');
        $rows = $read->fetchAll(
            "SELECT tv.option_type_id, tt.title
               FROM `{$tv}` tv
               JOIN `{$tt}` tt ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
              WHERE tv.option_id = ?",
            array((int) $optionId)
        );

        $hits = array();
        foreach ($rows as $r) {
            list($s, $e) = $this->_parseLabel($r['title']);
            if ($s === null || $s !== $start) {
                continue;
            }
            if ($e === null) {
                $e = $s;
            }
            if ($end !== null && $e !== $end) {
                continue;
            }
            $hits[] = array('option_type_id' => (int) $r['option_type_id'],
                'label' => (string) $r['title'], 'start' => $s, 'end' => $e);
        }

        if (!$hits) {
            return null;
        }
        if (count($hits) > 1) {
            $labels = array();
            foreach ($hits as $h) {
                $labels[] = $h['label'];
            }
            $this->_err('ambiguous_date',
                'This course has more than one date starting ' . $start . ' ("'
                . implode('", "', $labels) . '"). Say which one by adding end_date.', 409);
        }
        return $hits[0];
    }

    /**
     * How many order lines already booked this exact date value.
     *
     * The chosen value is recorded in the order item's serialized
     * info_buyRequest as  i:<option_id>;s:<len>:"<option_type_id>"  - matching
     * that whole fragment is exact, where a bare LIKE on the id alone would also
     * hit quantities, prices and other options' ids. Scoped to the product, so
     * the scan is bounded by that one course's orders.
     *
     * WSQ courses have no course_run_enrolments to count (they keep no class
     * records), but they are the biggest sellers on the site - so an order-side
     * count is the only way to know whether anyone is booked on a date before
     * taking it down.
     */
    protected function _bookingCount($productId, $optionId, $optionTypeId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $oi = $resource->getTableName('sales/order_item');
        $needle = 'i:' . (int) $optionId . ';s:' . strlen((string) (int) $optionTypeId)
                . ':"' . (int) $optionTypeId . '"';
        return (int) $read->fetchOne(
            "SELECT COUNT(*) FROM `{$oi}` WHERE product_id = ? AND product_options LIKE ?",
            array((int) $productId, '%' . $needle . '%')
        );
    }

    /**
     * The facts every schedule preview should put in front of the requester.
     *
     * A preview that says only "a date will be added" gives nobody enough to
     * check it against. These are the things a person actually needs in order to
     * spot a mistake before it reaches the website: which course, what shape the
     * class is, what times it runs, what the course already offers, and what is
     * still outstanding afterwards.
     *
     * Ordered: PHP preserves insertion order and json_encode keeps it, so the
     * agent can relay these top to bottom without reordering anything.
     */
    protected function _courseFacts($product, $optionId = null)
    {
        $sku  = trim((string) $product->getSku());
        $isWsq = stripos($sku, 'TGS-') === 0;
        $facts = array(
            'Course'      => $product->getName(),
            'Course code' => $sku,
            'Course type' => $isWsq ? 'WSQ / SkillsFuture funded' : 'Non-WSQ (unfunded)',
        );

        try {
            $title = $this->_productScheduleTemplate($product->getId());
            $facts['Schedule template'] = $title === null ? 'none (dates are one-offs)' : trim($title);
        } catch (MMD_AgentApi_Model_Exception $e) {
            $facts['Schedule template'] = 'more than one - unresolved';
        }

        $times = $this->_courseTimes($product->getId());
        if ($times !== '') {
            $facts['Class times'] = $times;
        }

        if ($optionId === null) {
            $optionId = $this->_courseDateOptionId($product->getId());
        }
        if ($optionId) {
            $stats = $this->_courseDateStats($optionId);
            $facts['Dates on this course'] = $stats['total'] . ' (' . $stats['upcoming'] . ' still upcoming)';
            if ($stats['next'] !== null) {
                $facts['Next one after today'] = $stats['next'];
            }
        }
        return $facts;
    }

    /** The course's Course Time values, joined - e.g. "09:00 - 18:00, 19:00 - 22:00". */
    protected function _courseTimes($productId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $rows = $read->fetchCol(
            "SELECT tt.title
               FROM " . $resource->getTableName('catalog/product_option') . " o
               JOIN " . $resource->getTableName('catalog/product_option_title') . " ot
                    ON ot.option_id = o.option_id AND ot.store_id = 0 AND ot.title = ?
               JOIN " . $resource->getTableName('catalog/product_option_type_value') . " tv
                    ON tv.option_id = o.option_id
               JOIN " . $resource->getTableName('catalog/product_option_type_title') . " tt
                    ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
              WHERE o.product_id = ?
              ORDER BY tv.sort_order",
            array(self::COURSE_TIME_OPTION, (int) $productId)
        );
        return implode(', ', array_filter(array_map('trim', $rows)));
    }

    /** How many dates the course offers, how many are still ahead, and the next one. */
    protected function _courseDateStats($optionId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $rows = $read->fetchCol(
            "SELECT tt.title
               FROM " . $resource->getTableName('catalog/product_option_type_value') . " tv
               JOIN " . $resource->getTableName('catalog/product_option_type_title') . " tt
                    ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
              WHERE tv.option_id = ?
              ORDER BY tv.sort_order",
            array((int) $optionId)
        );
        $today = date('Y-m-d');
        $upcoming = 0; $next = null;
        foreach ($rows as $label) {
            list($s) = $this->_parseLabel($label);
            if ($s === null || $s < $today) {
                continue;
            }
            $upcoming++;
            if ($next === null) { $next = trim((string) $label); }
        }
        return array('total' => count($rows), 'upcoming' => $upcoming, 'next' => $next);
    }

    /** "2 days (Wed-Thu)" / "1 day (Tue)" for a start/end pair. */
    protected function _spanText($start, $end)
    {
        $s = strtotime($start); $e = strtotime($end);
        $days = (int) floor(($e - $s) / 86400) + 1;
        return $days . ' day' . ($days === 1 ? '' : 's')
            . ' (' . date('D', $s) . ($days === 1 ? '' : '-' . date('D', $e)) . ')';
    }

    /* -------------------------------------------------------- add_date */

    protected function _previewAddDate(array $body)
    {
        $sku       = $this->_courseSku($body);
        $startDate = $this->_date(isset($body['start_date']) ? $body['start_date'] : '', 'start_date');
        $endDate   = $this->_date($this->_opt($body, 'end_date', $startDate), 'end_date');
        $startTime = (string) $this->_opt($body, 'start_time', '');
        $endTime   = (string) $this->_opt($body, 'end_time', '');

        $this->_assertSpanSane($startDate, $endDate);
        if (strtotime($endDate) < strtotime($startDate)) {
            $this->_err('validation_error', 'end_date cannot be before start_date.', 400);
        }
        $this->_assertDateOpsAllowed($sku);
        $product = $this->_loadAdmin($sku);

        // No Course Date list yet -> this first date also sets the schedule up,
        // which needs an explicit time (there is no template to inherit one from).
        $optionId  = $this->_courseDateOptionId($product->getId());
        $bootstrap = !$optionId;
        if ($bootstrap && ($startTime === '' || $endTime === '')) {
            $this->_err('course_not_scheduled',
                'Course ' . $sku . ' has no schedule set up yet. To create it with this first date, '
                . 'also provide start_time and end_time.', 422);
        }
        // Resolve the shape first: the template may extend a single day into the
        // two- or five-day class this course actually runs, which changes what
        // counts as an existing date.
        $shape     = $this->_resolveShape($product->getId(), $startDate, $endDate);
        $startDate = $shape['start'];
        $endDate   = $shape['end'];
        $label     = $shape['label'];

        if ($optionId && $this->_locateCourseDateValue($optionId, $startDate, $endDate)) {
            $this->_err('conflict',
                'Course ' . $sku . ' already has that date on the website.', 409);
        }

        $warnings = array_merge($shape['warnings'], $this->_ssgWarnings($sku, 'added'));
        if ($bootstrap) {
            $warnings[] = 'This course has no schedule yet - confirming also creates its date + time '
                . 'lists (' . $startTime . '-' . $endTime . ').';
        }

        $details = $this->_courseFacts($product, $optionId ?: null);
        $details['New date'] = $label;
        $details['Runs for'] = $this->_spanText($startDate, $endDate);
        if ($bootstrap) {
            $details['Class times'] = $startTime . ' - ' . $endTime . ' (being set up now)';
        }
        $details['Still needed after this'] = stripos($sku, 'TGS-') === 0
            ? 'the SkillsFuture (SSG) course run - not done by this change'
            : 'nothing';

        return array(
            'target'        => $sku,
            'diff'          => array(array('field' => 'course_date', 'from' => null, 'to' => $label)),
            'human_summary' => 'A new bookable date will be added to "' . $product->getName() . '" ('
                                . $sku . '): ' . $label . ' - ' . $this->_spanText($startDate, $endDate) . '.',
            'details'       => $details,
            'warnings'      => $warnings,
            'token_payload' => array('sku' => $sku, 'product_id' => (int) $product->getId(),
                'start' => $startDate, 'end' => $endDate, 'start_time' => $startTime,
                'end_time' => $endTime, 'label' => $label, 'bootstrap' => $bootstrap),
        );
    }

    protected function _commitAddDate(array $preview)
    {
        $p = $preview['token_payload'];

        if (!empty($p['bootstrap'])) {
            $this->_bootstrapScheduleOptions($p['product_id'], $p['start_time'], $p['end_time']);
        }
        $optionId = $this->_courseDateOptionId($p['product_id']);
        if (!$optionId) {
            $this->_err('course_not_scheduled',
                'Course ' . $p['sku'] . ' is not set up for scheduled dates (no date list).', 422);
        }
        $this->_appendCourseDateValueSql($optionId, $p['label'], $p['product_id']);
        $this->_resortCourseDateValues($optionId);
        $this->_touchProduct($p['product_id']);

        return array('target' => $p['sku'], 'reindexed' => array('option_value'),
            'after' => array('course_date' => $p['label']));
    }

    /* ----------------------------------------------------- update_date */

    protected function _previewUpdateDate(array $body)
    {
        $sku      = $this->_courseSku($body);
        $start    = $this->_date(isset($body['start_date']) ? $body['start_date'] : '', 'start_date');
        $end      = array_key_exists('end_date', $body) && $body['end_date'] !== null && $body['end_date'] !== ''
                        ? $this->_date($body['end_date'], 'end_date') : null;
        $newStart = $this->_date(isset($body['new_start_date']) ? $body['new_start_date'] : '', 'new_start_date');
        $newEnd   = $this->_date($this->_opt($body, 'new_end_date', $newStart), 'new_end_date');

        $this->_assertSpanSane($newStart, $newEnd);
        if (strtotime($newEnd) < strtotime($newStart)) {
            $this->_err('validation_error', 'new_end_date cannot be before new_start_date.', 400);
        }
        $this->_assertDateOpsAllowed($sku);
        $product = $this->_loadAdmin($sku);

        $optionId = $this->_courseDateOptionId($product->getId());
        if (!$optionId) {
            $this->_err('course_not_scheduled',
                'Course ' . $sku . ' has no dates on the website yet.', 422);
        }
        $value = $this->_locateCourseDateValue($optionId, $start, $end);
        if (!$value) {
            $this->_err('not_found',
                'Course ' . $sku . ' has no date starting ' . $start . ' on the website.', 404);
        }
        // The destination gets the same shape treatment as a new date: the
        // template, not the request, decides how many days the class runs.
        $shape    = $this->_resolveShape($product->getId(), $newStart, $newEnd);
        $newStart = $shape['start'];
        $newEnd   = $shape['end'];
        $newLabel = $shape['label'];

        if ($newStart === $value['start'] && $newEnd === $value['end']) {
            $this->_err('validation_error', 'That date is already ' . $value['label'] . '.', 400);
        }
        // Moving onto a date the course already offers would leave two identical
        // entries in the dropdown.
        $clash = $this->_locateCourseDateValue($optionId, $newStart, $newEnd);
        if ($clash && $clash['option_type_id'] !== $value['option_type_id']) {
            $this->_err('conflict',
                'Course ' . $sku . ' already has that date on the website ("' . $clash['label'] . '").', 409);
        }
        $booked = $this->_bookingCount($product->getId(), $optionId, $value['option_type_id']);

        $warnings = array_merge($shape['warnings'], $this->_ssgWarnings($sku, 'changed'));
        if ($booked > 0) {
            $warnings[] = $booked . ' order(s) already booked this date. They are NOT notified '
                . 'automatically - tell them separately.';
        }

        $details = $this->_courseFacts($product, $optionId);
        $details['Date now']    = $value['label'] . '  (' . $this->_spanText($value['start'], $value['end']) . ')';
        $details['Changing to'] = $newLabel . '  (' . $this->_spanText($newStart, $newEnd) . ')';
        $details['Already booked on it'] = $booked === 0
            ? 'nobody'
            : $booked . ' order(s) - NOT notified automatically';
        $details['Still needed after this'] = stripos($sku, 'TGS-') === 0
            ? 'the SkillsFuture (SSG) course run - not done by this change'
            : 'nothing';

        return array(
            'target'        => $sku,
            'diff'          => array(array('field' => 'course_date',
                'from' => $value['label'], 'to' => $newLabel)),
            'human_summary' => 'On "' . $product->getName() . '" (' . $sku . '), the date "'
                                . $value['label'] . '" will be changed to "' . $newLabel . '" ('
                                . $this->_spanText($newStart, $newEnd) . ').'
                                . ($booked > 0 ? ' ' . $booked . ' order(s) already booked it.' : ' Nobody has booked it.'),
            'details'       => $details,
            'warnings'      => $warnings,
            'token_payload' => array('sku' => $sku, 'product_id' => (int) $product->getId(),
                'option_id' => (int) $optionId, 'option_type_id' => (int) $value['option_type_id'],
                'old_label' => $value['label'], 'label' => $newLabel,
                'start' => $newStart, 'end' => $newEnd, 'booked' => $booked),
        );
    }

    protected function _commitUpdateDate(array $preview)
    {
        $p = $preview['token_payload'];
        $this->_writeCourseDateLabel($p['option_type_id'], $p['label']);
        $this->_resortCourseDateValues($p['option_id']);
        $this->_touchProduct($p['product_id']);

        return array('target' => $p['sku'], 'reindexed' => array('option_value'),
            'after' => array('course_date' => $p['label'], 'was' => $p['old_label']));
    }

    /* ----------------------------------------------------- remove_date */

    protected function _previewRemoveDate(array $body)
    {
        $sku   = $this->_courseSku($body);
        $start = $this->_date(isset($body['start_date']) ? $body['start_date'] : '', 'start_date');
        $end   = array_key_exists('end_date', $body) && $body['end_date'] !== null && $body['end_date'] !== ''
                    ? $this->_date($body['end_date'], 'end_date') : null;
        $force = !empty($body['force']);

        $this->_assertDateOpsAllowed($sku);
        $product = $this->_loadAdmin($sku);

        $optionId = $this->_courseDateOptionId($product->getId());
        if (!$optionId) {
            $this->_err('course_not_scheduled',
                'Course ' . $sku . ' has no dates on the website yet.', 422);
        }
        $value = $this->_locateCourseDateValue($optionId, $start, $end);
        if (!$value) {
            $this->_err('not_found',
                'Course ' . $sku . ' has no date starting ' . $start . ' on the website.', 404);
        }
        $booked = $this->_bookingCount($product->getId(), $optionId, $value['option_type_id']);
        if ($booked > 0 && !$force) {
            $this->_err('bookings_exist',
                $booked . ' order(s) already booked "' . $value['label'] . '" on ' . $sku
                . '. Removing it takes the date off the website but does not cancel or refund them. '
                . 'Re-issue with "force": true to remove it anyway.', 422);
        }
        $warnings = $this->_ssgWarnings($sku, 'removed');
        if ($booked > 0) {
            $warnings[] = $booked . ' order(s) booked this date. Removing it does NOT cancel or '
                . 'refund them, and they are not notified - handle those separately.';
        }

        $stats   = $this->_courseDateStats($optionId);
        $details = $this->_courseFacts($product, $optionId);
        $details['Date being removed'] = $value['label'] . '  (' . $this->_spanText($value['start'], $value['end']) . ')';
        $details['Already booked on it'] = $booked === 0
            ? 'nobody'
            : $booked . ' order(s) - these are NOT cancelled or refunded, and nobody is told';
        $details['Dates left afterwards'] = max(0, $stats['total'] - 1)
            . ' (' . max(0, $stats['upcoming'] - 1) . ' still upcoming)';
        $details['Still needed after this'] = stripos($sku, 'TGS-') === 0
            ? 'the SkillsFuture (SSG) course run - not done by this change'
            : 'nothing';

        return array(
            'target'        => $sku,
            'diff'          => array(array('field' => 'course_date',
                'from' => $value['label'], 'to' => null)),
            'human_summary' => 'The date "' . $value['label'] . '" will be removed from "'
                                . $product->getName() . '" (' . $sku . ') so it can no longer be booked'
                                . ($booked > 0 ? ' - ' . $booked . ' order(s) already booked it' : ', and nobody has booked it')
                                . '. That leaves ' . max(0, $stats['upcoming'] - 1) . ' upcoming date(s) on the course.',
            'details'       => $details,
            'warnings'      => $warnings,
            'token_payload' => array('sku' => $sku, 'product_id' => (int) $product->getId(),
                'option_id' => (int) $optionId, 'option_type_id' => (int) $value['option_type_id'],
                'label' => $value['label'], 'booked' => $booked),
        );
    }

    protected function _commitRemoveDate(array $preview)
    {
        $p = $preview['token_payload'];
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        foreach (array('catalog/product_option_type_value', 'catalog/product_option_type_title',
                       'catalog/product_option_type_price') as $t) {
            $write->delete($resource->getTableName($t), array('option_type_id = ?' => (int) $p['option_type_id']));
        }
        $this->_touchProduct($p['product_id']);

        return array('target' => $p['sku'], 'reindexed' => array('option_value'),
            'after' => array('removed_course_date' => $p['label']));
    }
    /* ------------------------------------------------------------- internals */

    /**
     * Refuse to touch a class unless its course is still an eligible
     * (non-WSQ / unfunded) C-prefix course.
     *
     * add_class checks the SKU it was given. update_class / remove_class /
     * assign_trainer are handed a class_id instead, so they must resolve the
     * course themselves — and they must read the LIVE product SKU, never
     * course_runs.course_sku. That column is a display snapshot taken when the
     * class was formed and is re-synced by migration 845; on SG today 36 rows
     * hold a snapshot that disagrees with the live product. A guard reading the
     * snapshot would wave those through.
     *
     * TRIM before matching: some SKUs carry a leading space (" C1235"), and those
     * are legitimate C-courses that must keep working.
     *
     * Fails closed when the product is gone: without a live SKU we cannot prove
     * the course is eligible, so we refuse rather than assume.
     */
    protected function _assertCourseEligible(array $run)
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $pe       = $resource->getTableName('catalog/product');

        $liveSku = $read->fetchOne(
            "SELECT sku FROM `{$pe}` WHERE entity_id = ? LIMIT 1",
            array((int) $run['product_id'])
        );

        if ($liveSku === false || $liveSku === null || trim((string) $liveSku) === '') {
            $this->_err('orphaned_class',
                'Class ' . $run['class_id'] . ' points at a course that no longer exists in the '
                . 'catalog (product id ' . (int) $run['product_id'] . '), so its eligibility cannot '
                . 'be verified. It cannot be changed from here.', 422);
        }

        if (!preg_match('/^C[0-9]/i', trim((string) $liveSku))) {
            $this->_err('course_not_eligible',
                'Class ' . $run['class_id'] . ' belongs to course ' . trim((string) $liveSku)
                . ', which is not a non-WSQ / unfunded C-prefix course. WSQ (TGS-) classes are '
                . 'managed in the external SSG system and changing them here would leave the '
                . 'official course run untouched and out of step. Ask an admin to make this change '
                . 'in the system that owns it.', 422);
        }
    }

    protected function _runExists($productId, $start, $end)
    {
        $resource = Mage::getSingleton('core/resource');
        $read  = $resource->getConnection('core_read');
        $table = $resource->getTableName('course_runs');
        return (bool) $read->fetchOne(
            "SELECT run_id FROM `{$table}` WHERE product_id = ? AND course_start_date = ? AND course_end_date = ? LIMIT 1",
            array((int) $productId, $start, $end)
        );
    }

    protected function _runSnapshot($run)
    {
        return array(
            'start' => $run['course_start_date'], 'end' => $run['course_end_date'],
            'start_time' => $run['course_start_time'], 'end_time' => $run['course_end_time'],
            'mode' => (int) $run['mode_of_training'], 'venue' => $run['venue_building'],
            'vacancy' => $run['vacancy'], 'trainer_option_id' => (int) $run['trainer_option_id'],
        );
    }

    /** Load a product at admin scope by sku OR id. */
    protected function _loadAdmin($sku, $id = null)
    {
        if ($id === null) {
            $id = Mage::getModel('catalog/product')->getIdBySku($sku);
            if (!$id) {
                // A handful of catalogue SKUs carry stray whitespace (" C1235").
                // getIdBySku matches exactly, so resolve on the trimmed value
                // rather than leaving those courses unreachable.
                $resource = Mage::getSingleton('core/resource');
                $id = $resource->getConnection('core_read')->fetchOne(
                    "SELECT entity_id FROM " . $resource->getTableName('catalog/product')
                    . " WHERE TRIM(sku) = TRIM(?) LIMIT 1",
                    array((string) $sku)
                );
            }
            if (!$id) {
                // No near-match suggestions on purpose: offering a shortlist here
                // invites picking one, and the whole point is that the requester
                // names the course, not the agent.
                $this->_err('not_found',
                    'No course has the code "' . $sku . '". Check it with the requester rather than '
                    . 'trying variations — a code that is nearly right belongs to a different course.', 404);
            }
        }
        return Mage::getModel('catalog/product')->setStoreId(0)->load($id);
    }

    /** option_id of the product's "Course Date" custom option, or 0. */
    protected function _courseDateOptionId($productId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $o    = $resource->getTableName('catalog/product_option');
        $ot   = $resource->getTableName('catalog/product_option_title');
        return (int) $read->fetchOne(
            "SELECT o.option_id FROM `{$o}` o
               JOIN `{$ot}` ot ON ot.option_id = o.option_id
              WHERE o.product_id = ? AND ot.title = ?
              ORDER BY ot.store_id LIMIT 1",
            array((int) $productId, self::COURSE_DATE_OPTION)
        );
    }

    /**
     * Bootstrap a never-scheduled course: create its "Course Time" option (one
     * value, from the given class time) and an empty "Course Date" option, so the
     * date appended next is bookable (dates dependent_ids-link to a Course Time
     * value). Both values are admin_managed - a one-off, not a shared template.
     */
    protected function _bootstrapScheduleOptions($productId, $startTime, $endTime)
    {
        $resource = Mage::getSingleton('core/resource');
        $read  = $resource->getConnection('core_read');
        $write = $resource->getConnection('core_write');
        $opt  = $resource->getTableName('catalog/product_option');
        $optT = $resource->getTableName('catalog/product_option_title');
        $tv   = $resource->getTableName('catalog/product_option_type_value');
        $tt   = $resource->getTableName('catalog/product_option_type_title');
        $tp   = $resource->getTableName('catalog/product_option_type_price');

        // Unique in_group_ids across the product's existing options / values (an
        // empty/0 in_group_id collides on a later template apply -> data loss).
        $maxOptIgi = (int) $read->fetchOne("SELECT MAX(in_group_id) FROM `{$opt}` WHERE product_id = ?", array((int) $productId));
        $maxValIgi = (int) $read->fetchOne(
            "SELECT MAX(tv.in_group_id) FROM `{$tv}` tv JOIN `{$opt}` o ON o.option_id = tv.option_id WHERE o.product_id = ?",
            array((int) $productId));

        // 1. Course Time option + one time value.
        $write->insert($opt, array('product_id' => (int) $productId, 'type' => 'drop_down',
            'is_require' => 1, 'sort_order' => 2, 'in_group_id' => $maxOptIgi + 2));
        $ctOptId = (int) $write->lastInsertId();
        $write->insert($optT, array('option_id' => $ctOptId, 'store_id' => 0, 'title' => self::COURSE_TIME_OPTION));
        $write->insert($tv, array('option_id' => $ctOptId, 'sku' => '', 'sort_order' => 1,
            'in_group_id' => $maxValIgi + 1, 'dependent_ids' => '', 'admin_managed' => 1));
        $ctVid = (int) $write->lastInsertId();
        $write->insert($tt, array('option_type_id' => $ctVid, 'store_id' => 0, 'title' => $this->_timeLabel($startTime, $endTime)));
        $write->insert($tp, array('option_type_id' => $ctVid, 'store_id' => 0, 'price' => 0, 'price_type' => 'fixed'));

        // 2. Empty Course Date option - the caller appends the date value, which
        //    auto-links (dependent_ids) to the Course Time value created above.
        $write->insert($opt, array('product_id' => (int) $productId, 'type' => 'drop_down',
            'is_require' => 1, 'sort_order' => 1, 'in_group_id' => $maxOptIgi + 1));
        $cdOptId = (int) $write->lastInsertId();
        $write->insert($optT, array('option_id' => $cdOptId, 'store_id' => 0, 'title' => self::COURSE_DATE_OPTION));
    }

    /** Friendly time label for a bootstrapped Course Time value, e.g. "09:00 - 18:00". */
    protected function _timeLabel($start, $end)
    {
        $start = trim((string) $start);
        $end   = trim((string) $end);
        return ($start !== '' && $end !== '') ? ($start . ' - ' . $end) : ($start . $end);
    }

    /**
     * Append a value to the Course Date option, matching the structure of
     * template-generated dates so it is bookable: a unique in_group_id (the
     * MMD_CustomOptions stable value key) plus dependent_ids linking the date to
     * a Course Time value (so the storefront shows/requires the right time).
     */
    protected function _appendCourseDateValueSql($optionId, $label, $productId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read  = $resource->getConnection('core_read');
        $write = $resource->getConnection('core_write');
        $tv  = $resource->getTableName('catalog/product_option_type_value');
        $tt  = $resource->getTableName('catalog/product_option_type_title');
        $tp  = $resource->getTableName('catalog/product_option_type_price');
        $opt = $resource->getTableName('catalog/product_option');

        // Unique in_group_id across all this product's option values (an empty one
        // collides to a single key on save/apply -> silent data loss).
        $maxIgi = (int) $read->fetchOne(
            "SELECT MAX(tv.in_group_id) FROM `{$tv}` tv
               JOIN `{$opt}` o ON o.option_id = tv.option_id
              WHERE o.product_id = ?", array((int) $productId));
        $depId = $this->_courseTimeDepId($productId, $label);

        $max = (int) $write->fetchOne("SELECT MAX(sort_order) FROM `{$tv}` WHERE option_id = ?", array((int) $optionId));
        $write->insert($tv, array(
            'option_id'     => (int) $optionId,
            'sku'           => '',
            'sort_order'    => $max + 1,
            'in_group_id'   => $maxIgi + 1,
            'dependent_ids' => $depId,
            // Admin/agent-added dates are case-by-case confirmations - flag them
            // so a later schedule-template Apply never removes them.
            'admin_managed' => 1,
        ));
        $otid = (int) $write->lastInsertId();
        $write->insert($tt, array('option_type_id' => $otid, 'store_id' => 0, 'title' => $label));
        $write->insert($tp, array('option_type_id' => $otid, 'store_id' => 0, 'price' => 0, 'price_type' => 'fixed'));
        return $otid;
    }

    /**
     * in_group_id of the Course Time value this date should depend on. Defaults
     * to the first (morning/daytime) time; an "Evening"-labelled date links to
     * the last time value. Mirrors the template Apply's morning/evening pick.
     */
    protected function _courseTimeDepId($productId, $label)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $tv  = $resource->getTableName('catalog/product_option_type_value');
        $opt = $resource->getTableName('catalog/product_option');
        $ot  = $resource->getTableName('catalog/product_option_title');
        $rows = $read->fetchAll(
            "SELECT tv.in_group_id, tv.option_type_id
               FROM `{$tv}` tv
               JOIN `{$opt}` o ON o.option_id = tv.option_id
               JOIN `{$ot}` ot ON ot.option_id = o.option_id AND ot.store_id = 0
              WHERE o.product_id = ? AND ot.title = 'Course Time'
              ORDER BY tv.sort_order ASC", array((int) $productId));
        if (!$rows) {
            return '';
        }
        $pick = function ($r) {
            return (string) (($r['in_group_id'] !== null && $r['in_group_id'] !== '') ? $r['in_group_id'] : $r['option_type_id']);
        };
        if (stripos($label, 'Evening') !== false && count($rows) >= 2) {
            return $pick($rows[count($rows) - 1]);
        }
        return $pick($rows[0]);
    }

    /**
     * Re-sort a Course Date option's values chronologically and rewrite each
     * value's sort_order (1..N), so an added/relabelled date lands in its
     * correct slot in the dropdown rather than at the bottom. Mirrors the
     * template Apply's sort. Unparseable labels sink to the end.
     */
    protected function _resortCourseDateValues($optionId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read  = $resource->getConnection('core_read');
        $write = $resource->getConnection('core_write');
        $tv = $resource->getTableName('catalog/product_option_type_value');
        $tt = $resource->getTableName('catalog/product_option_type_title');
        $rows = $read->fetchAll(
            "SELECT tv.option_type_id, tt.title
               FROM `{$tv}` tv
               JOIN `{$tt}` tt ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
              WHERE tv.option_id = ?",
            array((int) $optionId)
        );
        if (!$rows) {
            return;
        }
        usort($rows, function ($a, $b) {
            list($sa) = $this->_parseLabel($a['title']);
            list($sb) = $this->_parseLabel($b['title']);
            $ka = $sa ?: '9999-12-31';
            $kb = $sb ?: '9999-12-31';
            return strcmp($ka, $kb);
        });
        $i = 1;
        foreach ($rows as $r) {
            $write->update($tv, array('sort_order' => $i++), array('option_type_id = ?' => (int) $r['option_type_id']));
        }
    }

    /** Find the option_type_id whose Course Date label parses to (start,end), or 0. */
    protected function _findCourseDateValueId($optionId, $start, $end)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $tv = $resource->getTableName('catalog/product_option_type_value');
        $tt = $resource->getTableName('catalog/product_option_type_title');
        $rows = $read->fetchAll(
            "SELECT tv.option_type_id, tt.title
               FROM `{$tv}` tv
               JOIN `{$tt}` tt ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
              WHERE tv.option_id = ?",
            array((int) $optionId)
        );
        foreach ($rows as $r) {
            list($s, $e) = $this->_parseLabel($r['title']);
            if ($s === $start && ($e === $end || $e === null)) {
                return (int) $r['option_type_id'];
            }
        }
        return 0;
    }

    protected function _updateCourseDateTitleSql($optionId, $oldStart, $oldEnd, $newLabel)
    {
        $otid = $this->_findCourseDateValueId($optionId, $oldStart, $oldEnd);
        if (!$otid) {
            return false;
        }
        $this->_writeCourseDateLabel($otid, $newLabel);
        return true;
    }

    /**
     * Relabel one Course Date value that has already been located.
     *
     * A date edit takes ownership of the value: flag it admin_managed so a later
     * schedule-template Apply never reconciles or removes it (mirrors the Edit
     * Course tab).
     */
    protected function _writeCourseDateLabel($optionTypeId, $newLabel)
    {
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        $tt = $resource->getTableName('catalog/product_option_type_title');
        $tv = $resource->getTableName('catalog/product_option_type_value');
        $write->update($tt, array('title' => $newLabel),
            array('option_type_id = ?' => (int) $optionTypeId, 'store_id = ?' => 0));
        $write->update($tv, array('admin_managed' => 1),
            array('option_type_id = ?' => (int) $optionTypeId));
    }

    protected function _removeCourseDateValueSql($optionId, $start, $end)
    {
        $otid = $this->_findCourseDateValueId($optionId, $start, $end);
        if (!$otid) {
            return false;
        }
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        foreach (array('catalog/product_option_type_value', 'catalog/product_option_type_title', 'catalog/product_option_type_price') as $t) {
            $write->delete($resource->getTableName($t), array('option_type_id = ?' => $otid));
        }
        return true;
    }

    /**
     * Mark a schedule change visible: bump updated_at and clear the cached
     * blocks / full-page cache tagged to this product, so the course page shows
     * the new/edited/removed date. No reindex is needed - Course Date option
     * values are not part of any index (the storefront reads them live); the
     * catalog indexers are real_time and already partial-reindex on product
     * save for the attribute/status writes that DO get indexed.
     */
    protected function _touchProduct($productId)
    {
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        $write->update($resource->getTableName('catalog/product'), array('updated_at' => now()),
            array('entity_id = ?' => (int) $productId));
        try {
            Mage::app()->cleanCache(array('catalog_product_' . (int) $productId));
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /** Parse a Course Date label -> [start,end] using the enrolment service parser. */
    protected function _parseLabel($label)
    {
        try {
            $parser = Mage::getModel('mmd_rolemanager/courseRunEnrolmentService');
            $parsed = $parser->_parseDate((string) $label);
            if (is_array($parsed) && !empty($parsed[0])) {
                return array($parsed[0], !empty($parsed[1]) ? $parsed[1] : $parsed[0]);
            }
        } catch (Exception $e) {
            // fall through
        }
        return array(null, null);
    }

    /** Resolve a trainer name or option_type_id for a product -> [option_type_id, name]. */
    /**
     * Resolve a trainer name/email to an assignment decision:
     *   existing trainer account            -> ['mode'=>'existing', user_id, name, email]
     *   no account but legacy record w/email -> ['mode'=>'create','source'=>'legacy', name, email]
     *   genuinely new                        -> ['mode'=>'create','source'=>'new', name, email]  (email required)
     */
    protected function _resolveTrainer($input, $emailIn)
    {
        $input   = trim((string) $input);
        $isEmail = strpos($input, '@') !== false;

        // 1. Existing trainer-role account (by email or exact name).
        $matches = array();
        foreach (Mage::helper('mmd_rolemanager/trainer')->getTrainerAccounts() as $a) {
            $hit = $isEmail ? (strcasecmp($a['email'], $input) === 0)
                            : (strcasecmp($a['name'], $input) === 0);
            if ($hit) { $matches[] = $a; }
        }
        if (count($matches) === 1) {
            return array('mode' => 'existing', 'user_id' => (int) $matches[0]['user_id'],
                'name' => $matches[0]['name'], 'email' => $matches[0]['email']);
        }
        if (count($matches) > 1) {
            $this->_err('ambiguous_trainer',
                'There are multiple trainers named "' . $input . '". Please identify them by email instead.', 409);
        }

        // The email we would use (from an email input or an explicit trainer_email).
        $email = trim((string) ($isEmail ? $input : $emailIn));

        // 2. Someone who already has an MMS account.
        //
        //    a) They already hold the trainer role -> nothing to change, just assign.
        //       Step 1 above only sees ACTIVE accounts (getTrainerAccounts filters
        //       is_active = 1), and trainer accounts created here start INACTIVE — so
        //       without this branch the first trainer the agent creates would become
        //       un-assignable on the very next call.
        //
        //    b) They exist WITHOUT the trainer role -> refuse. Granting the role also
        //       rewrites that account's permission group (applyRoleAcl replaces the
        //       user's single admin_role 'U' row), so an existing Admin or Super Admin
        //       would silently be moved into the Trainer group. This operation never
        //       modifies an account that already exists.
        if ($email !== '' && strpos($email, '@') !== false) {
            $existing = $this->_findAdminUserByEmail($email);
            if ($existing) {
                if ($this->_hasTrainerRole($existing['user_id'])) {
                    return array('mode' => 'existing', 'user_id' => (int) $existing['user_id'],
                        'name' => $existing['name'], 'email' => $existing['email']);
                }
                $this->_err('trainer_account_exists',
                    $existing['name'] . ' (' . $existing['email'] . ') already has an MMS account but is '
                    . 'not set up as a trainer. Granting the trainer role would also change what that '
                    . 'account can access, so it cannot be done from here — ask an admin to add the '
                    . 'trainer role in Role Management, then assign the class.', 422);
            }
        }

        // 3. Legacy courses_trainers record (name or email) that carries an email.
        $legacy = $this->_findLegacyTrainer($input, $isEmail);
        if ($legacy && $legacy['email'] !== '') {
            return array('mode' => 'create', 'source' => 'legacy',
                'name' => $legacy['name'], 'email' => $legacy['email']);
        }

        // 4. Genuinely new -> require an email.
        if ($email === '' || strpos($email, '@') === false) {
            $this->_err('trainer_email_required',
                'Trainer "' . $input . '" has no MMS account and no email on file. To add them, include their email as "trainer_email".', 422);
        }
        $name = $isEmail ? ($legacy ? $legacy['name'] : $email) : $input;
        return array('mode' => 'create', 'source' => 'new', 'name' => $name, 'email' => $email);
    }

    /** Is this admin_user's login enabled? */
    protected function _isAccountActive($userId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $au   = $resource->getTableName('admin_user');
        return (bool) $read->fetchOne(
            "SELECT is_active FROM `{$au}` WHERE user_id = ? LIMIT 1",
            array((int) $userId)
        );
    }

    /** Does this admin_user already hold the trainer role? (active or not) */
    protected function _hasTrainerRole($userId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $rm   = $resource->getTableName('mmd_user_role_map');
        return (bool) $read->fetchOne(
            "SELECT 1 FROM `{$rm}` WHERE user_id = ? AND role_code = 'trainer' LIMIT 1",
            array((int) $userId)
        );
    }

    /**
     * Existing admin_user by email (any role) -> ['user_id','name','email'] or null.
     * Normalises with LOWER(TRIM(...)) on BOTH sides so this and the
     * _ensureTrainerAccount guard can never disagree about whether an account exists.
     */
    protected function _findAdminUserByEmail($email)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $au = $resource->getTableName('admin_user');
        $row = $read->fetchRow(
            "SELECT user_id, TRIM(CONCAT(COALESCE(firstname,''), ' ', COALESCE(lastname,''))) AS name, email"
            . " FROM `{$au}` WHERE LOWER(TRIM(email)) = ? LIMIT 1",
            array(strtolower(trim($email)))
        );
        if (!$row) { return null; }
        $name = trim((string) $row['name']);
        return array('user_id' => (int) $row['user_id'],
            'name' => $name !== '' ? $name : (string) $row['email'], 'email' => (string) $row['email']);
    }

    /** Legacy trainer record from courses_trainers by name or email (email may be blank). */
    protected function _findLegacyTrainer($input, $isEmail)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $ct = $resource->getTableName('courses_trainers');
        $where = $isEmail ? 'LOWER(email) = ?' : 'LOWER(TRIM(title)) = ?';
        $row = $read->fetchRow(
            "SELECT title, email FROM `{$ct}` WHERE {$where} ORDER BY (email IS NULL OR email = '') ASC LIMIT 1",
            array(strtolower(trim($input)))
        );
        if (!$row) { return null; }
        return array('name' => trim((string) $row['title']) ?: $input, 'email' => trim((string) $row['email']));
    }

    /** Current assigned trainer name for a run (account pointer first, EAV fallback). */
    protected function _currentTrainerName($run)
    {
        $r = Mage::helper('mmd_rolemanager/trainer')->resolveRunTrainer($run);
        return $r ? $r['name'] : null;
    }

    /**
     * Ensure a trainer-role admin_user exists for this email; create INACTIVE if
     * new. Mirrors MMD_RoleManager_Model_TrainerImportService (match by email,
     * create + trainer role + applyRoleAcl). Inactive because roles currently
     * inherit the full Administrators ACL - login is enabled separately later.
     */
    protected function _ensureTrainerAccount($fullName, $email)
    {
        $resource = Mage::getSingleton('core/resource');
        $read  = $resource->getConnection('core_read');
        $write = $resource->getConnection('core_write');
        $auTbl   = $resource->getTableName('admin_user');
        $roleTbl = $resource->getTableName('mmd_user_role_map');

        // Invariant, enforced here rather than left to callers: this method NEVER
        // modifies an account that already exists. Granting a role would also rewrite
        // the account's permission group via applyRoleAcl. _resolveTrainer already
        // refuses such cases; this is the backstop so a future caller cannot
        // reintroduce the behaviour by accident. Normalised identically to
        // _findAdminUserByEmail (LOWER(TRIM(...)) both sides) so the two never disagree.
        $userId = (int) $read->fetchOne(
            "SELECT user_id FROM `{$auTbl}` WHERE LOWER(TRIM(email)) = ? LIMIT 1",
            array(strtolower(trim($email)))
        );
        if ($userId) {
            $this->_err('trainer_account_exists',
                'An MMS account already exists for ' . $email . '. This operation never modifies an '
                . 'existing account — ask an admin to grant the trainer role in Role Management.', 422);
        }
        $created = false;
        if (!$userId) {
            $parts = preg_split('/\s+/', trim($fullName ?: $email), 2);
            $first = ($parts[0] !== '') ? $parts[0] : 'Trainer';
            $last  = (isset($parts[1]) && $parts[1] !== '') ? $parts[1] : '-';
            $user  = Mage::getModel('admin/user')->setData(array(
                'username'  => $email,
                'firstname' => $first,
                'lastname'  => $last,
                'email'     => $email,
                'password'  => 'Agt' . bin2hex(random_bytes(8)) . '7',
                'is_active' => 0,
            ));
            $user->save();
            $userId = (int) $user->getId();
            $created = true;
        }
        $has = (int) $read->fetchOne("SELECT COUNT(*) FROM `{$roleTbl}` WHERE user_id = ? AND role_code = 'trainer'", array($userId));
        if (!$has) {
            $write->insert($roleTbl, array('user_id' => $userId, 'role_code' => 'trainer', 'is_primary' => 0, 'created_at' => now()));
            Mage::helper('mmd_rolemanager')->applyRoleAcl($userId, 'trainer');
        }
        return array('user_id' => $userId, 'created' => $created);
    }

    /* ----- validators / formatters ----- */

    /**
     * The course reference, insisted upon rather than inferred.
     *
     * Nothing here guesses which course someone meant. A course code identifies
     * exactly one course; a course NAME does not — the catalogue is full of near
     * neighbours ("Excel Basic" / "Excel Intermediate" / four WSQ Excel courses),
     * and picking the wrong one puts a date on the wrong course page where
     * customers can book it. So a reference that reads like a name is refused
     * with an instruction to go back and ask, not a best guess or a shortlist.
     *
     * A real code has no spaces and contains digits (C1234, TGS-2021003160, M12).
     */
    protected function _courseSku(array $body)
    {
        $raw = isset($body['course_sku']) ? trim((string) $body['course_sku']) : '';
        if ($raw === '') {
            $this->_err('course_ref_required',
                'A course code is required — the course must be named exactly, never inferred. '
                . 'Ask the requester for it (e.g. C1234, or TGS-2021003160 for a WSQ course) and '
                . 'do not work it out from the course title.', 400);
        }
        if (strpos($raw, ' ') !== false || !preg_match('/\d/', $raw)) {
            $this->_err('course_ref_required',
                '"' . $raw . '" is a course name, not a course code. Several courses can share '
                . 'similar titles, so this is not resolved by guessing. Ask the requester for the '
                . 'course code (e.g. C1234, or TGS-2021003160 for a WSQ course).', 400);
        }
        return $raw;
    }

    /**
     * A class id, held to the same rule: named exactly or not accepted.
     * Format is C###### (see MMD_RoleManager_Helper_Data::nextClassId).
     */
    protected function _classId(array $body)
    {
        $raw = isset($body['class_id']) ? trim((string) $body['class_id']) : '';
        if ($raw === '') {
            $this->_err('class_ref_required',
                'A class id is required (format C000123). Ask the requester which class they mean — '
                . 'a course can be running several, and the wrong one affects real learners.', 400);
        }
        if (!preg_match('/^C\d{4,}$/i', $raw)) {
            $this->_err('class_ref_required',
                '"' . $raw . '" is not a class id. Class ids look like C000123. If you only have '
                . 'the course and a date, look the class up first rather than guessing an id.', 400);
        }
        return $raw;
    }

    /**
     * Refuse an absurd start-to-end span before any work is done on it.
     *
     * Labelling walks the schedule template day by day across the span, so a
     * request like 2027-01-01 to 2037-01-01 makes the server generate ten years
     * of slots only to refuse the result — measured at ~4s of CPU per call, which
     * an agent retrying in a loop could turn into real load.
     *
     * The longest class this site has ever run is 22 days and the average is
     * under one, so 120 days is roughly five times the real maximum: generous
     * for any genuine course, and a firm bound on the work a single call can ask
     * for. A legitimate programme longer than this belongs in the admin
     * schedule, where the days are set explicitly.
     */
    protected function _assertSpanSane($start, $end)
    {
        $days = (int) floor((strtotime($end) - strtotime($start)) / 86400);
        if ($days > self::MAX_SPAN_DAYS) {
            $this->_err('validation_error',
                'That is a ' . $days . '-day span (' . $start . ' to ' . $end . '). The longest class '
                . 'on this site runs 22 days, so this is almost certainly a typo in one of the dates. '
                . 'Check them with the requester. A genuine programme this long has to be set up '
                . 'through the admin schedule.', 400);
        }
    }

    protected function _date($v, $field)
    {
        $v = trim((string) $v);
        if ($v === '') {
            $this->_err('validation_error',
                $field . ' is required. Ask the requester for the exact date — never assume one '
                . 'from "next month" or "the usual slot".', 400);
        }
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $v) || !strtotime($v)) {
            $this->_err('validation_error',
                $field . ' must be an exact date as YYYY-MM-DD (got "' . $v . '"). If the requester '
                . 'was vague, confirm the date with them before retrying.', 400);
        }
        return $v;
    }

    protected function _modeInt($v)
    {
        $k = strtolower(trim((string) $v));
        if (!isset($this->_modeToInt[$k])) {
            $this->_err('validation_error', 'mode must be "Physical Classroom" or "Virtual".', 400);
        }
        return $this->_modeToInt[$k];
    }

    protected function _vacancy($v)
    {
        $v = strtoupper(trim((string) $v));
        if (!in_array($v, array('A', 'L', 'F'), true)) {
            $this->_err('validation_error', 'vacancy must be A (available), L (limited) or F (full).', 400);
        }
        return $v;
    }

    /**
     * The course's schedule template title, or null when it has none.
     *
     * Deliberately refuses instead of choosing when a product carries more than
     * one template. custom_options_relation's unique key is
     * (group_id, option_id, product_id) — one row per option — so multiple
     * DISTINCT group_ids per product are permitted by the schema even though no
     * product has them today. Picking one arbitrarily would silently label a
     * class from the wrong structure.
     */
    protected function _productScheduleTemplate($productId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $rel      = $resource->getTableName('custom_options_relation');
        $grp      = $resource->getTableName('custom_options_group');

        $titles = $read->fetchCol(
            "SELECT DISTINCT g.title
               FROM `{$rel}` r
               JOIN `{$grp}` g ON g.group_id = r.group_id
              WHERE r.product_id = ?",
            array((int) $productId)
        );

        if (!$titles) {
            return null;
        }
        if (count($titles) > 1) {
            $this->_err('ambiguous_template',
                'This course is attached to more than one schedule template ('
                . implode('; ', array_map('trim', $titles)) . '), so the shape of a multi-day class '
                . 'cannot be determined. Ask an admin to resolve the templates first.', 422);
        }
        return (string) $titles[0];
    }

    /**
     * Is the start/end heuristic in _dateLabel() provably correct for this pair?
     *
     * It is, in exactly two cases:
     *   - both dates in the same calendar month — the slash form names both days
     *     explicitly ("1/4 Jan"), so nothing can be misread;
     *   - the dates are adjacent — the dash form spans exactly those two days.
     * Anything else (cross-month AND non-adjacent) renders as a dash RANGE and
     * would wrongly imply the days in between are taught.
     */
    protected function _fallbackLabelIsSafe($start, $end)
    {
        $s = strtotime($start);
        $e = strtotime($end);
        if ($s === false || $e === false) {
            return false;
        }
        if (date('M Y', $s) === date('M Y', $e)) {
            return true;
        }
        return (int) floor(($e - $s) / 86400) === 1;
    }

    /**
     * Label a class using its course's schedule template when that template can
     * account for the dates, falling back to the start/end heuristic only where
     * the heuristic is provably right.
     *
     * The template (A01-E04 slot codes) defines the SHAPE of a class — which days
     * it runs — so it, not a guess from two dates, is the authority on whether a
     * label should read "2/4 Oct" (two separate days) or "2-4 Oct" (a run of days).
     *
     * A generated label is accepted only when BOTH its first and last dates match
     * the stored start and end. A slot that merely happens to fire on the start
     * date can produce a label that contradicts the record — e.g. a class stored
     * 2-10 Oct being labelled "2-4 Oct" — and such a label is rejected rather
     * than trusted. (Same rule the LMS parser applies.)
     *
     * Called only when a single class is created or its dates are updated; it
     * never relabels a class in bulk and never runs off a template switch.
     */
    /**
     * Decide the real shape of a class starting on $start, from the course's
     * schedule template — and correct the requested end date when it disagrees.
     *
     * This exists because the number of days is a property of the COURSE, not of
     * the request. A course on "B03 Wed-Thurs/Sat-Sun" only ever runs two-day
     * classes; asked for a single day it must produce "2/3 Jun", not "2 Jun".
     * Nobody asking in plain English ("put one on the 2nd") knows or should have
     * to know that, so the template decides and the preview says what it did.
     *
     * Three outcomes:
     *   - the asked span matches a class the template starts that day -> use it;
     *   - it does not, and the template starts exactly ONE class that day ->
     *     amend to that one and warn, so the human approves the corrected span;
     *   - it does not, and the template starts SEVERAL that day (a daytime class
     *     and a longer evening class often share a start date) -> refuse and ask
     *     which, because either would be a guess.
     * A date the template never starts a class on is still allowed — admins add
     * genuine one-offs — but it is flagged rather than passed silently.
     *
     * Returns array(start, end, label, amended, warnings). The end may differ
     * from the one passed in; callers must use the returned value.
     */
    protected function _resolveShape($productId, $start, $end)
    {
        $out = array('start' => $start, 'end' => $end, 'label' => null,
                     'amended' => false, 'warnings' => array());

        $title = $this->_productScheduleTemplate($productId);
        if ($title === null) {
            $out['label'] = $this->_shapedDateLabel($productId, $start, $end);
            return $out;
        }
        $generator = Mage::getModel('mmd/schedule_generator');
        $code = $generator->normalizeCode($title);
        if ($code === '' || !$generator->isKnownCode($code)) {
            $out['label'] = $this->_shapedDateLabel($productId, $start, $end);
            return $out;
        }

        // Every class this template starts on $start. The window runs FORWARD
        // because a label can start well before the day that triggers it — an
        // evening row pairs backwards by one day, and the five-slot E rows by up
        // to three weeks — so generating only $start would miss them.
        $window = date('Y-m-d', strtotime($start . ' +25 days'));
        $options = array();
        foreach ((array) $generator->generateForCode($code, $start, $window) as $entry) {
            $candidate = isset($entry['title']) ? (string) $entry['title'] : '';
            if ($candidate === '') {
                continue;
            }
            list($ls, $le) = $this->_parseLabel($candidate);
            if ($ls !== $start) {
                continue;
            }
            $options[$candidate] = ($le === null ? $ls : $le);
        }

        if (!$options) {
            $out['label'] = $this->_shapedDateLabel($productId, $start, $end);
            $out['warnings'][] = 'This course follows schedule template "' . trim($title) . '", which does '
                . 'not normally start a class on ' . $start . '. Adding it anyway is fine — it becomes a '
                . 'one-off date — but check it is what was intended.';
            return $out;
        }

        // Asked span matches one of the template's classes: nothing to correct.
        foreach ($options as $label => $optEnd) {
            if ($optEnd === $end) {
                $out['label'] = (string) $label;
                return $out;
            }
        }

        if (count($options) > 1) {
            $this->_err('ambiguous_class_shape',
                'Course template "' . trim($title) . '" starts more than one class on ' . $start . ': "'
                . implode('", "', array_keys($options)) . '". The dates given match neither. '
                . 'Say which by giving its end date.', 409);
        }

        $label  = (string) key($options);
        $optEnd = (string) current($options);
        $asked  = (int) floor((strtotime($end) - strtotime($start)) / 86400) + 1;
        $should = (int) floor((strtotime($optEnd) - strtotime($start)) / 86400) + 1;

        $out['end']      = $optEnd;
        $out['label']    = $label;
        $out['amended']  = true;
        $out['warnings'][] = 'This course runs as a ' . $should . '-day class on schedule template "'
            . trim($title) . '", but ' . $asked . ' day' . ($asked === 1 ? ' was' : 's were')
            . ' asked for. It has been set to "' . $label . '" to match the course. '
            . 'If a one-off ' . $asked . '-day class really is wanted, an admin can add it through the '
            . 'admin schedule.';
        return $out;
    }

    protected function _shapedDateLabel($productId, $start, $end)
    {
        // A single-day class cannot be misread — no template lookup needed.
        if ($start === $end) {
            return $this->_dateLabel($start, $end);
        }

        $title = $this->_productScheduleTemplate($productId);
        if ($title !== null) {
            $generator = Mage::getModel('mmd/schedule_generator');
            $code      = $generator->normalizeCode($title);
            if ($code !== '' && $generator->isKnownCode($code)) {
                foreach ((array) $generator->generateForCode($code, $start, $end) as $entry) {
                    $candidate = isset($entry['title']) ? (string) $entry['title'] : '';
                    if ($candidate === '') {
                        continue;
                    }
                    list($labelStart, $labelEnd) = $this->_parseLabel($candidate);
                    // Both ends must agree with the record, or the label
                    // describes a different class than the one being saved.
                    if ($labelStart === $start && $labelEnd === $end) {
                        return $candidate;
                    }
                }
            }
        }

        if ($this->_fallbackLabelIsSafe($start, $end)) {
            return $this->_dateLabel($start, $end);
        }

        $this->_err('ambiguous_date_shape',
            'This course has no schedule template that accounts for ' . $start . ' to ' . $end
            . ', and the dates span more than one month without being consecutive — so the label '
            . 'would read as a range of days and wrongly imply the days in between are taught. '
            . 'Add this class through the admin schedule instead, where the exact days can be set.', 422);
    }

    /**
     * Heuristic label from a start/end pair, used when no schedule template
     * accounts for the dates.
     *
     * The two-date shape is delegated to the generator's pairLabel() so this and
     * the template roll-out cannot drift into different formats. That matters:
     * the shape this used to emit for a cross-month span
     * ("28 Sep - 1 Oct 2026") is not in the date parser's grammar at all, so
     * every label written that way was unreadable afterwards - the class could
     * not be matched to an order, and the date could not be located again.
     */
    protected function _dateLabel($start, $end)
    {
        $s = new DateTime($start);
        if ($start === $end) {
            return $s->format('j M Y') . ' (' . $s->format('D') . ')';
        }
        // Always the slash form: this is only reached for pairs
        // _fallbackLabelIsSafe() has cleared - same month, or adjacent days - and
        // in both the label names two specific days rather than a run.
        $e = new DateTime($end);
        return Mage::getModel('mmd/schedule_generator')->pairLabel($s, $e, '/')
            . ' (' . $s->format('D') . '/' . $e->format('D') . ')';
    }

    protected function _disp($v)
    {
        return ($v === null || $v === '') ? '(none)' : (string) $v;
    }
}
