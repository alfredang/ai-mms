<?php
/**
 * Capability: edit course schedule.
 *
 *   op: add_class      { course_sku, start_date, end_date?, start_time?, end_time?, mode?, venue?, vacancy? }
 *   op: update_class   { class_id, start_date?, end_date?, start_time?, end_time?, mode?, venue?, vacancy? }
 *   op: remove_class   { class_id, force? }
 *   op: assign_trainer { class_id, trainer }        (name or trainer_option_id)
 *
 * There is deliberately no per-course "generate a range" op: to add several
 * dates to one course the agent calls add_class once per date (each is an
 * admin-managed, durable class). Bulk schedule generation across ALL products
 * is a template-level operation (see api_template), not a per-course one.
 *
 * Keeps two things in sync: the authoritative class record (course_runs) and
 * the learner-facing "Course Date" custom-option value on the product. Class
 * identity is (course, start date); a new date is a new class. Enrolment-
 * affecting edits are applied + audited but do NOT notify learners in v1 - the
 * preview surfaces the enrolment count so the agent can tell the user.
 */
class MMD_AgentApi_Model_Schedule extends MMD_AgentApi_Model_Abstract
{
    const COURSE_DATE_OPTION = 'Course Date';
    const COURSE_TIME_OPTION = 'Course Time';

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
            default:
                $this->_err('validation_error', 'Unsupported op "' . $op . '" for api_schedule.', 400);
        }
    }

    /* ------------------------------------------------------------------ add */

    protected function _previewAdd(array $body)
    {
        $sku       = $this->_require($body, 'course_sku');
        $startDate = $this->_date($this->_require($body, 'start_date'), 'start_date');
        $endDate   = $this->_date($this->_opt($body, 'end_date', $startDate), 'end_date');
        $startTime = (string) $this->_opt($body, 'start_time', '');
        $endTime   = (string) $this->_opt($body, 'end_time', '');
        $mode      = $this->_modeInt($this->_opt($body, 'mode', 'Physical Classroom'));
        $venue     = (string) $this->_opt($body, 'venue', '');
        $vacancy   = $this->_vacancy($this->_opt($body, 'vacancy', 'A'));

        $product = $this->_loadAdmin($sku);

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
        if ($this->_runExists($product->getId(), $startDate, $endDate)) {
            $this->_err('conflict', 'A class for ' . $sku . ' already exists on ' . $startDate . '.', 409);
        }
        $label = $this->_dateLabel($startDate, $endDate);

        return array(
            'target'        => $sku,
            'diff'          => array(array('field' => 'class', 'from' => null,
                'to' => $label . ' - ' . $this->_intToMode[$mode] . ($venue ? ' @ ' . $venue : ''))),
            'human_summary' => 'A new class for "' . $product->getName() . '" (' . $sku . ') will be added on '
                                . $label . ' (' . $this->_intToMode[$mode] . ($venue ? ', ' . $venue : '')
                                . '). A new SG-series class id is assigned on confirm.'
                                . ($bootstrap ? ' This course has no schedule yet, so this also sets it up ('
                                    . $startTime . '-' . $endTime . ').' : ''),
            'warnings'      => $bootstrap
                ? array('This course has no schedule yet - confirming creates its date + time lists (a one-off, not a shared template) and adds this first class.')
                : array(),
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
        $read  = $resource->getConnection('core_read');
        $write = $resource->getConnection('core_write');
        $table = $resource->getTableName('course_runs');
        $cc    = MMD_RoleManager_Helper_Data::countryCodeForProduct($read, $p['product_id']);
        $classId = MMD_RoleManager_Helper_Data::nextClassId($write, $table, $cc);
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
        $classId = $this->_require($body, 'class_id');
        $run     = $this->_loadRunByClassId($classId);

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
        $enrol = $this->_enrolmentCount($run['run_id']);
        $dateChanged = isset($fields['course_start_date']) || isset($fields['course_end_date']);
        if ($dateChanged && $enrol > 0) {
            $warnings[] = $enrol . ' learner(s) are enrolled on this class; they will NOT be auto-notified of the date change.';
        }

        return array(
            'target'        => $classId,
            'diff'          => $diff,
            'human_summary' => 'Class ' . $classId . ' (' . $run['course_sku'] . '): '
                                . implode('; ', array_map(function ($d) { return $d['field'] . ' ' . $this->_disp($d['from']) . ' -> ' . $this->_disp($d['to']); }, $diff)) . '.',
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
            $synced   = $optionId ? $this->_updateCourseDateTitleSql($optionId, $p['old_start'], $p['old_end'], $this->_dateLabel($newStart, $newEnd)) : false;
            if ($synced) { $this->_resortCourseDateValues($optionId); $this->_touchProduct($p['product_id']); }
            $reindexed[] = $synced ? 'option_value' : 'run_only';
        }
        return array('target' => $p['class_id'], 'reindexed' => $reindexed, 'after' => $p['fields']);
    }

    /* --------------------------------------------------------------- remove */

    protected function _previewRemove(array $body)
    {
        $classId = $this->_require($body, 'class_id');
        $force   = !empty($body['force']);
        $run     = $this->_loadRunByClassId($classId);
        $enrol   = $this->_enrolmentCount($run['run_id']);

        if ($enrol > 0 && !$force) {
            $this->_err('enrolments_exist',
                'Class ' . $classId . ' has ' . $enrol . ' enrolled learner(s). Re-issue with "force": true to remove it anyway.', 422);
        }
        $warnings = $enrol > 0
            ? array($enrol . ' enrolled learner(s) will be affected; they are NOT auto-notified in v1.')
            : array();

        return array(
            'target'        => $classId,
            'diff'          => array(array('field' => 'class', 'from' => $run['course_start_date'], 'to' => null)),
            'human_summary' => 'Class ' . $classId . ' (' . $run['course_sku'] . ', ' . $run['course_start_date'] . ') will be removed'
                                . ($enrol > 0 ? ' - ' . $enrol . ' learner(s) enrolled' : '') . '.',
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
        $classId = $this->_require($body, 'class_id');
        $trainer = $this->_require($body, 'trainer');
        $emailIn = trim((string) $this->_opt($body, 'trainer_email', ''));
        $run     = $this->_loadRunByClassId($classId);

        $res     = $this->_resolveTrainer($trainer, $emailIn);
        $oldName = $this->_currentTrainerName($run);

        if ($res['mode'] === 'existing' && (int) $res['user_id'] === (int) $run['trainer_user_id']) {
            $this->_err('validation_error', 'Class ' . $classId . ' is already assigned to ' . $res['name'] . '.', 400);
        }

        $warnings = array();
        if ($res['mode'] === 'create') {
            if ($res['source'] === 'link') {
                $warnings[] = $res['name'] . ' already has an MMS account - assigning them grants that existing account the trainer role (no new account is created; email ' . $res['email'] . ').';
            } elseif ($res['source'] === 'legacy') {
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
                                . ($res['mode'] === 'create'
                                    ? ($res['source'] === 'link'
                                        ? ' (the trainer role will be added to their existing account)'
                                        : ' (a trainer account will be set up for them)')
                                    : '') . '.',
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

    /* ------------------------------------------------------------- internals */

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
                $this->_err('not_found', 'No course with sku=' . $sku . '.', 404);
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
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        $tt = $resource->getTableName('catalog/product_option_type_title');
        $write->update($tt, array('title' => $newLabel), array('option_type_id = ?' => $otid, 'store_id = ?' => 0));
        // A date edit takes ownership of this value: flag it so a later template
        // Apply never reconciles/removes it (mirrors the Edit Course tab).
        $tv = $resource->getTableName('catalog/product_option_type_value');
        $write->update($tv, array('admin_managed' => 1), array('option_type_id = ?' => $otid));
        return true;
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

        // 2. Existing admin_user with this email but no trainer role yet. The commit
        //    (_ensureTrainerAccount) dedupes by email and just grants the trainer role,
        //    so surface that accurately instead of claiming a brand-new account is made.
        if ($email !== '' && strpos($email, '@') !== false) {
            $existing = $this->_findAdminUserByEmail($email);
            if ($existing) {
                return array('mode' => 'create', 'source' => 'link',
                    'user_id' => $existing['user_id'], 'name' => $existing['name'], 'email' => $email);
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

    /** Existing admin_user by email (any role) -> ['user_id','name','email'] or null. */
    protected function _findAdminUserByEmail($email)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $au = $resource->getTableName('admin_user');
        $row = $read->fetchRow(
            "SELECT user_id, TRIM(CONCAT(COALESCE(firstname,''), ' ', COALESCE(lastname,''))) AS name, email"
            . " FROM `{$au}` WHERE LOWER(email) = ? LIMIT 1",
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

        $userId = (int) $read->fetchOne("SELECT user_id FROM `{$auTbl}` WHERE LOWER(email) = ? LIMIT 1", array(strtolower($email)));
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

    protected function _date($v, $field)
    {
        $v = trim((string) $v);
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $v) || !strtotime($v)) {
            $this->_err('validation_error', $field . ' must be a valid YYYY-MM-DD date.', 400);
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

    protected function _dateLabel($start, $end)
    {
        $s = strtotime($start); $e = strtotime($end);
        if ($start === $end) {
            return date('j M Y', $s) . ' (' . date('D', $s) . ')';
        }
        if (date('M Y', $s) === date('M Y', $e)) {
            return date('j', $s) . '/' . date('j', $e) . ' ' . date('M Y', $s) . ' (' . date('D', $s) . '/' . date('D', $e) . ')';
        }
        return date('j M', $s) . ' - ' . date('j M Y', $e) . ' (' . date('D', $s) . '-' . date('D', $e) . ')';
    }

    protected function _disp($v)
    {
        return ($v === null || $v === '') ? '(none)' : (string) $v;
    }
}
