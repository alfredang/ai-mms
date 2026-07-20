<?php
/**
 * One-shot import of order emails into this site's MailerLite subscriber group.
 *
 * The daily cron (mmd_marketing/cron_subscribersync) only picks up NEW orders;
 * this script is the historical backfill you run once per site.
 *
 * Every parameter comes from Company Setting → Integrations → MailerLite
 * (API key, subscriber group, store id) so each franchise site imports its own
 * learners into its own list. Nothing about SG is hardcoded here.
 *
 * Learners who previously unsubscribed / bounced are filtered out and never
 * sent — re-adding an opt-out is a compliance breach, and a subscriber import
 * cannot be undone.
 *
 * Usage (inside the web container):
 *   php scripts/maintenance/mailerlite-import-order-emails.php --since=2026-01-01 --dry-run
 *   php scripts/maintenance/mailerlite-import-order-emails.php --since=2026-01-01
 *
 * Options:
 *   --since=YYYY-MM-DD   only orders created on/after this date (default: all)
 *   --dry-run            resolve + filter, send nothing (ALWAYS run this first)
 *   --group=<id>         override the configured subscriber group
 *   --store=<id>         override the configured store id
 */

require_once dirname(dirname(__DIR__)) . '/app/Mage.php';
Mage::app();

// ---- args ----
$opts   = getopt('', array('since::', 'dry-run', 'group::', 'store::'));
$since  = isset($opts['since']) && $opts['since'] !== '' ? $opts['since'] . ' 00:00:00' : null;
$dryRun = isset($opts['dry-run']);
$group  = isset($opts['group']) && $opts['group'] !== '' ? (string) $opts['group'] : null;
$store  = isset($opts['store']) && $opts['store'] !== '' ? (int) $opts['store']    : null;

$helper = Mage::helper('mmd_marketing/mailerlite');

if (!$helper->isConfigured()) {
    fwrite(STDERR, "ERROR: MailerLite API key not configured.\n"
        . "Set it in Company Setting -> Integrations -> MailerLite.\n");
    exit(1);
}
$resolvedGroup = $group ?: $helper->getSyncGroupId();
if ($resolvedGroup === '') {
    fwrite(STDERR, "ERROR: No subscriber group configured.\n"
        . "Set Company Setting -> Integrations -> MailerLite -> Subscriber Group ID,\n"
        . "or pass --group=<id>. Refusing to guess: importing into the wrong\n"
        . "group cannot be undone.\n");
    exit(1);
}
$resolvedStore = $store === null ? $helper->getSyncStoreId() : $store;

echo "MailerLite order-email import\n";
echo "  store id : {$resolvedStore}\n";
echo "  group id : {$resolvedGroup}\n";
echo "  since    : " . ($since ?: '(all time)') . "\n";
echo "  mode     : " . ($dryRun ? 'DRY RUN (nothing sent)' : 'LIVE') . "\n\n";

if (!$dryRun) {
    echo "Fetching opt-out list and importing — this makes one API call per\n"
       . "subscriber and is rate-limited, so it may take several minutes.\n\n";
}

$t0    = microtime(true);
$stats = $helper->syncOrderEmails($since, $dryRun, $resolvedGroup, $resolvedStore);
$secs  = round(microtime(true) - $t0);

echo "Done in {$secs}s\n";
echo "  candidates           : {$stats['candidates']}\n";
echo "  skipped (opted out)  : {$stats['skipped_suppressed']}\n";
echo "  " . ($dryRun ? 'would add          ' : 'added              ') . "  : {$stats['added']}\n";
echo "  failed               : {$stats['failed']}\n";

if (!empty($stats['errors'])) {
    echo "\nErrors (first " . count($stats['errors']) . "):\n";
    foreach ($stats['errors'] as $e) { echo "  - {$e}\n"; }
}

exit(empty($stats['errors']) || $stats['added'] > 0 ? 0 : 1);
