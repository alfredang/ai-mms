<?php
if (getenv('MMS_HANDOVER_ISOLATED_TEST') !== '1') throw new RuntimeException('Isolated fixture required.');
$root=dirname(__DIR__,2); $xml=simplexml_load_file($root.'/app/etc/local.xml');
if ((string)$xml->global->resources->default_setup->connection->dbname !== 'mms_handover_test') throw new RuntimeException('Wrong fixture database.');
require $root.'/app/Mage.php'; Mage::app('admin');
$w=Mage::getSingleton('core/resource')->getConnection('core_write'); $checks=0;
function verifyMirror($ok,$label) { global $checks; if (!$ok) throw new RuntimeException($label); $checks++; }
function sendMirror($service,$data) { $data['snapshot_hash']=MMD_Courses_Model_TmsContract::contentHash($data); return $service->apply($data); }
foreach (array('provider_id'=>'tertiary-sg','website_id'=>'1','course_allowlist'=>'','access_verified'=>'0','public_origin'=>'http://localhost:18089') as $key=>$value) Mage::app()->getStore()->setConfig('mmd/tms_handover/'.$key,$value);
Mage::getConfig()->setNode('global/events/customer_save_before/observers/mmd_email_validate_customer/type','disabled');
$productId=(int)$w->fetchOne("SELECT entity_id FROM catalog_product_entity WHERE sku='C916'");
if (!$productId) { $w->insert('catalog_product_entity',array('entity_type_id'=>4,'attribute_set_id'=>4,'type_id'=>'simple','sku'=>'C916','has_options'=>0,'required_options'=>0)); $productId=(int)$w->lastInsertId(); $w->insert('catalog_product_website',array('product_id'=>$productId,'website_id'=>1)); }
$svc=Mage::getModel('courses/tmsImport');
verifyMirror(Mage::getModel('courses/tmsMirror') instanceof MMD_Courses_Model_TmsMirror,'Mirror model alias must instantiate.');
$data=array('schema_version'=>2,'source_provider_id'=>'tertiary-sg','source_run_key'=>'masterlist:pending-test','website_id'=>1,'course_code'=>'C916','course_title'=>'Independent LMS title','calendar_id'=>'masterlist','event_occurrences'=>array(),'revision'=>1,'request_id'=>'test','snapshot_hash'=>'','roster_complete'=>false,'cancelled'=>false,'class_start_date'=>null,'class_end_date'=>null,'sessions'=>array(),'learners'=>array(),'trainers'=>array(),'pending_learners'=>array(array('source_id'=>'pending','email'=>'','name'=>'Pending Learner')),'pending_trainers'=>array(),'courseware'=>array(),'feedback_url'=>'');
$first=sendMirror($svc,$data); $runId=$first['run_id'];
verifyMirror($first['success'] && $first['readiness']==='incomplete','Empty pending class must synchronize.');
verifyMirror(count($first['pending_learners'])===1,'Incomplete learner details must be retained.');
verifyMirror(sendMirror($svc,$data)['run_id']===$runId,'Undated retry must reuse class.');
$data['revision']=2; $data['class_start_date']='2020-10-20'; $data['class_end_date']='2099-11-11';
$updated=sendMirror($svc,$data);
verifyMirror($updated['run_id']===$runId,'Ongoing class begun before old pilot cutoff must synchronize.');
verifyMirror($w->fetchOne('SELECT course_start_date FROM course_runs WHERE run_id=?',array($runId))==='2020-10-20','LMS start date must replace MMS date.');
$w->update('course_runs',array('gcal_event_id'=>'different-calendar','course_start_time'=>'08:00','course_end_time'=>'15:00','trainer_user_id'=>1),array('run_id = ?'=>$runId));
$w->insert('course_run_enrolments',array('product_id'=>$productId,'run_id'=>$runId,'learner_email'=>'directmirror@example.com','learner_name'=>'Native MMS Learner'));
$data['revision']=3; $data['learners']=array(array('source_id'=>'email:mirrortest@example.com','email'=>'mirrortest@example.com','name'=>'LMS Learner')); $data['roster_complete']=true; $data['pending_learners']=array();
$result=sendMirror($svc,$data);
verifyMirror($result['success'],'Native membership and Calendar differences must not block synchronization.');
verifyMirror($w->fetchOne('SELECT trainer_user_id FROM course_runs WHERE run_id=?',array($runId))===null,'Unassigned LMS trainer must clear MMS trainer.');
verifyMirror(in_array('directmirror@example.com',array_column($result['native_registrations'],'email'),true),'Direct MMS registration must be returned to LMS.');
verifyMirror(!in_array('mirrortest@example.com',array_column($result['native_registrations'],'email'),true),'LMS-origin membership must not echo as a native registration.');
// A second Master List source, different title and time, must adopt the same date-range class.
$other=$data; $other['source_run_key']='masterlist:duplicate-test'; $other['revision']=1; $other['course_title']='Another unchanged title';
$adopt=sendMirror($svc,$other);
verifyMirror($adopt['run_id']===$runId,'Code/date identity must reuse class across different source/Calendar/title/time.');
$data['revision']=4; $data['trainers']=array(array('source_id'=>'trainer-mirror-a','email'=>'mirrora@example.com','name'=>'Trainer A','confirmed'=>true),array('source_id'=>'trainer-mirror-b','email'=>'mirrorb@example.com','name'=>'Trainer B','confirmed'=>true));
$assigned=sendMirror($svc,$data);
verifyMirror(count($assigned['trainer_user_ids'])===2,'Multiple LMS trainers must synchronize without conflict gate.');
verifyMirror((int)$w->fetchOne('SELECT trainer_user_id FROM course_runs WHERE run_id=?',array($runId))===$assigned['trainer_user_ids'][0],'LMS trainer must replace MMS trainer.');
verifyMirror(Mage::helper('mmd_rolemanager/handover')->canAccessRun($runId,'trainer',$assigned['trainer_user_ids'][1],'mirrorb@example.com'),'Additional LMS trainer must have class access.');
$native=Mage::getModel('mmd_rolemanager/courseRunEnrolmentService'); $method=new ReflectionMethod($native,'_findOrCreateRun'); $method->setAccessible(true);
verifyMirror($method->invoke($native,$productId,'C916','2020-10-20','2099-11-11','11:00','19:00',Mage::getModel('sales/order_item'))===$runId,'Native registration must reuse mirrored class despite differing session times.');
$invalid=$data; $invalid['revision']=5; $invalid['course_code']='TGS-123';
try { sendMirror($svc,$invalid); throw new RuntimeException('Funded snapshot accepted.'); } catch (InvalidArgumentException $e) { $checks++; }
$invalid=$data; $invalid['revision']=1;
try { sendMirror($svc,$invalid); throw new RuntimeException('Stale revision accepted.'); } catch (InvalidArgumentException $e) { $checks++; }
verifyMirror($w->fetchOne('SELECT learner_name FROM course_run_enrolments WHERE run_id=? AND learner_email=?',array($runId,'directmirror@example.com'))==='Native MMS Learner','Reverse reconciliation must preserve native membership.');
// Existing duplicate native classes with different times do not block matching.
$nativeIds=array();
foreach (array('SG990101','SG990102') as $i=>$classId) {
    $w->insert('course_runs',array('class_id'=>$classId,'product_id'=>$productId,'course_sku'=>'C916','course_start_date'=>'2097-11-10','course_end_date'=>'2097-11-11','course_start_time'=>$i?'10:00':'08:00','course_end_time'=>'17:00','gcal_event_id'=>'native-different-'.$i,'created_by'=>'Isolated native fixture'));
    $nativeIds[]=(int)$w->lastInsertId();
    $w->insert('course_run_enrolments',array('product_id'=>$productId,'run_id'=>$nativeIds[$i],'learner_email'=>'duplicatenative'.$i.'@example.com','learner_name'=>'Native duplicate '.$i));
}
$before=(int)$w->fetchOne('SELECT COUNT(*) FROM course_runs');
$native=$data;$native['source_run_key']='masterlist:native-date-match';$native['revision']=1;$native['class_start_date']='2097-11-10';$native['class_end_date']='2097-11-11';$native['trainers']=array();
$matched=sendMirror($svc,$native);
verifyMirror($matched['run_id']===$nativeIds[0],'Existing native class must match code/date regardless of time, title or Calendar.');
verifyMirror((int)$w->fetchOne('SELECT COUNT(*) FROM course_runs')===$before,'Matching a native class must not create another duplicate.');
verifyMirror(count($matched['native_registrations'])===2,'Native registrations across duplicate date-matching classes must consolidate.');
$blocked=Mage::getModel('admin/user')->setData(array('username'=>'blockedmirror@example.com','email'=>'blockedmirror@example.com','firstname'=>'Blocked','lastname'=>'Fixture','password'=>'synthetic-blocked-only','is_active'=>0));$blocked->save();
$native['revision']=2;$native['learners'][]=array('source_id'=>'blocked-mirror','email'=>'blockedmirror@example.com','name'=>'Blocked Fixture');
$blockedResult=sendMirror($svc,$native);
verifyMirror($blockedResult['success'] && count($blockedResult['pending_learners'])===1,'A blocked participant account must not block class/roster synchronization.');
verifyMirror((int)$w->fetchOne('SELECT is_active FROM admin_user WHERE user_id=?',array($blocked->getId()))===0,'Synchronization must not reactivate a blocked account.');
verifyMirror((int)$w->fetchOne('SELECT COUNT(*) FROM course_run_enrolments WHERE run_id=? AND learner_email=?',array($nativeIds[0],'blockedmirror@example.com'))===1,'Pending account provisioning must retain the authoritative roster entry.');
echo 'PASS: '.$checks." Master List MMS integration checks\n";
