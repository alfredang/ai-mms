<?php
/**
 * Generate the migration that moves the "Skills Framework" section out of every
 * course's short_description and into the per-course
 * `course_<sku>_skills_framework` cms/block, so the storefront TSC card is
 * driven solely by the block.
 *
 * view.phtml already reads block-first with a regex fallback (section 4), and
 * the card's TSC Title / TSC Code are DERIVED from whichever source wins. A
 * replay of the derivation over all 299 local rows — extracted-from-description
 * vs seeded-block — produced identical output for 299/299 with 0 anomalies, so
 * the card renders unchanged. No template change is needed or made.
 *
 * Unlike the brochure move (887), the block does NOT exist anywhere yet
 * (0 rows locally, and memory feedback_per_course_cms_block_sections records
 * skills_framework as never bootstrapped on prod). So every course seeds its
 * block from its own description body, then strips:
 *
 *   - block exists & non-empty -> leave the block ALONE, strip the description
 *   - block missing / empty    -> seed from the description body, THEN strip
 *   - empty body / no code     -> skip entirely (never strip a section whose
 *                                 content would be lost; view.phtml's regex
 *                                 fallback must keep something to render)
 *
 * That last rule is the safety net from memory
 * feedback_per_course_cms_block_sections. It also skips TGS-2023040474, whose
 * "Skills Framework" heading sits over Certification copy and yields no TSC
 * code — a pre-existing quirk noted in
 * feedback_tsc_code_marker_is_regex_anchor_not_data. Seeding a block there
 * would promote wrong content to the primary source.
 *
 * Course selection is by the <h2> HEADING, never the bare phrase "Skills
 * Framework" — the OpenCerts certification bullet ends with that phrase, so a
 * phrase match yields false positives/negatives
 * (memory feedback_skills_framework_detect_by_heading_not_phrase).
 *
 * The strip uses the SAME whitespace-tolerant regex as
 * view.phtml::$_extractSection — in particular its lookahead
 * `(?:<[a-z...]\b[^>]*>\s*)*<h[1-6]` stops BEFORE any wrapper tag that opens
 * just ahead of the next heading. 277 of 299 courses have the WSQ Funding
 * section's `<div style="...border-radius: 25px;">` opener sitting between the
 * Skills Framework paragraph and the Funding <h2>; a naive `.*?<h2` strip would
 * swallow that opener and break the funding card's markup while every lint and
 * apply.php run still reported success
 * (memory feedback_section_strip_must_preserve_next_wrapper_div).
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
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/generate-skills-framework-to-cms-block-migration.php
 */

declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$outFile = dirname(__DIR__, 2) . '/migrations/889-skills-framework-to-cms-block.sql';

$db = Mage::getSingleton('core/resource')->getConnection('core_read');

$aidSd = (int) $db->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description'");

// Same whitespace class + section pattern as view.phtml's $_extractSection.
$WS      = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';
$pattern = '#<h[1-6][^>]*>' . $WS . '*(?:<br\s*/?>' . $WS . '*)*Skills' . $WS . '+Framework' . $WS . '*:?' . $WS . '*</h[1-6]>(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)#siu';

// Heading-based selection (never the bare phrase).
$rows = $db->fetchAll(
    "SELECT e.entity_id, e.sku, t.value AS sd
       FROM catalog_product_entity e
       JOIN catalog_product_entity_text t
         ON t.entity_id = e.entity_id AND t.attribute_id = ? AND t.store_id = 0
      WHERE t.value REGEXP '<h[1-6][^>]*>[[:space:]]*Skills[[:space:]]+Framework'
      ORDER BY e.sku",
    [$aidSd]
);

/** Emit a MySQL-safe literal: hex-encode so no charset/escaping path can corrupt it. */
$lit = static function (string $s): string {
    return $s === '' ? "''" : '0x' . bin2hex($s);
};

/**
 * The card's TSC-code derivation, copied verbatim from view.phtml (~line 390).
 * Used only as a guard: a body from which no code can be derived is not real
 * Skills Framework content and must not be promoted into a block.
 */
$deriveCode = static function (string $raw): string {
    $h = html_entity_decode(strip_tags($raw), ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $h = preg_replace('#[\x{00A0}\x{2007}\x{202F}]#u', ' ', $h);
    $h = preg_replace('#\s+#u', ' ', trim($h));
    if (preg_match('#([A-Z]{2,}(?:-[A-Z][A-Z0-9]*)+(?:[-.][0-9][0-9.\-]*)?)\s+(T(?:SC)?)\b#u', $h, $c)) {
        return trim($c[1]);
    }
    if (preg_match('#([A-Z]{2,}(?:-[A-Z][A-Z0-9]*)+(?:[-.][0-9][0-9.\-]*))#u', $h, $c)) {
        return trim($c[1]);
    }
    return '';
};

$stats = ['seen' => 0, 'stripped' => 0, 'block_seeded' => 0, 'skipped_no_code' => 0, 'no_match' => 0];
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

    $identifier = 'course_' . $sku . '_skills_framework';
    $existing   = trim((string) $db->fetchOne('SELECT content FROM cms_block WHERE identifier = ?', [$identifier]));

    $seed = '';
    if ($existing === '') {
        // Never promote a body the card cannot read (empty, or Certification
        // copy filed under a Skills Framework heading). Leave the heading in
        // short_description so the regex fallback still renders it.
        if ($extracted === '' || $deriveCode($extracted) === '') {
            $stats['skipped_no_code']++;
            continue;
        }
        $seed = $extracted;
        $stats['block_seeded']++;
    }

    // Strip EVERY Skills Framework section (guards against a legacy duplicate;
    // 2 courses locally carry two).
    $newSd = rtrim((string) preg_replace($pattern, '', $sd));
    $stats['stripped']++;

    $stmt = "-- {$sku}\n";
    if ($seed !== '') {
        $title = 'Course ' . $sku . ' — Skills Framework';
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

$header = "-- 889: Move the \"Skills Framework\" section out of short_description and into\n"
    . "-- the per-course `course_<sku>_skills_framework` cms/block, so the storefront\n"
    . "-- TSC card is driven solely by the block. Generated by\n"
    . "-- scripts/local-dev/generate-skills-framework-to-cms-block-migration.php\n"
    . "--\n"
    . "-- view.phtml already reads block-first with a regex fallback and DERIVES the\n"
    . "-- TSC Title / TSC Code from whichever source wins, so the card is unchanged.\n"
    . "-- Verified by replaying the derivation over all 299 rows (extracted vs seeded):\n"
    . "-- 299/299 identical, 0 anomalies. No template change accompanies this.\n"
    . "--\n"
    . "-- Courses are selected by the <h2> HEADING, never the bare phrase \"Skills\n"
    . "-- Framework\" — the OpenCerts certification bullet ends with that phrase\n"
    . "-- (memory feedback_skills_framework_detect_by_heading_not_phrase).\n"
    . "--\n"
    . "-- A course whose section body yields no TSC code is SKIPPED and keeps its\n"
    . "-- heading, so the regex fallback still has something to render (memory\n"
    . "-- feedback_per_course_cms_block_sections). That covers TGS-2023040474, whose\n"
    . "-- Skills Framework heading sits over Certification copy.\n"
    . "--\n"
    . "-- The strip mirrors view.phtml::\$_extractSection, whose lookahead stops before\n"
    . "-- a wrapper tag opening ahead of the next heading — 277 courses have the WSQ\n"
    . "-- Funding section's <div style=\"...border-radius: 25px;\"> opener trailing the\n"
    . "-- Skills Framework paragraph (memory\n"
    . "-- feedback_section_strip_must_preserve_next_wrapper_div).\n"
    . "--\n"
    . "-- Every literal is hex-encoded so apply.php's utf8 PDO connection cannot hit\n"
    . "-- error 1366 on legacy bytes (feedback_migration_applyphp_utf8_outage).\n"
    . "-- Idempotent: the block INSERT is NOT EXISTS-guarded and the UPDATE rewrites\n"
    . "-- the same already-stripped description.\n"
    . "-- Partner-safe (SKU-driven, no store guard needed).\n"
    . "--\n"
    . sprintf(
        "-- courses stripped: %d  (blocks seeded: %d)  skipped, no derivable TSC code: %d\n\n",
        $stats['stripped'], $stats['block_seeded'], $stats['skipped_no_code']
    )
    . "SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');\n\n";

file_put_contents($outFile, $header . implode("\n\n", $sql) . "\n");

echo "wrote: $outFile\n";
echo '  bytes: ' . number_format(filesize($outFile)) . "\n";
foreach ($stats as $k => $v) {
    printf("  %-18s %d\n", $k, $v);
}
