<?php
/**
 * HARD RULE: every active (enabled) course is visible on the storefront.
 *
 * Lists enabled products whose visibility is "Not Visible Individually" (they
 * vanish from category pages, search and the course-code search). Exit 1 if any.
 *
 *   php scripts/audit/check-active-courses-visible.php          # report
 *   php scripts/audit/check-active-courses-visible.php --fix    # make them visible + reindex
 *
 * Run inside the web container, as www-data when using --fix.
 */
ob_start();
require_once dirname(__FILE__) . '/../../app/Mage.php';
Mage::app('admin');
ob_end_clean();

$fix  = in_array('--fix', $argv, true);
$res  = Mage::getSingleton('core/resource');
$conn = $res->getConnection('core_read');
$eav  = Mage::getSingleton('eav/config');
$int  = $res->getTableName('catalog/product') . '_int';
$st   = (int) $eav->getAttribute('catalog_product', 'status')->getId();
$vis  = (int) $eav->getAttribute('catalog_product', 'visibility')->getId();

// Enabled at store 0, hidden at ANY scope (a store-view row shadows store 0).
$rows = $conn->fetchAll("
    SELECT e.entity_id, e.sku, v.store_id
      FROM {$res->getTableName('catalog/product')} e
      JOIN {$int} s ON s.entity_id = e.entity_id AND s.attribute_id = {$st} AND s.store_id = 0 AND s.value = 1
      JOIN {$int} v ON v.entity_id = e.entity_id AND v.attribute_id = {$vis} AND v.value = 1
  ORDER BY e.sku");

if (!$rows) {
    echo "OK: every active course is visible\n";
    exit(0);
}
foreach ($rows as $r) {
    echo "HIDDEN: {$r['sku']} (id {$r['entity_id']}, store {$r['store_id']})\n";
}
echo count($rows) . " active course(s) hidden\n";
if (!$fix) {
    exit(1);
}

$both = Mage_Catalog_Model_Product_Visibility::VISIBILITY_BOTH;
$byStore = array();
foreach ($rows as $r) {
    $byStore[(int) $r['store_id']][] = (int) $r['entity_id'];
}
foreach ($byStore as $storeId => $ids) {
    Mage::getSingleton('catalog/product_action')->updateAttributes($ids, array('visibility' => $both), $storeId);
}
try {
    $res->getConnection('core_write')->update(
        $res->getTableName('mmd_course_availability'),
        array('original_visibility' => null)
    );
} catch (Exception $e) {
    // table absent on a site that never synced availability
}
foreach (array('catalog_category_product', 'catalogsearch_fulltext', 'catalog_product_flat') as $code) {
    $p = Mage::getModel('index/process')->load($code, 'indexer_code');
    if ($p->getId()) {
        $p->reindexEverything();
    }
}
Mage::app()->getCacheInstance()->flush();
echo "FIXED: " . count($rows) . " course(s) set to Catalog, Search; reindexed; cache flushed\n";
