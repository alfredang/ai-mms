<?php
/**
 * Fix Course Date dep_ids in all schedule templates.
 *
 * The dep_id stored on a Course Date option value must equal the Course Time
 * value's `in_group_id` (template level). When saveProductOptions applies the
 * template it computes:
 *
 *   product_dep = (groupId * 65535) + template_dep
 *
 * and matches that against each Course Time value's product-level in_group_id:
 *
 *   product_igi = (groupId * 65535) + template_in_group_id
 *
 * So template_dep MUST equal template_in_group_id, not option_type_id (these
 * are the same on some templates but differ on others, e.g. A01).
 *
 * This script:
 *   1. Walks every schedule template
 *   2. Reads the Course Time morning/evening in_group_ids
 *   3. Fixes Course Date dep_ids in hash_options to match those in_group_ids
 *   4. Saves the corrected hash and re-applies to products
 *
 * Usage (dry run):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/fix-depid-in-group-id.php
 *
 * Usage (apply):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/fix-depid-in-group-id.php --apply
 */

$apply = in_array('--apply', $argv ?? [], true);

require_once '/var/www/html/app/Mage.php';
Mage::app('admin');

$generator = Mage::getModel('mmd/schedule_generator');
$col       = Mage::getResourceModel('customoptions/group_collection');

$checked      = 0;
$noCtOpt      = 0;
$alreadyOk    = 0;
$fixed        = 0;
$totalFixed   = 0;

echo ($apply ? "[APPLY MODE]\n" : "[DRY RUN — pass --apply to commit changes]\n") . "\n";
echo str_pad('', 80, '-') . "\n";

foreach ($col as $group) {
    $ncode = $generator->normalizeCode((string) $group->getTitle());
    if ($ncode === '' || !$generator->isKnownCode($ncode)) continue;

    $checked++;
    $opts = @unserialize($group->getHashOptions());
    if (!is_array($opts)) continue;

    /* ── find Course Date + Course Time options ── */
    $cdOptId = $ctOpt = null;
    foreach ($opts as $optId => $opt) {
        if (empty($opt['title'])) continue;
        if (strcasecmp(trim($opt['title']), 'course date') === 0) $cdOptId = $optId;
        if (strcasecmp(trim($opt['title']), 'course time') === 0) $ctOpt   = $opt;
    }
    if ($cdOptId === null || $ctOpt === null || empty($ctOpt['values'])) {
        echo sprintf("  [SKIP] #%-4d %-50s no Course Date/Time\n",
            $group->getId(), substr($group->getTitle(), 0, 50));
        $noCtOpt++;
        continue;
    }
    if (empty($opts[$cdOptId]['values'])) {
        $alreadyOk++;
        continue;
    }

    /* ── resolve morning/evening dep via in_group_id ── */
    $ctVals = array_values($ctOpt['values']);
    usort($ctVals, function ($a, $b) {
        return (int)($a['sort_order'] ?? 0) - (int)($b['sort_order'] ?? 0);
    });

    $morningDep = (string)(($ctVals[0]['in_group_id'] ?? '') !== ''
        ? $ctVals[0]['in_group_id']
        : ($ctVals[0]['option_type_id'] ?? ''));
    $last = $ctVals[count($ctVals) - 1];
    $eveningDep = (count($ctVals) >= 2)
        ? (string)(($last['in_group_id'] ?? '') !== '' ? $last['in_group_id'] : ($last['option_type_id'] ?? ''))
        : $morningDep;

    if ($morningDep === '') {
        echo sprintf("  [SKIP] #%-4d %-50s cannot resolve dep_id\n",
            $group->getId(), substr($group->getTitle(), 0, 50));
        continue;
    }

    /* ── fix each Course Date value ── */
    $fixedHere = 0;
    foreach ($opts[$cdOptId]['values'] as $vid => $v) {
        $isEvening  = (stripos($v['title'] ?? '', 'Evening') !== false);
        $correctDep = $isEvening ? $eveningDep : $morningDep;
        $currentDep = (string)($v['dependent_ids'] ?? '');
        if ($currentDep !== $correctDep) {
            if ($apply) {
                $opts[$cdOptId]['values'][$vid]['dependent_ids'] = $correctDep;
            }
            $fixedHere++;
        }
    }

    if ($fixedHere === 0) {
        echo sprintf("  [OK]   #%-4d %-50s all dep_ids already correct\n",
            $group->getId(), substr($group->getTitle(), 0, 50));
        $alreadyOk++;
        continue;
    }

    $totalFixed += $fixedHere;

    echo sprintf("  [%s] #%-4d %-50s morning_dep=%-6s evening_dep=%-6s fixed=%d\n",
        $apply ? 'FIXED ' : 'WOULD ',
        $group->getId(),
        substr($group->getTitle(), 0, 50),
        $morningDep, $eveningDep, $fixedHere
    );

    if ($apply) {
        /* save corrected template hash */
        $group->setHashOptions(serialize($opts))->save();

        /* re-apply to products (full re-sync) */
        $productIds = resolveProductIds($group);

        if (!empty($productIds)) {
            Mage::getModel('catalog/product_option')->saveProductOptions(
                $opts, [], $productIds, $group, $group->getIsActive(), 'apo', []
            );
            Mage::getResourceModel('catalog/product_indexer_price')->reindexProductIds($productIds);
            echo sprintf("         → applied to %d product(s)\n", count($productIds));
        } else {
            echo "         → no products assigned (in_products empty on local DB — update DB first)\n";
        }

        $fixed++;
    }
}

echo str_pad('', 80, '-') . "\n";
echo "Templates checked:           {$checked}\n";
echo "No Course Date/Time option:  {$noCtOpt}\n";
echo "dep_ids already correct:     {$alreadyOk}\n";
echo "Total dep_ids to fix:        {$totalFixed}\n";
if ($apply) {
    echo "Templates saved + applied:   {$fixed}\n";
} else {
    echo "\nRun with --apply to commit.\n";
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
