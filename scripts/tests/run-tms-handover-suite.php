<?php
if (getenv('MMS_HANDOVER_ISOLATED_TEST') !== '1') throw new RuntimeException('Isolated test flag required.');
$root=dirname(__DIR__,2);$xml=simplexml_load_file($root.'/app/etc/local.xml');$c=$xml->global->resources->default_setup->connection;
if ((string)$c->host!=='mms-nonfunded-test-mysql' || (string)$c->dbname!=='mms_handover_test') throw new RuntimeException('Fixture DB identity mismatch.');
$steps=array(
    array('scripts/tests/prepare-tms-handover-migration.php'),
    array('migrations/apply.php'),
    array('migrations/apply.php'),
    array('scripts/tests/tms-handover-contract.php'),
    array('scripts/tests/tms-handover-integration.php'),
    array('scripts/tests/tms-handover-http.php','--prepare'),
    array('scripts/tests/tms-handover-http.php'),
    array('scripts/tests/tms-class-access-integration.php')
);
foreach ($steps as $step) {
    $file=array_shift($step);
    echo 'CHECK: '.$file."\n";
    $command=escapeshellarg(PHP_BINARY).' '.escapeshellarg($root.'/'.$file);
    foreach ($step as $arg) $command.=' '.escapeshellarg($arg);
    passthru($command,$status);
    if ($status!==0) exit($status);
}
echo "PASS: Complete isolated MMS handover suite\n";
