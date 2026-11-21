<?php

/**
 * Daily 11:00 (store time) funding-expiry check, Singapore site only (user rule 2026-11-21).
 *
 * For every ENABLED funded (TGS-) course past its SSG funding validity
 * (MMD_Courses_Helper_Data::isFundingExpired) that is still on a WSQ schedule
 * template "(SG) WSQ-B09 ...", switch it to the non-WSQ template with the same
 * code "B09 ..." through the shared switch path (admin-confirmed dates carry over).
 * The non-WSQ template has no Funding Eligibility option, so no funded fee is offered.
 *
 * When the funding is renewed (the course is no longer expired) and the course is
 * still on the template this job gave it, the original WSQ template is put back.
 *
 * It changes the schedule template only. It never touches status or visibility
 * and never closes registration. The storefront pills ("Funding Expired, Renewal
 * Pending") are drawn at render time from the same isFundingExpired() check.
 * Every switch is recorded in mmd_funding_expiry_schedule.
 */
class MMD_Courses_Model_Cron_FundingExpiry
{
    const TABLE = 'mmd_funding_expiry_schedule';

    /**
     * @param bool $dryRun report what would change, change nothing
     * @return array list of { sku, name, action: switched|restored|skipped, from, to, note }
     */
    public function run($dryRun = false)
    {
        $dryRun = ($dryRun === true);   // the cron passes a schedule object
        $out = array();
        try {
            Mage::app()->getStore('singapore');
        } catch (Exception $e) {
            return $out;                // partner site: no funded courses
        }

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $tLog     = $resource->getTableName(self::TABLE);
        $tGroup   = $resource->getTableName('custom_options_group');
        $tRel     = $resource->getTableName('custom_options_relation');
        $helper   = Mage::helper('courses');
        $switcher = Mage::getModel('mmd_rolemanager/scheduleTemplateSwitch');

        $templatesOf = function ($pid) use ($read, $tGroup, $tRel) {
            return $read->fetchAll(
                "SELECT DISTINCT g.group_id, g.title FROM {$tRel} x
                   JOIN {$tGroup} g ON g.group_id = x.group_id WHERE x.product_id = ?", array((int) $pid));
        };

        $courses = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId(0)
            ->addAttributeToSelect('name')
            ->addAttributeToFilter('sku', array('like' => 'TGS-%'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED);

        $expiredIds = array();
        foreach ($courses as $course) {
            if (!$helper->isFundingExpired($course)) {
                continue;
            }
            $pid = (int) $course->getId();
            $expiredIds[$pid] = true;
            $row = array('sku' => $course->getSku(), 'name' => $course->getName(),
                'action' => 'skipped', 'from' => '', 'to' => '', 'note' => '');

            $cur = $templatesOf($pid);
            $row['from'] = implode(' + ', array_map(function ($t) { return $t['title']; }, $cur));
            if (count($cur) !== 1 || !preg_match('/^\(SG\)\s*WSQ-([A-E]\d\d)\b/', $cur[0]['title'], $m)) {
                // Already on a non-WSQ template (done on an earlier day) is not worth a line.
                if (count($cur) === 1 && strpos($cur[0]['title'], '(SG)') !== 0) {
                    continue;
                }
                $row['note'] = 'no standard WSQ template code; switch it by hand';
                $out[] = $row;
                continue;
            }
            $target = $read->fetchAll(
                "SELECT group_id, title FROM {$tGroup}
                  WHERE title LIKE ? AND title NOT LIKE '(SG)%' AND is_active = 1", array($m[1] . ' %'));
            if (count($target) !== 1) {
                $row['note'] = 'no single active non-WSQ template ' . $m[1];
                $out[] = $row;
                continue;
            }
            $row['to'] = $target[0]['title'];
            if (!$dryRun) {
                try {
                    $res = $switcher->switchProduct($pid, (int) $target[0]['group_id']);
                    if (!empty($res['dropped_admin_dates'])) {
                        $row['note'] = 'confirmed dates not carried over: ' . implode('; ', $res['dropped_admin_dates']);
                    }
                    $write->insert($tLog, array(
                        'product_id'    => $pid,
                        'sku'           => $course->getSku(),
                        'from_group_id' => (int) $cur[0]['group_id'],
                        'from_title'    => $cur[0]['title'],
                        'to_group_id'   => (int) $target[0]['group_id'],
                        'to_title'      => $target[0]['title'],
                        'switched_at'   => Varien_Date::now(),
                    ));
                } catch (Exception $e) {
                    Mage::logException($e);
                    $row['note'] = 'switch failed: ' . $e->getMessage();
                    $out[] = $row;
                    continue;
                }
            }
            $row['action'] = 'switched';
            $out[] = $row;
        }

        // Renewed: put the WSQ template back where this job's template is still in place.
        $open = $read->fetchAll("SELECT * FROM {$tLog} WHERE restored_at IS NULL ORDER BY id");
        foreach ($open as $log) {
            $pid = (int) $log['product_id'];
            if (isset($expiredIds[$pid])) {
                continue;
            }
            $course = Mage::getModel('catalog/product')->setStoreId(0)->load($pid);
            if (!$course->getId()
                || (int) $course->getStatus() !== Mage_Catalog_Model_Product_Status::STATUS_ENABLED
                || $helper->isFundingExpired($course)
            ) {
                continue;               // disabled course: leave as is
            }
            $cur = $templatesOf($pid);
            $row = array('sku' => $course->getSku(), 'name' => $course->getName(), 'action' => 'restored',
                'from' => $log['to_title'], 'to' => $log['from_title'], 'note' => 'funding renewed');
            $stillOurs = (count($cur) === 1 && (int) $cur[0]['group_id'] === (int) $log['to_group_id']);
            if (!$dryRun) {
                try {
                    if ($stillOurs) {
                        $switcher->switchProduct($pid, (int) $log['from_group_id']);
                    }
                    $write->update($tLog, array('restored_at' => Varien_Date::now()), array('id = ?' => (int) $log['id']));
                } catch (Exception $e) {
                    Mage::logException($e);
                    $row['action'] = 'skipped';
                    $row['note']   = 'restore failed: ' . $e->getMessage();
                }
            }
            if ($stillOurs) {
                $out[] = $row;          // a template someone changed by hand is left alone
            }
        }

        foreach ($out as $r) {
            Mage::log(($dryRun ? '[dry-run] ' : '') . json_encode($r), null, 'mmd_funding_expiry.log', true);
        }
        return $out;
    }
}
