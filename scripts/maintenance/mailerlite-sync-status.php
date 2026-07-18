<?php
/**
 * "Did the daily MailerLite sync actually run, and did emails really land?"
 *
 * Reads the status the 4am cron records, then INDEPENDENTLY verifies against
 * the MailerLite API — because a cron that reports success while the API
 * silently rejects everything is the exact failure this script exists to catch.
 *
 * Usage (inside the web container):
 *   php scripts/maintenance/mailerlite-sync-status.php
 *   php scripts/maintenance/mailerlite-sync-status.php --verify=5
 *
 * Options:
 *   --verify=N   sample the N most recent order emails and ask MailerLite
 *                whether each one actually exists in the group (default 5;
 *                use 0 to skip the live check)
 *
 * Exit code 0 = healthy, 1 = something needs attention (usable from a monitor).
 */

require_once dirname(dirname(__DIR__)) . '/app/Mage.php';
Mage::app();

$opts   = getopt('', array('verify::'));
$verify = isset($opts['verify']) ? (int) $opts['verify'] : 5;

$helper = Mage::helper('mmd_marketing/mailerlite');
$warn   = array();

echo "MailerLite subscriber sync — status\n";
echo str_repeat('=', 52) . "\n";

// ---- 1. configuration ----
$enabled = $helper->isSyncEnabled();
$group   = $helper->getSyncGroupId();
echo "enabled  : " . ($enabled ? 'yes' : 'NO — daily sync is switched off') . "\n";
echo "api key  : " . ($helper->isConfigured() ? 'configured' : 'MISSING') . "\n";
echo "group    : " . ($group !== '' ? $group : 'NOT SET — sync refuses to run') . "\n";
echo "store    : " . $helper->getSyncStoreId() . "\n";
if (!$enabled)                 { $warn[] = 'daily sync is disabled'; }
if (!$helper->isConfigured())  { $warn[] = 'API key not configured'; }
if ($group === '')             { $warn[] = 'no subscriber group configured'; }

// ---- 2. last run ----
$lastRun = trim((string) Mage::getStoreConfig('mmd_marketing/mailerlite/subscriber_sync_last_run'));
$raw     = trim((string) Mage::getStoreConfig('mmd_marketing/mailerlite/subscriber_sync_last_status'));
$status  = $raw !== '' ? json_decode($raw, true) : null;

echo "\nlast run : " . ($lastRun !== '' ? $lastRun : 'NEVER') . "\n";
if ($lastRun === '') {
    $warn[] = 'the cron has never completed a run';
} else {
    $ageHours = (time() - strtotime($lastRun)) / 3600;
    printf("age      : %.1f hours\n", $ageHours);
    // 4am daily → anything past ~26h means a run was missed.
    if ($ageHours > 26) { $warn[] = sprintf('last run was %.0fh ago — a daily run was missed', $ageHours); }
}

if (is_array($status)) {
    echo "result   : " . (!empty($status['ok']) ? 'OK' : 'FAILED') . "\n";
    foreach (array('candidates', 'added', 'skipped_suppressed', 'failed') as $k) {
        if (isset($status[$k])) { printf("  %-19s %d\n", $k, $status[$k]); }
    }
    if (!empty($status['error']))  { echo "  error: " . $status['error'] . "\n"; $warn[] = 'last run errored'; }
    if (!empty($status['errors'])) {
        foreach ($status['errors'] as $e) { echo "  - " . $e . "\n"; }
    }
}

// ---- 3. independent verification against the API ----
if ($verify > 0 && $helper->isConfigured() && $group !== '') {
    echo "\nverifying the {$verify} most recent order emails against MailerLite:\n";
    $conn = Mage::getSingleton('core/resource')->getConnection('core_read');
    $rows = $conn->fetchAll(
        "SELECT DISTINCT LOWER(TRIM(customer_email)) AS email, created_at"
        . " FROM " . Mage::getSingleton('core/resource')->getTableName('sales/order')
        // LIMIT cannot take a bound placeholder under PDO — cast and inline it.
        . " WHERE store_id = ? AND customer_email <> '' ORDER BY created_at DESC"
        . " LIMIT " . (int) $verify,
        array($helper->getSyncStoreId())
    );
    if (!$rows) {
        echo "  (no orders found)\n";
    }
    $missing = 0;
    foreach ($rows as $r) {
        $found = $helper->findSubscriber($r['email']);
        if ($found === null) {
            echo "  MISSING     {$r['email']}  (ordered {$r['created_at']})\n";
            $missing++;
        } else {
            $st     = isset($found['status']) ? $found['status'] : '?';
            $inGrp  = false;
            if (!empty($found['groups'])) {
                foreach ($found['groups'] as $g) {
                    if ((string) $g['id'] === (string) $group) { $inGrp = true; break; }
                }
            }
            printf("  %-11s %s  (status=%s)\n", $inGrp ? 'IN GROUP' : 'not in grp', $r['email'], $st);
            // Unsubscribed people are CORRECTLY absent from the group — not a fault.
            if (!$inGrp && $st !== 'unsubscribed') { $missing++; }
        }
    }
    if ($missing > 0) {
        $warn[] = $missing . ' recent order email(s) are not in the group';
    }
}

// ---- verdict ----
echo "\n" . str_repeat('=', 52) . "\n";
if ($warn) {
    echo "NEEDS ATTENTION:\n";
    foreach ($warn as $w) { echo "  - {$w}\n"; }
    exit(1);
}
echo "Healthy — the sync ran recently and recent order emails are in the group.\n";
exit(0);
