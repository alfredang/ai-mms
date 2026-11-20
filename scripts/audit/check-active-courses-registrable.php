<?php
/**
 * HARD RULE: every active (enabled) course allows registration.
 *
 * Loads every enabled product on each store it is sold on and asks the storefront
 * the same question the Register button asks (isSalable(), which runs every
 * catalog_product_is_salable_after observer and the stock check). Exit 1 if any
 * enabled course cannot be registered for.
 *
 *   php scripts/audit/check-active-courses-registrable.php          # report
 *   php scripts/audit/check-active-courses-registrable.php --fix    # put them back in stock + flush
 *
 * Run inside the web container, as www-data when using --fix. --fix only repairs
 * the stock flag; a course blocked by code is reported again and needs the code
 * removed (see scripts/audit/check-registration-open.sh).
 */
ob_start();
require_once dirname(__FILE__) . '/../../app/Mage.php';
Mage::app('admin');
ob_clean();
// Output stays buffered until exit: loading a product starts a session, which PHP
// refuses once anything has been printed.

$fix = in_array('--fix', $argv, true);

function mmdBlockedCourses()
{
    $blocked = array();
    foreach (Mage::app()->getStores() as $store) {
        $storeId = (int) $store->getId();
        $ids = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId($storeId)
            ->addStoreFilter($storeId)
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->getAllIds();
        Mage::app()->setCurrentStore($storeId);
        foreach ($ids as $id) {
            $product = Mage::getModel('catalog/product')->setStoreId($storeId)->load($id);
            if (!$product->isSalable()) {
                $blocked[(int) $id] = array('sku' => $product->getSku(), 'store' => $store->getCode());
            }
            $product->clearInstance();
        }
    }
    Mage::app()->setCurrentStore(Mage_Core_Model_App::ADMIN_STORE_ID);
    return $blocked;
}

$blocked = mmdBlockedCourses();
if (!$blocked) {
    echo "OK: every active course allows registration\n";
    exit(0);
}
foreach ($blocked as $id => $r) {
    echo "REGISTRATION CLOSED: {$r['sku']} (id {$id}, store {$r['store']})\n";
}
echo count($blocked) . " active course(s) cannot be registered for\n";
if (!$fix) {
    exit(1);
}

foreach (array_keys($blocked) as $id) {
    $stock = Mage::getModel('cataloginventory/stock_item')->loadByProduct($id);
    if (!$stock->getId()) {
        $stock->setProductId($id)->setStockId(1);
    }
    $stock->setUseConfigManageStock(0)->setManageStock(0)->setIsInStock(1)->save();
}
$p = Mage::getModel('index/process')->load('cataloginventory_stock', 'indexer_code');
if ($p->getId()) {
    $p->reindexEverything();
}
Mage::app()->getCacheInstance()->flush();

$still = mmdBlockedCourses();
if ($still) {
    foreach ($still as $id => $r) {
        echo "STILL CLOSED (blocked by code, not stock): {$r['sku']} (id {$id}, store {$r['store']})\n";
    }
    exit(1);
}
echo "FIXED: " . count($blocked) . " course(s) back in stock; cache flushed\n";
