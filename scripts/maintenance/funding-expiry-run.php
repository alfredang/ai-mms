<?php
/**
 * Run the daily funding-expiry check now (same code as the 11:00 cron job
 * MMD_Courses_Model_Cron_FundingExpiry). Run in the web container as www-data:
 *   php scripts/maintenance/funding-expiry-run.php            # dry run: list only
 *   php scripts/maintenance/funding-expiry-run.php --apply    # switch the templates
 */
require_once dirname(__FILE__) . '/../../app/Mage.php';
Mage::app('admin');

$apply = in_array('--apply', $argv, true);
$rows  = Mage::getModel('courses/cron_fundingExpiry')->run(!$apply);
foreach ($rows as $r) {
    echo implode("\t", array($r['action'], $r['sku'], $r['from'], '->', $r['to'], $r['name'], $r['note'])), "\n";
}
echo count($rows), ' course(s)', $apply ? '' : ' (dry run, nothing changed)', "\n";
