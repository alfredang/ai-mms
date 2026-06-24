<?php
/**
 * Weekly past-date purge for class-schedule templates + courses.
 *
 * Automates the manual two-step on the Manage Class Schedule page
 * ("1. Clean Templates" + "2. Apply to Products"): removes every "Course
 * Date" entry whose reg_course is in the past, from both the option
 * templates (customoptions_group hash_options + per-store overrides) and the
 * products' custom-option tables, then reindexes prices and flushes caches.
 *
 * Mirrors MMD_Adminhtml_Customoptions_OptionsController::cleanTemplatesPastDates
 * + applyTemplatesToProducts so the cron is self-contained and the working
 * manual UI flow is left untouched.
 *
 * Wired as a weekly job (Sun 01:00 SGT) in MMD_Adminhtml/etc/config.xml.
 */
class MMD_Adminhtml_Model_Schedule_Cron
{
    /**
     * Cron entry point. $schedule is the Mage_Cron schedule row (unused).
     */
    public function purgePastDates($schedule = null)
    {
        $today = strtotime('today');
        try {
            $templateRows = $this->_cleanTemplates($today);
            $productRows  = $this->_purgeProducts();
            Mage::log(
                sprintf(
                    'schedule purge: removed %d past template entry/entries, %d past product row(s)',
                    $templateRows, $productRows
                ),
                null,
                'mmd_schedule_purge.log'
            );
        } catch (Exception $e) {
            Mage::logException($e);
        }
        return $this;
    }

    /**
     * Strip past Course Date values from every template (+ per-store override).
     * @return int total values removed
     */
    protected function _cleanTemplates($todayTs)
    {
        $removed = 0;
        $collection = Mage::getResourceModel('customoptions/group_collection');
        foreach ($collection as $group) {
            $hash = $group->getHashOptions();
            if ($hash) {
                $opts = @unserialize($hash);
                if (is_array($opts)) {
                    list($opts, $n) = $this->_stripPast($opts, $todayTs);
                    if ($n > 0) {
                        $group->setHashOptions(serialize($opts))->save();
                        $removed += $n;
                    }
                }
            }

            $storeColl = Mage::getResourceModel('customoptions/group_store_collection')
                ->addFieldToFilter('group_id', $group->getId());
            foreach ($storeColl as $gs) {
                $sh = $gs->getHashOptions();
                if (!$sh) {
                    continue;
                }
                $sOpts = @unserialize($sh);
                if (!is_array($sOpts)) {
                    continue;
                }
                list($sOpts, $sn) = $this->_stripPast($sOpts, $todayTs);
                if ($sn > 0) {
                    $gs->setHashOptions(serialize($sOpts))->save();
                    $removed += $sn;
                }
            }
        }
        return $removed;
    }

    /**
     * Remove past-dated entries from the "Course Date" option of one
     * unserialized hash_options array. Returns [cleanedOpts, removedCount].
     */
    protected function _stripPast(array $opts, $todayTs)
    {
        $removed = 0;
        foreach ($opts as $optId => $opt) {
            if (empty($opt['title']) || strcasecmp(trim($opt['title']), 'course date') !== 0) {
                continue;
            }
            if (empty($opt['values']) || !is_array($opt['values'])) {
                continue;
            }
            foreach ($opt['values'] as $valId => $val) {
                $ts = $this->_parseRegCourseTs(isset($val['reg_course']) ? $val['reg_course'] : '');
                if ($ts !== false && $ts < $todayTs) {
                    unset($opts[$optId]['values'][$valId]);
                    $removed++;
                }
            }
        }
        return array($opts, $removed);
    }

    /**
     * Delete past Course Date rows from products, reindex prices, flush caches.
     * @return int rows deleted
     */
    protected function _purgeProducts()
    {
        $resource = Mage::getSingleton('core/resource');
        $write   = $resource->getConnection('core_write');
        $tValue  = $resource->getTableName('catalog_product_option_type_value');
        $tTitle  = $resource->getTableName('catalog_product_option_type_title');
        $tPrice  = $resource->getTableName('catalog_product_option_type_price');
        $tImage  = $resource->getTableName('custom_options_option_type_image');
        $tOpt    = $resource->getTableName('catalog_product_option');
        $tOptTit = $resource->getTableName('catalog_product_option_title');

        $rows = $write->fetchAll(
            "SELECT DISTINCT v.option_type_id, o.product_id
             FROM {$tValue} v
             JOIN {$tOpt} o       ON o.option_id = v.option_id
             JOIN {$tOptTit} ot   ON ot.option_id = v.option_id
             WHERE LOWER(TRIM(ot.title)) = 'course date'
               AND v.reg_course IS NOT NULL
               AND v.reg_course <> ''
               AND STR_TO_DATE(v.reg_course, '%m/%d/%y') IS NOT NULL
               AND STR_TO_DATE(v.reg_course, '%m/%d/%y') < CURDATE()"
        );
        if (empty($rows)) {
            return 0;
        }

        $ids = $productIds = array();
        foreach ($rows as $r) {
            $ids[] = $r['option_type_id'];
            if (!empty($r['product_id'])) {
                $productIds[$r['product_id']] = true;
            }
        }
        $productIds = array_keys($productIds);

        $write->beginTransaction();
        try {
            $deleted = $write->delete($tValue, array('option_type_id IN (?)' => $ids));
            $write->delete($tTitle, array('option_type_id IN (?)' => $ids));
            $write->delete($tPrice, array('option_type_id IN (?)' => $ids));
            if ($write->isTableExists($tImage)) {
                $write->delete($tImage, array('option_type_id IN (?)' => $ids));
            }
            $write->commit();
        } catch (Exception $e) {
            $write->rollBack();
            throw $e;
        }

        try {
            if (!empty($productIds)) {
                Mage::getResourceModel('catalog/product_indexer_price')
                    ->reindexProductIds($productIds);
            }
            Mage::app()->getCacheInstance()->cleanType('block_html');
            Mage::app()->getCacheInstance()->cleanType('full_page');
            Mage::app()->getCacheInstance()->cleanType('collections');
            $flat = Mage::getModel('index/process')->load('catalog_product_flat', 'indexer_code');
            if ($flat && $flat->getId()) {
                $flat->changeStatus(Mage_Index_Model_Process::STATUS_REQUIRE_REINDEX);
            }
        } catch (Exception $cacheEx) {
            Mage::logException($cacheEx);
        }

        return $deleted;
    }

    /**
     * Parse reg_course ("%m/%d/%y", e.g. "03/14/26") to a midnight timestamp.
     * Returns false when unparseable.
     */
    protected function _parseRegCourseTs($value)
    {
        $v = trim((string) $value);
        if ($v === '') {
            return false;
        }
        if (!preg_match('#^(\d{1,2})/(\d{1,2})/(\d{2,4})$#', $v, $m)) {
            return false;
        }
        $yy = (int) $m[3];
        if ($yy < 100) {
            $yy += 2000;
        }
        $ts = mktime(0, 0, 0, (int) $m[1], (int) $m[2], $yy);
        return $ts === false ? false : $ts;
    }
}
