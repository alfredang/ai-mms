<?php
// Collapse a franchise partner DB to a single store. Args: keepStore keepGroup keepWebsite
require '/var/www/html/app/Mage.php';
Mage::app();
$keepStore   = (int)$argv[1];
$keepGroup   = (int)$argv[2];
$keepWebsite = (int)$argv[3];
$conn = Mage::getSingleton('core/resource')->getConnection('core_write');

$delStores   = array_map('intval', $conn->fetchCol("SELECT store_id FROM core_store WHERE store_id NOT IN (0,$keepStore)"));
$delWebsites = array_map('intval', $conn->fetchCol("SELECT website_id FROM core_website WHERE website_id NOT IN (0,$keepWebsite)"));
$delGroups   = array_map('intval', $conn->fetchCol("SELECT group_id FROM core_store_group WHERE group_id NOT IN (0,$keepGroup)"));
$sids = $delStores   ? implode(',', $delStores)   : '-1';
$wids = $delWebsites ? implode(',', $delWebsites) : '-1';
echo "KEEP store=$keepStore group=$keepGroup website=$keepWebsite\n";
echo "DELETE stores=[$sids] websites=[$wids] groups=[" . implode(',', $delGroups) . "]\n";

// 1) Repoint defaults to the survivor BEFORE deleting the old default website.
$conn->query("UPDATE core_website SET is_default = IF(website_id=$keepWebsite,1,0)");
$conn->query("UPDATE core_store_group SET default_store_id=$keepStore WHERE group_id=$keepGroup");
$conn->query("UPDATE core_website SET default_group_id=$keepGroup WHERE website_id=$keepWebsite");

$conn->query("SET FOREIGN_KEY_CHECKS=0");

// 2) Purge every store-scoped / website-scoped row for the deleted ids (never id 0 / survivor).
foreach ([['store_id', $sids], ['website_id', $wids]] as $pair) {
    list($col, $ids) = $pair;
    $tbls = $conn->fetchCol("SELECT DISTINCT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND COLUMN_NAME='$col'");
    foreach ($tbls as $t) {
        if (in_array($t, ['core_store', 'core_store_group', 'core_website'])) {
            continue;
        }
        try {
            $n = $conn->query("DELETE FROM `$t` WHERE `$col` IN ($ids)")->rowCount();
            if ($n) {
                echo "  $t.$col -$n\n";
            }
        } catch (Throwable $e) {
            echo "  [skip] $t.$col: " . substr($e->getMessage(), 0, 70) . "\n";
        }
    }
}

// 3) Config scope rows (no FK).
$conn->query("DELETE FROM core_config_data WHERE scope='stores' AND scope_id IN ($sids)");
$conn->query("DELETE FROM core_config_data WHERE scope='websites' AND scope_id IN ($wids)");

// 4) The topology rows themselves.
$conn->query("DELETE FROM core_store WHERE store_id IN ($sids)");
$conn->query("DELETE FROM core_store_group WHERE group_id NOT IN (0,$keepGroup)");
$conn->query("DELETE FROM core_website WHERE website_id IN ($wids)");

$conn->query("SET FOREIGN_KEY_CHECKS=1");

echo "REMAIN stores:   " . implode(' | ', $conn->fetchCol("SELECT CONCAT(store_id,':',code) FROM core_store ORDER BY store_id")) . "\n";
echo "REMAIN groups:   " . implode(' | ', $conn->fetchCol("SELECT CONCAT(group_id,':',name) FROM core_store_group ORDER BY group_id")) . "\n";
echo "REMAIN websites: " . implode(' | ', $conn->fetchCol("SELECT CONCAT(website_id,':',code,IF(is_default,'*','')) FROM core_website ORDER BY website_id")) . "\n";
echo "REMAIN sitemap:  " . implode(' | ', $conn->fetchCol("SELECT CONCAT(sitemap_id,':store',store_id) FROM sitemap ORDER BY sitemap_id")) . "\n";
