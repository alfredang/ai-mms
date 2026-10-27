<?php
require dirname(__DIR__,2) . '/app/code/local/MMD/Courses/Model/TmsContract.php';
$data=array('schema_version'=>1,'course_code'=>'C916','course_title'=>'Pilot','source_provider_id'=>'tertiary-sg','source_run_key'=>'calendar:test:event','calendar_id'=>'sales@tertiarycourses.com.sg','website_id'=>1,'revision'=>1,'snapshot_hash'=>str_repeat('a',64),'cancelled'=>false,'roster_complete'=>true,'event_occurrences'=>array('event'),'sessions'=>array(array('key'=>'s1234567','date'=>'2026-10-22','start_time'=>'09:30','end_time'=>'17:30','mode'=>1,'virtual_link'=>'')),'learners'=>array(),'trainers'=>array(),'courseware'=>array(),'feedback_url'=>'');
$checks=0;
function rejects($test,$label) {global $checks;try{MMD_Courses_Model_TmsContract::validate($test);}catch(InvalidArgumentException $e){$checks++;return;}throw new RuntimeException('Failed exclusion: '.$label);}
foreach(array('TGS-2024051900',' tgs-2024051900 ','TGSANY','') as $code){$test=$data;$test['course_code']=$code;rejects($test,'funded/missing code');}
$test=$data;$test['roster_complete']=false;rejects($test,'partial roster');
$test=$data;$test['course_title']=' ';rejects($test,'missing course title');
$test=$data;$test['sessions'][0]['date']='2916-12-23';rejects($test,'invalid future year');
$test=$data;$test['sessions'][0]['date']='2026-02-30';rejects($test,'impossible date');
$test=$data;$test['learners']=array(array('source_id'=>'a','email'=>'one@example.com'),array('source_id'=>'b','email'=>'ONE@example.com'));rejects($test,'duplicate email');
$test=$data;$test['feedback_url']='javascript:alert(1)';rejects($test,'non-HTTP resource');
$test=$data;$test['revision']=0;rejects($test,'invalid revision');
$data['snapshot_hash']=MMD_Courses_Model_TmsContract::contentHash($data);
$valid=MMD_Courses_Model_TmsContract::validate($data);
if($valid['course_code']!=='C916')throw new RuntimeException('Valid snapshot rejected.');
$altered=$data;$altered['cancelled']=true;rejects($altered,'tampered snapshot hash');
echo 'PASS: '.($checks+1)." MMS contract checks\n";
