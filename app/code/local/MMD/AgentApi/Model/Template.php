<?php
/**
 * Capability: schedule-template bulk operations (generate + apply to ALL products).
 *
 *   op: generate_and_apply { template, start_date, end_date, slot_code? }
 *
 * Reuses the native GAS port (mmd/schedule_generator) and the same option-value
 * write path (catalog/product_option::saveProductOptions) that the admin "Manage
 * Templates" scheduler uses. The generate+merge and apply helpers are FAITHFUL
 * PORTS of MMD_Adminhtml_Block/Controller Customoptions OptionsController's
 * _generateAndMerge() / runGlobalApplyAction() / _resolveProductIds() /
 * _parseTitleTimestamp() - kept here (rather than refactoring the load-bearing
 * admin controller) so the agent surface stays isolated. If the admin scheduler
 * logic changes, mirror it here.
 *
 * Append-only: generate merges new dates in (deduped by reg_course|title) and
 * never removes existing template dates. The apply reconciles ONLY the template's
 * own generated values - admin_managed=1 (case-by-case admin/agent-added) dates
 * are protected by the saveProductOptions guard (migration 780).
 */
class MMD_AgentApi_Model_Template extends MMD_AgentApi_Model_Abstract
{
    const COURSE_DATE = 'Course Date';
    const COURSE_TIME = 'Course Time';

    public function preview($op, array $body)
    {
        switch ($op) {
            case 'generate_and_apply': return $this->_previewGenerateApply($body);
            case 'assign_course':      return $this->_previewAssignCourse($body);
            default:
                $this->_err('validation_error',
                    'Unsupported op "' . $op . '" for api_template (generate_and_apply | assign_course).', 400);
        }
    }

    public function commit($op, array $body, array $preview)
    {
        switch ($op) {
            case 'generate_and_apply': return $this->_commitGenerateApply($preview);
            case 'assign_course':      return $this->_commitAssignCourse($preview);
            default:
                $this->_err('validation_error', 'Unsupported op "' . $op . '" for api_template.', 400);
        }
    }

    /* ------------------------------------------------ generate_and_apply */

    protected function _previewGenerateApply(array $body)
    {
        $ref   = $this->_require($body, 'template');
        $start = $this->_date($this->_require($body, 'start_date'), 'start_date');
        $end   = $this->_date($this->_require($body, 'end_date'), 'end_date');
        if ($start > $end) {
            $this->_err('validation_error', 'start_date must be on or before end_date.', 400);
        }

        $group = $this->_resolveTemplate($ref);
        $code  = $this->_codeForGroup($group, $body);

        $entries = Mage::getModel('mmd/schedule_generator')->generateForCode($code, $start, $end);
        if (!$entries) {
            $this->_err('validation_error', 'No dates generated for template "' . $group->getTitle()
                . '" (slot ' . strtoupper($code) . ') between ' . $start . ' and ' . $end . '.', 400);
        }

        // Which generated dates are NEW (not already in the template)?
        $existing = $this->_existingSignatures($group);
        $newTitles = array();
        foreach ($entries as $e) {
            $sig = strtolower(trim($e['reg_course'] . '|' . $e['title']));
            if (!isset($existing[$sig])) {
                $newTitles[] = $e['title'];
            }
        }
        if (!$newTitles) {
            $this->_err('validation_error', 'All ' . count($entries) . ' generated date(s) are already in template "'
                . $group->getTitle() . '" - nothing to add.', 400);
        }

        $productIds = $this->_resolveProductIds($group);
        $pc = count($productIds);

        return array(
            'target'        => $group->getTitle(),
            'diff'          => array(array('field' => 'template_dates', 'from' => null, 'to' => $newTitles)),
            'human_summary' => 'Add ' . count($newTitles) . ' new class date(s) to template "' . $group->getTitle()
                                . '" (slot ' . strtoupper($code) . ') and apply to ALL ' . $pc . ' course(s) using it: '
                                . implode('; ', $newTitles) . '.',
            'warnings'      => array(
                'This applies to ALL ' . $pc . ' course(s) assigned to this template, not just one course.',
                'Append-only: existing template dates are kept, and any date an admin added to a single course by hand is never removed.',
            ),
            'token_payload' => array(
                'group_id' => (int) $group->getId(), 'code' => $code, 'start' => $start, 'end' => $end,
                'add'      => $newTitles, 'products' => $this->_sortedInts($productIds),
            ),
        );
    }

    protected function _commitGenerateApply(array $preview)
    {
        $p     = $preview['token_payload'];
        $group = Mage::getModel('customoptions/group')->load((int) $p['group_id']);
        if (!$group->getId()) {
            $this->_err('not_found', 'Template #' . (int) $p['group_id'] . ' not found.', 404);
        }

        $merge   = $this->_generateAndMerge($group, $p['code'], $p['start'], $p['end']);
        $applied = $this->_applyGroupToProducts($group);

        return array(
            'target'    => $group->getTitle(),
            'reindexed' => array('option_value', 'catalog_product_price'),
            'after'     => array('dates_added' => $merge['added'], 'products_applied' => $applied),
            'extra'     => array(
                'template'         => $group->getTitle(),
                'dates_added'      => $merge['added'],
                'already_present'  => $merge['existing'],
                'products_applied' => $applied,
            ),
        );
    }

    /* --------------------------------------------------------- assign_course */

    protected function _previewAssignCourse(array $body)
    {
        $ref = $this->_require($body, 'template');
        $sku = $this->_require($body, 'course_sku');
        $group = $this->_resolveTemplate($ref);

        $pid = (int) Mage::getModel('catalog/product')->getIdBySku($sku);
        if (!$pid) {
            $this->_err('not_found', 'No course with sku=' . $sku . '.', 404);
        }
        $product = Mage::getModel('catalog/product')->setStoreId(0)->load($pid);

        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $rel  = Mage::getSingleton('core/resource')->getTableName('custom_options_relation');
        $isMember = (bool) $read->fetchOne(
            "SELECT 1 FROM `{$rel}` WHERE group_id = ? AND product_id = ? LIMIT 1",
            array((int) $group->getId(), $pid));
        if ($isMember) {
            $this->_err('conflict', 'Course ' . $sku . ' is already on template "' . $group->getTitle() . '".', 409);
        }

        $dateCount = count($this->_existingSignatures($group));
        $alreadyScheduled = (bool) $this->_courseDateOptionId($pid);
        $warnings = array();
        if ($alreadyScheduled) {
            $warnings[] = 'This course already has its own schedule; the template dates will be merged in. Any date an admin added by hand is kept.';
        }

        return array(
            'target'        => $sku,
            'diff'          => array(array('field' => 'template', 'from' => null, 'to' => $group->getTitle())),
            'human_summary' => 'Course "' . $product->getName() . '" (' . $sku . ') will be added to template "'
                                . $group->getTitle() . '" and receive its ' . $dateCount . ' scheduled class date(s). '
                                . 'It then stays in sync with future roll-outs of this template.',
            'warnings'      => $warnings,
            'token_payload' => array('group_id' => (int) $group->getId(), 'product_id' => $pid, 'sku' => $sku),
        );
    }

    protected function _commitAssignCourse(array $preview)
    {
        $p     = $preview['token_payload'];
        $group = Mage::getModel('customoptions/group')->load((int) $p['group_id']);
        if (!$group->getId()) {
            $this->_err('not_found', 'Template #' . (int) $p['group_id'] . ' not found.', 404);
        }
        // Apply the template's current schedule to just this one course - creates
        // its Course Date/Time options + the membership relation, so future
        // generate_and_apply roll-outs include it.
        $this->_applyGroupToProducts($group, array((int) $p['product_id']));

        return array(
            'target'    => $p['sku'],
            'reindexed' => array('option_value', 'catalog_product_price'),
            'after'     => array('added_to_template' => $group->getTitle()),
            'extra'     => array('template' => $group->getTitle(), 'course' => $p['sku']),
        );
    }

    /** option_id of the product's "Course Date" custom option, or 0. */
    protected function _courseDateOptionId($productId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read = $resource->getConnection('core_read');
        $o    = $resource->getTableName('catalog/product_option');
        $ot   = $resource->getTableName('catalog/product_option_title');
        return (int) $read->fetchOne(
            "SELECT o.option_id FROM `{$o}` o JOIN `{$ot}` ot ON ot.option_id = o.option_id
              WHERE o.product_id = ? AND ot.title = 'Course Date' ORDER BY ot.store_id LIMIT 1",
            array((int) $productId));
    }

    /* ------------------------------------------------- template resolution */

    /** Resolve a loose template reference ("A01", "WSQ A01", "(SG) WSQ-B01") to a group. */
    protected function _resolveTemplate($ref)
    {
        $ref = trim((string) $ref);
        $gen = Mage::getModel('mmd/schedule_generator');
        $refCode = $gen->normalizeCode($ref);
        $tokens  = $this->_titleTokens($ref);

        if ($refCode === '' && empty($tokens)) {
            $this->_err('validation_error',
                'Name the template by its slot code (e.g. A01) or part of its name (e.g. "WSQ A01").', 400);
        }

        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $rows = $read->fetchAll('SELECT group_id, title FROM ' . $read->getTableName('custom_options_group'));

        $cands = array();
        foreach ($rows as $r) {
            $title = (string) $r['title'];
            if ($refCode !== '' && $gen->normalizeCode($title) !== $refCode) {
                continue;
            }
            $matchAll = true;
            foreach ($tokens as $tok) {
                if (stripos($title, $tok) === false) { $matchAll = false; break; }
            }
            if (!$matchAll) {
                continue;
            }
            $cands[(int) $r['group_id']] = $title;
        }

        if (count($cands) === 1) {
            return Mage::getModel('customoptions/group')->load((int) array_keys($cands)[0]);
        }
        if (count($cands) === 0) {
            $this->_err('not_found',
                'No schedule template matches "' . $ref . '". Give the slot code (A01-E04) or part of the template name.', 404);
        }
        $titles = array_values($cands);
        sort($titles);
        $this->_err('ambiguous_template',
            'Several templates match "' . $ref . '": ' . implode(' | ', $titles)
            . '. Please be more specific (e.g. include "WSQ" or "SG", or use the exact code).', 409);
    }

    /** Words in the reference that are NOT the slot code (e.g. "WSQ A01" -> ["WSQ"]). */
    protected function _titleTokens($ref)
    {
        $stripped = preg_replace('/[A-Ea-e]\s*0*[0-9]+/', ' ', (string) $ref);
        $tokens = array();
        foreach (preg_split('/[^A-Za-z0-9]+/', $stripped) as $w) {
            $w = trim($w);
            if (strlen($w) >= 2 && !is_numeric($w)) {
                $tokens[] = $w;
            }
        }
        return $tokens;
    }

    /** Slot code for a group: explicit slot_code override, else derived from the title. */
    protected function _codeForGroup($group, array $body)
    {
        $gen = Mage::getModel('mmd/schedule_generator');
        if (!empty($body['slot_code'])) {
            $c = $gen->normalizeCode($body['slot_code']);
            if ($c === '') {
                $this->_err('validation_error', 'slot_code "' . $body['slot_code'] . '" is not a valid A01-E04 code.', 400);
            }
            return $c;
        }
        $c = $gen->normalizeCode((string) $group->getTitle());
        if ($c === '') {
            $this->_err('validation_error',
                'Template "' . $group->getTitle() . '" has no A01-E04 slot code in its name; pass slot_code explicitly.', 422);
        }
        return $c;
    }

    /** reg_course|title signatures of the template's existing Course Date values. */
    protected function _existingSignatures($group)
    {
        $sigs = array();
        $opts = @unserialize($group->getHashOptions());
        if (!is_array($opts)) {
            return $sigs;
        }
        foreach ($opts as $opt) {
            if (empty($opt['title']) || strcasecmp(trim($opt['title']), self::COURSE_DATE) !== 0) {
                continue;
            }
            foreach ((array) ($opt['values'] ?? array()) as $v) {
                $sig = strtolower(trim((isset($v['reg_course']) ? $v['reg_course'] : '') . '|' . (isset($v['title']) ? $v['title'] : '')));
                $sigs[$sig] = true;
            }
        }
        return $sigs;
    }

    /* --------------------------------------- ports from OptionsController */

    /** Faithful port of OptionsController::_resolveProductIds(). */
    protected function _resolveProductIds($group)
    {
        $ids = array_values(array_filter(array_map('intval', explode(',', (string) $group->getInProducts()))));
        if (!empty($ids)) {
            return $ids;
        }
        $db  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $tbl = Mage::getSingleton('core/resource')->getTableName('custom_options_relation');
        $rows = $db->fetchAll('SELECT DISTINCT product_id FROM ' . $tbl . ' WHERE group_id = ?', array((int) $group->getId()));
        return array_values(array_map('intval', array_column($rows, 'product_id')));
    }

    /** Faithful port of OptionsController::_generateAndMerge(). */
    protected function _generateAndMerge($group, $code, $start, $end)
    {
        $entries = Mage::getModel('mmd/schedule_generator')->generateForCode($code, $start, $end);
        if (empty($entries)) {
            return array('added' => 0, 'fixed' => 0, 'existing' => 0);
        }

        $hash = $group->getHashOptions();
        $opts = ($hash !== '' && $hash !== null) ? @unserialize($hash) : array();
        if (!is_array($opts)) {
            $opts = array();
        }

        $cdOptId = null;
        foreach ($opts as $optId => $opt) {
            if (!empty($opt['title']) && strcasecmp(trim($opt['title']), self::COURSE_DATE) === 0) {
                $cdOptId = $optId;
                break;
            }
        }
        if ($cdOptId === null) {
            $cdOptId = 1;
            foreach (array_keys($opts) as $k) {
                if ((int) $k >= $cdOptId) $cdOptId = (int) $k + 1;
            }
            $opts[$cdOptId] = array('option_id' => (string) $cdOptId, 'title' => self::COURSE_DATE,
                'type' => 'drop_down', 'is_require' => '1', 'sort_order' => '1', 'values' => array());
        }
        if (empty($opts[$cdOptId]['values']) || !is_array($opts[$cdOptId]['values'])) {
            $opts[$cdOptId]['values'] = array();
        }

        // Course Time dep_ids (first = morning, last = evening).
        $morningDepId = '';
        $eveningDepId = '';
        foreach ($opts as $opt) {
            if (empty($opt['title']) || strcasecmp(trim($opt['title']), self::COURSE_TIME) !== 0) continue;
            if (empty($opt['values']) || !is_array($opt['values'])) break;
            $ctVals = array_values($opt['values']);
            usort($ctVals, function ($a, $b) { return (int) ($a['sort_order'] ?? 0) - (int) ($b['sort_order'] ?? 0); });
            $morningDepId = (string) (($ctVals[0]['in_group_id'] ?? '') !== '' ? $ctVals[0]['in_group_id'] : ($ctVals[0]['option_type_id'] ?? ''));
            if (count($ctVals) >= 2) {
                $last = $ctVals[count($ctVals) - 1];
                $eveningDepId = (string) (($last['in_group_id'] ?? '') !== '' ? $last['in_group_id'] : ($last['option_type_id'] ?? ''));
            }
            break;
        }

        $maxInGroupId = 0;
        foreach ($opts as $o) {
            foreach ((array) ($o['values'] ?? array()) as $v) {
                if (isset($v['in_group_id']) && $v['in_group_id'] !== '') $maxInGroupId = max($maxInGroupId, (int) $v['in_group_id']);
            }
        }

        $seen = array();
        $maxValId = 0;
        $maxSort = 0;
        $fixed = 0;
        $hasCourseTime = ($morningDepId !== '' || $eveningDepId !== '');
        foreach ($opts[$cdOptId]['values'] as $vid => $v) {
            $sig = strtolower(trim((isset($v['reg_course']) ? $v['reg_course'] : '') . '|' . (isset($v['title']) ? $v['title'] : '')));
            $seen[$sig] = true;
            $maxValId = max($maxValId, (int) ($v['option_type_id'] ?? $vid));
            if (isset($v['sort_order'])) $maxSort = max($maxSort, (int) $v['sort_order']);
            if ($hasCourseTime) {
                $isEvening  = (stripos($v['title'] ?? '', 'Evening') !== false);
                $correctDep = $isEvening ? $eveningDepId : $morningDepId;
                if ($correctDep !== '' && (string) ($v['dependent_ids'] ?? '') !== $correctDep) {
                    $opts[$cdOptId]['values'][$vid]['dependent_ids'] = $correctDep;
                    $fixed++;
                }
            }
        }

        $added = 0;
        $existing = 0;
        foreach ($entries as $e) {
            $sig = strtolower(trim($e['reg_course'] . '|' . $e['title']));
            if (isset($seen[$sig])) { $existing++; continue; }
            $seen[$sig] = true;
            $maxValId++;
            $maxSort++;
            $maxInGroupId++;
            $isEvening = (stripos($e['title'], 'Evening') !== false);
            $depId = $isEvening ? $eveningDepId : $morningDepId;
            $opts[$cdOptId]['values'][$maxValId] = array(
                'option_type_id' => (string) $maxValId, 'is_delete' => '', 'in_group_id' => (string) $maxInGroupId,
                'title' => $e['title'], 'reg_course' => $e['reg_course'], 'price' => '0.00', 'price_type' => 'fixed',
                'sku' => '', 'sort_order' => (string) $maxSort, 'customoptions_qty' => '', 'dependent_ids' => $depId,
                'images' => array(),
            );
            $added++;
        }

        if ($added > 0 || $fixed > 0) {
            $vals = array_values($opts[$cdOptId]['values']);
            usort($vals, function ($a, $b) {
                return $this->_parseTitleTimestamp($a['title'] ?? '') - $this->_parseTitleTimestamp($b['title'] ?? '');
            });
            $sorted = array();
            foreach ($vals as $i => $v) {
                $v['sort_order'] = (string) ($i + 1);
                $sorted[(int) $v['option_type_id']] = $v;
            }
            $opts[$cdOptId]['values'] = $sorted;
            $group->setHashOptions(serialize($opts))->save();
        }
        return array('added' => $added, 'fixed' => $fixed, 'existing' => $existing);
    }

    /**
     * Faithful port of OptionsController::runGlobalApplyAction() core. Applies the
     * template to its own products, or to an explicit $productIds set (used by
     * assign_course to apply to a single new member).
     */
    protected function _applyGroupToProducts($group, $productIds = null)
    {
        $newOpts = @unserialize($group->getHashOptions());
        if (!is_array($newOpts)) $newOpts = array();

        $maxIgi = 0;
        foreach ($newOpts as $o) {
            foreach ((array) ($o['values'] ?? array()) as $v) {
                if (isset($v['in_group_id']) && $v['in_group_id'] !== '') $maxIgi = max($maxIgi, (int) $v['in_group_id']);
            }
        }
        foreach ($newOpts as &$optFix) {
            if (!empty($optFix['values']) && is_array($optFix['values'])) {
                foreach ($optFix['values'] as &$vFix) {
                    if (!isset($vFix['in_group_id']) || $vFix['in_group_id'] === '') $vFix['in_group_id'] = (string) (++$maxIgi);
                }
                unset($vFix);
            }
        }
        unset($optFix);

        foreach ($newOpts as &$opt) {
            if (empty($opt['values']) || !is_array($opt['values'])) continue;
            $title = strtolower(trim($opt['title'] ?? ''));
            if (strpos($title, 'date') === false && strpos($title, 'course') === false) continue;
            $vals = array_values($opt['values']);
            usort($vals, function ($a, $b) {
                return $this->_parseTitleTimestamp($a['title'] ?? '') - $this->_parseTitleTimestamp($b['title'] ?? '');
            });
            $sorted = array();
            foreach ($vals as $i => $v) {
                $v['sort_order'] = (string) ($i + 1);
                $keyId = (isset($v['option_type_id']) && $v['option_type_id'] !== '') ? (int) $v['option_type_id'] : $i;
                $v['option_type_id'] = (string) $keyId;
                $sorted[$keyId] = $v;
            }
            $opt['values'] = $sorted;
        }
        unset($opt);

        if ($productIds === null) {
            $productIds = $this->_resolveProductIds($group);
        }
        if (!empty($productIds)) {
            Mage::getModel('catalog/product_option')->saveProductOptions(
                $newOpts, array(), $productIds, $group, $group->getIsActive(), 'apo', array());
            Mage::getResourceModel('catalog/product_indexer_price')->reindexProductIds($productIds);
        }
        return count($productIds);
    }

    /** Faithful port of OptionsController::_parseTitleTimestamp(). */
    protected function _parseTitleTimestamp($title)
    {
        $clean = preg_replace('/^(\d+)\/\d+\s+/', '$1 ', trim($title));
        $clean = preg_replace('/\s+(Evening|Morning|Afternoon|Night)\b.*/i', '', $clean);
        $clean = preg_replace('/\s*\([^)]*\)\s*$/', '', $clean);
        $clean = trim($clean);
        $ts = strtotime($clean);
        if ($ts !== false) return $ts;
        if (preg_match('/(\d{1,2})\s+(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(\d{4})/i', $clean, $m)) {
            $ts = strtotime($m[1] . ' ' . $m[2] . ' ' . $m[3]);
            if ($ts !== false) return $ts;
        }
        return PHP_INT_MAX;
    }

    /* ------------------------------------------------------------ helpers */

    protected function _date($v, $field)
    {
        $v = trim((string) $v);
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $v) || !strtotime($v)) {
            $this->_err('validation_error', $field . ' must be a valid YYYY-MM-DD date.', 400);
        }
        return $v;
    }

    protected function _sortedInts($arr)
    {
        $out = array_map('intval', (array) $arr);
        sort($out);
        return $out;
    }
}
