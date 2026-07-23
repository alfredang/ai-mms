<?php
/**
 * Extract the "Final Assessment" section out of every WSQ (TGS- SKU) course
 * description into the `assessment_methods` multiselect attribute, then strip
 * those assessment lines from the description so they no longer render inside
 * the storefront "What You'll Learn" card. The Assessment card already reads
 * `assessment_methods` (description.phtml), so the items move — not vanish.
 *
 * Variants handled (surveyed on SG prod 2026-07-21):
 *   A. <h3 class="course-topic-h3">Final Assessment</h3> + <ul>…</ul>
 *   B. <h3>Final Assessment</h3><ul>…</ul>            (no class, inline)
 *   C. <p><strong>Final Assessment[&nbsp;]</strong></p> + <ul>…</ul>
 *   D. <p><em>Final Assessment</em></p> + consecutive <p><em>item</em></p>
 *   E. LSN_DATA JSON comment entries {"title":"Final Assessment…","links":[]}
 *      and the item entries that follow them.
 *
 * Safety:
 *   - A heading+<ul> block is stripped ONLY if every <li> maps to a known
 *     assessment option; otherwise the product is logged for manual review
 *     and left untouched.
 *   - Standalone <p><em> lines are stripped only on a STRICT full-line match
 *     against the known assessment labels (so subtopic lines like
 *     "Demonstration of X" are never eaten).
 *   - Originals are backed up (base64 — descriptions contain invalid UTF-8
 *     bytes) to a per-run JSON report in media/migrations-reports/.
 *   - Description writes go through UNHEX(hex) so invalid bytes elsewhere in
 *     the value survive the utf8 connection byte-exact.
 *   - No /u regex modifier anywhere — subjects contain invalid UTF-8 and
 *     PCRE /u refuses such subjects outright.
 *   - Only store_id=0 rows are touched (survey: no per-store overrides).
 *
 * Usage:
 *   php scripts/maintenance/extract-assessment-methods.php --dry-run
 *   php scripts/maintenance/extract-assessment-methods.php --apply
 *   --sku=TGS-…   restrict to one course
 *   --limit=N     first N TGS- products
 */

declare(strict_types=1);

$flags = [];
foreach ($argv as $a) {
    if (in_array($a, ['--apply', '--dry-run'], true)) {
        $flags[ltrim($a, '-')] = true;
    } elseif (preg_match('/^--(\w+)=(.*)$/', $a, $m)) {
        $flags[$m[1]] = $m[2];
    }
}
$apply   = !empty($flags['apply']);
$onlySku = $flags['sku'] ?? null;
$limit   = isset($flags['limit']) ? (int) $flags['limit'] : 0;
$mode    = $apply ? 'apply' : 'dry-run';

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');
Mage::register('isSecureArea', true);

$pdoR = Mage::getSingleton('core/resource')->getConnection('core_read');
$pdoW = Mage::getSingleton('core/resource')->getConnection('core_write');

$descAid = (int) $pdoR->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='description' AND entity_type_id=4");
$asmtAid = (int) $pdoR->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='assessment_methods' AND entity_type_id=4");
if (!$descAid || !$asmtAid) { fwrite(STDERR, "could not resolve attribute ids\n"); exit(1); }

// Value table follows the attribute's backend_type (created as `text` by
// migration 157 — do NOT assume the stock multiselect `varchar` backend).
$asmtBackend = (string) $pdoR->fetchOne("SELECT backend_type FROM eav_attribute WHERE attribute_id = ?", [$asmtAid]);
if (!in_array($asmtBackend, ['varchar', 'text'], true)) { fwrite(STDERR, "unexpected backend_type: $asmtBackend\n"); exit(1); }
$asmtTable = 'catalog_product_entity_' . $asmtBackend;

// Option ids by label, read live (never hardcode — ids can differ per DB).
$optionByLabel = [];
foreach ($pdoR->fetchAll(
    "SELECT o.option_id, v.value FROM eav_attribute_option o
     JOIN eav_attribute_option_value v ON v.option_id = o.option_id AND v.store_id = 0
     WHERE o.attribute_id = ?", [$asmtAid]
) as $row) {
    $optionByLabel[$row['value']] = (int) $row['option_id'];
}
foreach (['Written Exam', 'Practical Exam', 'Case Study', 'Role Play', 'Oral Questioning', 'Assignment', 'Project'] as $must) {
    if (!isset($optionByLabel[$must])) { fwrite(STDERR, "missing option: $must\n"); exit(1); }
}

/**
 * Normalize an extracted line: strip tags, decode entities, replace any
 * non-printable-ASCII byte with a space, collapse whitespace, lowercase.
 */
$norm = function (string $raw) : string {
    $t = html_entity_decode(strip_tags($raw), ENT_QUOTES, 'ISO-8859-1');
    $t = preg_replace('/[^\x20-\x7E]/', ' ', $t);
    return strtolower(trim(preg_replace('/\s+/', ' ', $t)));
};

/**
 * LOOSE matcher — used only for <li> items INSIDE a Final Assessment block,
 * where every line is known to be an assessment item.
 * Returns canonical label, '' for a "Final Assessment" heading echo,
 * or null when unrecognized.
 */
$mapItemLoose = function (string $raw) use ($norm) : ?string {
    $t = $norm($raw);
    if ($t === '') return '';
    if (strpos($t, 'wa-saq') !== false || strpos($t, 'written assessment') !== false || strpos($t, 'written exam') !== false) return 'Written Exam';
    if (strpos($t, 'mcq') !== false || strpos($t, 'multiple choice') !== false) return 'Written Exam';
    if (strpos($t, 'practical performance') !== false || strpos($t, '(pp)') !== false || strpos($t, 'practical exam') !== false) return 'Practical Exam';
    if (strpos($t, 'case study') !== false || strpos($t, 'case studies') !== false) return 'Case Study';
    if (strpos($t, 'role play') !== false)        return 'Role Play';
    if (strpos($t, 'oral questioning') !== false || strpos($t, '(oq)') !== false) return 'Oral Questioning';
    if (strpos($t, 'assignment') !== false)       return 'Assignment';
    if (strpos($t, 'demonstration') !== false)    return 'Demonstration';
    if (strpos($t, 'project') !== false)          return 'Project';
    if (strpos($t, 'final assessment') !== false) return '';
    return null;
};

/**
 * STRICT matcher — the ENTIRE line must be a known assessment label.
 * Used for <p><em> lines, which sit among real syllabus content.
 */
$mapItemStrict = function (string $raw) use ($norm) : ?string {
    static $table = [
        '#^written assessment[ -]*(short answer questions?)? ?\(wa-?saq\)$#' => 'Written Exam',
        '#^written exam(ination)?$#'                                          => 'Written Exam',
        '#^practical performance ?(\(pp\))?$#'                                => 'Practical Exam',
        '#^practical exam(ination)?$#'                                        => 'Practical Exam',
        '#^case study ?(\(cs\))?$#'                                           => 'Case Study',
        '#^role play ?(\(rp\))?$#'                                            => 'Role Play',
        '#^oral questioning ?(\(oq\))?$#'                                     => 'Oral Questioning',
        '#^assignment ?(\(asg\))?$#'                                          => 'Assignment',
        '#^demonstration ?(\(dem\))?$#'                                       => 'Demonstration',
        '#^project ?(\(pj\))?$#'                                              => 'Project',
        '#^final assessment$#'                                                => '',
    ];
    $t = $norm($raw);
    if ($t === '') return null;
    foreach ($table as $re => $label) {
        if (preg_match($re, $t)) return $label;
    }
    return null;
};

// Whitespace incl. entities and stray high bytes (e.g. broken NBSP / '�').
$NBSP = '(?:\s|&nbsp;|[\x80-\xFF])';
// Heading text: "Final Assessment" (tolerating the "Assement" typo and a
// split <strong>F</strong><strong>inal…</strong>) or "Mode of Assessment".
$FA = '(?:F(?:</strong>' . $NBSP . '*<strong>)?inal' . $NBSP . '+Asse(?:ss)?ment|Mode' . $NBSP . '+of' . $NBSP . '+Assessment)' . $NBSP . '*';

// Heading + <ul> block, variants A/B/C. Captures the <ul> inner HTML.
$blockRe = '#(?:<h[1-6][^>]*>' . $NBSP . '*' . $FA . '</h[1-6]>|<p[^>]*>' . $NBSP . '*<strong>' . $NBSP . '*' . $FA . '</strong>' . $NBSP . '*</p>)'
         . $NBSP . '*<ul[^>]*>(.*?)</ul>#si';

// Variant D: <p><em>Final Assessment</em></p> then consecutive <p><em>…</em></p>.
$emHeadRe = '#<p>' . $NBSP . '*<em>' . $NBSP . '*' . $FA . '</em>' . $NBSP . '*</p>#si';
$emLineRe = '#\G' . $NBSP . '*<p>' . $NBSP . '*<em>(.*?)</em>' . $NBSP . '*</p>#si';

// Leftover bare heading (no <ul> following) — full-heading match only.
$bareHeadRe = '#(?:<h[1-6][^>]*>' . $NBSP . '*' . $FA . '</h[1-6]>|<p[^>]*>' . $NBSP . '*<strong>' . $NBSP . '*' . $FA . '</strong>' . $NBSP . '*</p>)#si';

// Variant E: LSN_DATA JSON entries (titles may carry a stray-byte suffix).
$jsonTitles = 'Final' . $NBSP . '*Asse(?:ss)?ment|Mode' . $NBSP . '+of' . $NBSP . '+Assessment|Written' . $NBSP . '*Assessment[^"]*|Practical' . $NBSP . '*Performance[^"]*|Oral' . $NBSP . '*Questioning[^"]*|(?:Case|Caes)' . $NBSP . '*Stud(?:y|ies)[^"]*|Written' . $NBSP . '*Exam|Practical' . $NBSP . '*Exam';
$jsonRe = '#\{"title":"(?:' . $jsonTitles . ')[^"]*","links":\[\]\},?#i';

$collection = Mage::getModel('catalog/product')->getCollection()
    ->addAttributeToSelect('sku')
    ->addAttributeToFilter('sku', ['like' => 'TGS-%'])
    ->setOrder('entity_id', 'ASC');
if ($onlySku) $collection->addAttributeToFilter('sku', $onlySku);
if ($limit > 0) $collection->setPageSize($limit)->setCurPage(1);

echo "mode: $mode | TGS products: " . $collection->getSize() . "\n";

$report = [
    'generated_at' => gmdate('c'),
    'mode'         => $mode,
    'totals'       => ['seen' => 0, 'updated' => 0, 'no_assessment_lines' => 0, 'manual_review' => 0],
    'methods_set'  => [],   // sku => [labels]
    'manual'       => [],   // sku => reason
    'backups_b64'  => [],   // entity_id => base64(original description)
];

foreach ($collection as $p) {
    $sku = (string) $p->getSku();
    $eid = (int) $p->getId();
    $report['totals']['seen']++;

    $desc = (string) $pdoR->fetchOne(
        "SELECT value FROM catalog_product_entity_text WHERE attribute_id=? AND entity_id=? AND store_id=0",
        [$descAid, $eid]
    );
    if ($desc === '') { $report['totals']['no_assessment_lines']++; continue; }

    $original = $desc;
    $labels   = [];
    $bad      = null;

    // --- Variants A/B/C: heading + <ul> (repeat while blocks remain) -----
    while ($bad === null && preg_match($blockRe, $desc, $m, PREG_OFFSET_CAPTURE)) {
        $lis = [];
        preg_match_all('#<li[^>]*>(.*?)</li>#si', $m[1][0], $liM);
        foreach ($liM[1] as $li) {
            $lab = $mapItemLoose($li);
            if ($lab === null) { $bad = 'unmapped item in Final Assessment block: ' . trim(strip_tags($li)); break; }
            if ($lab !== '') $lis[] = $lab;
        }
        if ($bad !== null) break;
        $labels = array_merge($labels, $lis);
        $desc = substr($desc, 0, $m[0][1]) . substr($desc, $m[0][1] + strlen($m[0][0]));
    }

    // --- Variant D: <p><em>Final Assessment</em></p> + item run ----------
    if ($bad === null && preg_match($emHeadRe, $desc, $m, PREG_OFFSET_CAPTURE)) {
        $start = $m[0][1];
        $end   = $start + strlen($m[0][0]);
        while (preg_match($emLineRe, $desc, $lm, 0, $end)) {
            $lab = $mapItemStrict($lm[1]);
            if ($lab === null) break;           // not an assessment line — stop the run
            if ($lab !== '') $labels[] = $lab;
            $end += strlen($lm[0]);
        }
        $desc = substr($desc, 0, $start) . substr($desc, $end);
    }

    // --- Orphan strict <p><em> assessment lines (partially-cleaned courses,
    //     e.g. the migration-637 course) ---------------------------------
    if ($bad === null) {
        $desc = preg_replace_callback('#<p>' . $NBSP . '*<em>(.*?)</em>' . $NBSP . '*</p>#si', function ($mm) use ($mapItemStrict, &$labels) {
            $lab = $mapItemStrict($mm[1]);
            if ($lab === null) return $mm[0];   // real content — keep
            if ($lab !== '') $labels[] = $lab;
            return '';
        }, $desc) ?? $desc;
        // Bare "Final Assessment" heading left with no list following.
        $desc = preg_replace($bareHeadRe, '', $desc) ?? $desc;
    }

    if ($bad !== null) {
        $report['manual'][$sku] = $bad;
        $report['totals']['manual_review']++;
        continue;
    }

    // --- Variant E: LSN_DATA JSON comment entries ------------------------
    $desc = preg_replace($jsonRe, '', $desc) ?? $desc;
    $desc = str_replace([',]', ',}'], [']', '}'], $desc);

    // Tidy repeated blank lines left behind.
    $desc = preg_replace('#(\r?\n){3,}#', "\n\n", $desc) ?? $desc;

    $labels = array_values(array_unique($labels));
    $optIds = [];
    foreach ($labels as $l) {
        if (!isset($optionByLabel[$l])) { $bad = 'no attribute option for label: ' . $l; break; }
        $optIds[] = $optionByLabel[$l];
    }
    if ($bad !== null) {
        $report['manual'][$sku] = $bad;
        $report['totals']['manual_review']++;
        continue;
    }
    sort($optIds);

    // Nothing extracted AND nothing stripped -> genuinely untouched course.
    if (empty($labels) && $desc === $original) {
        $report['totals']['no_assessment_lines']++;
        continue;
    }

    if ($labels) $report['methods_set'][$sku] = $labels;
    $report['backups_b64'][$eid] = base64_encode($original);
    $report['totals']['updated']++;

    if ($apply) {
        if ($desc !== $original) {
            // UNHEX keeps pre-existing invalid UTF-8 bytes byte-exact.
            $pdoW->query(
                'UPDATE catalog_product_entity_text SET value = UNHEX(?) WHERE attribute_id = ? AND entity_id = ? AND store_id = 0',
                [bin2hex($desc), $descAid, $eid]
            );
        }
        if ($optIds) {
            $pdoW->query(
                'INSERT INTO ' . $asmtTable . ' (entity_type_id, attribute_id, store_id, entity_id, value)
                 VALUES (4, ?, 0, ?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value)',
                [$asmtAid, $eid, implode(',', $optIds)]
            );
        }
    }
    $p->clearInstance();
}

$reportDir = dirname(__DIR__, 2) . '/media/migrations-reports';
if (!is_dir($reportDir)) @mkdir($reportDir, 0775, true);
$reportPath = $reportDir . '/extract-assessment-methods-' . $mode . '-' . gmdate('Ymd-His') . '.json';
file_put_contents($reportPath, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE) . "\n");

echo "report: $reportPath\n";
foreach ($report['totals'] as $k => $v) { echo "  $k: $v\n"; }
if ($report['manual']) {
    echo "MANUAL REVIEW:\n";
    foreach ($report['manual'] as $s => $r) { echo "  $s: $r\n"; }
}
echo "done\n";
