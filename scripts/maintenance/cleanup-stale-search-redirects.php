<?php
/**
 * Clears catalogsearch_query.redirect for every row in a given store
 * whose redirect points at a path that no longer resolves on that
 * store's storefront (slug isn't in core_url_rewrite for that store,
 * and isn't a published CMS page).
 *
 * Why: autopopulate-search-redirects.php earlier sourced URLs from
 * catalog_product_entity_varchar.url_key — an EAV attribute that can
 * be set on a product whose URL was never actually wired into
 * core_url_rewrite (retired product, indexer never ran, etc.).
 * MMD_SearchFallback clears such stale redirects on the first
 * customer hit; this script does the same in bulk so we don't expose
 * users to one bad search per stale URL.
 *
 *   php scripts/maintenance/cleanup-stale-search-redirects.php \
 *       --store=<code> --dry-run  [--verify-http]
 *   php scripts/maintenance/cleanup-stale-search-redirects.php \
 *       --store=<code> --confirm  [--verify-http]
 *   php scripts/maintenance/cleanup-stale-search-redirects.php \
 *       --all-stores   --confirm  [--verify-http]
 *
 * Store codes: singapore, malaysia, ghana, nigeria, bhutan, india,
 * infotech (matches core_store.code).
 *
 * --verify-http
 *   Before clearing a candidate, HEAD the URL against the store's
 *   own base_url and KEEP if 200. Catches false positives like
 *   operator-curated /media/*.pdf redirects and category pages that
 *   route outside core_url_rewrite. Parallel via curl_multi.
 *
 * After this clears the bad ones, re-run
 *   autopopulate-search-redirects.php --store=<code> --confirm
 * to refill the freshly-emptied rows with VALID URLs (the
 * autopopulate sources from core_url_rewrite, not stale EAV).
 *
 * Resolve check (mirrors MMD_SearchFallback::_redirectTargetResolves):
 *   - External host (not the store's own domain) → trust, KEEP
 *   - core_url_rewrite request_path match on store 0 or current → KEEP
 *   - cms_page identifier match (with .html stripped) → KEEP
 *   - anything else → stale, CLEAR
 *
 * Idempotent: re-running after success clears 0 rows.
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app();

// Active country stores after the 2026-06 retirement
// (migration 205-remove-malaysia-infotech-stores.sql) — websites 2
// (Malaysia), 3 (Ghana), 5 (Bhutan), 6 (India), 7 (Infotech) are
// no longer routable. --all-stores only iterates SG + NG now.
const COUNTRY_STORE_CODES = [
    'singapore',
    'nigeria',
];

$args       = array_slice($argv, 1);
$dryRun     = in_array('--dry-run',    $args, true);
$confirm    = in_array('--confirm',    $args, true);
$verifyHttp = in_array('--verify-http', $args, true);
$allStores  = in_array('--all-stores', $args, true);
$storeCode  = null;
foreach ($args as $a) {
    if (strpos($a, '--store=') === 0) {
        $storeCode = substr($a, strlen('--store='));
        break;
    }
}

if (!$dryRun && !$confirm) {
    fwrite(STDERR, "Usage:\n");
    fwrite(STDERR, "  --store=<code>  --dry-run  [--verify-http]\n");
    fwrite(STDERR, "  --store=<code>  --confirm  [--verify-http]\n");
    fwrite(STDERR, "  --all-stores    --dry-run  [--verify-http]\n");
    fwrite(STDERR, "  --all-stores    --confirm  [--verify-http]\n");
    fwrite(STDERR, "\nStore codes: " . implode(', ', COUNTRY_STORE_CODES) . "\n");
    exit(1);
}
if ($dryRun && $confirm) {
    fwrite(STDERR, "Pass --dry-run OR --confirm, not both.\n");
    exit(1);
}
if (!$storeCode && !$allStores) {
    fwrite(STDERR, "Pass --store=<code> OR --all-stores.\n");
    exit(1);
}
if ($storeCode && $allStores) {
    fwrite(STDERR, "Pass --store=<code> OR --all-stores, not both.\n");
    exit(1);
}

$conn = Mage::getSingleton('core/resource')->getConnection('core_write');

/**
 * Cleanup pass for a single store. Returns
 *   ['cleared' => N, 'kept' => K, 'skipped' => bool]
 * Throws on DB error; caller wraps each call.
 */
function processStore(
    string $code,
    bool $dryRun,
    bool $verifyHttp,
    $conn
): array {
    $store = Mage::app()->getStore($code);
    if (!$store || !$store->getId()) {
        throw new RuntimeException("Unknown store code: $code");
    }
    $storeId  = (int) $store->getId();
    $baseUrl  = rtrim((string) $store->getBaseUrl(), '/') . '/';
    $storeHost = parse_url($baseUrl, PHP_URL_HOST);

    echo "\n========================================================\n";
    echo ($dryRun ? "[DRY RUN] " : "[CONFIRM] ")
       . "store=$code (id=$storeId)  base=$baseUrl\n";
    echo "========================================================\n";

    echo "loading routable paths from core_url_rewrite for store $storeId...\n";
    $paths = $conn->fetchCol(
        "SELECT DISTINCT request_path
           FROM core_url_rewrite
          WHERE store_id IN (0, $storeId)
            AND request_path IS NOT NULL
            AND request_path != ''"
    );
    $validPaths = [];
    foreach ($paths as $p) {
        $validPaths[strtolower($p)] = true;
    }
    echo "  " . number_format(count($validPaths)) . " unique routable paths\n";

    echo "loading published CMS pages for store $storeId...\n";
    $cmsIds = $conn->fetchCol("
        SELECT DISTINCT cp.identifier
          FROM cms_page cp
          JOIN cms_page_store cps ON cps.page_id = cp.page_id
         WHERE cp.is_active = 1
           AND cps.store_id IN (0, $storeId)
    ");
    $validCms = [];
    foreach ($cmsIds as $id) {
        $validCms[strtolower($id)] = true;
    }
    echo "  " . number_format(count($validCms)) . " CMS identifiers\n";

    echo "scanning catalogsearch_query.redirect on store $storeId...\n";
    $rows = $conn->fetchAll("
        SELECT query_id, query_text, redirect
          FROM catalogsearch_query
         WHERE store_id = $storeId
           AND redirect IS NOT NULL
           AND redirect != ''
    ");
    echo "  " . number_format(count($rows)) . " rows have a redirect set\n";

    if (empty($rows)) {
        echo "  (no redirects set — skipping)\n";
        return ['cleared' => 0, 'kept' => 0, 'skipped' => true];
    }

    $toClear  = [];
    $kept     = 0;
    $external = 0;
    foreach ($rows as $r) {
        $url = trim($r['redirect']);
        if ($url === '') continue;

        if (preg_match('#^https?://#i', $url)) {
            $host = parse_url($url, PHP_URL_HOST);
            // External (different host) → trust, KEEP
            if ($host && $storeHost && strcasecmp($host, $storeHost) !== 0) {
                $external++;
                $kept++;
                continue;
            }
            $url = (string) parse_url($url, PHP_URL_PATH);
        }

        $path = ltrim((string) $url, '/');
        if (strpos($path, 'index.php/') === 0) {
            $path = substr($path, strlen('index.php/'));
        }
        $path = strtolower($path);

        if ($path === '') {
            $toClear[] = [
                'query_id'   => (int) $r['query_id'],
                'query_text' => $r['query_text'],
                'redirect'   => $r['redirect'],
            ];
            continue;
        }

        if (isset($validPaths[$path])) {
            $kept++;
            continue;
        }

        $cmsId = preg_replace('#\.html$#i', '', $path);
        if ($cmsId !== '' && isset($validCms[$cmsId])) {
            $kept++;
            continue;
        }

        $toClear[] = [
            'query_id'   => (int) $r['query_id'],
            'query_text' => $r['query_text'],
            'redirect'   => $r['redirect'],
        ];
    }

    if ($verifyHttp && !empty($toClear)) {
        $unique = array_values(array_unique(array_column($toClear, 'redirect')));
        echo "verifying " . count($unique) . " unique URLs against $baseUrl...\n";
        $verified = [];
        $i = 0;
        foreach (array_chunk($unique, 25) as $batch) {
            $mh = curl_multi_init();
            $handles = [];
            foreach ($batch as $u) {
                $ch = curl_init($u);
                curl_setopt_array($ch, [
                    CURLOPT_NOBODY         => true,
                    CURLOPT_FOLLOWLOCATION => true,
                    CURLOPT_TIMEOUT        => 8,
                    CURLOPT_CONNECTTIMEOUT => 4,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_USERAGENT      => 'mmd-stale-redirect-cleanup/1.0',
                ]);
                curl_multi_add_handle($mh, $ch);
                $handles[(int) $ch] = ['ch' => $ch, 'url' => $u];
            }
            do {
                curl_multi_exec($mh, $running);
                curl_multi_select($mh, 1.0);
            } while ($running > 0);
            foreach ($handles as $h) {
                $hcode = (int) curl_getinfo($h['ch'], CURLINFO_HTTP_CODE);
                $verified[$h['url']] = ($hcode === 200);
                curl_multi_remove_handle($mh, $h['ch']);
                curl_close($h['ch']);
            }
            curl_multi_close($mh);
            $i += count($batch);
            if ($i % 200 === 0 || $i === count($unique)) {
                echo "  ... $i / " . count($unique) . "\n";
            }
        }
        $stillStale = [];
        $rescued    = 0;
        foreach ($toClear as $t) {
            if (!empty($verified[$t['redirect']])) {
                $rescued++;
                $kept++;
            } else {
                $stillStale[] = $t;
            }
        }
        $toClear = $stillStale;
        echo "  rescued (200 OK on live): " . number_format($rescued) . "\n";
        echo "  confirmed stale (non-200): " . number_format(count($toClear)) . "\n";
    }

    echo "\n=== Plan for $code ===\n";
    echo "  keep:  " . number_format($kept) . "  (routable"
       . ($external > 0 ? "; " . number_format($external) . " external" : "")
       . ($verifyHttp ? "; HTTP-verified" : "")
       . ")\n";
    echo "  CLEAR: " . number_format(count($toClear)) . "  (stale — redirect → NULL)\n";

    if (!empty($toClear)) {
        echo "\n=== First 10 to clear ===\n";
        foreach (array_slice($toClear, 0, 10) as $t) {
            printf("  [%d]  '%s'\n        was: %s\n",
                $t['query_id'], $t['query_text'], $t['redirect']);
        }
    }

    if ($dryRun) {
        return ['cleared' => count($toClear), 'kept' => $kept, 'skipped' => false];
    }

    if (empty($toClear)) {
        echo "\nNothing to do for $code.\n";
        return ['cleared' => 0, 'kept' => $kept, 'skipped' => true];
    }

    echo "\nclearing redirects for $code in batches of 500...\n";
    $conn->beginTransaction();
    try {
        $cleared = 0;
        foreach (array_chunk($toClear, 500) as $batch) {
            $ids = implode(',', array_map(fn($r) => (int) $r['query_id'], $batch));
            $conn->query("
                UPDATE catalogsearch_query
                   SET redirect = NULL
                 WHERE query_id IN ($ids)
            ");
            $cleared += count($batch);
            if ($cleared % 2000 === 0 || $cleared === count($toClear)) {
                echo "  ... cleared $cleared / " . count($toClear) . "\n";
            }
        }
        $conn->commit();
    } catch (Exception $e) {
        $conn->rollBack();
        throw $e;
    }
    echo "  done.  cleared=" . number_format(count($toClear)) . "\n";
    return ['cleared' => count($toClear), 'kept' => $kept, 'skipped' => false];
}

// ============================================================
// Dispatch: one store or all stores
// ============================================================
$targets = $allStores ? COUNTRY_STORE_CODES : [$storeCode];

// Filter against the actual installed stores. Each country runs on its
// own Coolify deployment with its own DB, so the SG instance only has
// the SG store, the NG instance only has NG, etc. Stores in
// COUNTRY_STORE_CODES that don't exist here are skipped silently
// rather than logged as errors.
$installed = array_map(
    static fn($s) => $s->getCode(),
    Mage::app()->getStores(true)
);
$missing = array_diff($targets, $installed);
$targets = array_values(array_intersect($targets, $installed));
foreach ($missing as $code) {
    echo "skipping store '$code' — not installed on this instance\n";
}

$totals = ['cleared' => 0, 'kept' => 0, 'errored' => 0, 'skipped' => 0];
foreach ($targets as $code) {
    try {
        $r = processStore($code, $dryRun, $verifyHttp, $conn);
        $totals['cleared'] += $r['cleared'];
        $totals['kept']    += $r['kept'];
        if (!empty($r['skipped'])) $totals['skipped']++;
    } catch (Exception $e) {
        fwrite(STDERR, "ERROR processing store $code: " . $e->getMessage() . "\n");
        $totals['errored']++;
    }
}

if (count($targets) > 1) {
    echo "\n========================================================\n";
    echo "Grand total across " . count($targets) . " stores:\n";
    echo "  kept:    " . number_format($totals['kept']) . " rows\n";
    echo "  cleared: " . number_format($totals['cleared']) . " rows\n";
    echo "  skipped: " . $totals['skipped'] . " stores (no redirects)\n";
    if ($totals['errored']) {
        echo "  ERRORED: " . $totals['errored'] . " stores — see above\n";
    }
    echo "========================================================\n";
}

if ($dryRun) {
    echo "\n[DRY RUN] no rows touched. Re-run with --confirm to apply.\n";
} else {
    echo "\nNext step: re-run autopopulate-search-redirects.php with the same --store / --all-stores\n";
    echo "  to re-fill these now-empty rows with VALID URLs from core_url_rewrite.\n";
}
