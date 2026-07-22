<?php
/**
 * One-shot CLI rename — replaces the term "SSG" with "SWDA (formerly SSG)"
 * across all user-visible DB content (CMS blocks/pages, course EAV text,
 * category names, email templates, payment config texts).
 *
 * SkillsFuture Singapore (SSG) was restructured into SWDA; storefront copy
 * must say "SWDA (formerly SSG)".
 *
 * Word-boundary regex, NOT SQL REPLACE — "CLSSGB" (Certified Lean Six Sigma
 * Green Belt) contains "SSG" and must never be touched. Case-sensitive, so
 * lowercase URLs like ssg.gov.sg are also untouched.
 *
 * Per field: the first mention becomes "SWDA (formerly SSG)", subsequent
 * mentions just "SWDA" (avoids "(formerly SSG)" spam in long descriptions).
 * Idempotent: the lookbehind skips the "SSG" inside "formerly SSG", and a
 * field already containing "formerly SSG" gets plain "SWDA" for any stragglers.
 *
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/rename-ssg-to-swda.php           # dry-run
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/rename-ssg-to-swda.php --apply   # write
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$opts  = getopt('', array('apply'));
$apply = isset($opts['apply']);

$db = Mage::getSingleton('core/resource')->getConnection('core_write');

/** @return string|null new value, or null if unchanged */
function swdaRewrite($value)
{
    if ($value === null || strpos($value, 'SSG') === false) {
        return null;
    }
    $out = $value;

    // Full-name phrases first, so we never nest parentheses.
    $out = preg_replace("/SkillsFuture Singapore(['\xE2\x80\x99]s)? \\(SSG\\)/u", 'SWDA$1 (formerly SSG)', $out);
    $out = preg_replace('/SSG \(SkillsFuture Singapore\)/', 'SWDA (formerly SSG)', $out);

    // Remaining standalone SSG. First mention per field gets the gloss,
    // unless the field already carries a "formerly SSG" from above.
    $glossed = (strpos($out, 'formerly SSG') !== false);
    $out = preg_replace_callback('/(?<!formerly )\bSSG\b/', function () use (&$glossed) {
        if ($glossed) {
            return 'SWDA';
        }
        $glossed = true;
        return 'SWDA (formerly SSG)';
    }, $out);

    return ($out === $value) ? null : $out;
}

$targets = array(
    // table, pk column, list of text columns
    array('cms_block',                       'block_id',     array('title', 'content')),
    array('cms_page',                        'page_id',      array('title', 'content_heading', 'content', 'meta_keywords', 'meta_description')),
    array('core_email_template',             'template_id',  array('template_subject', 'template_text')),
    array('core_config_data',                'config_id',    array('value')),
    array('catalog_product_entity_text',     'value_id',     array('value')),
    array('catalog_product_entity_varchar',  'value_id',     array('value')),
    array('catalog_category_entity_text',    'value_id',     array('value')),
    array('catalog_category_entity_varchar', 'value_id',     array('value')),
);

$totalChanged = 0;
foreach ($targets as $t) {
    list($table, $pk, $cols) = $t;
    $tableName = Mage::getSingleton('core/resource')->getTableName($table);
    $where = implode(' OR ', array_map(function ($c) {
        return "`$c` LIKE BINARY '%SSG%'";
    }, $cols));
    $rows = $db->fetchAll("SELECT `$pk`, `" . implode('`,`', $cols) . "` FROM `$tableName` WHERE $where");

    foreach ($rows as $row) {
        $updates = array();
        foreach ($cols as $c) {
            $new = swdaRewrite($row[$c]);
            if ($new !== null) {
                $updates[$c] = $new;
            }
        }
        if (!$updates) {
            continue; // e.g. CLSSGB-only false positive
        }
        $totalChanged++;
        fwrite(STDOUT, sprintf("%s #%s: %s\n", $table, $row[$pk], implode(', ', array_keys($updates))));
        if ($apply) {
            $db->update($tableName, $updates, array("`$pk` = ?" => $row[$pk]));
        }
    }
}

fwrite(STDOUT, sprintf("%s: %d row(s) %s\n", $apply ? 'APPLIED' : 'DRY-RUN', $totalChanged, $apply ? 'updated' : 'would change'));
if ($apply && $totalChanged) {
    fwrite(STDOUT, "Remember: reindex catalog_product_flat + flush cache for storefront visibility.\n");
}
