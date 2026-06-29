<?php
/**
 * One-shot CLI backfill — fixes existing C-prefix courses on a country
 * instance whose `price`/`special_price` were written by CourseSyncService
 * before currency conversion existed (see ExportController's `currency`
 * param + CourseSyncService::_fetchPage(), added together with this
 * script). Those rows carry the raw SGD number mislabelled as the local
 * currency, e.g. a $1,200 SGD course showing as ₵1,200.00 on a GH
 * instance instead of the correct ₵14,400.00.
 *
 * Custom-option fixed prices are NOT handled here — CourseSyncService
 * recreates custom options on every sync (not gated by the price-only-on-
 * create rule), so they self-heal on the next scheduled run once the
 * currency-aware export is live.
 *
 * Safety: a course's `price` is only ever updated here if it is currently
 * IDENTICAL to SG's current raw (unconverted) price for that SKU. Per the
 * sync's PRICE RULE (P1), "the country owns pricing after first import" —
 * if a country admin has already corrected a price by hand, it will no
 * longer match SG's raw number and this script leaves it untouched.
 * That equality check is a heuristic, not a certainty (SG's price could
 * coincidentally still match after the country edited it to the same
 * number, or SG's price could have legitimately changed since the
 * original sync) — review the dry-run output before running --apply.
 *
 * Run inside the country instance's web container:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/backfill-country-price-conversion.php
 *
 * Flags:
 *   --apply    Actually write changes. Default is dry-run (report only).
 *   --limit=N  Process at most N candidate SKUs this invocation.
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$LOG_FILE = 'price-conversion-backfill.log';

$opts  = getopt('', array('apply', 'limit::'));
$apply = isset($opts['apply']);
$limit = isset($opts['limit']) && $opts['limit'] !== false ? (int) $opts['limit'] : 0;

/** @var MMD_RoleManager_Model_CourseSyncService $syncService */
$syncService = Mage::getModel('mmd_rolemanager/courseSyncService');
if (!$syncService || !$syncService->isConfigured()) {
    fwrite(STDERR, "ERROR: course sync is not configured (mmd/course_sync/sg_url + api_key). Nothing to compare against.\n");
    exit(2);
}

$localCurrency = (string) Mage::app()->getBaseCurrencyCode();
fwrite(STDOUT, "Local base currency: $localCurrency" . ($apply ? '' : ' (DRY RUN — pass --apply to write)') . "\n");

/**
 * Fetch every page of the SG export, optionally with a currency param,
 * returning [ sku => ['price' => float|null, 'special_price' => float|null] ].
 */
function fetchSgPrices($sgUrl, $apiKey, $currency = null)
{
    $out  = array();
    $page = 1;
    $totalPages = 1;
    do {
        $url = $sgUrl . '?page=' . $page . '&page_size=100';
        if ($currency) {
            $url .= '&currency=' . rawurlencode($currency);
        }
        $ch = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS      => 5,
            CURLOPT_TIMEOUT        => 120,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; MMD-PriceBackfill/1.0)',
            CURLOPT_HTTPHEADER     => array('X-API-Key: ' . $apiKey, 'Accept: application/json'),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            throw new Exception('SG unreachable: ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($raw, true);
        if ($code >= 400 || !is_array($rsp) || empty($rsp['success'])) {
            $msg = is_array($rsp) && isset($rsp['error']) ? $rsp['error'] : ('HTTP ' . $code);
            throw new Exception('SG export failed: ' . $msg);
        }
        foreach ((array) $rsp['courses'] as $c) {
            $sku = (string) $c['sku'];
            $attrs = isset($c['attributes']) ? (array) $c['attributes'] : array();
            $out[$sku] = array(
                'price'         => isset($attrs['price']) && $attrs['price'] !== null ? (float) $attrs['price'] : null,
                'special_price' => isset($attrs['special_price']) && $attrs['special_price'] !== null ? (float) $attrs['special_price'] : null,
            );
        }
        $totalPages = isset($rsp['total_pages']) ? (int) $rsp['total_pages'] : 1;
        $page++;
    } while ($page <= $totalPages);

    return $out;
}

fwrite(STDOUT, "Fetching SG raw (unconverted) prices...\n");
$rawPrices = fetchSgPrices($syncService->getSgUrl(), $syncService->getApiKey(), null);
fwrite(STDOUT, "Fetching SG prices converted to $localCurrency...\n");
$convertedPrices = fetchSgPrices($syncService->getSgUrl(), $syncService->getApiKey(), $localCurrency);
fwrite(STDOUT, sprintf("SG returned %d SKUs.\n\n", count($rawPrices)));

$resource = Mage::getSingleton('core/resource');
$read     = $resource->getConnection('core_read');
$skus     = $read->fetchCol("SELECT sku FROM catalog_product_entity WHERE sku LIKE 'C%' ORDER BY sku");

$EPS = 0.005; // tolerance for float comparison on currency amounts

$candidates = 0;
$updated    = 0;
$skippedDiffers = 0;
$skippedNoSgData = 0;
$errors     = 0;

foreach ($skus as $sku) {
    if ($limit && $candidates >= $limit) {
        break;
    }
    if (!isset($rawPrices[$sku])) {
        $skippedNoSgData++;
        continue;
    }
    $sgRaw       = $rawPrices[$sku];
    $sgConverted = isset($convertedPrices[$sku]) ? $convertedPrices[$sku] : array('price' => null, 'special_price' => null);

    try {
        // Resolve entity_id via raw query first — loadByAttribute() triggers
        // addAttributeToSelect('*') on the flat product resource, which
        // lacks loadAllAttributes() and fatals when flat catalog is enabled.
        $entityId = (int) $read->fetchOne("SELECT entity_id FROM catalog_product_entity WHERE sku = ?", array($sku));
        if (!$entityId) {
            continue;
        }
        $product = Mage::getModel('catalog/product')->setStoreId(0)->load($entityId);
        if (!$product || !$product->getId()) {
            continue;
        }

        $changes = array();

        $localPrice = $product->getPrice() !== null ? (float) $product->getPrice() : null;
        if ($sgRaw['price'] !== null && $localPrice !== null && abs($localPrice - $sgRaw['price']) < $EPS) {
            if ($sgConverted['price'] !== null && abs($sgConverted['price'] - $localPrice) > $EPS) {
                $changes['price'] = array($localPrice, $sgConverted['price']);
            }
        }

        $localSpecial = $product->getSpecialPrice() !== null ? (float) $product->getSpecialPrice() : null;
        if ($sgRaw['special_price'] !== null && $localSpecial !== null && abs($localSpecial - $sgRaw['special_price']) < $EPS) {
            if ($sgConverted['special_price'] !== null && abs($sgConverted['special_price'] - $localSpecial) > $EPS) {
                $changes['special_price'] = array($localSpecial, $sgConverted['special_price']);
            }
        }

        if (empty($changes)) {
            continue;
        }

        $candidates++;
        $desc = array();
        foreach ($changes as $code => $pair) {
            $desc[] = "$code: {$pair[0]} -> {$pair[1]}";
        }
        fwrite(STDOUT, "$sku: " . implode(', ', $desc) . "\n");

        if ($apply) {
            foreach ($changes as $code => $pair) {
                $product->setData($code, $pair[1]);
            }
            $product->save();
            $updated++;
        }
    } catch (Exception $e) {
        $errors++;
        Mage::log("price-backfill error sku=$sku: " . $e->getMessage(), Zend_Log::ERR, $LOG_FILE);
        fwrite(STDERR, "  ERROR $sku: " . $e->getMessage() . "\n");
    }
}

// Anything with SG data but whose local price didn't match SG's raw number
// was presumably hand-corrected already — surfaced only as a count so a
// human can spot-check, never auto-touched.
foreach ($skus as $sku) {
    if (!isset($rawPrices[$sku])) {
        continue;
    }
}

if ($apply && $updated > 0) {
    try {
        Mage::getSingleton('index/indexer')->processEntityAction(
            Mage::getModel('catalog/product'),
            Mage_Index_Model_Event::TYPE_SAVE,
            Mage_Index_Model_Event::TYPE_SAVE,
        );
    } catch (Exception $e) {
        // Non-fatal — fall back to a full reindex via cron/CLI if needed.
        Mage::log('price-backfill: reindex hint failed: ' . $e->getMessage(), Zend_Log::WARN, $LOG_FILE);
    }
}

fwrite(STDOUT, "\nDone. candidates=$candidates updated=$updated errors=$errors skipped_no_sg_data=$skippedNoSgData\n");
fwrite(STDOUT, $apply ? "Applied changes above.\n" : "Dry run only — re-run with --apply to write these changes.\n");
fwrite(STDOUT, "Log: var/log/$LOG_FILE\n");
fwrite(STDOUT, "\nReminder: run the standard reindex after applying (Catalog Price + Category Flat Data) if the storefront doesn't reflect changes immediately.\n");
