<?php
/**
 * Revert bulk-generated Course Date values for non-A01 templates.
 *
 * Removes Course Date values whose reg_course falls in Q1 2027 (Jan–Mar 2027)
 * from every schedule template EXCEPT those whose normalised code is 'a1'.
 * Then re-applies the cleaned template hash to assigned products.
 *
 * dep_id fixes (stale 130→125) are intentionally KEPT — they were correct.
 *
 * Usage (dry run — shows what would be removed, no writes):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/revert-bulk-schedule-q1-2027.php
 *
 * Usage (commit changes):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/revert-bulk-schedule-q1-2027.php --apply
 */

$apply = in_array('--apply', $argv ?? [], true);

require_once '/var/www/html/app/Mage.php';
Mage::app('admin');

// Q1 2027 boundaries as unix timestamps (00:00 local)
$rangeStart = mktime(0, 0, 0, 1,  1, 2027); // 2027-01-01
$rangeEnd   = mktime(0, 0, 0, 3, 31, 2027); // 2027-03-31

$generator = Mage::getModel('mmd/schedule_generator');
$col       = Mage::getResourceModel('customoptions/group_collection');

$a1Skipped    = 0;
$checked      = 0;
$noDateOpt    = 0;
$noDatesFound = 0;
$reverted     = 0;
$totalRemoved = 0;

echo ($apply ? "[APPLY MODE]\n" : "[DRY RUN — pass --apply to commit changes]\n") . "\n";
echo str_pad('', 72, '-') . "\n";

foreach ($col as $group) {
    $hash = $group->getHashOptions();
    if (!$hash) continue;
    $opts = @unserialize($hash);
    if (!is_array($opts)) continue;

    $ncode = $generator->normalizeCode((string) $group->getTitle());
    if ($ncode === '' || !$generator->isKnownCode($ncode)) continue;

    /* ── keep A01 unchanged ── */
    if ($ncode === 'a1') {
        $a1Skipped++;
        continue;
    }

    $checked++;

    /* ── find Course Date option ── */
    $cdOptId = null;
    foreach ($opts as $optId => $opt) {
        if (isset($opt['title']) && strcasecmp(trim($opt['title']), 'course date') === 0) {
            $cdOptId = $optId;
            break;
        }
    }
    if ($cdOptId === null || empty($opts[$cdOptId]['values'])) {
        echo sprintf("  [SKIP] #%-4d %-45s no Course Date option\n",
            $group->getId(), substr($group->getTitle(), 0, 45));
        $noDateOpt++;
        continue;
    }

    /* ── partition values ── */
    $toRemove   = [];
    $cleanValues = [];

    foreach ($opts[$cdOptId]['values'] as $vid => $v) {
        $ts = parseRegCourseTs(isset($v['reg_course']) ? $v['reg_course'] : '');
        if ($ts !== false && $ts >= $rangeStart && $ts <= $rangeEnd) {
            $toRemove[$vid] = $v;
        } else {
            $cleanValues[$vid] = $v;
        }
    }

    if (empty($toRemove)) {
        echo sprintf("  [OK]   #%-4d %-45s no Q1 2027 dates\n",
            $group->getId(), substr($group->getTitle(), 0, 45));
        $noDatesFound++;
        continue;
    }

    $removeCount = count($toRemove);
    $keepCount   = count($cleanValues);
    $totalRemoved += $removeCount;

    echo sprintf("  [%s] #%-4d %-45s -%d dates (keep %d)\n",
        $apply ? 'REVERT' : 'WOULD ',
        $group->getId(),
        substr($group->getTitle(), 0, 45),
        $removeCount,
        $keepCount
    );

    if ($apply) {
        /* save cleaned template hash */
        $cleanOpts = $opts;
        $cleanOpts[$cdOptId]['values'] = $cleanValues;
        $group->setHashOptions(serialize($cleanOpts))->save();

        /* full re-sync to products (prevOpts=[] forces complete replace) */
        $productIds = resolveProductIds($group);

        if (!empty($productIds)) {
            Mage::getModel('catalog/product_option')->saveProductOptions(
                $cleanOpts,
                [],
                $productIds,
                $group,
                $group->getIsActive(),
                'apo',
                []
            );
            Mage::getResourceModel('catalog/product_indexer_price')->reindexProductIds($productIds);
            echo sprintf("         → applied to %d product(s): %s\n",
                count($productIds),
                implode(', ', $productIds)
            );
        } else {
            echo "         → no products assigned\n";
        }

        $reverted++;
    }
}

echo str_pad('', 72, '-') . "\n";
echo "A01 templates kept intact:   {$a1Skipped}\n";
echo "Non-A01 templates checked:  {$checked}\n";
echo "  No Course Date option:    {$noDateOpt}\n";
echo "  No Q1 2027 dates found:   {$noDatesFound}\n";
echo "  Q1 2027 dates to remove:  {$totalRemoved}\n";
if ($apply) {
    echo "Templates reverted:         {$reverted}\n";
    echo "\nDone. Run the price indexer if needed:\n";
    echo "  php /var/www/html/shell/indexer.php --reindex catalog_product_price\n";
} else {
    echo "\nThis was a dry run. Rerun with --apply to commit.\n";
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

/**
 * Parse reg_course stored as M/D/YY (e.g. "01/15/27") into a unix timestamp.
 * Returns false if the value is missing or unparseable.
 */
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
