<?php
/**
 * For every catalogsearch_query row in a given store with NO redirect
 * set, find the store-visible product whose name + canonical
 * request_path best match the query_text. If a confident match exists,
 * write the full <base_url><request_path> into `redirect` and set
 * num_results = 1. If nothing matches confidently, DELETE the row.
 *
 * URL source: core_url_rewrite (is_system=1, category_id IS NULL — the
 * canonical flat URL the storefront router actually serves), NOT
 * catalog_product_entity_varchar.url_key (which can be a stale EAV
 * value pointing at a retired URL that 404s). MMD_SearchFallback
 * clears any stale redirect on the first customer hit anyway, but
 * generating routable URLs in the first place avoids the "search
 * shows results page once, then redirect goes empty" oddity.
 *
 * Two-phase, operator-driven:
 *
 *   php scripts/maintenance/autopopulate-search-redirects.php \
 *       --store=<code> --dry-run [--verify-http]
 *       audit + report; write nothing
 *
 *   php scripts/maintenance/autopopulate-search-redirects.php \
 *       --store=<code> --confirm [--verify-http]
 *       apply UPDATE + DELETE inside one transaction (per store)
 *
 *   php scripts/maintenance/autopopulate-search-redirects.php \
 *       --all-stores --confirm [--verify-http]
 *       loop over every country store (singapore, malaysia, ghana,
 *       nigeria, bhutan, india, infotech). Each store runs in its own
 *       transaction so a failure on one doesn't roll back the others.
 *
 * Store codes (from core_store.code): singapore, malaysia, ghana,
 * nigeria, bhutan, india, infotech. Resolved at runtime via
 * Mage::app()->getStore($code) so base_url comes from Magento's own
 * store config — no per-country domain hardcoding.
 *
 * --verify-http
 *   HEAD each unique candidate URL against the store's base_url and
 *   accept only 200. Demotes anything else to DELETE. Useful when
 *   catalog drift might still let stale rewrites through. Adds ~30s
 *   per store on a fleet of ~1500 unique URLs (parallel via
 *   curl_multi).
 *
 * Matching:
 *   - Tokenize on non-alnum boundaries; drop stopwords; min length 2
 *     so short real signals like "ai", "ml", "bi", "rpa", "iot"
 *     survive.
 *   - Pick the product with highest containment |Q ∩ P|/|Q|.
 *     Tiebreak: highest Jaccard |Q ∩ P|/|Q ∪ P|.
 *   - Accept if containment ≥ 0.5 AND Jaccard ≥ 0.3 (multi-token
 *     queries) or containment ≥ 1.0 (single-token queries — the word
 *     is unambiguous; verbose products would otherwise be unfairly
 *     demoted by a low Jaccard).
 *
 * Hard "don't"s (per CLAUDE.md):
 *   - Only touch rows where `redirect IS NULL OR redirect = ''`.
 *     Never overwrite a manual redirect.
 *   - Only emit URLs from core_url_rewrite — guaranteed routable on
 *     the destination storefront.
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app();

// Active country stores after the 2026-06 retirement
// (migration 205-remove-malaysia-infotech-stores.sql) — websites 2
// (Malaysia), 3 (Ghana), 5 (Bhutan), 6 (India), 7 (Infotech) are
// no longer routable. --all-stores only iterates SG + NG now.
// Single-store mode (--store=<code>) accepts any code Magento can
// resolve via getStore($code); if the code maps to a deleted store
// the per-store try/catch in the dispatch loop logs the error and
// moves on without aborting other stores.
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
    fwrite(STDERR, "\n");
    fwrite(STDERR, "Store codes: " . implode(', ', COUNTRY_STORE_CODES) . "\n");
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

$THRESHOLD_C = 0.5;  // containment floor
$THRESHOLD_J = 0.3;  // Jaccard floor (multi-token queries only)

// Same stopwords as audit-bad-url-rewrites.php so behavior stays
// consistent. Country names already in here — irrelevant for matching
// since the search runs within a single country at a time.
$stopwords = array_flip([
    'training', 'course', 'courses', 'day', 'days', 'hour', 'hours',
    'class', 'classes', 'workshop', 'workshops', 'certified', 'cert',
    'certification', 'professional', 'expert', 'beginner', 'beginners',
    'advanced', 'intermediate', 'introduction', 'fundamental', 'fundamentals',
    'essential', 'essentials', 'basic', 'basics', 'guide', 'with', 'using',
    'for', 'and', 'the', 'how', 'to', 'all', 'new', 'best', 'top',
    'singapore', 'malaysia', 'ghana', 'nigeria', 'bhutan', 'india',
    'wsq', 'tgs', 'in', 'on', 'of', 'an',
]);

$tokenize = function ($text) use ($stopwords) {
    $text  = strtolower(trim((string) $text));
    $text  = preg_replace('/\.html$/i', '', $text);
    $parts = preg_split('/[^a-z0-9]+/', $text);
    $out   = [];
    foreach ($parts as $p) {
        $p = trim($p);
        if (strlen($p) < 2)            continue;
        if (isset($stopwords[$p]))     continue;
        if (preg_match('/^\d+$/', $p)) continue;
        $out[$p] = true;
    }
    return array_keys($out);
};

$conn = Mage::getSingleton('core/resource')->getConnection('core_write');

$nameAttr   = (int) $conn->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'    AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')");
$statusAttr = (int) $conn->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='status'  AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')");
$visibAttr  = (int) $conn->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='visibility' AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')");
if (!$nameAttr || !$statusAttr || !$visibAttr) {
    fwrite(STDERR, "ERROR: missing EAV attribute(s) (name/status/visibility)\n");
    exit(3);
}

/**
 * Run the autopopulate flow for one store. Returns
 *   ['updated' => N, 'deleted' => M, 'skipped' => bool]
 * Errors throw — caller wraps each store in its own try so a single
 * store failure doesn't take down the rest of --all-stores.
 */
function processStore(
    string $code,
    bool $dryRun,
    bool $confirm,
    bool $verifyHttp,
    array $stopwords,
    callable $tokenize,
    int $nameAttr,
    int $statusAttr,
    int $visibAttr,
    float $THRESHOLD_C,
    float $THRESHOLD_J,
    $conn
): array {
    $store = Mage::app()->getStore($code);
    if (!$store || !$store->getId()) {
        throw new RuntimeException("Unknown store code: $code");
    }
    $storeId  = (int) $store->getId();
    $baseUrl  = rtrim((string) $store->getBaseUrl(), '/') . '/';
    $doneFlag = "mmd/{$code}_search_redirect_autopop/done_2026_06";

    echo "\n========================================================\n";
    echo ($dryRun ? "[DRY RUN] " : "[CONFIRM] ")
       . "store=$code (id=$storeId)  base=$baseUrl\n";
    echo "========================================================\n";

    if ($confirm) {
        $already = $conn->fetchOne(
            "SELECT value FROM core_config_data WHERE path = ?",
            [$doneFlag]
        );
        if ($already) {
            echo "Already ran on $already — proceeding (idempotent: only empty rows are touched).\n";
        }
    }

    echo "building product index for store $storeId...\n";
    $products = $conn->fetchAll("
        SELECT cpe.entity_id, cpe.sku,
               COALESCE(name_s.value, name_g.value) AS name,
               cur.request_path
          FROM catalog_product_entity cpe
          JOIN catalog_product_entity_int s
            ON s.entity_id = cpe.entity_id
           AND s.attribute_id = $statusAttr
           AND s.store_id IN (0, $storeId)
           AND s.value = 1
          JOIN catalog_product_entity_int v
            ON v.entity_id = cpe.entity_id
           AND v.attribute_id = $visibAttr
           AND v.store_id IN (0, $storeId)
           AND v.value IN (3, 4)
          JOIN core_url_rewrite cur
            ON cur.product_id = cpe.entity_id
           AND cur.store_id = $storeId
           AND cur.is_system = 1
           AND cur.category_id IS NULL
           AND (cur.options IS NULL OR cur.options = '')
     LEFT JOIN catalog_product_entity_varchar name_s
            ON name_s.entity_id = cpe.entity_id
           AND name_s.attribute_id = $nameAttr
           AND name_s.store_id = $storeId
     LEFT JOIN catalog_product_entity_varchar name_g
            ON name_g.entity_id = cpe.entity_id
           AND name_g.attribute_id = $nameAttr
           AND name_g.store_id = 0
      GROUP BY cpe.entity_id
    ");

    $index = [];
    foreach ($products as $p) {
        if (empty($p['request_path'])) continue;
        $toks = array_unique(array_merge(
            $tokenize($p['request_path']),
            $tokenize($p['name'])
        ));
        if (empty($toks)) continue;
        $index[] = [
            'sku'       => $p['sku'],
            'url'       => $baseUrl . $p['request_path'],
            'tokens'    => array_flip($toks),
            'tok_count' => count($toks),
        ];
    }
    echo "  indexed " . number_format(count($index)) . " products in store $code\n";

    if (empty($index)) {
        echo "  (no products with current rewrite rows — skipping)\n";
        return ['updated' => 0, 'deleted' => 0, 'skipped' => true];
    }

    echo "scoring empty search-term rows for store $storeId...\n";
    $rows = $conn->fetchAll("
        SELECT query_id, query_text, num_results
          FROM catalogsearch_query
         WHERE store_id = $storeId
           AND (redirect IS NULL OR redirect = '')
    ");
    echo "  " . number_format(count($rows)) . " empty rows to consider\n";

    if (empty($rows)) {
        echo "  (nothing empty — skipping)\n";
        return ['updated' => 0, 'deleted' => 0, 'skipped' => true];
    }

    $updates  = [];
    $deletes  = [];
    $emptyTok = 0;
    foreach ($rows as $r) {
        $qToks = $tokenize($r['query_text']);
        if (empty($qToks)) {
            $deletes[] = (int) $r['query_id'];
            $emptyTok++;
            continue;
        }
        $qCount = count($qToks);

        $best = null;
        $bestC = 0.0;
        $bestJ = 0.0;
        foreach ($index as $p) {
            $hit = 0;
            foreach ($qToks as $t) {
                if (isset($p['tokens'][$t])) $hit++;
            }
            if ($hit === 0) continue;
            $cont  = $hit / $qCount;
            $union = $qCount + $p['tok_count'] - $hit;
            $jacc  = $union > 0 ? $hit / $union : 0.0;
            if ($cont > $bestC || ($cont === $bestC && $jacc > $bestJ)) {
                $bestC = $cont;
                $bestJ = $jacc;
                $best  = $p;
            }
        }

        // Single-token queries: skip the Jaccard floor (containment 1.0
        // alone is a strong signal for domain-specific words).
        $jFloor = ($qCount === 1) ? 0.0 : $THRESHOLD_J;
        if ($best && $bestC >= $THRESHOLD_C && $bestJ >= $jFloor) {
            $updates[] = [
                'query_id'   => (int) $r['query_id'],
                'query_text' => $r['query_text'],
                'url'        => $best['url'],
                'c'          => $bestC,
                'j'          => $bestJ,
            ];
        } else {
            $deletes[] = (int) $r['query_id'];
        }
    }

    // Optional live-site HEAD check on each unique target.
    if ($verifyHttp && !empty($updates)) {
        $unique = array_values(array_unique(array_column($updates, 'url')));
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
                    CURLOPT_USERAGENT      => 'mmd-search-redirect-autopop/1.0',
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
        $kept = [];
        $dropped = 0;
        foreach ($updates as $u) {
            if (!empty($verified[$u['url']])) {
                $kept[] = $u;
            } else {
                $dropped++;
                $deletes[] = $u['query_id'];
            }
        }
        $updates = $kept;
        echo "  verified OK: " . number_format(count($kept))
           . "   demoted to DELETE: " . number_format($dropped) . "\n";
    }

    echo "\n=== Plan for $code ===\n";
    echo "  UPDATE: " . number_format(count($updates)) . " rows\n";
    echo "  DELETE: " . number_format(count($deletes)) . " rows"
       . ($emptyTok > 0 ? "  (of which $emptyTok had no usable tokens)" : "")
       . "\n";

    if (!empty($updates)) {
        echo "\n=== First 10 UPDATEs ===\n";
        foreach (array_slice($updates, 0, 10) as $u) {
            printf("  [c=%.2f j=%.2f]  '%s'  ->  %s\n",
                $u['c'], $u['j'], $u['query_text'], $u['url']);
        }
    }
    if (!empty($deletes)) {
        echo "\n=== First 10 DELETEs ===\n";
        $delSample = array_slice($deletes, 0, 10);
        $sample = $conn->fetchAll("SELECT query_id, query_text FROM catalogsearch_query WHERE query_id IN (" . implode(',', $delSample) . ")");
        foreach ($sample as $s) {
            printf("  [%d]  '%s'\n", $s['query_id'], $s['query_text']);
        }
    }

    if ($dryRun) {
        return ['updated' => count($updates), 'deleted' => count($deletes), 'skipped' => false];
    }

    if (empty($updates) && empty($deletes)) {
        echo "\nNothing to do for $code.\n";
        return ['updated' => 0, 'deleted' => 0, 'skipped' => true];
    }

    echo "\napplying UPDATE + DELETE inside one transaction for $code...\n";
    $conn->beginTransaction();
    try {
        $u = 0;
        foreach ($updates as $row) {
            $conn->update(
                'catalogsearch_query',
                [
                    'redirect'     => $row['url'],
                    'num_results'  => 1,
                    'is_processed' => 1,
                ],
                ['query_id = ?' => $row['query_id']]
            );
            $u++;
            if ($u % 500 === 0) echo "  ... updated $u / " . count($updates) . "\n";
        }
        $d = 0;
        foreach (array_chunk($deletes, 500) as $batch) {
            $ids = implode(',', array_map('intval', $batch));
            $conn->query("DELETE FROM catalogsearch_query WHERE query_id IN ($ids)");
            $d += count($batch);
            if ($d % 2000 === 0 || $d === count($deletes)) {
                echo "  ... deleted $d / " . count($deletes) . "\n";
            }
        }
        $conn->query(
            "INSERT INTO core_config_data (scope, scope_id, path, value)
                  VALUES ('default', 0, ?, NOW())
             ON DUPLICATE KEY UPDATE value = VALUES(value)",
            [$doneFlag]
        );
        $conn->commit();
    } catch (Exception $e) {
        $conn->rollBack();
        throw $e;
    }

    echo "  done.  updated=" . number_format(count($updates))
       . "  deleted=" . number_format(count($deletes)) . "\n";

    return ['updated' => count($updates), 'deleted' => count($deletes), 'skipped' => false];
}

// ============================================================
// Dispatch: one store or all stores
// ============================================================
$targets = $allStores ? COUNTRY_STORE_CODES : [$storeCode];

$totals = ['updated' => 0, 'deleted' => 0, 'errored' => 0, 'skipped' => 0];
foreach ($targets as $code) {
    try {
        $r = processStore(
            $code, $dryRun, $confirm, $verifyHttp,
            $stopwords, $tokenize,
            $nameAttr, $statusAttr, $visibAttr,
            $THRESHOLD_C, $THRESHOLD_J,
            $conn
        );
        $totals['updated'] += $r['updated'];
        $totals['deleted'] += $r['deleted'];
        if (!empty($r['skipped'])) $totals['skipped']++;
    } catch (Exception $e) {
        fwrite(STDERR, "ERROR processing store $code: " . $e->getMessage() . "\n");
        $totals['errored']++;
        // Continue to the next store rather than abort the whole run.
    }
}

if (count($targets) > 1) {
    echo "\n========================================================\n";
    echo "Grand total across " . count($targets) . " stores:\n";
    echo "  updated:  " . number_format($totals['updated']) . "\n";
    echo "  deleted:  " . number_format($totals['deleted']) . "\n";
    echo "  skipped:  " . $totals['skipped'] . " stores (no rows / no products)\n";
    if ($totals['errored']) {
        echo "  ERRORED:  " . $totals['errored'] . " stores — see above\n";
    }
    echo "========================================================\n";
}

if ($dryRun) {
    echo "\n[DRY RUN] no rows touched. Re-run with --confirm to apply.\n";
}
