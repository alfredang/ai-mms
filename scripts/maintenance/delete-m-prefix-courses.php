<?php
/**
 * Hard-delete every course (catalog product) whose SKU starts with "M" via
 * Magento's resource model. Cascades through:
 *   - catalog_product_entity + all _varchar/_text/_int/_decimal/_datetime/
 *     _gallery/_tier_price/_group_price EAV value tables
 *   - catalog_product_website / catalog_category_product / catalog_product_link
 *   - catalog_product_option + _title + _type_value + _type_title + _type_price
 *     (custom options, including the Course Date dropdown)
 *   - core_url_rewrite (rewrite rows for these products)
 *   - cataloginventory_stock_item / cataloginventory_stock_status
 *   - catalogsearch_result / catalogsearch_query
 *
 * NOT TOUCHED (same as delete-wsq-courses.php's Option B):
 *   - sales_flat_order / sales_flat_order_item — historical order lines for
 *     deleted products keep their snapshotted SKU/name/price. The line's
 *     product_id will point at a now-missing row but the line itself reads
 *     fine. We don't want to lose order history.
 *   - course_runs / course_run_enrolments — no FK constraint to
 *     catalog_product_entity (verified in migrations/042 + 043), so these
 *     rows are left as historical roster/class records pointing at a
 *     deleted product_id. Same reasoning as order history.
 *
 * Context (2026-06-23): M-prefix products are NOT part of the C-prefix
 * SG->country catalog sync (MMD_RoleManager_Model_CourseSyncService only
 * pulls C-prefix). They were instead receiving a steady stream of orders
 * (15-49/month) from a broken external SOAP/REST order-creation
 * integration writing to an orphaned store_id=2 (no matching core_store
 * row). This script's purpose is explicitly to remove those products so
 * the broken integration's order-create calls fail outright. Confirmed
 * with the requester before running with --confirm.
 *
 * Explicitly excludes TGS- and C-prefix SKUs (SG's own catalog) by
 * matching only sku LIKE 'M%' — never broaden this match.
 *
 * USAGE
 *   docker exec <web-container> php /var/www/html/scripts/maintenance/delete-m-prefix-courses.php
 *     -> dry run, lists the products that WOULD be deleted
 *
 *   docker exec <web-container> php /var/www/html/scripts/maintenance/delete-m-prefix-courses.php --confirm
 *     -> actually deletes them
 *
 * Run dry first; verify the list; only then re-run with --confirm.
 */

@ini_set('memory_limit', '1024M');
set_time_limit(0);

// Bootstrap Magento.
require __DIR__ . '/../../app/Mage.php';
Mage::app('admin');

// Required by Magento to allow programmatic catalog deletes — without this,
// Mage_Catalog_Model_Resource_Product::_beforeDelete throws "Cannot delete
// the product" because it treats the request as if it came from the frontend.
Mage::register('isSecureArea', true);

// MMD_CustomOptions_Model_Mysql4_Product_Option_Collection::addTitleToResult()
// lazily touches Mage::getSingleton('adminhtml/session_quote') on first
// product load. If that's the first thing to touch PHP's session machinery
// AFTER this script has already echo'd anything, session_set_save_handler()
// fails with "headers already sent" (PHP tracks any prior output as
// blocking session init, even under the CLI SAPI) and product load throws.
// Force the singleton to initialize right now, before any output below.
Mage::getSingleton('adminhtml/session_quote');

$confirm = in_array('--confirm', $argv ?? array(), true);

$resource = Mage::getSingleton('core/resource');
$read     = $resource->getConnection('core_read');

// Find all products whose SKU starts with "M". Never broaden this to a
// case-insensitive or substring match — TGS- and C-prefix SKUs are SG's
// own synced catalog and must never be touched by this script.
$rows = $read->fetchAll(
    "SELECT e.entity_id, e.sku, v.value AS name
     FROM catalog_product_entity e
     LEFT JOIN catalog_product_entity_varchar v
       ON v.entity_id = e.entity_id AND v.attribute_id = 71 AND v.store_id = 0
     WHERE e.sku LIKE 'M%'
     ORDER BY e.entity_id ASC"
);

$count = count($rows);
echo "=== M-prefix course deletion ===\n";
echo "Mode:    " . ($confirm ? "DELETE" : "DRY RUN (no changes — pass --confirm to delete)") . "\n";
echo "Matched: {$count} products\n\n";

if ($count === 0) {
    echo "Nothing to do.\n";
    exit(0);
}

// In dry-run mode, just print the matched list.
if (!$confirm) {
    foreach ($rows as $r) {
        echo "  [{$r['entity_id']}]  {$r['sku']}  —  {$r['name']}\n";
    }
    echo "\n{$count} products would be deleted. Re-run with --confirm to actually delete.\n";
    exit(0);
}

// Confirmed — delete each product through Magento's resource model so the
// cascade runs cleanly. Loop product IDs (not objects) and load+delete one
// at a time so we don't blow memory on ~500 fully-hydrated products.
$ok       = 0;
$failed   = array();
$progress = 0;
$startTs  = microtime(true);

// Something in the bootstrap chain promotes PHP E_WARNING into a catchable
// exception. catalog/product delete fires a benign
// "session_set_save_handler(): Session save handler cannot be changed
// after headers have already been sent" warning (Mage_Core_Model_Resource_
// Session::setSaveHandler(), irrelevant in a CLI script with no real HTTP
// session) that would otherwise abort every single delete. Suppress
// warnings just for the delete loop; real Magento exceptions are thrown
// directly via `throw` and are unaffected by this handler.
set_error_handler(function () { return true; }, E_WARNING);

foreach ($rows as $r) {
    $progress++;
    $pid  = (int) $r['entity_id'];
    $sku  = (string) $r['sku'];
    $name = (string) $r['name'];

    try {
        $product = Mage::getModel('catalog/product')->load($pid);
        if (!$product->getId()) {
            // Already gone (maybe deleted in a previous partial run). Skip.
            echo "  [SKIP {$progress}/{$count}] entity_id={$pid} not found\n";
            continue;
        }
        $product->delete();
        $ok++;
        if ($progress % 10 === 0 || $progress === $count) {
            $elapsed = round(microtime(true) - $startTs, 1);
            echo "  [{$progress}/{$count}] deleted entity_id={$pid} sku={$sku} ({$elapsed}s elapsed)\n";
        }
    } catch (Exception $e) {
        $failed[] = array('id' => $pid, 'sku' => $sku, 'name' => $name, 'error' => $e->getMessage());
        echo "  [FAIL {$progress}/{$count}] entity_id={$pid} sku={$sku}: " . $e->getMessage() . "\n";
    }
}

restore_error_handler();

$elapsed = round(microtime(true) - $startTs, 1);
echo "\n=== Done ===\n";
echo "Deleted:   {$ok} / {$count}\n";
echo "Failed:    " . count($failed) . "\n";
echo "Elapsed:   {$elapsed}s\n";

if (!empty($failed)) {
    echo "\nFailures:\n";
    foreach ($failed as $f) {
        echo "  [{$f['id']}] {$f['sku']}: {$f['error']}\n";
    }
}

// Reindex so the catalog grid + search update.
echo "\nKick off catalog reindexers...\n";
try {
    $indexer = Mage::getSingleton('index/indexer');
    foreach (array('catalog_product_attribute', 'catalog_product_price', 'catalog_url',
                   'catalog_product_flat', 'cataloginventory_stock', 'catalogsearch_fulltext') as $code) {
        try {
            $process = $indexer->getProcessByCode($code);
            if ($process) {
                $process->reindexEverything();
                echo "  reindexed: {$code}\n";
            }
        } catch (Exception $e) {
            echo "  skip {$code}: " . $e->getMessage() . "\n";
        }
    }
} catch (Exception $e) {
    echo "Reindex error: " . $e->getMessage() . "\n";
    echo "(You can manually reindex from admin: System -> Index Management.)\n";
}

echo "\nFinished.\n";
