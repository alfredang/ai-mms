<?php
/**
 * Phase 0 + Phase 1 — per-course cms/block bootstrap.
 *
 * Replicates view.phtml's extraction logic EXACTLY (regex copied verbatim
 * from app/design/frontend/ultimo/default/template/catalog/product/view.phtml
 * lines ~75-260). For every product, captures the raw HTML each section
 * would have rendered from short_description, writes a per-product JSON
 * report, and (with --apply) creates one cms/block per (product × section).
 *
 *   Identifier convention:  course_<sku>_<section>
 *   Sections:               learning_outcomes, brochure,
 *                           skills_framework, certification, wsq_funding
 *   Store scope:            all stores (stores=[0])
 *   Content:                EXACTLY what view.phtml's regex extracted today
 *                           (raw, pre-post-processing for WSQ). No template
 *                           seeding, no inference. Empty extractions create
 *                           no block.
 *
 * The frontend is NOT touched by this script. view.phtml continues to render
 * from short_description via regex. cms/blocks are created in parallel for
 * a later cutover (Phase 4).
 *
 * Usage:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/cms-block-phase01.php --dry-run
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/cms-block-phase01.php --apply
 *
 * Flags:
 *   --dry-run    (default) write JSON report only, no DB writes
 *   --apply      additionally upsert cms/block rows
 *   --overwrite  in --apply mode, clobber existing non-empty blocks
 *   --sku=X      restrict to one SKU (smoke test)
 *   --limit=N    restrict to first N products
 *   --section=A,B  restrict to specific sections (e.g. --section=learning_outcomes)
 */

declare(strict_types=1);

$flags = [];
foreach ($argv as $a) {
    if (in_array($a, ['--apply','--dry-run','--overwrite'], true)) {
        $flags[ltrim($a,'-')] = true;
    } elseif (preg_match('/^--(\w+)=(.*)$/', $a, $m)) {
        $flags[$m[1]] = $m[2];
    }
}
$apply     = !empty($flags['apply']);
$overwrite = !empty($flags['overwrite']);
$onlySku   = $flags['sku']  ?? null;
$limit     = isset($flags['limit']) ? (int)$flags['limit'] : 0;
$mode      = $apply ? ($overwrite ? 'apply-overwrite' : 'apply') : 'dry-run';

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');
Mage::register('isSecureArea', true);

// --------------------------------------------------------------------------
// Extractors — copied verbatim from view.phtml's logic.
// view.phtml lines: 83 (_WS), 93-107 (WSQ), 161-166 (_extractSection helper),
// 169, 172, 192, 240 (per-section calls).
// --------------------------------------------------------------------------
$WS = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';

$extractSection = function (string $title, string $desc) use ($WS): string {
    if ($desc === '') return '';
    $pattern = '#<h[1-6][^>]*>' . $WS . '*(?:<br\s*/?>' . $WS . '*)*' . $title . $WS . '*:?' . $WS . '*</h[1-6]>(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)#siu';
    return preg_match($pattern, $desc, $m) ? trim($m[1]) : '';
};

// WSQ — match the rounded-div wrapper first, fall back to the heading-anchored
// form. Capture the RAW inner HTML; the post-processing (drop fee table,
// wrap subsections in .wsq-sub) stays in view.phtml and runs on whatever
// HTML the cms/block content feeds it.
$extractWsqRaw = function (string $desc) use ($WS): string {
    if ($desc === '') return '';
    $div  = '#<div\b[^>]*border-radius\s*:[^>]*>(.*?)</div>#siu';
    $head = '#<h[1-6][^>]*>' . $WS . '*WSQ' . $WS . '+Funding' . $WS . '*</h[1-6]>(.*?)(?=<h[12]\b|\z)#siu';
    if (preg_match($div,  $desc, $m)) return trim($m[1]);
    if (preg_match($head, $desc, $m)) return trim($m[1]);
    return '';
};

$sections = [
    'learning_outcomes' => [
        'label'   => 'Learning Outcomes',
        'extract' => fn(string $sd): string => $extractSection('Learning' . $WS . '+Outcomes', $sd),
    ],
    'brochure' => [
        'label'   => 'Course Brochure',
        'extract' => fn(string $sd): string => $extractSection('Course' . $WS . '+Brochure', $sd),
    ],
    'skills_framework' => [
        'label'   => 'Skills Framework',
        'extract' => fn(string $sd): string => $extractSection('Skills' . $WS . '+Framework', $sd),
    ],
    'certification' => [
        'label'   => 'Certification',
        'extract' => fn(string $sd): string => $extractSection('(?:Certifications?|Certificate)', $sd),
    ],
    // Merged: WSQ Funding (SG WSQ courses) and Funding and Grant (MY courses)
    // share a single per-course cms/block. Extractor tries the WSQ wrapper
    // first; if no WSQ content found, tries the "Funding and Grant" heading.
    'funding_and_grant' => [
        'label'   => 'Funding and Grant',
        'extract' => function (string $sd) use ($extractWsqRaw, $extractSection, $WS): string {
            $v = $extractWsqRaw($sd);
            if ($v !== '') return $v;
            return $extractSection('Funding' . $WS . '+(?:and|&amp;|&)' . $WS . '+Grant', $sd);
        },
    ],
];

if (!empty($flags['section'])) {
    $only = array_filter(array_map('trim', explode(',', (string)$flags['section'])));
    $unknown = array_diff($only, array_keys($sections));
    if ($unknown) { fwrite(STDERR, 'unknown section(s): ' . implode(',', $unknown) . "\n"); exit(1); }
    $sections = array_intersect_key($sections, array_flip($only));
}

// --------------------------------------------------------------------------
// Iterate products. Read short_description at admin/default scope (store_id=0)
// since that's where view.phtml falls back if there's no store override, and
// it's the source of truth for the per-course block (one block, all stores).
// --------------------------------------------------------------------------
$collection = Mage::getModel('catalog/product')->getCollection()
    ->addAttributeToSelect('sku')
    ->addAttributeToSelect('short_description')
    ->setOrder('entity_id', 'ASC');
if ($onlySku) $collection->addAttributeToFilter('sku', $onlySku);
if ($limit > 0) $collection->setPageSize($limit)->setCurPage(1);

echo "mode: $mode | products: " . $collection->getSize() . "\n";

$report = [
    'generated_at' => gmdate('c'),
    'mode'         => $mode,
    'naming'       => 'course_<sku>_<section>',
    'totals'       => [
        'products_seen' => 0,
        'extracted'     => array_fill_keys(array_keys($sections), 0),
        'created'       => array_fill_keys(array_keys($sections), 0),
        'updated'       => array_fill_keys(array_keys($sections), 0),
        'skipped_exist' => array_fill_keys(array_keys($sections), 0),
        'empty'         => array_fill_keys(array_keys($sections), 0),
    ],
    'rows' => [],
];

foreach ($collection as $p) {
    $sku = (string) $p->getSku();
    if ($sku === '') continue;

    $sd = (string) $p->getShortDescription();
    $report['totals']['products_seen']++;
    $row = ['sku' => $sku, 'sd_len' => mb_strlen($sd)];

    foreach ($sections as $code => $def) {
        $blockId   = 'course_' . $sku . '_' . $code;
        $extracted = trim($def['extract']($sd));
        $entry = ['block_id' => $blockId, 'extracted_len' => mb_strlen($extracted)];

        if ($extracted === '') {
            $report['totals']['empty'][$code]++;
            $entry['action'] = 'empty-skip';
            $row[$code] = $entry;
            continue;
        }
        $report['totals']['extracted'][$code]++;

        // Optional content hash for cross-checking with frontend rendering.
        $entry['content_md5'] = md5($extracted);

        if (!$apply) {
            $entry['action'] = 'dry';
            $row[$code] = $entry;
            continue;
        }

        $existing = Mage::getModel('cms/block')->load($blockId, 'identifier');
        if ($existing->getId()) {
            if (!$overwrite && trim((string)$existing->getContent()) !== '') {
                $report['totals']['skipped_exist'][$code]++;
                $entry['action'] = 'skip-exists';
                $row[$code] = $entry;
                continue;
            }
            $existing->setContent($extracted)->setIsActive(1)->save();
            $report['totals']['updated'][$code]++;
            $entry['action'] = 'updated';
            $row[$code] = $entry;
            continue;
        }

        Mage::getModel('cms/block')
            ->setIdentifier($blockId)
            ->setTitle('Course ' . $sku . ' — ' . $def['label'])
            ->setContent($extracted)
            ->setIsActive(1)
            ->setStores([0])
            ->save();
        $report['totals']['created'][$code]++;
        $entry['action'] = 'created';
        $row[$code] = $entry;
    }

    $report['rows'][] = $row;
    $p->clearInstance();
}

// --------------------------------------------------------------------------
// Write report
// --------------------------------------------------------------------------
$reportDir = dirname(__DIR__, 2) . '/media/migrations-reports';
if (!is_dir($reportDir)) @mkdir($reportDir, 0775, true);
$reportPath = $reportDir . '/cms-block-phase01-' . $mode . '-' . gmdate('Ymd-His') . '.json';
file_put_contents($reportPath, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");

echo "report: $reportPath\n";
echo "totals:\n";
foreach (array_keys($sections) as $code) {
    printf("  %-20s extracted=%d created=%d updated=%d skipped(exists)=%d empty=%d\n",
        $code,
        $report['totals']['extracted'][$code],
        $report['totals']['created'][$code],
        $report['totals']['updated'][$code],
        $report['totals']['skipped_exist'][$code],
        $report['totals']['empty'][$code]
    );
}
echo "done\n";
