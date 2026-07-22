<?php
/**
 * PARTNER-SITE variant of backfill-course-upsells.php (MY / GH).
 *
 * Guarantee every enabled + visible course on a partner DB has at least
 * MIN_UPSELL (5) *valid* Upsell links — the storefront "Recommended Courses"
 * rail. Partner catalogs have NO WSQ (TGS-) courses, so unlike the SG script
 * the fill source is the partner's OWN catalog: any enabled + visible course,
 * ranked by:
 *   1. number of shared (direct) categories   — most on-topic first
 *   2. review count (popularity, max across stores)
 *   3. entity_id                               — deterministic tie-break
 * If the course's own categories can't supply enough, the candidate set is
 * broadened to their parent (ancestor) categories before giving up.
 *
 * "Valid" = the linked product is enabled + catalog/search-visible, because the
 * frontend upsell block only renders those; links to disabled/deleted products
 * don't count toward the 5.
 *
 * Existing upsells are never removed or reordered — new links are appended
 * after them (position). Idempotent: candidates already linked are skipped;
 * the unique key (link_type_id, product_id, linked_product_id) + INSERT IGNORE
 * make re-runs safe.
 *
 * Run this on a PARTNER server only (MY / GH). It is a one-shot maintenance
 * script, NOT a repo migration.
 *
 * Usage (inside the partner web container):
 *   php scripts/maintenance/backfill-course-upsells-partner.php            # DRY RUN
 *   php scripts/maintenance/backfill-course-upsells-partner.php --commit   # write + flush caches
 *   php scripts/maintenance/backfill-course-upsells-partner.php --commit --no-flush
 */

require_once dirname(__FILE__) . '/../../app/Mage.php';
Mage::app();

$MIN_UPSELL       = 5;
$UPSELL_TYPE_ID   = 4;   // catalog_product_link_type.code = up_sell
$POSITION_ATTR_ID = 4;   // catalog_product_link_attribute (link_type 4, code 'position')
$STORE_ROOT_CAT   = (int) Mage::app()->getDefaultStoreView()->getRootCategoryId();
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

echo "== backfill-course-upsells (PARTNER) ==\n";
echo "mode: " . ($commit ? "COMMIT" : "DRY RUN (default)") . "\n";
echo "min upsell: {$MIN_UPSELL}   store root cat: {$STORE_ROOT_CAT}\n\n";

/* ---------------------------------------------------------------------------
 * 1. Load all enabled + visible products (status=1, visibility in catalog/search).
 *    On a partner site every product is a course, and all of them are both the
 *    target set AND the fill pool.
 * ------------------------------------------------------------------------- */
$sql = "SELECT e.entity_id, e.sku
        FROM {$tProd} e
        JOIN {$tInt} st ON st.entity_id=e.entity_id AND st.attribute_id={$statusId} AND st.store_id=0 AND st.value=1
        JOIN {$tInt} vs ON vs.entity_id=e.entity_id AND vs.attribute_id={$visId}    AND vs.store_id=0 AND vs.value IN (3,4)";
$visible = array();   // id => sku
foreach ($read->fetchAll($sql) as $r) {
    $visible[(int) $r['entity_id']] = $r['sku'];
}
echo "visible courses: " . count($visible) . "\n";

/* ---------------------------------------------------------------------------
 * 2. Review counts (popularity), max across stores.  $reviews[id] = count
 * ------------------------------------------------------------------------- */
$reviews = array();
$sql = "SELECT entity_pk_value, MAX(reviews_count) AS rc FROM {$tReview} WHERE entity_type=1 GROUP BY entity_pk_value";
foreach ($read->fetchAll($sql) as $r) {
    $reviews[(int) $r['entity_pk_value']] = (int) $r['rc'];
}

/* ---------------------------------------------------------------------------
 * 3. Category maps (only for visible products):
 *      $prodCats[pid]  = [catId,...]   direct category assignments
 *      $catPool[catId] = [pid,...]     visible courses in that category
 * ------------------------------------------------------------------------- */
$prodCats = array();
$catPool  = array();
$sql = "SELECT category_id, product_id FROM {$tCatPrd}";
foreach ($read->fetchAll($sql) as $r) {
    $cid = (int) $r['category_id'];
    $pid = (int) $r['product_id'];
    if (!isset($visible[$pid])) { continue; }
    $prodCats[$pid][] = $cid;
    $catPool[$cid][]  = $pid;
}

/* ---------------------------------------------------------------------------
 * 4. Category ancestors (for broadening). Excludes root + store root.
 * ------------------------------------------------------------------------- */
$catAnc = array();
$sql = "SELECT entity_id, path FROM {$tCatEnt}";
foreach ($read->fetchAll($sql) as $r) {
    $cid = (int) $r['entity_id'];
    $anc = array();
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
 * 6. Walk courses; compute shortfall; pick related courses; collect inserts.
 * ------------------------------------------------------------------------- */
$plan       = array();   // [pid, linkedId, position]
$stillShort = array();   // pid => [have, want, got]
$deficient  = 0;
$addedTotal = 0;

foreach (array_keys($visible) as $pid) {
    $existing = isset($ups[$pid]) ? $ups[$pid] : array();
    $validCount = 0;
    foreach ($existing as $lid => $_) {
        if (isset($visible[$lid])) { $validCount++; }
    }
    $need = $MIN_UPSELL - $validCount;
    if ($need <= 0) { continue; }
    $deficient++;

    $directCats = isset($prodCats[$pid]) ? array_unique($prodCats[$pid]) : array();

    // --- candidate scoring over a given category set -> [candId => sharedCount]
    $score = function (array $catSet) use ($pid, $existing, $catPool) {
        $out = array();
        foreach ($catSet as $cid) {
            if (empty($catPool[$cid])) { continue; }
            foreach ($catPool[$cid] as $cand) {
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

    // position: append after existing links.
    $basePos = count($existing);
    $i = 0;
    foreach ($pick as $cand) {
        $plan[] = array($pid, $cand, $basePos + 1 + $i);
        $i++;
        $addedTotal++;
    }
}

echo "courses short of {$MIN_UPSELL}: {$deficient}\n";
echo "upsell links to add: {$addedTotal}\n";
echo "courses still < {$MIN_UPSELL} after fill (thin categories): " . count($stillShort) . "\n\n";

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
    try { Mage::app()->getCacheInstance()->flush(); } catch (Exception $e) {}
}
echo "done.\n";
