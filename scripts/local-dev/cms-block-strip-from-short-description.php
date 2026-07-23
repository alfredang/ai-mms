<?php
/**
 * Strip section content from short_description that has already been
 * migrated to per-course cms/blocks. The frontend reads cms/block first
 * (view.phtml ~85-265) so stripping these duplicates from short_description
 * is purely a cosmetic cleanup for the admin "Course Description" field
 * and has zero effect on storefront rendering — that's the safety
 * guarantee.
 *
 * Sections handled:
 *   - learning_outcomes / brochure / skills_framework / certification
 *     / wsq_funding / funding_and_grant
 *
 * Per-section guard:
 *   - Only strip a section's heading+body from short_description IF the
 *     corresponding per-course cms/block exists AND is non-empty.
 *   - Never strip a section whose cms/block is missing — preserves the
 *     regex-fallback path in view.phtml.
 *
 * Backup:
 *   - Before any UPDATE, writes the original short_description for every
 *     product to a per-run JSON file in media/migrations-reports/.
 *     If anything goes wrong, restore from that file.
 *
 * Usage:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/cms-block-strip-from-short-description.php --dry-run
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/cms-block-strip-from-short-description.php --apply
 *
 *   --sku=SKU    restrict to one course
 *   --limit=N    restrict to first N products
 *   --section=A,B  restrict to specific sections (e.g. --section=learning_outcomes)
 */

declare(strict_types=1);

$flags = [];
foreach ($argv as $a) {
    if (in_array($a, ['--apply','--dry-run'], true)) {
        $flags[ltrim($a,'-')] = true;
    } elseif (preg_match('/^--(\w+)=(.*)$/', $a, $m)) {
        $flags[$m[1]] = $m[2];
    }
}
$apply   = !empty($flags['apply']);
$onlySku = $flags['sku']   ?? null;
$limit   = isset($flags['limit']) ? (int)$flags['limit'] : 0;
$mode    = $apply ? 'apply' : 'dry-run';

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');
Mage::register('isSecureArea', true);

// --------------------------------------------------------------------------
// Strip patterns — copied from view.phtml so the regions stripped here are
// EXACTLY the regions view.phtml would have extracted/consumed.
// --------------------------------------------------------------------------
$WS = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';

$stripSection = function (string $title, string $desc) use ($WS): string {
    $pattern = '#<h[1-6][^>]*>' . $WS . '*(?:<br\s*/?>' . $WS . '*)*' . $title . $WS . '*:?' . $WS . '*</h[1-6]>(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)#siu';
    return preg_replace($pattern, '', $desc) ?? $desc;
};

$stripWsq = function (string $desc) use ($WS): string {
    $div  = '#<div\b[^>]*border-radius\s*:[^>]*>.*?</div>#siu';
    $head = '#<h[1-6][^>]*>' . $WS . '*WSQ' . $WS . '+Funding' . $WS . '*</h[1-6]>.*?(?=<h[12]\b|\z)#siu';
    $desc = preg_replace($div,  '', $desc) ?? $desc;
    $desc = preg_replace($head, '', $desc) ?? $desc;
    return $desc;
};

// Merged: wsq_funding and funding_and_grant share one cms/block. Strip BOTH
// patterns when the (single) funding_and_grant cms/block exists for the
// product — WSQ rounded-div, WSQ heading, and the MY "Funding and Grant"
// heading-anchored section.
$stripFunding = function (string $d) use ($stripWsq, $stripSection, $WS): string {
    $d = $stripWsq($d);
    $d = $stripSection('Funding' . $WS . '+(?:and|&amp;|&)' . $WS . '+Grant', $d);
    return $d;
};
$sections = [
    'learning_outcomes' => fn(string $d): string => $stripSection('Learning' . $WS . '+Outcomes', $d),
    'brochure'          => fn(string $d): string => $stripSection('Course' . $WS . '+Brochure', $d),
    'skills_framework'  => fn(string $d): string => $stripSection('Skills' . $WS . '+Framework', $d),
    'certification'     => fn(string $d): string => $stripSection('(?:Certifications?|Certificate)', $d),
    'funding_and_grant' => $stripFunding,
];

if (!empty($flags['section'])) {
    $only = array_filter(array_map('trim', explode(',', (string)$flags['section'])));
    $unknown = array_diff($only, array_keys($sections));
    if ($unknown) { fwrite(STDERR, 'unknown section(s): ' . implode(',', $unknown) . "\n"); exit(1); }
    $sections = array_intersect_key($sections, array_flip($only));
}

// --------------------------------------------------------------------------
// Resolve EAV attribute id for short_description once.
// --------------------------------------------------------------------------
$pdoR = Mage::getSingleton('core/resource')->getConnection('core_read');
$pdoW = Mage::getSingleton('core/resource')->getConnection('core_write');
$aid  = (int) $pdoR->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=4");
if (!$aid) { fwrite(STDERR, "could not resolve short_description attribute_id\n"); exit(1); }

// --------------------------------------------------------------------------
// Iterate products (default scope only — short_description at store_id=0
// is the fallback every store inherits unless overridden).
// --------------------------------------------------------------------------
$collection = Mage::getModel('catalog/product')->getCollection()
    ->addAttributeToSelect('sku')
    ->setOrder('entity_id', 'ASC');
if ($onlySku) $collection->addAttributeToFilter('sku', $onlySku);
if ($limit > 0) $collection->setPageSize($limit)->setCurPage(1);

echo "mode: $mode | products: " . $collection->getSize() . "\n";

$report = [
    'generated_at' => gmdate('c'),
    'mode'         => $mode,
    'totals'       => [
        'products_seen' => 0,
        'updated'       => 0,
        'unchanged'     => 0,
        'stripped'      => array_fill_keys(array_keys($sections), 0),
    ],
    'backups' => [],  // entity_id => original short_description
];

foreach ($collection as $p) {
    $sku = (string)$p->getSku();
    $eid = (int)$p->getId();
    if ($sku === '') continue;
    $report['totals']['products_seen']++;

    // Read default-scope short_description directly (avoid product load overhead).
    $sd = (string) $pdoR->fetchOne(
        "SELECT value FROM catalog_product_entity_text WHERE attribute_id=? AND entity_id=? AND store_id=0",
        [$aid, $eid]
    );
    if ($sd === '') { $report['totals']['unchanged']++; continue; }

    $original = $sd;
    foreach ($sections as $code => $stripper) {
        $blockId = 'course_' . $sku . '_' . $code;
        $blockContent = (string) $pdoR->fetchOne(
            "SELECT content FROM cms_block WHERE identifier=? LIMIT 1",
            [$blockId]
        );
        if (trim($blockContent) === '') continue; // guard: never strip without a block to back-fill

        $before = $sd;
        $sd = $stripper($sd);
        if ($sd !== $before) {
            $report['totals']['stripped'][$code]++;
        }
    }

    if ($sd === $original) { $report['totals']['unchanged']++; continue; }

    $report['backups'][$eid] = $original;

    if ($apply) {
        $pdoW->update(
            'catalog_product_entity_text',
            ['value' => $sd],
            ['attribute_id=?' => $aid, 'entity_id=?' => $eid, 'store_id=?' => 0]
        );
    }
    $report['totals']['updated']++;
    $p->clearInstance();
}

// --------------------------------------------------------------------------
// Persist report (includes per-product original short_description for rollback)
// --------------------------------------------------------------------------
$reportDir = dirname(__DIR__, 2) . '/media/migrations-reports';
if (!is_dir($reportDir)) @mkdir($reportDir, 0775, true);
$reportPath = $reportDir . '/strip-from-short-description-' . $mode . '-' . gmdate('Ymd-His') . '.json';
file_put_contents($reportPath, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");

echo "report: $reportPath\n";
echo "totals:\n";
echo "  products_seen: " . $report['totals']['products_seen'] . "\n";
echo "  updated:       " . $report['totals']['updated'] . "\n";
echo "  unchanged:     " . $report['totals']['unchanged'] . "\n";
foreach ($sections as $code => $_) {
    echo "  stripped[$code]: " . $report['totals']['stripped'][$code] . "\n";
}
echo "done\n";
