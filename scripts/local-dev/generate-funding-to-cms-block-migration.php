<?php
/**
 * Generate the migration that moves the WSQ "Funding and Grant" section out of
 * every WSQ course's short_description and into the per-course
 * `course_<sku>_funding_and_grant` cms/block, so the storefront WSQ Funding
 * card is driven solely by the block.
 *
 * view.phtml section (1) already reads block-first with a regex fallback:
 * `$_courseSectionHtml('funding_and_grant')` at ~line 124 wins, and only when
 * it is empty does the legacy regex extract from short_description. The whole
 * post-processor that BUILDS the card (drop the fee table, drop the
 * Baseline/MCES/"Upon registration"/"You can pay the nett fee" boilerplate,
 * standardise PSEA, inject UTAP/PSEA fallbacks by badge, wrap each scheme in a
 * .wsq-sub mini-card) runs on whichever source won — it is pipeline-stage and
 * source-independent. So seeding the block with the exact bytes the regex
 * currently yields leaves the rendered card unchanged, and the auto-computed
 * fee tiles keep coming from the product price, never from the block.
 *
 * Verified by replaying the FULL post-processor over all 299 TGS- rows,
 * extracted-from-description vs block-round-tripped-through-hex:
 * 285/285 identical, 0 anomalies. No template change accompanies this.
 *
 * Two legacy shapes exist in the data, and this generator honours view.phtml's
 * OWN precedence (if div / elseif heading) so the same bytes are captured:
 *
 *   - div  (276 courses): <div style="...border-radius: 25px;">…</div> wrapper.
 *                         view.phtml concatenates EVERY such wrapper body
 *                         (preg_match_all + implode), so this does too.
 *   - head (9 courses):   <h2>WSQ Funding</h2> or the Quill-authored
 *                         <h2>Funding and Grant Applications</h2>, body running
 *                         to the next <h1>/<h2>.
 *   - none (14 courses):  no funding section at all -> SKIPPED entirely. They
 *                         keep today's behaviour and no block is seeded; all 14
 *                         already carry a hand-authored block from an earlier
 *                         migration, which this must not overwrite.
 *
 * Safety rules carried over from the 885/887/889 moves:
 *   - block exists & non-empty -> leave the block ALONE (never overwrite
 *     authored content); the 13 such courses are disjoint from the strip set.
 *   - empty extracted body     -> skip entirely, so view.phtml's regex fallback
 *     always keeps something to render
 *     (memory feedback_per_course_cms_block_sections).
 *
 * The strip reuses each shape's OWN pattern — the same one view.phtml uses to
 * remove the section from the About card (line ~155) — so the description is
 * left exactly as the storefront already renders it today. Both shapes were
 * checked to leave zero residual scheme copy (PSEA/UTAP/SFEC/SkillsFuture) in
 * the stripped description across all 285 rows.
 *
 * Every emitted literal is UTF-8 hex-encoded (0x...) so apply.php's
 * `charset=utf8` PDO connection cannot trip error 1366 on legacy bytes
 * (memory feedback_migration_applyphp_utf8_outage).
 *
 * NOTE (feedback_content_generator_not_idempotent_after_apply): this generator
 * READS the data it migrates, so re-running it AFTER the migration has been
 * applied emits an (almost) empty file. Restore from git rather than
 * regenerating if you need to inspect it later.
 *
 * Run:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/generate-funding-to-cms-block-migration.php
 */

declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$outFile = dirname(__DIR__, 2) . '/migrations/890-funding-to-cms-block.sql';

$db = Mage::getSingleton('core/resource')->getConnection('core_read');

$aidSd = (int) $db->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description'");

// Same whitespace class + patterns as view.phtml section (1), verbatim.
$WS     = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';
$pDiv   = '#<div\b[^>]*border-radius\s*:[^>]*>(.*?)</div>#siu';
$pHead  = '#<h[1-6][^>]*>' . $WS . '*(?:WSQ' . $WS . '+Funding|Funding' . $WS . '+and' . $WS . '+Grant' . $WS . '+Applications?)' . $WS . '*</h[1-6]>(.*?)(?=<h[12]\b|\z)#siu';

// WSQ courses only — the TGS- SKU prefix IS the WSQ marker
// (memory reference_wsq_course_tgs_sku). Partner sites carry no TGS- SKUs, so
// this is SG-only by construction and needs no store guard.
$rows = $db->fetchAll(
    "SELECT e.entity_id, e.sku, t.value AS sd
       FROM catalog_product_entity e
       JOIN catalog_product_entity_text t
         ON t.entity_id = e.entity_id AND t.attribute_id = ? AND t.store_id = 0
      WHERE e.sku LIKE 'TGS-%'
      ORDER BY e.sku",
    [$aidSd]
);

/** Emit a MySQL-safe literal: hex-encode so no charset/escaping path can corrupt it. */
$lit = static function (string $s): string {
    return $s === '' ? "''" : '0x' . bin2hex($s);
};

$stats = [
    'seen'            => 0,
    'shape_div'       => 0,
    'shape_head'      => 0,
    'no_section'      => 0,
    'stripped'        => 0,
    'block_seeded'    => 0,
    'block_existing'  => 0,
    'skipped_empty'   => 0,
];
$sql = [];

foreach ($rows as $r) {
    $eid = (int) $r['entity_id'];
    $sku = (string) $r['sku'];
    $sd  = (string) $r['sd'];
    $stats['seen']++;

    // Mirror view.phtml's precedence exactly: the rounded-div wrapper wins over
    // the heading variant, and every wrapper body is concatenated.
    if (preg_match_all($pDiv, $sd, $m)) {
        $extracted = trim(implode('', $m[1]));
        $strip     = $pDiv;
        $stats['shape_div']++;
    } elseif (preg_match($pHead, $sd, $m)) {
        $extracted = trim($m[1]);
        $strip     = $pHead;
        $stats['shape_head']++;
    } else {
        // No funding section in the description — leave the course untouched.
        $stats['no_section']++;
        continue;
    }

    // Never strip a section whose content would be lost.
    if ($extracted === '') {
        $stats['skipped_empty']++;
        continue;
    }

    $identifier = 'course_' . $sku . '_funding_and_grant';
    $existing   = trim((string) $db->fetchOne('SELECT content FROM cms_block WHERE identifier = ?', [$identifier]));

    $seed = '';
    if ($existing === '') {
        $seed = $extracted;
        $stats['block_seeded']++;
    } else {
        // Authored block already present — keep it, just strip the description.
        $stats['block_existing']++;
    }

    $newSd = rtrim((string) preg_replace($strip, '', $sd));
    $stats['stripped']++;

    $stmt = "-- {$sku}\n";
    if ($seed !== '') {
        $title = 'Course ' . $sku . ' — Funding and Grant';
        $stmt .= sprintf(
            "INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)\n"
            . "  SELECT %s, %s, %s, NOW(), NOW(), 1 FROM DUAL\n"
            . "  WHERE NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = %s);\n"
            . "INSERT IGNORE INTO cms_block_store (block_id, store_id)\n"
            . "  SELECT block_id, 0 FROM cms_block WHERE identifier = %s;\n",
            $lit($title), $lit($identifier), $lit($seed), $lit($identifier),
            $lit($identifier)
        );
    }
    $stmt .= sprintf(
        "UPDATE catalog_product_entity_text SET value = %s WHERE attribute_id = @a_sdesc AND store_id = 0 AND entity_id = %d;",
        $lit($newSd), $eid
    );

    $sql[] = $stmt;
}

$header = "-- 890: Move the WSQ \"Funding and Grant\" section out of short_description and\n"
    . "-- into the per-course `course_<sku>_funding_and_grant` cms/block, so the\n"
    . "-- storefront WSQ Funding card is driven solely by the block. Generated by\n"
    . "-- scripts/local-dev/generate-funding-to-cms-block-migration.php\n"
    . "--\n"
    . "-- view.phtml section (1) already reads block-first with a regex fallback, and\n"
    . "-- the post-processor that BUILDS the card (drop fee table + boilerplate,\n"
    . "-- standardise PSEA, inject UTAP/PSEA by badge, wrap schemes in .wsq-sub) runs\n"
    . "-- on whichever source wins — it is source-independent. The auto-computed fee\n"
    . "-- tiles come from the product price, never from the block. So the card is\n"
    . "-- unchanged. Verified by replaying the FULL post-processor over all 299 TGS-\n"
    . "-- rows, extracted vs block-round-tripped: 285/285 identical, 0 anomalies.\n"
    . "-- No template change accompanies this.\n"
    . "--\n"
    . "-- Two legacy shapes, captured with view.phtml's OWN precedence (div, else\n"
    . "-- heading) so the identical bytes move across:\n"
    . "--   div  — <div style=\"...border-radius: 25px;\"> wrapper (every wrapper body\n"
    . "--          concatenated, as view.phtml's preg_match_all + implode does)\n"
    . "--   head — <h2>WSQ Funding</h2> / <h2>Funding and Grant Applications</h2>\n"
    . "-- Courses with no funding section are skipped and left untouched.\n"
    . "--\n"
    . "-- A course whose block is already non-empty keeps its authored content; only\n"
    . "-- its description is stripped (memory feedback_per_course_cms_block_sections).\n"
    . "--\n"
    . "-- The strip reuses each shape's own pattern — the same one view.phtml uses to\n"
    . "-- remove the section from the About card — so the description matches what the\n"
    . "-- storefront already renders. Both shapes leave zero residual scheme copy.\n"
    . "--\n"
    . "-- Every literal is hex-encoded so apply.php's utf8 PDO connection cannot hit\n"
    . "-- error 1366 on legacy bytes (feedback_migration_applyphp_utf8_outage).\n"
    . "-- Idempotent: the block INSERT is NOT EXISTS-guarded and the UPDATE rewrites\n"
    . "-- the same already-stripped description.\n"
    . "-- WSQ/SG-only by construction (TGS- prefix); partner sites carry no TGS- SKUs.\n"
    . "--\n"
    . sprintf(
        "-- courses stripped: %d  (blocks seeded: %d, existing blocks kept: %d)\n"
        . "-- shapes: div %d, heading %d  |  no funding section, untouched: %d\n\n",
        $stats['stripped'], $stats['block_seeded'], $stats['block_existing'],
        $stats['shape_div'], $stats['shape_head'], $stats['no_section']
    )
    . "SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');\n\n";

file_put_contents($outFile, $header . implode("\n\n", $sql) . "\n");

echo "wrote: $outFile\n";
echo '  bytes: ' . number_format(filesize($outFile)) . "\n";
foreach ($stats as $k => $v) {
    printf("  %-16s %d\n", $k, $v);
}
