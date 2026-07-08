<?php
/**
 * Full revert of the bulk generate+apply cycle — all 75 templates.
 *
 * For every schedule template:
 *   1. Remove Course Date values with reg_course in Q1 2027 (Jan–Mar 2027).
 *   2. Clear dependent_ids to '' on all remaining Course Date values so the
 *      next generate+apply cycle can write correct in_group_id-based deps.
 *   3. Save the cleaned hash_options.
 *   4. Re-apply to products via saveProductOptions (full re-sync, prevOpts=[]).
 *
 * After this script completes:
 *   - No template contains Q1 2027 dates.
 *   - No Course Date value in any template or product has a dep_id set.
 *     (Dates remain selectable — all Course Time slots show; filtering restored
 *      after the next generate+apply with the in_group_id-based dep fix.)
 *
 * Then run:  Bulk Generate → review → Apply to Products
 *
 * Usage (dry run):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/revert-all-bulk-generate.php
 *
 * Usage (apply):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/revert-all-bulk-generate.php --apply
 */

$apply = in_array('--apply', $argv ?? [], true);

require_once '/var/www/html/app/Mage.php';
Mage::app('admin');

$rangeStart = mktime(0, 0, 0, 1,  1, 2027);
$rangeEnd   = mktime(0, 0, 0, 3, 31, 2027);

$generator = Mage::getModel('mmd/schedule_generator');
$col       = Mage::getResourceModel('customoptions/group_collection');

$checked      = 0;
$totalRemoved = 0;
$totalCleared = 0;
$applied      = 0;

echo ($apply ? "[APPLY MODE]\n" : "[DRY RUN — pass --apply to commit changes]\n") . "\n";
echo str_pad('', 80, '-') . "\n";

foreach ($col as $group) {
    $ncode = $generator->normalizeCode((string) $group->getTitle());
    if ($ncode === '' || !$generator->isKnownCode($ncode)) continue;
    if ($ncode === 'a1') { echo sprintf("  [SKIP] #%-4d %-50s A01 kept intact\n", $group->getId(), substr($group->getTitle(), 0, 50)); continue; }

    $checked++;
    $opts = @unserialize($group->getHashOptions());
    if (!is_array($opts)) continue;

    $cdOptId = null;
    foreach ($opts as $optId => $opt) {
        if (isset($opt['title']) && strcasecmp(trim($opt['title']), 'course date') === 0) {
            $cdOptId = $optId;
            break;
        }
    }
    if ($cdOptId === null || empty($opts[$cdOptId]['values'])) continue;

    $removed = 0;
    $cleared = 0;
    $cleanValues = [];

    foreach ($opts[$cdOptId]['values'] as $vid => $v) {
        /* remove Q1 2027 dates */
        $ts = parseRegCourseTs($v['reg_course'] ?? '');
        if ($ts !== false && $ts >= $rangeStart && $ts <= $rangeEnd) {
            $removed++;
            continue;
        }

        /* clear dep_id on remaining values */
        if (($v['dependent_ids'] ?? '') !== '') {
            if ($apply) $v['dependent_ids'] = '';
            $cleared++;
        }

        $cleanValues[$vid] = $v;
    }

    $totalRemoved += $removed;
    $totalCleared += $cleared;

    echo sprintf(
        "  [%s] #%-4d %-50s  -%d Q1-2027  clear-dep=%d  keep=%d\n",
        $apply ? 'APPLY ' : 'WOULD ',
        $group->getId(),
        substr($group->getTitle(), 0, 50),
        $removed,
        $cleared,
        count($cleanValues)
    );

    if ($apply) {
        $cleanOpts = $opts;
        $cleanOpts[$cdOptId]['values'] = $cleanValues;
        $group->setHashOptions(serialize($cleanOpts))->save();

        $productIds = resolveProductIds($group);
        if (!empty($productIds)) {
            Mage::getModel('catalog/product_option')->saveProductOptions(
                $cleanOpts, [], $productIds, $group, $group->getIsActive(), 'apo', []
            );
            Mage::getResourceModel('catalog/product_indexer_price')->reindexProductIds($productIds);
            echo sprintf("         → applied to %d product(s)\n", count($productIds));
        } else {
            echo "         → no products assigned (local DB — run on prod or after DB sync)\n";
        }
        $applied++;
    }
}

echo str_pad('', 80, '-') . "\n";
echo "Templates processed:   {$checked}\n";
echo "Q1 2027 dates removed: {$totalRemoved}\n";
echo "Dep_ids cleared:       {$totalCleared}\n";
if ($apply) {
    echo "Templates saved:       {$applied}\n";
    echo "\nDone. Now run:  Bulk Generate → review → Apply to Products\n";
} else {
    echo "\nDry run complete. Add --apply to commit.\n";
}

function resolveProductIds(Varien_Object $group)
{
    $ids = array_values(array_filter(
        array_map('intval', explode(',', (string) $group->getInProducts()))
    ));
    if (!empty($ids)) return $ids;
    $db  = Mage::getSingleton('core/resource')->getConnection('core_read');
    $tbl = (string) Mage::getConfig()->getTablePrefix() . 'custom_options_relation';
    $rows = $db->fetchAll('SELECT DISTINCT product_id FROM ' . $tbl . ' WHERE group_id = ?', [(int) $group->getId()]);
    return array_values(array_map('intval', array_column($rows, 'product_id')));
}

function parseRegCourseTs($value)
{
    $v = trim((string) $value);
    if ($v === '') return false;
    if (!preg_match('#^(\d{1,2})/(\d{1,2})/(\d{2,4})$#', $v, $m)) return false;
    $yy = (int) $m[3];
    if ($yy < 100) $yy += 2000;
    $ts = mktime(0, 0, 0, (int) $m[1], (int) $m[2], $yy);
    return ($ts === false) ? false : $ts;
}
