<?php
/**
 * Generate the migration that moves the Certification section out of every
 * course's short_description and into its per-course
 * `course_<sku>_certification` cms/block, so the storefront Certification
 * card is driven by the CMS block rather than by hardcoded template copy.
 *
 * Content is CANONICAL, not copied: the legacy description text is
 * inconsistent (327 courses say "Tertiary Courses", others say "Tertiary
 * Infotech", and some C-prefix courses wrongly carry an OpenCerts bullet).
 * We regenerate it from the course type instead, matching the rules the
 * storefront template already applies:
 *
 *   WSQ  (TGS-* SKU, name NOT 'CASL - %')  -> 2 bullets: Cert of Completion + OpenCerts
 *   CASL (name starts 'CASL')              -> 1 bullet:  Cert of Completion
 *   non-WSQ (C-prefix and everything else) -> 1 bullet:  Cert of Completion
 *
 * Preserves the "Certification Exam at Pearson Vue" supplement that
 * migration 151 / move-all-pearson-vue-to-cert-cms-block.php appended to
 * existing blocks — that copy is vendor-specific and is NOT regenerable.
 *
 * The description strip uses the SAME whitespace-tolerant regex as
 * view.phtml::$_extractSection, which raw SQL cannot express — hence a
 * generator that emits deterministic, fully-escaped SQL literals.
 *
 * Every emitted literal is UTF-8 hex-encoded (0x...) so apply.php's
 * `charset=utf8` PDO connection cannot trip error 1366 on legacy bytes.
 * See memory feedback_migration_applyphp_utf8_outage.
 *
 * Run:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/generate-certification-to-cms-block-migration.php
 */

declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$outFile = dirname(__DIR__, 2) . '/migrations/885-certification-to-cms-block.sql';

$db = Mage::getSingleton('core/resource')->getConnection('core_read');

$aidSd   = (int) $db->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description'");
$aidName = (int) $db->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name'");

// Same whitespace class + section pattern as view.phtml's $_extractSection,
// widened for two malformed legacy headings that the template's stricter
// regex also fails on (so today they leak into the narrative):
//   <h2>Certificate</span></h2>  — stray closing tag  (C1201)
//   <h2>Certification.</h2>      — trailing period    (TGS-2020505109)
$WS      = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';
$pattern = '#<h[1-6][^>]*>' . $WS . '*(?:<br\s*/?>' . $WS . '*)*(?:Certifications?|Certificate)' . $WS . '*(?:</span>)?' . $WS . '*[.:]?' . $WS . '*</h[1-6]>(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)#siu';

$BULLET_TERTIARY = '<li><strong>Certificate of Achievement from Tertiary Infotech Academy Pte Ltd</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Achievement from Tertiary Infotech Academy Pte Ltd.</li>';
$BULLET_OPENCERT = '<li><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</li>';

$rows = $db->fetchAll(
    "SELECT e.entity_id, e.sku, n.value AS name, t.value AS sd
       FROM catalog_product_entity e
       JOIN catalog_product_entity_text t
         ON t.entity_id = e.entity_id AND t.attribute_id = ? AND t.store_id = 0
  LEFT JOIN catalog_product_entity_varchar n
         ON n.entity_id = e.entity_id AND n.attribute_id = ? AND n.store_id = 0
      WHERE t.value REGEXP '<h[1-6][^>]*>[[:space:]]*(Certifications?|Certificate)'
      ORDER BY e.sku",
    [$aidSd, $aidName]
);

/** Emit a MySQL-safe literal: hex-encode so no charset/escaping path can corrupt it. */
$lit = static function (string $s): string {
    return $s === '' ? "''" : '0x' . bin2hex($s);
};

$stats = ['seen' => 0, 'wsq' => 0, 'casl' => 0, 'nonwsq' => 0, 'pearson_preserved' => 0, 'no_match' => 0];
$sql   = [];

foreach ($rows as $r) {
    $eid  = (int) $r['entity_id'];
    $sku  = (string) $r['sku'];
    $name = trim((string) $r['name']);
    $sd   = (string) $r['sd'];
    $stats['seen']++;

    // Strip EVERY Certification section (some legacy rows carry it twice).
    $newSd = preg_replace($pattern, '', $sd);
    if ($newSd === null || $newSd === $sd) {
        $stats['no_match']++;
        continue;
    }
    $newSd = rtrim($newSd);

    // Course type -> canonical bullets. Mirrors view.phtml exactly.
    $isCasl = stripos($name, 'CASL') === 0;
    $isWsq  = !$isCasl && stripos($sku, 'TGS-') === 0;
    $body   = '<ul class="cert-bullets">' . $BULLET_TERTIARY . ($isWsq ? $BULLET_OPENCERT : '') . '</ul>';
    $stats[$isCasl ? 'casl' : ($isWsq ? 'wsq' : 'nonwsq')]++;

    // Preserve any vendor-specific Pearson Vue supplement already in the block.
    $identifier = 'course_' . $sku . '_certification';
    $existing   = (string) $db->fetchOne('SELECT content FROM cms_block WHERE identifier = ?', [$identifier]);
    if ($existing !== '' && preg_match('#<p>\s*<strong>\s*Certification Exam at Pearson Vue\s*</strong>\s*</p>.*$#siu', $existing, $pv)) {
        $body .= $pv[0];
        $stats['pearson_preserved']++;
    }

    $title = 'Course ' . $sku . ' — Certification';

    $sql[] = sprintf(
        "-- %s\n"
        . "INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)\n"
        . "  SELECT %s, %s, %s, NOW(), NOW(), 1 FROM DUAL\n"
        . "  WHERE NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = %s);\n"
        . "UPDATE cms_block SET content = %s, is_active = 1, update_time = NOW() WHERE identifier = %s;\n"
        . "INSERT IGNORE INTO cms_block_store (block_id, store_id)\n"
        . "  SELECT block_id, 0 FROM cms_block WHERE identifier = %s;\n"
        . "UPDATE catalog_product_entity_text SET value = %s WHERE attribute_id = @a_sdesc AND store_id = 0 AND entity_id = %d;",
        $sku,
        $lit($title), $lit($identifier), $lit($body), $lit($identifier),
        $lit($body), $lit($identifier),
        $lit($identifier),
        $lit($newSd), $eid
    );
}

$header = "-- 885: Move the Certification section out of short_description into the\n"
    . "-- per-course `course_<sku>_certification` cms/block, so the storefront\n"
    . "-- Certification card renders FROM the CMS block instead of from hardcoded\n"
    . "-- template copy. Generated by\n"
    . "-- scripts/local-dev/generate-certification-to-cms-block-migration.php\n"
    . "--\n"
    . "-- Content is canonical per course type (the legacy description copy was\n"
    . "-- inconsistent: 'Tertiary Infotech' vs 'Tertiary Courses', and stray\n"
    . "-- OpenCerts bullets on non-WSQ courses):\n"
    . "--   WSQ (TGS-*, not CASL) -> Certificate of Completion + OpenCerts\n"
    . "--   CASL / non-WSQ        -> Certificate of Completion only\n"
    . "-- Any existing 'Certification Exam at Pearson Vue' supplement (migration\n"
    . "-- 151) is preserved verbatim.\n"
    . "--\n"
    . "-- Every literal is hex-encoded so apply.php's utf8 PDO connection cannot\n"
    . "-- hit error 1366 on legacy bytes (feedback_migration_applyphp_utf8_outage).\n"
    . "-- Idempotent: re-running rewrites the same block content and the same\n"
    . "-- already-stripped description. Partner-safe (SKU-driven, no store guard\n"
    . "-- needed — each site only holds its own SKUs).\n"
    . "--\n"
    . sprintf(
        "-- courses: %d  (WSQ %d / CASL %d / non-WSQ %d)  pearson-vue preserved: %d\n\n",
        $stats['seen'] - $stats['no_match'], $stats['wsq'], $stats['casl'], $stats['nonwsq'], $stats['pearson_preserved']
    )
    . "SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');\n\n";

file_put_contents($outFile, $header . implode("\n\n", $sql) . "\n");

echo "wrote: $outFile\n";
echo '  bytes: ' . number_format(filesize($outFile)) . "\n";
foreach ($stats as $k => $v) {
    printf("  %-18s %d\n", $k, $v);
}
