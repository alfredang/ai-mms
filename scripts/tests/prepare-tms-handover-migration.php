<?php
if(getenv('MMS_HANDOVER_ISOLATED_TEST')!=='1')throw new RuntimeException('Isolated test flag required.');
$root=dirname(__DIR__,2);$xml=simplexml_load_file($root.'/app/etc/local.xml');$c=$xml->global->resources->default_setup->connection;
if((string)$c->host!=='mms-nonfunded-test-mysql'||(string)$c->dbname!=='mms_handover_test')throw new RuntimeException('Fixture DB identity mismatch.');
$pdo=new PDO('mysql:host='.$c->host.';dbname='.$c->dbname.';charset=utf8',(string)$c->username,(string)$c->password,array(PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION));
$pdo->exec('CREATE TABLE IF NOT EXISTS schema_migrations(filename VARCHAR(255) PRIMARY KEY,applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8');
$insert=$pdo->prepare('INSERT IGNORE INTO schema_migrations(filename) VALUES(?)');
foreach(glob($root.'/migrations/*.sql') as $file)if(!in_array(basename($file),array('9999-nonfunded-tms-handover.sql','9999z-nonfunded-class-access.sql','9999zz-nonfunded-access-verification.sql'),true))$insert->execute(array(basename($file)));
// The structural seed predates these existing schema-only migrations.
foreach(array('num_sessions'=>'200-course-runs-add-num-sessions.sql','virtual_link'=>'1829-course-runs-virtual-link-gcal-event.sql','gcal_event_id'=>'1829-course-runs-virtual-link-gcal-event.sql') as $column=>$migration) {
    $exists=$pdo->prepare("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='course_runs' AND column_name=?");$exists->execute(array($column));
    if(!(int)$exists->fetchColumn()){$stmt=$pdo->prepare('DELETE FROM schema_migrations WHERE filename=?');$stmt->execute(array($migration));}
}
$exists=$pdo->query("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='mmd_course_run_attendance' AND column_name='session_key'");
if(!(int)$exists->fetchColumn())$pdo->exec("DELETE FROM schema_migrations WHERE filename='831-attendance-session-key.sql'");
// Remove transports from the disposable fixture before Magento can dispatch anything.
$pdo->exec("DELETE FROM core_config_data WHERE path LIKE '%google%' OR path LIKE '%smtp%' OR path LIKE '%api_key%' OR path LIKE '%refresh_token%'");
echo "Isolated seed prepared; handover and missing schema prerequisites are pending.\n";
