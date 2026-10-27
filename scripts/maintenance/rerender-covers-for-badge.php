<?php

/**
 * Re-render AI course covers for products carrying a given funding/perk badge.
 *
 * Why this exists: covers are pre-rendered PNGs on R2, so a change to the
 * cover RENDERER (e.g. adding the red "Free AI Subscription" chip)
 * does not affect any course until its cover is regenerated. The admin Bulk
 * AI Covers screen posts ONE badge set for the whole batch, which would
 * flatten per-course differences (some of these courses carry UTAP, some
 * don't). This script instead re-renders each product with ITS OWN badges.
 *
 * Tags are passed through unchanged — syncProductTags() is deliberately NOT
 * called, so this only ever swaps the image, never the badge data.
 *
 * Old R2 objects are left in place (new upload is timestamped), so reverting
 * is just repointing course_image_url back at the previous file.
 *
 * Usage (inside the web container):
 *   php scripts/maintenance/rerender-covers-for-badge.php --dry-run
 *   php scripts/maintenance/rerender-covers-for-badge.php --apply
 *   php scripts/maintenance/rerender-covers-for-badge.php --apply --badge="Free AI Subscription"
 *   php scripts/maintenance/rerender-covers-for-badge.php --apply --badge=UTAP --sku=TGS-2025052468,TGS-2024048317
 */

$opts = getopt('', ['apply', 'dry-run', 'badge::', 'sku::']);
$apply = isset($opts['apply']);
$badgeName = isset($opts['badge']) && $opts['badge'] !== false
    ? (string) $opts['badge']
    : 'Free AI Subscription';
// Optional comma-separated SKU list: limit the run to just those courses.
$skuFilter = isset($opts['sku']) && $opts['sku'] !== false
    ? array_filter(array_map('trim', explode(',', (string) $opts['sku'])))
    : [];

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

// MMD_CustomOptions' option collection reaches for the adminhtml quote
// session during Product::_afterLoad(); without a started session that
// fatals under CLI. Starting one up front keeps product loads working.
if (PHP_SAPI === 'cli' && session_status() !== PHP_SESSION_ACTIVE) {
    @session_start();
}

$helper = Mage::helper('mmd_courseimage');

/** @var Varien_Db_Adapter_Interface $db */
$db = Mage::getSingleton('core/resource')->getConnection('core_read');

// Products tagged with the badge (approved tags only).
$productIds = $db->fetchCol(
    "SELECT DISTINCT r.product_id
       FROM tag_relation r
       JOIN tag t ON t.tag_id = r.tag_id
      WHERE t.name = ? AND t.status = 1 AND r.active = 1",
    [$badgeName]
);
if ($skuFilter) {
    $productIds = array_intersect($productIds, $db->fetchCol(
        $db->quoteInto('SELECT entity_id FROM catalog_product_entity WHERE sku IN (?)', $skuFilter)
    ));
}

if (!$productIds) {
    echo "No products carry the badge \"{$badgeName}\" — nothing to do.\n";
    exit(0);
}

printf("Badge: %s\nProducts: %d\nMode: %s\n\n", $badgeName, count($productIds), $apply ? 'APPLY' : 'DRY-RUN');

$ok = 0;
$skipped = 0;
$failed = 0;

foreach ($productIds as $pid) {
    $product = Mage::getModel('catalog/product')->load((int) $pid);
    if (!$product->getId()) {
        printf("  [skip] product %d not found\n", $pid);
        $skipped++;
        continue;
    }

    $sku   = (string) $product->getSku();
    $title = (string) $product->getName();

    // Mirror the controller's guard: only fundable (TGS-) SKUs carry chips.
    if (!$helper->isFundableSku($sku)) {
        printf("  [skip] %-18s not a fundable SKU\n", $sku);
        $skipped++;
        continue;
    }

    // Each product's OWN badges — never a shared batch set.
    $badges = $helper->getProductBadges($product);
    if (!in_array($badgeName, $badges, true)) {
        printf("  [skip] %-18s badge not readable via helper\n", $sku);
        $skipped++;
        continue;
    }

    if (!$apply) {
        printf("  [dry ] %-18s would re-render with: %s\n", $sku, implode(', ', $badges));
        $ok++;
        continue;
    }

    try {
        $png = Mage::getModel('mmd_courseimage/cover')->render($title, $sku, $badges);

        $safeSku = preg_replace('/[^a-z0-9\-]+/i', '-', $sku) ?: ('product-' . $pid);
        $key     = 'course-covers/' . $safeSku . '-' . gmdate('Ymd-His') . '.png';

        $upload = Mage::helper('mmd_courseimage/r2')->putObject($key, $png, 'image/png');

        // Write at global scope (0) — the same default the single-course
        // generate flow uses. Deliberately no syncProductTags(): this script
        // changes the IMAGE only, never the badge data behind it.
        $product->setStoreId(0);
        $product->setData('course_image_url', $upload['url']);
        $product->getResource()->saveAttribute($product, 'course_image_url');

        // course_image_url is read from the flat table on the storefront, so
        // EAV-only writes would keep serving the stale cover until a reindex.
        if (Mage::helper('catalog/product_flat')->isEnabled()) {
            $flat = Mage::getResourceSingleton('catalog/product_flat_indexer');
            foreach (Mage::app()->getStores() as $st) {
                $flat->updateProduct((int) $pid, (int) $st->getId());
            }
        }
        Mage::app()->cleanCache(['catalog_product_' . (int) $pid]);

        printf("  [ ok ] %-18s %s (%d bytes)\n", $sku, basename($upload['url']), $upload['bytes']);
        $ok++;
    } catch (Throwable $e) {
        printf("  [FAIL] %-18s %s\n", $sku, $e->getMessage());
        $failed++;
    }
}

printf("\nDone. ok=%d skipped=%d failed=%d\n", $ok, $skipped, $failed);
exit($failed > 0 ? 1 : 0);
