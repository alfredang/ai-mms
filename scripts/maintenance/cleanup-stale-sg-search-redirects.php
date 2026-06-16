<?php
/**
 * Clears catalogsearch_query.redirect for every SG-store row whose
 * redirect points at a path that no longer resolves on the storefront
 * (the slug isn't in core_url_rewrite, and isn't a published CMS page).
 *
 * Why: the earlier autopopulate-sg-search-redirects.php run built URLs
 * from catalog_product_entity_varchar.url_key — an EAV attribute that
 * can be set on a product whose URL was never actually wired into
 * core_url_rewrite (retired product, indexer never ran, etc.). The
 * MMD_SearchFallback ResultController clears such stale redirects on
 * the first customer hit; this script does the same in bulk so we
 * don't expose users to one bad search per stale URL.
 *
 *   docker exec ai-mms-web-1 php scripts/maintenance/cleanup-stale-sg-search-redirects.php --dry-run
 *     → counts what would be cleared. Writes nothing.
 *
 *   docker exec ai-mms-web-1 php scripts/maintenance/cleanup-stale-sg-search-redirects.php --confirm
 *     → UPDATE redirect = NULL on every row that fails the resolve check.
 *
 * After this clears the bad ones, you can re-run
 *   autopopulate-sg-search-redirects.php --confirm
 * which now sources its URLs from core_url_rewrite — the freshly-emptied
 * rows get re-filled with VALID URLs this time.
 *
 * Resolve check (mirrors MMD_SearchFallback::_redirectTargetResolves):
 *   - External host (anything not www.tertiarycourses.com.sg) → assume valid
 *   - core_url_rewrite request_path match on store 0 or 1 → valid
 *   - cms_page identifier match (with .html stripped) → valid
 *   - anything else → stale, clear it
 *
 * Idempotent: re-running after success clears 0 rows.
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app();

$args       = array_slice($argv, 1);
$dryRun     = in_array('--dry-run', $args, true);
$confirm    = in_array('--confirm', $args, true);
$verifyHttp = in_array('--verify-http', $args, true);

if (!$dryRun && !$confirm) {
    fwrite(STDERR, "Usage:\n");
    fwrite(STDERR, "  --dry-run    [--verify-http]  count what would be cleared; write nothing\n");
    fwrite(STDERR, "  --confirm    [--verify-http]  UPDATE redirect=NULL on stale rows\n");
    fwrite(STDERR, "\n");
    fwrite(STDERR, "  --verify-http  before clearing a candidate, HEAD the live URL and KEEP\n");
    fwrite(STDERR, "                 it if the server returns 200. Catches false positives\n");
    fwrite(STDERR, "                 like operator-curated /media/*.pdf redirects and any\n");
    fwrite(STDERR, "                 category page that routes outside core_url_rewrite.\n");
    fwrite(STDERR, "                 Parallel via curl_multi — ~30s on ~1000 candidates.\n");
    exit(1);
}
if ($dryRun && $confirm) {
    fwrite(STDERR, "Pass --dry-run OR --confirm, not both.\n");
    exit(1);
}

$STORE_ID  = 1; // Singapore
$STORE_HOST = 'www.tertiarycourses.com.sg';

$conn = Mage::getSingleton('core/resource')->getConnection('core_write');

echo ($dryRun ? "[DRY RUN] " : "[CONFIRM] ")
   . "loading routable SG paths from core_url_rewrite...\n";

// Set of every request_path that resolves on SG (store 0 admin + store 1
// SG). is_system=1 → Magento-generated, current. options='RP' rows are
// 301 redirects to another URL — also valid landing points (the browser
// follows). Path-style comparisons are case-sensitive in MySQL utf8
// general_ci → request_paths in core_url_rewrite are stored lowercase
// so we lowercase the test path too.
$paths = $conn->fetchCol(
    "SELECT DISTINCT request_path
       FROM core_url_rewrite
      WHERE store_id IN (0, $STORE_ID)
        AND request_path IS NOT NULL
        AND request_path != ''"
);
$validPaths = [];
foreach ($paths as $p) {
    $validPaths[strtolower($p)] = true;
}
echo "  " . number_format(count($validPaths)) . " unique routable paths\n";

// CMS page identifiers (active, scoped to admin or SG). The page is
// reachable at /<identifier> on the storefront if a corresponding
// cms_page_store row exists.
echo "loading published CMS pages...\n";
$cmsIds = $conn->fetchCol("
    SELECT DISTINCT cp.identifier
      FROM cms_page cp
      JOIN cms_page_store cps ON cps.page_id = cp.page_id
     WHERE cp.is_active = 1
       AND cps.store_id IN (0, $STORE_ID)
");
$validCms = [];
foreach ($cmsIds as $id) {
    $validCms[strtolower($id)] = true;
}
echo "  " . number_format(count($validCms)) . " CMS identifiers\n";

echo "scanning catalogsearch_query.redirect on SG...\n";
$rows = $conn->fetchAll("
    SELECT query_id, query_text, redirect
      FROM catalogsearch_query
     WHERE store_id = $STORE_ID
       AND redirect IS NOT NULL
       AND redirect != ''
");
echo "  " . number_format(count($rows)) . " rows have a redirect set\n";

$toClear = [];
$kept    = 0;
$external = 0;
foreach ($rows as $r) {
    $url = trim($r['redirect']);
    if ($url === '') continue; // shouldn't happen given WHERE clause, but safe

    // External URL — host doesn't match ours: trust it (operator typed
    // it manually; not our problem to validate).
    if (preg_match('#^https?://#i', $url)) {
        $host = parse_url($url, PHP_URL_HOST);
        if ($host && strcasecmp($host, $STORE_HOST) !== 0) {
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

    // CMS fallback — strip .html and look up identifier.
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

// Optional HTTP safety net: HEAD each candidate URL against the live
// site. 200 → demote from CLEAR back to KEEP (catches direct-file
// redirects like /media/*.pdf and any category page routed outside
// core_url_rewrite). Parallel via curl_multi so ~1000 candidates
// finish in ~30s, not 25 min serially.
if ($verifyHttp && !empty($toClear)) {
    $unique = array_values(array_unique(array_column($toClear, 'redirect')));
    echo "verifying " . count($unique) . " unique URLs against live site...\n";
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
            $code = (int) curl_getinfo($h['ch'], CURLINFO_HTTP_CODE);
            $verified[$h['url']] = ($code === 200);
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

echo "\n=== Plan ===\n";
echo "  keep:  " . number_format($kept)           . "  (routable"
   . ($external > 0 ? "; " . number_format($external) . " external" : "")
   . ($verifyHttp ? "; HTTP-verified" : "")
   . ")\n";
echo "  CLEAR: " . number_format(count($toClear)) . "  (stale — redirect → NULL)\n";

if (!empty($toClear)) {
    echo "\n=== First 20 to clear ===\n";
    foreach (array_slice($toClear, 0, 20) as $t) {
        printf("  [%d]  '%s'\n        was: %s\n",
            $t['query_id'], $t['query_text'], $t['redirect']);
    }
}

if ($dryRun) {
    echo "\n[DRY RUN] no rows touched. Re-run with --confirm to apply.\n";
    exit(0);
}

if (empty($toClear)) {
    echo "\nNothing to do.\n";
    exit(0);
}

echo "\nclearing redirects in batches of 500...\n";
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
    fwrite(STDERR, "ERROR: " . $e->getMessage() . "\nRolled back. Table is untouched.\n");
    exit(4);
}

echo "\nDone.\n";
echo "  cleared: " . number_format(count($toClear)) . " rows\n";
echo "\nNext step: re-run autopopulate-sg-search-redirects.php --confirm\n";
echo "  to re-fill these now-empty rows with VALID URLs (the updated\n";
echo "  script sources from core_url_rewrite, not stale EAV url_keys).\n";
