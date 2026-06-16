<?php
/**
 * For every SG-store catalogsearch_query row with NO redirect set,
 * find the SG-store product whose name + canonical request_path best
 * match the query_text. If a confident match exists, write the full
 * https://www.tertiarycourses.com.sg/<request_path> into `redirect`
 * and set num_results = 1. If nothing matches confidently, DELETE the
 * row.
 *
 * URL source: core_url_rewrite (is_system=1, category_id IS NULL —
 * the canonical flat URL the storefront router actually serves), NOT
 * catalog_product_entity_varchar.url_key (which can be a stale EAV
 * value pointing at a retired URL that 404s). The
 * MMD_SearchFallback_ResultController would clear any stale redirect
 * on the first customer hit anyway, but generating routable URLs in
 * the first place avoids the "search shows results page once, then
 * redirect goes empty" oddity.
 *
 * Two-phase, operator-driven (same shape as
 * prune-bad-url-redirects.php):
 *
 *   docker exec ai-mms-web-1 php scripts/maintenance/autopopulate-sg-search-redirects.php --dry-run
 *     → builds the SG product index, scores every empty query,
 *       prints UPDATE/DELETE counts and the first 20 of each.
 *       Writes nothing.
 *
 *   docker exec ai-mms-web-1 php scripts/maintenance/autopopulate-sg-search-redirects.php --confirm
 *     → applies UPDATE + DELETE inside one transaction. Stamps a
 *       core_config_data flag so a careless re-run is a no-op.
 *
 *   Optional flag (either phase):
 *     --verify-http
 *       For every unique candidate URL, HEAD it against the live SG
 *       site and accept only 200. Anything else demotes the row to
 *       DELETE. Useful if local catalog drift might point at retired
 *       products. Adds ~5–10 min on a fleet of ~1,500 unique URLs
 *       (parallelized via curl_multi).
 *
 * Matching:
 *   - Tokenize query_text and product (url_key + name) on
 *     non-alnum boundaries; drop stopwords; min length 2 so short
 *     real signals like "ai", "ml", "bi", "rpa", "iot" survive.
 *   - For each query, find the product with the highest token
 *     containment score = |Q ∩ P| / |Q|. A containment of 1.0 means
 *     every query token is present in the product.
 *   - Accept only candidates with containment ≥ 0.5 AND Jaccard
 *     |Q ∩ P| / |Q ∪ P| ≥ 0.3. Below either threshold = no match =
 *     row deleted. Tiebreak among equally-scored products by Jaccard
 *     (prefer the tighter product).
 *
 * Why containment + Jaccard (not just one): containment alone would
 * happily map "python" → a product with 12 tokens including "python".
 * Adding a Jaccard floor keeps us off ultra-broad pages that happen
 * to contain the query word.
 *
 * Hard "don't"s (per CLAUDE.md):
 *   - Only operate on rows where `redirect IS NULL OR redirect = ''`.
 *     Never overwrite an existing manual redirect.
 *   - Targets must be product pages (built from a live, SG-visible,
 *     enabled product) — never homepage / category bounce / external.
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app();

$args       = array_slice($argv, 1);
$dryRun     = in_array('--dry-run', $args, true);
$confirm    = in_array('--confirm', $args, true);
$verifyHttp = in_array('--verify-http', $args, true);

if (!$dryRun && !$confirm) {
    fwrite(STDERR, "Usage:\n");
    fwrite(STDERR, "  --dry-run    [--verify-http]   audit + report; write nothing\n");
    fwrite(STDERR, "  --confirm    [--verify-http]   apply UPDATE + DELETE inside one transaction\n");
    exit(1);
}
if ($dryRun && $confirm) {
    fwrite(STDERR, "Pass --dry-run OR --confirm, not both.\n");
    exit(1);
}

$STORE_ID    = 1; // Singapore
$BASE_URL    = 'https://www.tertiarycourses.com.sg/';
$THRESHOLD_C = 0.5;  // containment floor
$THRESHOLD_J = 0.3;  // Jaccard floor
$DONE_FLAG   = 'mmd/sg_search_redirect_autopop/done_2026_06';

// Same stopwords as the URL-rewrite audit so behavior stays
// consistent across the two scripts. Add a few search-specific
// noise tokens at the end.
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
        if (strlen($p) < 2)            continue; // keep ai/ml/bi/rpa/iot
        if (isset($stopwords[$p]))     continue;
        if (preg_match('/^\d+$/', $p)) continue;
        $out[$p] = true;
    }
    return array_keys($out);
};

$conn = Mage::getSingleton('core/resource')->getConnection('core_write');

if ($confirm) {
    $already = $conn->fetchOne(
        "SELECT value FROM core_config_data WHERE path = ?",
        [$DONE_FLAG]
    );
    if ($already) {
        echo "Already ran on $already — proceeding (idempotent: only empty rows are touched).\n";
    }
}

echo ($dryRun ? "[DRY RUN] " : "[CONFIRM] ")
   . "building SG product index...\n";

$nameAttr   = (int) $conn->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'    AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')");
$statusAttr = (int) $conn->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='status'  AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')");
$visibAttr  = (int) $conn->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='visibility' AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')");
if (!$nameAttr || !$statusAttr || !$visibAttr) {
    fwrite(STDERR, "ERROR: missing EAV attribute(s) (name/status/visibility)\n");
    exit(3);
}

// Source of truth = core_url_rewrite (the actual storefront router),
// NOT catalog_product_entity_varchar.url_key. A product can be enabled
// + search-visible AND still have NO rewrite row (retired URL, indexer
// never ran, etc.) — its url_key is then a stale EAV value that 404s
// on the storefront. The MMD_SearchFallback ResultController clears
// such stale redirects on the first customer hit; we avoid generating
// them in the first place by pinning targets to actual rewrite rows.
//
// Filters:
//   - cur.store_id = SG (canonical flat URL is per-store on this site)
//   - cur.is_system = 1   (Magento-generated, current — not a manual RP)
//   - cur.options NULL/'' (excludes Permanent Redirect rows that just
//                          bounce to another URL — we want the final
//                          destination, not a 301-chain)
//   - cur.category_id IS NULL (the FlatCategoryUrl canonical — no
//                              parent-category prefix)
$products = $conn->fetchAll("
    SELECT cpe.entity_id, cpe.sku,
           COALESCE(name_s.value, name_g.value) AS name,
           cur.request_path
      FROM catalog_product_entity cpe
      JOIN catalog_product_entity_int s
        ON s.entity_id = cpe.entity_id
       AND s.attribute_id = $statusAttr
       AND s.store_id IN (0, $STORE_ID)
       AND s.value = 1
      JOIN catalog_product_entity_int v
        ON v.entity_id = cpe.entity_id
       AND v.attribute_id = $visibAttr
       AND v.store_id IN (0, $STORE_ID)
       AND v.value IN (3, 4)
      JOIN core_url_rewrite cur
        ON cur.product_id = cpe.entity_id
       AND cur.store_id = $STORE_ID
       AND cur.is_system = 1
       AND cur.category_id IS NULL
       AND (cur.options IS NULL OR cur.options = '')
 LEFT JOIN catalog_product_entity_varchar name_s
        ON name_s.entity_id = cpe.entity_id
       AND name_s.attribute_id = $nameAttr
       AND name_s.store_id = $STORE_ID
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
        'url'       => $BASE_URL . $p['request_path'],
        'tokens'    => array_flip($toks), // dict for O(1) lookup
        'tok_count' => count($toks),
    ];
}
echo "  indexed " . number_format(count($index)) . " SG products\n";

echo "scoring empty search-term rows...\n";
$rows = $conn->fetchAll("
    SELECT query_id, query_text, num_results
      FROM catalogsearch_query
     WHERE store_id = $STORE_ID
       AND (redirect IS NULL OR redirect = '')
");
echo "  " . number_format(count($rows)) . " empty rows to consider\n";

$updates   = [];
$deletes   = [];
$emptyTok  = 0;
foreach ($rows as $r) {
    $qToks = $tokenize($r['query_text']);
    if (empty($qToks)) {
        // Query was pure noise (punctuation, stopwords only, 1-char garbage).
        // Nothing to match against — drop.
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
        // Containment first, Jaccard breaks ties.
        if ($cont > $bestC || ($cont === $bestC && $jacc > $bestJ)) {
            $bestC = $cont;
            $bestJ = $jacc;
            $best  = $p;
        }
    }

    // Single-token queries: skip the Jaccard floor. The query word is
    // unambiguous — if a single domain term like "tensorflow" / "vba" /
    // "bootstrap" appears in any product at all, that's a strong
    // signal. The default Jaccard floor (0.3) was rejecting these
    // because a 5-token product yields jacc = 1/5 = 0.2 even though
    // containment is 1.0. Tiebreak already prefers the tightest
    // product, so generic words still pick the most-focused match.
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

// Optional live-site HEAD check on each unique target. Parallelized
// via curl_multi so 1500 URLs finish in ~30s, not 25 min serially.
if ($verifyHttp && !empty($updates)) {
    $unique = array_values(array_unique(array_column($updates, 'url')));
    echo "verifying " . count($unique) . " unique URLs against live site...\n";
    $verified = [];
    $batches  = array_chunk($unique, 25);
    $i = 0;
    foreach ($batches as $batch) {
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

echo "\n=== Plan ===\n";
echo "  UPDATE: " . number_format(count($updates)) . " rows (redirect set, num_results=1)\n";
echo "  DELETE: " . number_format(count($deletes)) . " rows  (no confident match"
   . ($emptyTok > 0 ? "; of which $emptyTok had no usable tokens" : "")
   . ")\n";

if (!empty($updates)) {
    echo "\n=== First 20 UPDATEs ===\n";
    foreach (array_slice($updates, 0, 20) as $u) {
        printf("  [c=%.2f j=%.2f]  '%s'  ->  %s\n",
            $u['c'], $u['j'], $u['query_text'], $u['url']);
    }
}
if (!empty($deletes)) {
    echo "\n=== First 20 DELETEs (no match) ===\n";
    $delSample = array_slice($deletes, 0, 20);
    $sample = $conn->fetchAll("SELECT query_id, query_text FROM catalogsearch_query WHERE query_id IN (" . implode(',', $delSample) . ")");
    foreach ($sample as $s) {
        printf("  [%d]  '%s'\n", $s['query_id'], $s['query_text']);
    }
}

if ($dryRun) {
    echo "\n[DRY RUN] no rows touched. Re-run with --confirm to apply.\n";
    exit(0);
}

if (empty($updates) && empty($deletes)) {
    echo "\nNothing to do.\n";
    exit(0);
}

echo "\napplying UPDATE + DELETE inside one transaction...\n";
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
        [$DONE_FLAG]
    );
    $conn->commit();
} catch (Exception $e) {
    $conn->rollBack();
    fwrite(STDERR, "ERROR: " . $e->getMessage() . "\nRolled back. Table is untouched.\n");
    exit(4);
}

echo "\nDone.\n";
echo "  updated: " . number_format(count($updates)) . "\n";
echo "  deleted: " . number_format(count($deletes)) . "\n";
