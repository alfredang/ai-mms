<?php

/**
 * Switches one course onto a different schedule-option template
 * (MMD_CustomOptions group, e.g. "(SG) WSQ-D01").
 *
 * Moved verbatim out of CoursesaveController::switchScheduleTemplateAction so the
 * admin "Switch template" button and the daily funding-expiry job
 * (MMD_Courses_Model_Cron_FundingExpiry) share one code path.
 *
 * Flow: remove the product's options that belong to its CURRENT template
 * group(s) (snapshotting admin_managed=1 values first, so case-by-case
 * confirmed dates are never lost), apply the new template to just this
 * product via the shared apply path, then re-insert the snapshotted
 * admin-managed values into the same-titled new options.
 */
class MMD_RoleManager_Model_ScheduleTemplateSwitch
{
    /**
     * @return array { success, from, to, restored_admin_dates, dropped_admin_dates }
     *               or { success, no_change, message }
     * @throws Exception on a missing course or template
     */
    public function switchProduct($pid, $gid)
    {
        $pid = (int) $pid;
        $gid = (int) $gid;
        if ($pid <= 0 || $gid <= 0) throw new Exception('course_id and group_id required');

        $product = Mage::getModel('catalog/product')->load($pid);
        if (!$product->getId()) throw new Exception('Course #' . $pid . ' not found');

        $group = Mage::getModel('customoptions/group')->load($gid);
        if (!$group->getId()) throw new Exception('Schedule template #' . $gid . ' not found');

        $relation    = Mage::getResourceSingleton('customoptions/relation');
        $optionModel = Mage::getModel('catalog/product_option');
        $curGids     = array_map('intval', (array) $relation->getGroupIds($pid));

        if (in_array($gid, $curGids, true)) {
            return array('success' => true, 'no_change' => true,
                'message' => 'Course is already on template "' . $group->getTitle() . '".');
        }

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $tOpt     = $resource->getTableName('catalog/product_option');
        $tOptT    = $resource->getTableName('catalog/product_option_title');
        $tVal     = $resource->getTableName('catalog/product_option_type_value');
        $tValT    = $resource->getTableName('catalog/product_option_type_title');
        $tValP    = $resource->getTableName('catalog/product_option_type_price');

        $fromTitles = array();
        $snapshot   = array();
        if (!empty($curGids)) {
            $fromTitles = $read->fetchCol(
                'SELECT title FROM ' . $resource->getTableName('custom_options_group')
                . ' WHERE group_id IN (' . implode(',', $curGids) . ') ORDER BY title');

            // Snapshot admin-managed (case-by-case confirmed) values living on the
            // options that are about to be removed with their old template.
            $oldOptionIds = array();
            foreach ($curGids as $og) {
                foreach ((array) $relation->getOptionIds($og, $pid) as $oid) {
                    $oldOptionIds[] = (int) $oid;
                }
            }
            if (!empty($oldOptionIds)) {
                $snapshot = $read->fetchAll(
                    "SELECT ot.title AS option_title, tt.title AS value_title,
                            tv.reg_course, tv.sku, tv.sort_order, tp.price
                       FROM {$tVal} tv
                       JOIN {$tOptT} ot ON ot.option_id = tv.option_id AND ot.store_id = 0
                       LEFT JOIN {$tValT} tt ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
                       LEFT JOIN {$tValP} tp ON tp.option_type_id = tv.option_type_id AND tp.store_id = 0
                      WHERE tv.admin_managed = 1
                        AND tv.option_id IN (" . implode(',', $oldOptionIds) . ")");
            }

            // Drop the old template's options + membership for THIS product only.
            foreach ($curGids as $og) {
                $optionModel->removeProductOptions($og, $pid);
                $relation->deleteGroupProduct($og, $pid);
            }
        }

        // Apply the new template to just this product (shared apply path —
        // same normalization the agent API's assign_course uses).
        Mage::getModel('mmd_agentapi/template')->applyGroupToProduct($group, $pid);

        // Re-insert snapshotted admin-managed values into the same-titled new
        // option (dedup on reg_course|title against what the template created).
        $restored = 0;
        $dropped  = array();
        foreach ($snapshot as $s) {
            $newOptId = (int) $read->fetchOne(
                "SELECT o.option_id FROM {$tOpt} o
                   JOIN {$tOptT} ot ON ot.option_id = o.option_id AND ot.store_id = 0
                  WHERE o.product_id = ? AND LOWER(TRIM(ot.title)) = ?
                  ORDER BY o.option_id LIMIT 1",
                array($pid, strtolower(trim((string) $s['option_title']))));
            if (!$newOptId) {
                $dropped[] = (string) $s['value_title'];
                continue;
            }
            $exists = (int) $read->fetchOne(
                "SELECT COUNT(*) FROM {$tVal} tv
                   JOIN {$tValT} tt ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
                  WHERE tv.option_id = ? AND LOWER(TRIM(COALESCE(tv.reg_course,''))) = ?
                    AND LOWER(TRIM(tt.title)) = ?",
                array($newOptId,
                      strtolower(trim((string) $s['reg_course'])),
                      strtolower(trim((string) $s['value_title']))));
            if ($exists) continue;   // template already carries this date

            // Unique in_group_id across the product's values — an empty one
            // collides to a single key on the next template apply (data loss).
            $maxIgi = (int) $read->fetchOne(
                "SELECT MAX(tv.in_group_id) FROM {$tVal} tv
                   JOIN {$tOpt} o ON o.option_id = tv.option_id WHERE o.product_id = ?",
                array($pid));
            $maxSort = (int) $read->fetchOne(
                "SELECT MAX(sort_order) FROM {$tVal} WHERE option_id = ?", array($newOptId));

            // Evening dates link to the last Course Time value, others to the
            // first — mirrors the template apply's morning/evening pick.
            $depId = '';
            $ctRows = $read->fetchAll(
                "SELECT tv.in_group_id FROM {$tVal} tv
                   JOIN {$tOpt} o ON o.option_id = tv.option_id
                   JOIN {$tOptT} ot ON ot.option_id = o.option_id AND ot.store_id = 0
                  WHERE o.product_id = ? AND ot.title = 'Course Time'
                  ORDER BY tv.sort_order, tv.option_type_id",
                array($pid));
            if (!empty($ctRows)) {
                $isEvening = (stripos((string) $s['value_title'], 'evening') !== false);
                $pick = $isEvening ? end($ctRows) : reset($ctRows);
                $depId = (string) $pick['in_group_id'];
            }

            $write->insert($tVal, array(
                'option_id'     => $newOptId,
                'sku'           => (string) $s['sku'],
                'sort_order'    => $maxSort + 1,
                'reg_course'    => (string) $s['reg_course'],
                'in_group_id'   => $maxIgi + 1,
                'dependent_ids' => $depId,
                'admin_managed' => 1,
            ));
            $newVid = (int) $write->lastInsertId();
            $write->insert($tValT, array(
                'option_type_id' => $newVid, 'store_id' => 0,
                'title' => (string) $s['value_title'],
            ));
            if ((float) $s['price'] > 0) {
                $write->insert($tValP, array(
                    'option_type_id' => $newVid, 'store_id' => 0,
                    'price' => (float) $s['price'], 'price_type' => 'fixed',
                ));
            }
            $restored++;
        }

        Mage::getResourceModel('catalog/product_indexer_price')->reindexProductIds(array($pid));
        Mage::app()->cleanCache();

        Mage::log(sprintf(
            'switchScheduleTemplate pid=%d sku=%s from=[%s] to=%s adminSnapshot=%d restored=%d dropped=%d',
            $pid, $product->getSku(), implode('|', $fromTitles), $group->getTitle(),
            count($snapshot), $restored, count($dropped)
        ), null, 'mmd_schedule_save.log', true);

        return array(
            'success'              => true,
            'from'                 => $fromTitles,
            'to'                   => $group->getTitle(),
            'restored_admin_dates' => $restored,
            'dropped_admin_dates'  => $dropped,
        );
    }
}
