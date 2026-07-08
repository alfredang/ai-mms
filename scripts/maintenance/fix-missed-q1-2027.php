<?php
/**
 * One-shot: generate Q1 2027 dates for templates that missed the bulk run,
 * apply to their products, then verify all assigned templates.
 *
 * Usage: docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/fix-missed-q1-2027.php
 */
ini_set('memory_limit', '512M');
set_time_limit(0);

require_once '/var/www/html/app/Mage.php';
Mage::app('admin');

$db  = Mage::getSingleton('core/resource')->getConnection('core_read');
$tbl = (string) Mage::getConfig()->getTablePrefix() . 'custom_options_relation';

$START = '2027-01-01';
$END   = '2027-03-31';

// Templates that need special handling or are purely manual — skip entirely
$skipTitles = [
    '(SG) ZZ - Custom Calendar',
    '(SG) ZZ - Kid Calendar',
    '(SG) ZZ - Kid Tuitions',
    '(SG) Custom WSQ',
    'Subscriptoin',
];

function resolveProductIds($group, $db, $tbl) {
    $ids = array_values(array_filter(
        array_map('intval', explode(',', (string) $group->getInProducts()))
    ));
    if (!empty($ids)) return $ids;
    $rows = $db->fetchAll(
        'SELECT DISTINCT product_id FROM ' . $tbl . ' WHERE group_id = ?',
        [(int) $group->getId()]
    );
    return array_values(array_map('intval', array_column($rows, 'product_id')));
}

function hasQ1InHashOptions($group) {
    $opts = @unserialize($group->getHashOptions());
    if (!is_array($opts)) return false;
    foreach ($opts as $opt) {
        if (!isset($opt['values'])) continue;
        foreach ($opt['values'] as $val) {
            $t = (string)($val['title'] ?? '');
            if (preg_match('/\b(Jan|Feb|Mar|January|February|March)\b.*2027/i', $t)
                || preg_match('/2027.*(Jan|Feb|Mar)/i', $t)
                || preg_match('/2027-(01|02|03)-/', $t)) {
                return true;
            }
        }
    }
    return false;
}

function productHasQ1($pid, $db) {
    return (int)$db->fetchOne(
        "SELECT COUNT(*)
           FROM catalog_product_option_type_value cotv
           JOIN catalog_product_option_type_title cott
             ON cott.option_type_id = cotv.option_type_id AND cott.store_id = 0
           JOIN catalog_product_option co ON co.option_id = cotv.option_id
           JOIN catalog_product_option_title cot
             ON cot.option_id = co.option_id AND cot.store_id = 0
          WHERE co.product_id = ?
            AND (cot.title LIKE '%Course Date%' OR cot.title LIKE '%Date%')
            AND (   cott.title LIKE '%Jan% 2027%'
                 OR cott.title LIKE '%Feb% 2027%'
                 OR cott.title LIKE '%Mar% 2027%'
                 OR cott.title LIKE '%January%2027%'
                 OR cott.title LIKE '%February%2027%'
                 OR cott.title LIKE '%March%2027%'
                 OR cott.title LIKE '%2027%Jan%'
                 OR cott.title LIKE '%2027%Feb%'
                 OR cott.title LIKE '%2027%Mar%')",
        [$pid]
    ) > 0;
}

$collection = Mage::getModel('customoptions/group')->getCollection();
$collection->getSelect()->where('is_active = 1');
$groups = [];
foreach ($collection as $g) {
    $groups[$g->getId()] = $g;
}

echo '=== PHASE 1: Generate Q1 2027 for missed templates ===' . PHP_EOL;
$generator = Mage::getModel('mmd/schedule_generator');
$generated = 0;
$skippedGen = 0;

foreach ($groups as $groupId => $group) {
    if (in_array($group->getTitle(), $skipTitles)) continue;
    if (hasQ1InHashOptions($group)) { $skippedGen++; continue; }

    $code    = $generator->normalizeCode((string) $group->getTitle());
    $entries = $generator->generateForCode($code, $START, $END);
    if (empty($entries)) {
        echo '  SKIP (no pattern) ' . $group->getTitle() . PHP_EOL;
        continue;
    }

    // Merge into hash_options
    $hash    = $group->getHashOptions();
    $opts    = ($hash !== '' && $hash !== null) ? @unserialize($hash) : [];
    if (!is_array($opts)) $opts = [];

    // Find the Course Date option index
    $dateOptIdx = null;
    foreach ($opts as $i => $opt) {
        $ot = strtolower($opt['option_type'] ?? $opt['type'] ?? '');
        $ol = strtolower($opt['title'] ?? '');
        if ($ot === 'drop_down' && (strpos($ol, 'date') !== false || strpos($ol, 'course') !== false)) {
            $dateOptIdx = $i;
            break;
        }
    }
    if ($dateOptIdx === null && !empty($opts)) $dateOptIdx = 0;
    if ($dateOptIdx === null) { echo '  SKIP (no date opt) ' . $group->getTitle() . PHP_EOL; continue; }

    $existingTitles = [];
    foreach ($opts[$dateOptIdx]['values'] ?? [] as $v) {
        $existingTitles[] = (string)($v['title'] ?? '');
    }

    $added = 0;
    foreach ($entries as $entry) {
        if (in_array($entry['title'], $existingTitles)) continue;
        $opts[$dateOptIdx]['values'][] = $entry;
        $added++;
    }

    if ($added > 0) {
        $group->setHashOptions(serialize($opts));
        $group->save();
        echo '  GENERATED +' . $added . ' dates: ' . $group->getTitle() . PHP_EOL;
        $generated++;
    } else {
        echo '  SKIP (already present) ' . $group->getTitle() . PHP_EOL;
    }
}

echo PHP_EOL . 'Generated for ' . $generated . ' templates. ' . $skippedGen . ' already had Q1 2027.' . PHP_EOL;

echo PHP_EOL . '=== PHASE 2: Apply to products ===' . PHP_EOL;
$applied = 0;
$applyErrors = [];

// Reload collection to get updated hash_options
$collection2 = Mage::getModel('customoptions/group')->getCollection();
$collection2->getSelect()->where('is_active = 1');

foreach ($collection2 as $group) {
    if (in_array($group->getTitle(), $skipTitles)) continue;
    if (!hasQ1InHashOptions($group)) continue;

    $productIds = resolveProductIds($group, $db, $tbl);
    if (empty($productIds)) continue;

    try {
        $newOpts = @unserialize($group->getHashOptions());
        if (!is_array($newOpts)) continue;
        Mage::getModel('catalog/product_option')->saveProductOptions(
            $newOpts, [], $productIds, $group, $group->getIsActive(), 'apo', []
        );
        echo '  APPLIED ' . $group->getTitle() . ' → ' . count($productIds) . ' product(s)' . PHP_EOL;
        $applied++;
    } catch (\Throwable $e) {
        $applyErrors[] = $group->getTitle() . ': ' . $e->getMessage();
        echo '  ERROR ' . $group->getTitle() . ': ' . $e->getMessage() . PHP_EOL;
    }
    gc_collect_cycles();
}

echo PHP_EOL . 'Applied ' . $applied . ' templates.' . PHP_EOL;
if ($applyErrors) {
    echo 'Errors: ' . count($applyErrors) . PHP_EOL;
    foreach ($applyErrors as $e) echo '  ' . $e . PHP_EOL;
}

// Flush caches
try { Mage::app()->getCacheInstance()->cleanType('block_html'); } catch (\Throwable $e) {}
try { Mage::app()->getCacheInstance()->cleanType('full_page'); } catch (\Throwable $e) {}
echo PHP_EOL . 'Caches flushed.' . PHP_EOL;

echo PHP_EOL . '=== PHASE 3: Verification ===' . PHP_EOL;
$ok = $missing = $noProducts = 0;
$missingDetail = [];

$collection3 = Mage::getModel('customoptions/group')->getCollection();
$collection3->getSelect()->where('is_active = 1');

$seen = [];
foreach ($collection3 as $group) {
    if (in_array($group->getTitle(), $skipTitles)) continue;
    if (!hasQ1InHashOptions($group)) {
        echo '  TEMPLATE NO Q1: ' . $group->getTitle() . PHP_EOL;
        continue;
    }

    $productIds = resolveProductIds($group, $db, $tbl);
    if (empty($productIds)) { $noProducts++; continue; }

    $groupOk = true;
    foreach ($productIds as $pid) {
        if (isset($seen[$pid])) continue;
        $seen[$pid] = true;
        if (productHasQ1($pid, $db)) {
            $ok++;
        } else {
            $sku = $db->fetchOne('SELECT sku FROM catalog_product_entity WHERE entity_id = ?', [$pid]);
            $missingDetail[] = 'SKU ' . $sku . ' (id=' . $pid . ') — ' . $group->getTitle();
            $missing++;
            $groupOk = false;
        }
    }
    if (!$groupOk) {
        echo '  PRODUCTS MISSING Q1: ' . $group->getTitle() . PHP_EOL;
    }
}

echo PHP_EOL . 'Verification results:' . PHP_EOL;
echo '  Products with Q1 2027 ✓ : ' . $ok . PHP_EOL;
echo '  Products missing Q1 2027  : ' . $missing . PHP_EOL;
echo '  Templates with no products: ' . $noProducts . PHP_EOL;

if (!empty($missingDetail)) {
    echo PHP_EOL . 'Missing detail (first 30):' . PHP_EOL;
    foreach (array_slice($missingDetail, 0, 30) as $d) echo '  ' . $d . PHP_EOL;
}

echo PHP_EOL . 'Done.' . PHP_EOL;
