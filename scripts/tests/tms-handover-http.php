<?php
/** HTTP route/auth smoke test against the isolated API container only. */
if(getenv('MMS_HANDOVER_ISOLATED_TEST')!=='1')throw new RuntimeException('Isolated test flag required.');
$root=dirname(__DIR__,2);$xml=simplexml_load_file($root.'/app/etc/local.xml');$c=$xml->global->resources->default_setup->connection;
if((string)$c->host!=='mms-nonfunded-test-mysql'||(string)$c->dbname!=='mms_handover_test')throw new RuntimeException('Fixture DB identity mismatch.');
$pdo=new PDO('mysql:host='.$c->host.';dbname='.$c->dbname.';charset=utf8',(string)$c->username,(string)$c->password,array(PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION));
$config=$pdo->prepare("INSERT INTO core_config_data(scope,scope_id,path,value) VALUES('default',0,?,?) ON DUPLICATE KEY UPDATE value=VALUES(value)");
foreach(array('enabled'=>'1','api_key'=>'isolated-http-test-key','course_allowlist'=>'C916','provider_id'=>'tertiary-sg','calendar_id'=>'sales@tertiarycourses.com.sg','website_id'=>'1') as $key=>$value)$config->execute(array('mmd/tms_handover/'.$key,$value));
$pdo->exec("UPDATE core_config_data SET value='http://mms-nonfunded-test-api:8080/' WHERE path IN ('web/unsecure/base_url','web/secure/base_url')");
if(in_array('--prepare',$argv,true)){require $root.'/app/Mage.php';Mage::app('admin')->cleanCache();echo "Isolated HTTP fixture configured.\n";exit(0);}
require $root.'/app/code/local/MMD/Courses/Model/TmsContract.php';
function request($body,$key='isolated-http-test-key',$method='POST'){
    $curl=curl_init('http://mms-nonfunded-test-api:8080/courses/api_tms_import');
    curl_setopt_array($curl,array(CURLOPT_CUSTOMREQUEST=>$method,CURLOPT_POSTFIELDS=>$body,CURLOPT_HTTPHEADER=>array('Content-Type: application/json','X-API-Key: '.$key),CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>30));
    $raw=curl_exec($curl);$code=curl_getinfo($curl,CURLINFO_HTTP_CODE);$error=curl_error($curl);curl_close($curl);
    return array($code,json_decode((string)$raw,true),$error,substr((string)$raw,0,300));
}
$checks=0;
foreach(array(array('{}','',401),array('{}','wrong',401),array('{','isolated-http-test-key',400),array('{"course_code":" tgs-123 "}','isolated-http-test-key',422)) as $test){
    $result=request($test[0],$test[1]);if($result[0]!==$test[2])throw new RuntimeException('Unexpected route status '.json_encode($result));$checks++;
}
$data=array('schema_version'=>1,'course_code'=>'C916','source_provider_id'=>'tertiary-sg','source_run_key'=>'calendar:test:http-preview','calendar_id'=>'sales@tertiarycourses.com.sg','website_id'=>1,'revision'=>1,'cancelled'=>false,'roster_complete'=>true,'event_occurrences'=>array('http-event'),'sessions'=>array(array('key'=>'s1234567','date'=>'2027-01-10','start_time'=>'09:30','end_time'=>'17:30','mode'=>1,'virtual_link'=>'')),'learners'=>array(),'trainers'=>array(),'courseware'=>array(),'feedback_url'=>'','dry_run'=>true);
$data['snapshot_hash']=MMD_Courses_Model_TmsContract::contentHash($data);
$before=(int)$pdo->query('SELECT COUNT(*) FROM course_runs')->fetchColumn();$result=request(json_encode($data));
if($result[0]!==200||empty($result[1]['dry_run'])||(int)$pdo->query('SELECT COUNT(*) FROM course_runs')->fetchColumn()!==$before)throw new RuntimeException('HTTP dry run failed: '.json_encode($result));
echo 'PASS: '.($checks+1)." MMS HTTP route/auth/dry-run checks\n";
