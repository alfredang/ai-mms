<?php
/**
 * Generate the migration that removes the "Course Brochure" section from every
 * course's short_description, so the storefront brochure card is driven solely
 * by the per-course `course_<sku>_brochure` cms/block.
 *
 * Unlike the Certification move (885), brochure content is NOT regenerated:
 * the existing block already holds the canonical link, written by the
 * Generate Brochure action / batch-generate-brochures.php and kept fresh by
 * the filesystem-first override in view.phtml. The description copy is a stale
 * duplicate (many still point at Google Drive, and 12 courses literally say
 * "TBD" while their block has a real PDF). So:
 *
 *   - block exists & non-empty -> leave the block ALONE, strip the description
 *   - block missing / empty    -> seed the block from the description's own
 *                                 anchor first, THEN strip
 *   - no anchor and no block   -> skip entirely (never strip a section whose
 *                                 content would be lost; the regex fallback in
 *                                 view.phtml must keep something to render)
 *
 * That last rule is the safety net from memory
 * feedback_per_course_cms_block_sections: a section without a populated block
 * must keep its heading in short_description.
 *
 * The strip uses the SAME whitespace-tolerant regex as
 * view.phtml::$_extractSection — in particular its lookahead
 * `(?:<[a-z...]\b[^>]*>\s*)*<h[1-6]` stops BEFORE any wrapper tag that opens
 * just ahead of the next heading. 18 courses have the Funding section's
 * `<div style="...">` opener sitting between the brochure paragraph and the
 * Funding <h2>; a naive `.*?<h2` strip would swallow that opener and break the
 * funding card's markup. Raw SQL cannot express this — hence a generator that
 * emits deterministic, fully-escaped literals.
 *
 * Every emitted literal is UTF-8 hex-encoded (0x...) so apply.php's
 * `charset=utf8` PDO connection cannot trip error 1366 on legacy bytes.
 * See memory feedback_migration_applyphp_utf8_outage.
 *
 * NOTE (feedback_content_generator_not_idempotent_after_apply): this generator
 * READS the data it migrates, so re-running it AFTER the migration has been
 * applied emits an (almost) empty file. Restore from git rather than
 * regenerating if you need to inspect it later.
 *
 * Run:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/generate-brochure-to-cms-block-migration.php
 */

declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$outFile = dirname(__DIR__, 2) . '/migrations/887-brochure-to-cms-block.sql';

$db = Mage::getSingleton('core/resource')->getConnection('core_read');

$aidSd = (int) $db->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description'");

// Same whitespace class + section pattern as view.phtml's $_extractSection.
$WS      = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';
$pattern = '#<h[1-6][^>]*>' . $WS . '*(?:<br\s*/?>' . $WS . '*)*Course' . $WS . '+Brochure' . $WS . '*:?' . $WS . '*</h[1-6]>(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)#siu';

$rows = $db->fetchAll(
    "SELECT e.entity_id, e.sku, t.value AS sd
       FROM catalog_product_entity e
       JOIN catalog_product_entity_text t
         ON t.entity_id = e.entity_id AND t.attribute_id = ? AND t.store_id = 0
      WHERE t.value REGEXP '<h[1-6][^>]*>[[:space:]]*Course[[:space:]]+Brochure'
      ORDER BY e.sku",
    [$aidSd]
);

/** Emit a MySQL-safe literal: hex-encode so no charset/escaping path can corrupt it. */
$lit = static function (string $s): string {
    return $s === '' ? "''" : '0x' . bin2hex($s);
};

$stats = ['seen' => 0, 'stripped' => 0, 'block_seeded' => 0, 'skipped_no_source' => 0, 'no_match' => 0];
$sql   = [];

foreach ($rows as $r) {
    $eid = (int) $r['entity_id'];
    $sku = (string) $r['sku'];
    $sd  = (string) $r['sd'];
    $stats['seen']++;

    if (!preg_match($pattern, $sd, $m)) {
        $stats['no_match']++;
        continue;
    }
    $extracted = trim($m[1]);

    $identifier = 'course_' . $sku . '_brochure';
    $existing   = trim((string) $db->fetchOne('SELECT content FROM cms_block WHERE identifier = ?', [$identifier]));

    // Seed a block only when there is none AND the description actually holds a
    // link. A "TBD" paragraph is not worth preserving — but with no block to
    // fall back on we must leave the section in place rather than lose it.
    $seed = '';
    if ($existing === '') {
        if (!preg_match('#<a\s[^>]*href=#siu', $extracted)) {
            $stats['skipped_no_source']++;
            continue;
        }
        // Keep the anchor only — drop the legacy <span style="underline"> and
        // <u> wrappers so the seeded block matches the shape the Generate
        // Brochure action writes (a bare <a>), which the card parses.
        preg_match('#<a\s[^>]*>.*?</a>#siu', $extracted, $am);
        $seed = trim($am[0]);
        $stats['block_seeded']++;
    }

    // Strip EVERY Course Brochure section (guards against a legacy duplicate).
    $newSd = rtrim((string) preg_replace($pattern, '', $sd));
    $stats['stripped']++;

    $stmt = "-- {$sku}\n";
    if ($seed !== '') {
        $title = 'Course ' . $sku . ' — Brochure';
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

$header = "-- 887: Remove the \"Course Brochure\" section from short_description so the\n"
    . "-- storefront brochure card is driven solely by the per-course\n"
    . "-- `course_<sku>_brochure` cms/block. Generated by\n"
    . "-- scripts/local-dev/generate-brochure-to-cms-block-migration.php\n"
    . "--\n"
    . "-- Block content is NOT rewritten: the existing block already holds the\n"
    . "-- canonical link (Generate Brochure / batch-generate-brochures.php), and\n"
    . "-- view.phtml rebuilds the URL filesystem-first anyway. The description copy\n"
    . "-- was a stale duplicate — many still pointed at Google Drive, and 12 courses\n"
    . "-- said \"TBD\" while their block held a real PDF.\n"
    . "--\n"
    . "-- A block is seeded from the description's own anchor ONLY where no block\n"
    . "-- exists yet. A course with neither a block nor an anchor is skipped and\n"
    . "-- KEEPS its heading, so view.phtml's regex fallback still has something to\n"
    . "-- render (memory feedback_per_course_cms_block_sections).\n"
    . "--\n"
    . "-- The strip mirrors view.phtml::\$_extractSection, whose lookahead stops\n"
    . "-- before a wrapper tag opening ahead of the next heading — 18 courses have\n"
    . "-- the Funding section's <div> opener trailing the brochure paragraph.\n"
    . "--\n"
    . "-- Every literal is hex-encoded so apply.php's utf8 PDO connection cannot\n"
    . "-- hit error 1366 on legacy bytes (feedback_migration_applyphp_utf8_outage).\n"
    . "-- Idempotent: re-running writes the same already-stripped description.\n"
    . "-- Partner-safe (SKU-driven, no store guard needed).\n"
    . "--\n"
    . sprintf(
        "-- courses stripped: %d  (blocks seeded: %d)  skipped, no block+no link: %d\n\n",
        $stats['stripped'], $stats['block_seeded'], $stats['skipped_no_source']
    )
    . "SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');\n\n";

file_put_contents($outFile, $header . implode("\n\n", $sql) . "\n");

echo "wrote: $outFile\n";
echo '  bytes: ' . number_format(filesize($outFile)) . "\n";
foreach ($stats as $k => $v) {
    printf("  %-18s %d\n", $k, $v);
}
