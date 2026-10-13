<?php
/**
 * Apply a reviewed Course Info manifest to MY/GH only. Dry-run by default.
 * php scripts/maintenance/update-partner-course-info.php --manifest=path.json [--apply]
 * Back up the country DB first. Reindex catalog_product_flat and
 * catalog_category_flat and flush Magento cache separately after applying.
 * Only the target store's prerequisite EAV value is written; no product save,
 * timestamps, prices, courseware, schedules, visibility or shared templates.
 */
if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}
require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

try {
    $opts = getopt('', array('manifest:', 'apply'));
    $cc = strtoupper((string) getenv('MMS_COUNTRY_CODE'));
    $codes = array('MY' => 'malaysia', 'GH' => 'ghana');
    if (strtolower((string) getenv('MMS_MODE')) !== 'country' || !isset($codes[$cc])) {
        throw new Exception('Refusing: this script is restricted to MY/GH country instances.');
    }
    if (empty($opts['manifest'])) {
        throw new Exception('Specify a reviewed --manifest JSON file.');
    }
    $manifest = json_decode(file_get_contents($opts['manifest']), true, 512, JSON_THROW_ON_ERROR);
    $store = Mage::app()->getStore($codes[$cc]);
    $sid = (int) $store->getId();
    if ($manifest['country'] !== $cc || $manifest['store_code'] !== $codes[$cc]
        || (int) $manifest['store_id'] !== $sid) {
        throw new Exception('Country/store identity does not match the reviewed manifest.');
    }
    $db = Mage::getSingleton('core/resource')->getConnection('core_write');
    $attrs = $db->fetchPairs("SELECT attribute_code, attribute_id FROM eav_attribute WHERE entity_type_id = 4");
    $type = $db->fetchOne('SELECT backend_type FROM eav_attribute WHERE attribute_id = ?', $attrs['prerequisite']);
    if ($type !== 'text') {
        throw new Exception('Unexpected prerequisite storage type.');
    }
    $effective = function ($id, $code, $table) use ($db, $attrs, $sid) {
        return (string) $db->fetchOne(
            'SELECT value FROM catalog_product_entity_' . $table
            . ' WHERE entity_id = ? AND attribute_id = ? AND store_id IN (0, ?)'
            . ' ORDER BY store_id DESC LIMIT 1', array($id, $attrs[$code], $sid)
        );
    };
    $active = $db->fetchAll(
        'SELECT p.entity_id, p.sku FROM catalog_product_entity p'
        . ' JOIN catalog_product_website w ON w.product_id = p.entity_id AND w.website_id = ?'
        . ' LEFT JOIN catalog_product_entity_int s0 ON s0.entity_id = p.entity_id'
        . ' AND s0.attribute_id = ? AND s0.store_id = 0'
        . ' LEFT JOIN catalog_product_entity_int ss ON ss.entity_id = p.entity_id'
        . ' AND ss.attribute_id = ? AND ss.store_id = ?'
        . ' WHERE COALESCE(ss.value, s0.value) = 1 ORDER BY p.entity_id',
        array($store->getWebsiteId(), $attrs['status'], $attrs['status'], $sid)
    );
    $bySku = array();
    foreach ($active as $row) {
        $sku = trim($row['sku']);
        if (isset($bySku[$sku])) {
            throw new Exception('Duplicate normalized active SKU: ' . $sku);
        }
        $bySku[$sku] = (int) $row['entity_id'];
    }
    if (count($bySku) !== (int) $manifest['active_count']
        || count($manifest['changes']) !== count($bySku)) {
        throw new Exception('Active catalogue count changed; regenerate and review the manifest.');
    }
    $pending = array();
    $seen = array();
    $db->beginTransaction();
    foreach ($manifest['changes'] as $change) {
        $sku = $change['sku'];
        if (!isset($bySku[$sku]) || isset($seen[$sku])) {
            throw new Exception('Manifest must cover every active SKU exactly once: ' . $sku);
        }
        $seen[$sku] = true;
        $id = $bySku[$sku];
        $db->fetchOne('SELECT entity_id FROM catalog_product_entity WHERE entity_id = ? FOR UPDATE', $id);
        if ($effective($id, 'name', 'varchar') !== $change['name']) {
            throw new Exception('Course identity changed: ' . $sku);
        }
        $html = $change['prerequisite'];
        foreach (array('Prerequisite', 'Software Requirement', 'Hardware Requirement') as $heading) {
            if (strpos($html, '<h2>' . $heading . '</h2>') === false) {
                throw new Exception('Missing section for ' . $sku . ': ' . $heading);
            }
        }
        if (preg_match('/<script|<iframe|\bon\w+\s*=|javascript:|\bTBD\b|SkillsFuture|UTAP|PSEA|CITREP/i', $html)) {
            throw new Exception('Unsafe or Singapore-only content: ' . $sku);
        }
        if (($cc === 'MY' && strpos($html, '<h2>How to Apply for HRD Corp Funding</h2>') === false)
            || ($cc === 'GH' && strpos($html, 'HRD Corp') !== false)) {
            throw new Exception('Incorrect country funding content: ' . $sku);
        }
        $current = hash('sha256', $effective($id, 'prerequisite', 'text'));
        if ($current === hash('sha256', $html)) {
            continue; // Already applied: safe to rerun.
        }
        if (!hash_equals($change['before_sha256'], $current)) {
            throw new Exception('Course Info changed since review: ' . $sku);
        }
        $pending[] = array('entity_type_id' => 4, 'attribute_id' => $attrs['prerequisite'],
            'store_id' => $sid, 'entity_id' => $id, 'value' => $html);
    }
    if (isset($opts['apply'])) {
        foreach ($pending as $row) {
            $db->insertOnDuplicate('catalog_product_entity_text', $row, array('value'));
        }
        $db->commit();
    } else {
        $db->rollBack();
    }
    echo json_encode(array('country' => $cc, 'store_id' => $sid, 'active' => count($active),
        'changed' => count($pending), 'apply' => isset($opts['apply'])), JSON_PRETTY_PRINT) . "\n";
} catch (Throwable $e) {
    if (isset($db) && $db->getTransactionLevel()) {
        $db->rollBack();
    }
    file_put_contents('php://stderr', $e->getMessage() . "\n");
    exit(1);
}
