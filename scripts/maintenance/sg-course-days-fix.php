<?php
/**
 * Singapore course corrections — group approval of 14 Oct 2026 ("single consolidated approval").
 *
 *   C188  2 days / 15 h    C104  2 days / 15 h    C1768 4 days / 30 h    C337  2 days / 15 h (SG ops, 15 Oct)
 *   C428  2 days / 15 h    C1231 2 days / 15 h    C384  2 days / 15 h    C683  2 days / 15 h
 *   C1762 4 days / 30 h    C1394 4 days / 30 h (remove its old 5-day dates)
 *
 * Per course: duration + sessions set; schedule template switched to one with the right number of days
 * (same week + starting weekday where the old one was wrong) via the real admin code path
 * (CoursesaveController::switchScheduleTemplateAction — never raw SQL); then every Course Date value whose
 * number of days does not fit the course is REMOVED (group: no learners/registrations on these courses),
 * valid dates are kept, duplicates removed, orphan rows checked.
 *
 * Usage (inside the Singapore web container):
 *   php scripts/maintenance/sg-course-days-fix.php            REPORT ONLY — changes nothing, prints what would happen
 *   php scripts/maintenance/sg-course-days-fix.php --apply    makes the changes
 *   add --skip=C104,C337 to leave those courses untouched (held for a later run)
 *
 * Safety:
 *   - refuses on any site other than Singapore
 *   - every removed date (value + title + price rows) is copied to table sgfix_removed_dates first
 *   - a date is NEVER removed if any order line for the course contains that date label (it is reported)
 *   - a template is NEVER switched while an order uses one of the course's current dates (course HELD, FAILED=1)
 *   - a date whose backup cannot be written in full is kept
 *   - a value that cannot be read as a date ("TBC", "On request", no title, …) is NEVER removed (it is reported)
 *   - only Course Date values of these 10 courses are touched; past registrations keep their own copy
 * Idempotent: a second --apply finds nothing left to do.
 * Rollback: re-insert rows from sgfix_removed_dates (keeps original option_type_id) + switch template back.
 */
error_reporting(E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_WARNING);
require '/var/www/html/app/Mage.php';
Mage::app('admin');
if (Mage::app()->getDefaultStoreView()->getCode() !== 'singapore') {
    echo "Not the Singapore site — refusing.\n";
    exit(1);
}
$apply = in_array('--apply', $argv, true);
Mage::getSingleton('core/session', array('name' => 'adminhtml'));   // must start before any output
echo $apply ? "=== APPLY MODE — making changes ===\n" : "=== REPORT ONLY — nothing is changed (add --apply to make the changes) ===\n";
require_once Mage::getModuleDir('controllers', 'MMD_RoleManager') . '/Adminhtml/CoursesaveController.php';
$_SERVER['REQUEST_METHOD'] = 'POST';

// sku => [days, duration hours, target template code]
$fix = array(
    'C188'  => array(2, '15',   'B17'),   // was A17 Tues/Sat 4th wk
    'C104'  => array(2, '15',   'B13'),   // was A14 Thurs/Sun 3rd wk
    'C1768' => array(4, '30',   'D03'),   // was C03 Wed-Fri/Sat 3rd wk
    'C337'  => array(2, '15',   'B11'),   // SG ops 15 Oct: 2 days / 15 h — its B11 2-day dates were right, the course length was wrong
    'C428'  => array(2, '15',   'B03'),   // schedule already 2-day on live; sessions was 1
    'C1231' => array(2, '15',   'B03'),   // was A04 Thurs/Sun 1st wk
    'C384'  => array(2, '15',   'B03'),   // was A04 Thurs/Sun 1st wk
    'C683'  => array(2, '15',   'B15'),   // was A15 Fri/Sat 3rd wk
    'C1762' => array(4, '30',   'D03'),   // already 4-day on live (verify only)
    'C1394' => array(4, '30',   'D04'),   // 4-day schedule kept; old 5-day dates removed
);
foreach ($argv as $a) {
    if (strpos($a, '--skip=') === 0) {
        $skip = array_map('strtoupper', array_filter(array_map('trim', explode(',', substr($a, 7)))));
        $fix = array_diff_key($fix, array_flip($skip));
        echo "held (not touched): " . implode(', ', $skip) . "\n";
    }
}

$r0 = Mage::getSingleton('core/resource');
$read = $r0->getConnection('core_read');
$write = $r0->getConnection('core_write');
$t = function ($n) use ($r0) { return $r0->getTableName($n); };
$tOpt = $t('catalog/product_option'); $tOptT = $t('catalog/product_option_title');
$tVal = $t('catalog/product_option_type_value'); $tValT = $t('catalog/product_option_type_title');
$tValP = $t('catalog/product_option_type_price');

$groups = array();
foreach ($read->fetchPairs("SELECT group_id, title FROM custom_options_group WHERE title NOT LIKE '(SG)%'") as $gid => $title) {
    if (preg_match('/^([A-F]\d{2})\b/', trim($title), $m)) {
        $groups[$m[1]] = (int) $gid;
    }
}
$relation = Mage::getResourceSingleton('customoptions/relation');
$attr = function ($code) { return (int) Mage::getSingleton('eav/config')->getAttribute('catalog_product', $code)->getId(); };
$aSes = $attr('sessions');
$aDur = $attr('duration');
$flat = Mage::getResourceSingleton('catalog/product_flat_indexer');

/** Number of training days in a Course Date label (evening classes: 2 evenings = 1 day). */
function labelDays($label)
{
    static $mon = array('Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7,
        'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12);
    $s = trim(preg_replace('/\b(Evening|Morning)\b/i', '', preg_replace('/\(.*$/', '', $label)));
    $s = preg_replace('/\bSept\b/', 'Sep', $s);
    if (preg_match('/^(\d+)\s+([A-Z][a-z]{2})(?:\s+(\d{4}))?\s*-\s*(\d+)\s+([A-Z][a-z]{2})\s+(\d{4})$/', $s, $m)) {
        $a = mktime(0, 0, 0, $mon[$m[2]], (int) $m[1], (int) ($m[3] ?: $m[6]));
        $b = mktime(0, 0, 0, $mon[$m[5]], (int) $m[4], (int) $m[6]);
        $n = (int) round(($b - $a) / 86400) + 1;
    } else {
        $n = 0;
        foreach (explode('/', $s) as $p) {
            if (preg_match('/(\d+)\s*-\s*(\d+)/', $p, $r)) {
                $n += $r[2] - $r[1] + 1;
            } elseif (preg_match('/^\s*(\d{1,2})\b/', $p)) {
                $n++;
            }
        }
    }
    return stripos($label, 'Evening') !== false ? $n / 2 : $n;
}

/** Course Date values of a product: option_type_id => [title, admin_managed, sort_order]. */
$dates = function ($pid) use ($read, $tOpt, $tOptT, $tVal, $tValT) {
    return $read->fetchAssoc(
        "SELECT tv.option_type_id, tt.title, tv.admin_managed, tv.sort_order, tv.option_id
           FROM {$tOpt} o
           JOIN {$tOptT} ot ON ot.option_id = o.option_id AND ot.store_id = 0 AND ot.title = 'Course Date'
           JOIN {$tVal} tv ON tv.option_id = o.option_id
           LEFT JOIN {$tValT} tt ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
          WHERE o.product_id = ? ORDER BY tv.option_id, tv.sort_order, tv.option_type_id", array($pid));
};

if ($apply) {
    $write->query("CREATE TABLE IF NOT EXISTS sgfix_removed_dates (
        option_type_id INT UNSIGNED NOT NULL PRIMARY KEY, option_id INT UNSIGNED NOT NULL, sku VARCHAR(64) NOT NULL,
        reason VARCHAR(32) NOT NULL, title VARCHAR(255) NULL, value_row TEXT NOT NULL, title_rows TEXT NOT NULL,
        price_rows TEXT NOT NULL, removed_at DATETIME NOT NULL) DEFAULT CHARSET=utf8");
}

$failed = 0;
$totals = array('removed' => 0, 'kept' => 0, 'blocked' => 0, 'dupes' => 0, 'unreadable' => 0);
foreach ($fix as $sku => $f) {
    list($days, $hours, $to) = $f;
    $pid = (int) Mage::getModel('catalog/product')->getIdBySku($sku);
    if (!$pid || !isset($groups[$to])) {
        echo "$sku\tFAILED missing product or template $to\n";
        $failed++;
        continue;
    }
    $cur = array();
    foreach ((array) $relation->getGroupIds($pid) as $g) {
        $cur[] = array_search((int) $g, $groups, true);
    }
    $sesNow = $read->fetchOne("SELECT value FROM catalog_product_entity_varchar WHERE entity_id = ? AND attribute_id = ? AND store_id = 0", array($pid, $aSes));
    $durNow = $read->fetchOne("SELECT value FROM catalog_product_entity_varchar WHERE entity_id = ? AND attribute_id = ? AND store_id = 0", array($pid, $aDur));
    echo "\n$sku — target $days day(s) / {$hours} h, template $to | now: duration $durNow, sessions $sesNow, template " . (implode(',', $cur) ?: 'none') . "\n";

    // 1. duration + sessions
    if ($apply) {
        foreach (array($aDur => $hours, $aSes => (string) $days) as $aid => $val) {
            $write->insertOnDuplicate('catalog_product_entity_varchar', array('entity_type_id' => 4, 'attribute_id' => $aid,
                'store_id' => 0, 'entity_id' => $pid, 'value' => $val), array('value'));
            $write->update('catalog_product_entity_varchar', array('value' => $val), array('entity_id = ?' => $pid, 'attribute_id = ?' => $aid));
        }
    }

    // 2. schedule template — the switch drops every date of the old template, so never switch while an
    //    order uses one of the course's current dates (the course is held and reported instead)
    $orderLabels = $read->fetchCol("SELECT product_options FROM sales_flat_order_item WHERE sku = ? OR product_id = ?", array($sku, $pid));
    $isBooked = function ($label) use ($orderLabels) {
        foreach ($orderLabels as $po) {
            // exact label only: order options store it as a quoted string ("4 Oct" must not match "14 Oct")
            if ($label !== '' && strpos((string) $po, '"' . $label . '"') !== false) {
                return true;
            }
        }
        return false;
    };
    if ($cur !== array($to)) {
        $bookedNow = array();
        foreach ($dates($pid) as $d) {
            if ($isBooked(trim((string) $d['title']))) {
                $bookedNow[] = trim((string) $d['title']);
            }
        }
        if ($bookedNow) {
            $failed++;
            echo "  HELD — template NOT switched: an order uses " . implode(' | ', $bookedNow) . " (decide with SG ops, then run again)\n";
            continue;
        }
        if ($apply) {
            $req = new Mage_Core_Controller_Request_Http();
            $req->setParam('course_id', $pid)->setParam('group_id', $groups[$to])
                ->setParam('form_key', Mage::getSingleton('core/session')->getFormKey());
            $res = new Mage_Core_Controller_Response_Http();
            $res->headersSentThrowsException = false;
            $ctl = new MMD_RoleManager_Adminhtml_CoursesaveController($req, $res);
            $ctl->switchScheduleTemplateAction();
            $out = json_decode($res->getBody(), true);
            if (empty($out['success'])) {
                $failed++;
                echo "  template switch FAILED: " . $res->getBody() . "\n";
                continue;
            }
            echo "  template " . implode(',', $cur) . " -> $to (kept " . (int) $out['restored_admin_dates'] . " hand-added dates for checking)\n";
        } else {
            echo "  would switch template " . (implode(',', $cur) ?: 'none') . " -> $to\n";
        }
    }

    // 3. dates whose number of days does not fit; duplicates
    $remove = array();
    $seen = array();
    $kept = 0;
    foreach ($dates($pid) as $vid => $d) {
        $label = trim((string) $d['title']);
        $key = $d['option_id'] . '|' . strtolower(preg_replace('/\s+/', ' ', $label));
        $reason = null;
        // SAFETY: never remove what cannot be read as a date ("TBC", "On request", no title, …) — keep + list it
        if ($label === '' || labelDays($label) <= 0) {
            $totals['unreadable']++;
            $kept++;
            echo "  KEPT (not a readable date — check by hand): " . ($label === '' ? '(no title, option_type_id ' . $vid . ')' : $label) . "\n";
            continue;
        }
        if (labelDays($label) != $days) {
            $reason = labelDays($label) . '-day date';
        } elseif (isset($seen[$key])) {
            $reason = 'duplicate';
            $totals['dupes']++;
        }
        $seen[$key] = true;
        if ($reason === null) {
            $kept++;
            continue;
        }
        if ($isBooked($label)) {
            $totals['blocked']++;
            echo "  KEPT (an order uses it): $label\n";
            continue;
        }
        $remove[$vid] = array($label, $reason, (int) $d['option_id']);
    }
    $totals['kept'] += $kept;
    if (!$apply && $cur !== array($to)) {
        echo "  (dates below are from the CURRENT template; after the switch, only hand-added dates of the wrong length remain to remove)\n";
    }
    if ($remove) {
        $byReason = array();
        foreach ($remove as $r) {
            $byReason[$r[1]][] = $r[0];
        }
        foreach ($byReason as $reason => $labels) {
            echo "  " . ($apply ? 'removed ' : 'would remove ') . count($labels) . " × $reason: " . implode(' | ', array_slice($labels, 0, 5)) . (count($labels) > 5 ? ' …' : '') . "\n";
        }
    }
    echo "  dates kept (correct length): $kept\n";

    if ($apply && $remove) {
        $ids = array();
        foreach ($remove as $vid => $r) {
            $bak = array(
                'value_row'  => json_encode($read->fetchRow("SELECT * FROM {$tVal} WHERE option_type_id = ?", array($vid))),
                'title_rows' => json_encode($read->fetchAll("SELECT * FROM {$tValT} WHERE option_type_id = ?", array($vid))),
                'price_rows' => json_encode($read->fetchAll("SELECT * FROM {$tValP} WHERE option_type_id = ?", array($vid))),
            );
            if (in_array(false, $bak, true)) {   // backup could not be written in full — keep the date
                echo "  KEPT (backup failed — check by hand): {$r[0]}\n";
                continue;
            }
            $write->insertIgnore('sgfix_removed_dates', array(
                'option_type_id' => $vid, 'option_id' => $r[2], 'sku' => $sku, 'reason' => $r[1], 'title' => $r[0],
                'removed_at' => gmdate('Y-m-d H:i:s'),
            ) + $bak);
            $ids[] = $vid;
        }
        // only rows saved in the backup table are removed
        $saved = !$ids ? array() : array_map('intval', $read->fetchCol("SELECT option_type_id FROM sgfix_removed_dates WHERE option_type_id IN (" . implode(',', array_map('intval', $ids)) . ")"));
        if ($saved) {
            $in = implode(',', $saved);
            $write->query("DELETE FROM {$tValP} WHERE option_type_id IN ($in)");
            $write->query("DELETE FROM {$tValT} WHERE option_type_id IN ($in)");
            $write->query("DELETE FROM {$tVal} WHERE option_type_id IN ($in)");
        }
        $totals['removed'] += count($saved);
    }

    if ($apply) {
        Mage::getResourceModel('catalog/product_indexer_price')->reindexProductIds(array($pid));
        foreach (Mage::app()->getStores() as $s) {
            $flat->updateProduct($pid, (int) $s->getId());
        }
    }
}

// 4. orphans on these courses: title/price rows without a value, values without an option
$pids = array();
foreach (array_keys($fix) as $sku) {
    $p = (int) Mage::getModel('catalog/product')->getIdBySku($sku);
    if ($p) {
        $pids[] = $p;
    }
}
$in = $pids ? implode(',', $pids) : '0';
$hasBak = $read->isTableExists('sgfix_removed_dates');
$orph = array(
    'removed dates still having a title row' => !$hasBak ? 0 : (int) $read->fetchOne(
        "SELECT COUNT(*) FROM {$tValT} WHERE option_type_id IN (SELECT option_type_id FROM sgfix_removed_dates)"),
    'removed dates still having a price row' => !$hasBak ? 0 : (int) $read->fetchOne(
        "SELECT COUNT(*) FROM {$tValP} WHERE option_type_id IN (SELECT option_type_id FROM sgfix_removed_dates)"),
    'dates of these courses without a title' => (int) $read->fetchOne(
        "SELECT COUNT(*) FROM {$tOpt} o JOIN {$tVal} v ON v.option_id = o.option_id
           LEFT JOIN {$tValT} tt ON tt.option_type_id = v.option_type_id AND tt.store_id = 0
          WHERE o.product_id IN ($in) AND tt.option_type_id IS NULL"),
    'Course Date options with no dates (these courses)' => (int) $read->fetchOne(
        "SELECT COUNT(*) FROM {$tOpt} o JOIN {$tOptT} ot ON ot.option_id = o.option_id AND ot.store_id = 0 AND ot.title = 'Course Date'
          WHERE o.product_id IN ($in) AND NOT EXISTS (SELECT 1 FROM {$tVal} v WHERE v.option_id = o.option_id)"),
);
if ($apply) {
    Mage::app()->cleanCache();
}
echo "\n=== Summary ===\n";
echo ($apply ? "dates removed: " : "dates that would be removed (current templates): ") . ($apply ? $totals['removed'] : '(see per course)') . "\n";
echo "valid dates kept: {$totals['kept']}   duplicates found: {$totals['dupes']}   kept because an order uses them: {$totals['blocked']}   kept because not a readable date: {$totals['unreadable']}\n";
foreach ($orph as $k => $n) {
    echo "orphan check — $k: $n\n";
}
echo $failed ? "FAILED=$failed\n" : ($apply ? "all done\n" : "report only — run again with --apply to make the changes\n");
exit($failed ? 1 : 0);
