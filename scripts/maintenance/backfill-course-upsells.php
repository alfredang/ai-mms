<?php
/**
 * One-shot backfill: guarantee every SG course (WSQ "TGS-" + non-WSQ "C") has
 * at least MIN_UPSELL (5) *valid* Upsell links — the storefront "Recommended
 * Courses" rail. Courses that fall short are topped up to exactly 5 with
 * RELATED WSQ courses, ranked by:
 *   1. number of shared (direct) categories   — most on-topic first
 *   2. review count (popularity)
 *   3. entity_id                               — deterministic tie-break
 * If the course's own categories can't supply enough WSQ, the candidate set is
 * broadened to their parent (ancestor) categories before giving up.
 *
 * "Valid" = the linked product is enabled + catalog/search-visible, because the
 * frontend upsell block only renders those; links to disabled/deleted products
 * don't count toward the 5.
 *
 * Only WSQ (TGS-) courses are ever ADDED (per requirement). Existing upsells are
 * never removed or reordered — new links are appended after them (position).
 * Idempotent: candidates already linked are skipped; the unique key
 * (link_type_id, product_id, linked_product_id) + INSERT IGNORE make re-runs
 * safe. Re-running only fills whatever is still short.
 *
 * Store-scoped by SKU prefix, so on a partner DB (MY/GH, no TGS- courses) the
 * WSQ candidate pool is empty and the script is a pure no-op — but this is a
 * one-shot maintenance script, NOT a repo migration, and is meant to be run on
 * the SG server only.
 *
 * Usage (inside the web container on the SG server):
 *   php scripts/maintenance/backfill-course-upsells.php
 *       -> DRY RUN (default): reports scope + exactly what it *would* add. No writes.
 *   php scripts/maintenance/backfill-course-upsells.php --commit
 *       -> writes the upsell links, then flushes block_html + FPC caches.
 *   php scripts/maintenance/backfill-course-upsells.php --commit --no-flush
 *       -> writes but skips cache flush (flush manually later).
 */

require_once dirname(__FILE__) . '/../../app/Mage.php';
Mage::app();

$MIN_UPSELL       = 5;
$UPSELL_TYPE_ID   = 4;   // catalog_product_link_type.code = up_sell
$POSITION_ATTR_ID = 4;   // catalog_product_link_attribute (link_type 4, code 'position')
$STORE_ROOT_CAT   = (int) Mage::app()->getStore(1)->getRootCategoryId(); // 2 on SG
$ROOT_CAT         = 1;

$commit  = in_array('--commit', $argv, true);
$noFlush = in_array('--no-flush', $argv, true);

$res   = Mage::getSingleton('core/resource');
$read  = $res->getConnection('core_read');
$write = $res->getConnection('core_write');

$tProd   = $res->getTableName('catalog/product');            // catalog_product_entity
$tInt    = $res->getTableName('catalog/product') . '_int';   // *_int (status/visibility)
$tCatPrd = $res->getTableName('catalog/category_product');   // catalog_category_product
$tCatEnt = $res->getTableName('catalog/category');           // catalog_category_entity
$tLink   = $res->getTableName('catalog/product_link');       // catalog_product_link
$tLinkI  = $res->getTableName('catalog/product_link') . '_attribute_int';
$tReview = $res->getTableName('review_entity_summary');      // review_entity_summary

// status/visibility attribute ids (product EAV)
$eav       = Mage::getModel('eav/entity_attribute');
$statusId  = (int) $eav->getIdByCode('catalog_product', 'status');
$visId     = (int) $eav->getIdByCode('catalog_product', 'visibility');

echo "== backfill-course-upsells ==\n";
echo "mode: " . ($commit ? "COMMIT" : "DRY RUN (default)") . "\n";
echo "min upsell: {$MIN_UPSELL}   store root cat: {$STORE_ROOT_CAT}\n\n";

/* ---------------------------------------------------------------------------
 * 1. Load all enabled + visible products (status=1, visibility in catalog/search).
 *    $visible[id] = sku ; $isWsq[id] = bool ; $sgCourse[id] = true (TGS-/C-)
 * ------------------------------------------------------------------------- */
$sql = "SELECT e.entity_id, e.sku
        FROM {$tProd} e
        JOIN {$tInt} st ON st.entity_id=e.entity_id AND st.attribute_id={$statusId} AND st.store_id=0 AND st.value=1
        JOIN {$tInt} vs ON vs.entity_id=e.entity_id AND vs.attribute_id={$visId}    AND vs.store_id=0 AND vs.value IN (3,4)";
$visible = array();   // id => sku
$isWsq   = array();   // id => true
$sgCourse = array();  // id => true
foreach ($read->fetchAll($sql) as $r) {
    $id  = (int) $r['entity_id'];
    $sku = $r['sku'];
    $visible[$id] = $sku;
    if (strpos($sku, 'TGS-') === 0) { $isWsq[$id] = true; }
    if (strpos($sku, 'TGS-') === 0 || strpos($sku, 'C') === 0) { $sgCourse[$id] = true; }
}
echo "visible products: " . count($visible)
   . " | WSQ(TGS-): " . count($isWsq)
   . " | SG courses(TGS-/C): " . count($sgCourse) . "\n";

/* ---------------------------------------------------------------------------
 * 2. Review counts (popularity) for store 1 products.  $reviews[id] = count
 * ------------------------------------------------------------------------- */
$reviews = array();
$sql = "SELECT entity_pk_value, reviews_count FROM {$tReview} WHERE store_id=1 AND entity_type=1";
foreach ($read->fetchAll($sql) as $r) {
    $reviews[(int) $r['entity_pk_value']] = (int) $r['reviews_count'];
}

/* ---------------------------------------------------------------------------
 * 3. Category maps (only for visible products):
 *      $prodCats[pid]   = [catId,...]   direct category assignments
 *      $catWsq[catId]   = [wsqPid,...]  visible WSQ products in that category
 * ------------------------------------------------------------------------- */
$prodCats = array();
$catWsq   = array();
$sql = "SELECT category_id, product_id FROM {$tCatPrd}";
foreach ($read->fetchAll($sql) as $r) {
    $cid = (int) $r['category_id'];
    $pid = (int) $r['product_id'];
    if (!isset($visible[$pid])) { continue; }
    $prodCats[$pid][] = $cid;
    if (isset($isWsq[$pid])) { $catWsq[$cid][] = $pid; }
}

/* ---------------------------------------------------------------------------
 * 4. Category ancestors (for broadening). $catAnc[catId] = [ancestorCatId,...]
 *    excludes the root (1) and the store root (2) — only real nav categories.
 * ------------------------------------------------------------------------- */
$catAnc = array();
$sql = "SELECT entity_id, path FROM {$tCatEnt}";
foreach ($read->fetchAll($sql) as $r) {
    $cid  = (int) $r['entity_id'];
    $anc  = array();
    foreach (explode('/', $r['path']) as $p) {
        $p = (int) $p;
        if ($p === $cid || $p === $ROOT_CAT || $p === $STORE_ROOT_CAT) { continue; }
        $anc[] = $p;
    }
    $catAnc[$cid] = $anc;
}

/* ---------------------------------------------------------------------------
 * 5. Existing upsell links.  $ups[pid] = [linkedId => true]
 * ------------------------------------------------------------------------- */
$ups = array();
$sql = "SELECT product_id, linked_product_id FROM {$tLink} WHERE link_type_id={$UPSELL_TYPE_ID}";
foreach ($read->fetchAll($sql) as $r) {
    $ups[(int) $r['product_id']][(int) $r['linked_product_id']] = true;
}

/* ---------------------------------------------------------------------------
 * 6. Walk SG courses; compute shortfall; pick related WSQ; collect inserts.
 * ------------------------------------------------------------------------- */
$plan        = array();   // [pid, linkedId, position]
$stillShort  = array();   // pid => [have, want, got]
$deficient   = 0;
$addedTotal  = 0;

foreach (array_keys($sgCourse) as $pid) {
    $existing = isset($ups[$pid]) ? $ups[$pid] : array();
    // valid = existing link whose target is currently visible
    $validCount = 0;
    foreach ($existing as $lid => $_) {
        if (isset($visible[$lid])) { $validCount++; }
    }
    $need = $MIN_UPSELL - $validCount;
    if ($need <= 0) { continue; }
    $deficient++;

    $directCats = isset($prodCats[$pid]) ? array_unique($prodCats[$pid]) : array();

    // --- candidate scoring over a given category set -> [candId => sharedCount]
    $score = function (array $catSet) use ($pid, $existing, $catWsq) {
        $out = array();
        foreach ($catSet as $cid) {
            if (empty($catWsq[$cid])) { continue; }
            foreach ($catWsq[$cid] as $cand) {
                if ($cand === $pid) { continue; }
                if (isset($existing[$cand])) { continue; }
                $out[$cand] = isset($out[$cand]) ? $out[$cand] + 1 : 1;
            }
        }
        return $out;
    };

    // Tier 1: shared DIRECT categories.
    $directShared = $score($directCats);

    // Broaden only if the direct pool can't satisfy the shortfall.
    if (count($directShared) < $need) {
        $expanded = $directCats;
        foreach ($directCats as $cid) {
            if (!empty($catAnc[$cid])) {
                foreach ($catAnc[$cid] as $a) { $expanded[] = $a; }
            }
        }
        $expanded  = array_unique($expanded);
        $poolScore = $score($expanded);           // includes the direct hits
    } else {
        $poolScore = $directShared;
    }

    if (empty($poolScore)) {
        $stillShort[$pid] = array($validCount, $MIN_UPSELL, 0);
        continue;
    }

    // Rank: direct-shared desc, broad-shared desc, reviews desc, id asc.
    $cands = array_keys($poolScore);
    usort($cands, function ($a, $b) use ($directShared, $poolScore, $reviews) {
        $da = isset($directShared[$a]) ? $directShared[$a] : 0;
        $db = isset($directShared[$b]) ? $directShared[$b] : 0;
        if ($da !== $db) { return $db - $da; }
        if ($poolScore[$a] !== $poolScore[$b]) { return $poolScore[$b] - $poolScore[$a]; }
        $ra = isset($reviews[$a]) ? $reviews[$a] : 0;
        $rb = isset($reviews[$b]) ? $reviews[$b] : 0;
        if ($ra !== $rb) { return $rb - $ra; }
        return $a - $b;
    });

    $pick = array_slice($cands, 0, $need);
    if (count($pick) < $need) {
        $stillShort[$pid] = array($validCount, $MIN_UPSELL, $validCount + count($pick));
    }

    // position: append after existing links (existing positions are ~0, so any
    // positive value sorts them after the originals).
    $basePos = count($existing);
    $i = 0;
    foreach ($pick as $cand) {
        $plan[] = array($pid, $cand, $basePos + 1 + $i);
        $i++;
        $addedTotal++;
    }
}

echo "SG courses short of {$MIN_UPSELL}: {$deficient}\n";
echo "upsell links to add: {$addedTotal}\n";
echo "courses still < {$MIN_UPSELL} after fill (thin categories): " . count($stillShort) . "\n\n";

// Show a few examples of what will be added (by SKU).
$shown = 0;
foreach ($plan as $row) {
    if ($shown >= 15) { echo "  ... (" . (count($plan) - 15) . " more)\n"; break; }
    list($pid, $cand, $pos) = $row;
    echo "  {$visible[$pid]}  +->  {$visible[$cand]}  (pos {$pos})\n";
    $shown++;
}
if ($stillShort) {
    echo "\nStill short (SKU: have -> got / want):\n";
    foreach ($stillShort as $pid => $s) {
        echo "  {$visible[$pid]}: {$s[0]} -> {$s[2]} / {$s[1]}\n";
    }
}

if (!$commit) {
    echo "\nDRY RUN — no rows written. Re-run with --commit to apply.\n";
    exit(0);
}

/* ---------------------------------------------------------------------------
 * 7. Write links (+ position) inside a transaction. INSERT IGNORE = idempotent.
 * ------------------------------------------------------------------------- */
echo "\nWriting " . count($plan) . " upsell links...\n";
$write->beginTransaction();
try {
    $written = 0;
    foreach ($plan as $row) {
        list($pid, $cand, $pos) = $row;
        $write->query(
            "INSERT IGNORE INTO {$tLink} (product_id, linked_product_id, link_type_id) VALUES (?,?,?)",
            array($pid, $cand, $UPSELL_TYPE_ID)
        );
        $linkId = (int) $write->lastInsertId();
        if ($linkId > 0) {
            $write->query(
                "INSERT IGNORE INTO {$tLinkI} (product_link_attribute_id, link_id, value) VALUES (?,?,?)",
                array($POSITION_ATTR_ID, $linkId, $pos)
            );
            $written++;
        }
    }
    $write->commit();
    echo "inserted {$written} new links (rest already existed).\n";
} catch (Exception $e) {
    $write->rollBack();
    echo "ERROR — rolled back: " . $e->getMessage() . "\n";
    exit(1);
}

if (!$noFlush) {
    echo "flushing block_html + full_page_cache...\n";
    Mage::app()->getCacheInstance()->cleanType('block_html');
    Mage::app()->getCacheInstance()->cleanType('full_page_cache');
    // If Redis-backed, also flush the instance to be safe.
    try { Mage::app()->getCacheInstance()->flush(); } catch (Exception $e) {}
}
echo "done.\n";
