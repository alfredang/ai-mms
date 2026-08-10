<?php
/**
 * Generate migration 915: card the Learning Outcomes + Brochure sections on the
 * 7 IBF courses, exactly like the WSQ courses.
 *
 * The IBF course descriptions were authored with non-standard markup that
 * view.phtml's $_extractSection cannot see:
 *   - heading `<h2>Brochure</h2>` (the extractor expects "Course Brochure"), so
 *     the section double-renders inline below the description while the
 *     brochure CARD (driven by the existing course_<sku>_brochure block +
 *     filesystem-first PDF override) renders too;
 *   - on TGS-2025052659 only, Learning Outcomes is a styled paragraph
 *     `<p><span style="font-size: 1.5em;">Learning Outcomes</span></p>` — not a
 *     heading at all — so it renders inline and no LO card appears (the other 6
 *     IBF courses already have course_<sku>_learning_outcomes blocks and no
 *     inline copy).
 *
 * Data-only fix (memory feedback_section_to_cms_block_move_is_data_only — the
 * template already reads block-first with regex fallback):
 *   1. seed course_TGS-2025052659_learning_outcomes from the inline body
 *      (intro <p> + <ul>, heading excluded — the card supplies its own title);
 *   2. strip the inline LO section (270) and the inline Brochure section (all
 *       7) from short_description via exact-byte REPLACE.
 *
 * REPLACE (not a full-value UPDATE) + a SKU join makes this safe on partner
 * DBs whose rows may have diverged: if the exact bytes aren't present the
 * statement no-ops (memories feedback_sku_migrations_hit_partners_irreversibly,
 * feedback_cms_block_hex_replace_generate_programmatically). Every literal is
 * hex-encoded so apply.php's utf8 PDO connection cannot hit error 1366
 * (feedback_migration_applyphp_utf8_outage).
 *
 * The strip pattern reuses view.phtml::$_extractSection's whitespace class and
 * wrapper-safe lookahead, so the chunk never swallows a wrapper tag opening
 * ahead of the next heading (feedback_section_strip_must_preserve_next_wrapper_div).
 *
 * NOTE (feedback_content_generator_not_idempotent_after_apply): this generator
 * READS the data it migrates — re-running it AFTER the migration has been
 * applied emits an empty file. Restore from git rather than regenerating.
 *
 * Run:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/generate-ibf-lo-brochure-migration.php
 */

declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$outFile = dirname(__DIR__, 2) . '/migrations/915-ibf-lo-brochure-to-cms-block.sql';

$db = Mage::getSingleton('core/resource')->getConnection('core_read');

$aidSd = (int) $db->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description'");

// Same whitespace class + wrapper-safe lookahead as view.phtml's $_extractSection.
$WS   = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';
$TAIL = '(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)';
// Plain "<h2>Brochure</h2>" heading (NOT "Course Brochure" — the tag anchor
// keeps this from matching the standard heading).
$brPattern = '#<h[1-6][^>]*>' . $WS . '*Brochure' . $WS . '*:?' . $WS . '*</h[1-6]>' . $TAIL . '#siu';
// The styled-paragraph pseudo-heading on TGS-2025052659.
$loPattern = '#<p><span[^>]*font-size[^>]*>' . $WS . '*Learning' . $WS . '+Outcomes' . $WS . '*</span></p>' . $TAIL . '#siu';

$skus = [
    'TGS-2022601648', 'TGS-2022601875', 'TGS-2022602057', 'TGS-2022602569',
    'TGS-2023017892', 'TGS-2023018794', 'TGS-2025052659',
];

$lit = static function (string $s): string {
    return $s === '' ? "''" : '0x' . bin2hex($s);
};

$stats = ['brochure_stripped' => 0, 'lo_stripped' => 0, 'lo_block_seeded' => 0, 'skipped' => 0];
$sql   = [];

foreach ($skus as $sku) {
    $sd = (string) $db->fetchOne(
        'SELECT t.value FROM catalog_product_entity_text t
           JOIN catalog_product_entity e ON e.entity_id = t.entity_id
          WHERE e.sku = ? AND t.attribute_id = ? AND t.store_id = 0',
        [$sku, $aidSd]
    );
    if ($sd === '') {
        $stats['skipped']++;
        continue;
    }

    $stmt = "-- {$sku}\n";
    $chunks = [];

    if (preg_match($loPattern, $sd, $m)) {
        $body       = trim($m[1]);
        $identifier = 'course_' . $sku . '_learning_outcomes';
        $existing   = trim((string) $db->fetchOne('SELECT content FROM cms_block WHERE identifier = ?', [$identifier]));
        if ($existing === '' && $body !== '') {
            $title = 'Course ' . $sku . ' — Learning Outcomes';
            $stmt .= sprintf(
                "INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)\n"
                . "  SELECT %s, %s, %s, NOW(), NOW(), 1 FROM DUAL\n"
                . "  WHERE NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = %s);\n"
                . "INSERT IGNORE INTO cms_block_store (block_id, store_id)\n"
                . "  SELECT block_id, 0 FROM cms_block WHERE identifier = %s;\n",
                $lit($title), $lit($identifier), $lit($body), $lit($identifier), $lit($identifier)
            );
            $stats['lo_block_seeded']++;
        }
        // Strip only when the card has a populated block to render from
        // (memory feedback_per_course_cms_block_sections).
        if ($existing !== '' || $body !== '') {
            $chunks[] = $m[0];
            $stats['lo_stripped']++;
        }
    }

    if (preg_match($brPattern, $sd, $m)) {
        $blockContent = trim((string) $db->fetchOne(
            'SELECT content FROM cms_block WHERE identifier = ?',
            ['course_' . $sku . '_brochure']
        ));
        if ($blockContent !== '') {
            $chunks[] = $m[0];
            $stats['brochure_stripped']++;
        }
    }

    if (!$chunks) {
        $stats['skipped']++;
        continue;
    }

    foreach ($chunks as $chunk) {
        $stmt .= sprintf(
            "UPDATE catalog_product_entity_text t\n"
            . "  JOIN catalog_product_entity e ON e.entity_id = t.entity_id AND e.sku = %s\n"
            . "   SET t.value = REPLACE(t.value, %s, '')\n"
            . " WHERE t.attribute_id = @a_sdesc AND t.store_id = 0;\n",
            $lit($sku), $lit($chunk)
        );
    }

    $sql[] = $stmt;
}

$header = "-- 915: IBF courses — card the Learning Outcomes + Brochure sections exactly\n"
    . "-- like the WSQ courses. Generated by\n"
    . "-- scripts/local-dev/generate-ibf-lo-brochure-migration.php (see its header\n"
    . "-- for the full rationale).\n"
    . "--\n"
    . "-- The 7 IBF descriptions used markup view.phtml's extractor cannot see:\n"
    . "-- `<h2>Brochure</h2>` (extractor expects \"Course Brochure\") and, on\n"
    . "-- TGS-2025052659, a styled-<span> pseudo-heading for Learning Outcomes.\n"
    . "-- Seeds the one missing learning_outcomes block, then strips the inline\n"
    . "-- duplicates so only the left-panel cards render the content.\n"
    . "--\n"
    . "-- Idempotent + partner-safe: SKU-joined exact-byte REPLACE no-ops when the\n"
    . "-- bytes are absent (already stripped, or a diverged partner row). Literals\n"
    . "-- hex-encoded for apply.php's utf8 connection.\n"
    . "--\n"
    . sprintf(
        "-- brochure stripped: %d  lo stripped: %d  lo blocks seeded: %d  skipped: %d\n\n",
        $stats['brochure_stripped'], $stats['lo_stripped'], $stats['lo_block_seeded'], $stats['skipped']
    )
    . "SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');\n\n";

file_put_contents($outFile, $header . implode("\n\n", $sql) . "\n");

echo "wrote: $outFile\n";
echo '  bytes: ' . number_format(filesize($outFile)) . "\n";
foreach ($stats as $k => $v) {
    printf("  %-18s %d\n", $k, $v);
}
