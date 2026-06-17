<?php
/**
 * Renumber catalog_category_product.position to sparse 10/20/30/... steps
 * for every non-root category.
 *
 * Why: stock Magento assigns positions densely (1, 2, 3, ...), so inserting
 * a new course between #5 and #6 means renumbering every subsequent row.
 * Spacing positions by 10 lets ops drop in a new course mid-list by simply
 * typing "25" between 20 and 30 — no cascade rewrite.
 *
 * What it does:
 *   - Loops every category (level > 1, skipping the synthetic root).
 *   - For each category, fetches its products ordered by current position
 *     (then product_id as a stable tiebreaker).
 *   - Rewrites positions to 10, 20, 30, ... in that order.
 *   - Wrapped in a single transaction so a mid-run failure rolls back to
 *     the original state.
 *
 * Idempotent: re-running just re-applies the 10/20/30 spacing. If a row
 * already matches its target position, the UPDATE is skipped.
 *
 * Reindex after running:
 *   - System -> Index Management -> "Catalog URL Rewrites" + "Category Flat
 *     Data" + "Catalog Category/Product Index" (whichever your version uses).
 *   - Or from CLI: php shell/indexer.php --reindex catalog_url,catalog_category_flat,catalog_category_product_index
 *
 * Usage:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/renumber-category-product-positions.php
 *
 * Flags:
 *   --dry-run     Print what WOULD change without writing.
 *   --category=N  Only process category id N (handy for testing on one).
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app();

$argvFlags = array_slice($argv, 1);
$dryRun    = in_array('--dry-run', $argvFlags, true);
$onlyCat   = null;
foreach ($argvFlags as $a) {
    if (preg_match('/^--category=(\d+)$/', $a, $m)) {
        $onlyCat = (int) $m[1];
    }
}

$db = Mage::getSingleton('core/resource')->getConnection('core_write');

// Skip the root category (level 1 is the always-present "Root Catalog");
// real ops-visible categories sit at level 2 and below.
$catSql = "SELECT entity_id FROM catalog_category_entity WHERE level > 1";
if ($onlyCat) {
    $catSql .= " AND entity_id = " . (int) $onlyCat;
}
$categoryIds = $db->fetchCol($catSql);

echo "Scope: " . count($categoryIds) . " categories"
    . ($onlyCat ? " (filtered to category_id=$onlyCat)" : "")
    . ($dryRun  ? " [DRY RUN — no writes]" : "")
    . PHP_EOL;

$totalCats  = 0;
$totalProds = 0;
$skipped    = 0;
$txStarted  = false;

try {
    if (!$dryRun) {
        $db->beginTransaction();
        $txStarted = true;
    }

    foreach ($categoryIds as $catId) {
        $rows = $db->fetchAll(
            "SELECT product_id, position FROM catalog_category_product
             WHERE category_id = ? ORDER BY position ASC, product_id ASC",
            [$catId]
        );
        if (empty($rows)) continue;

        $pos = 10;
        $changes = 0;
        foreach ($rows as $r) {
            if ((int) $r['position'] === $pos) {
                $skipped++;
                $pos += 10;
                continue;
            }
            if (!$dryRun) {
                $db->update(
                    'catalog_category_product',
                    ['position' => $pos],
                    ['category_id = ?' => (int) $catId, 'product_id = ?' => (int) $r['product_id']]
                );
            }
            $pos += 10;
            $totalProds++;
            $changes++;
        }
        if ($changes > 0) {
            $totalCats++;
            echo "  cat=$catId : " . count($rows) . " products, $changes positions rewritten" . PHP_EOL;
        }
    }

    if ($txStarted) {
        $db->commit();
        $txStarted = false;
    }
} catch (Exception $e) {
    if ($txStarted) {
        $db->rollBack();
    }
    echo "FAILED: " . $e->getMessage() . PHP_EOL;
    exit(1);
}

echo PHP_EOL;
echo "Done. " . ($dryRun ? "Would update" : "Updated")
    . " $totalProds positions across $totalCats categories"
    . " (skipped $skipped already-correct rows)." . PHP_EOL;

if (!$dryRun) {
    echo PHP_EOL;
    echo "Next step (storefront cache):" . PHP_EOL;
    echo "  Admin -> System -> Cache Management -> Flush Magento Cache" . PHP_EOL;
    echo "  Admin -> System -> Index Management -> reindex Catalog Category/Product Index" . PHP_EOL;
}
