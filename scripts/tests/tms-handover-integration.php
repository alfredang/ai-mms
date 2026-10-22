<?php
/** Run only on the isolated mms_handover_test fixture DB with external networking disabled. */
if (getenv('MMS_HANDOVER_ISOLATED_TEST') !== '1') throw new RuntimeException('Isolated test flag required.');
$root=dirname(__DIR__,2);
$xml=simplexml_load_file($root.'/app/etc/local.xml');
$connection=$xml->global->resources->default_setup->connection;
if((string)$connection->host!=='mms-nonfunded-test-mysql' || (string)$connection->dbname!=='mms_handover_test')throw new RuntimeException('Test DB identity mismatch.');
require $root.'/app/Mage.php';
Mage::app('admin');
$r=Mage::getSingleton('core/resource');$w=$r->getConnection('core_write');
$checks=0;
function check($condition,$message){global $checks;if(!$condition)throw new RuntimeException($message);$checks++;}
function applySnapshot($service,array $data){$data['snapshot_hash']=MMD_Courses_Model_TmsContract::contentHash($data);return $service->apply($data);}
function previewSnapshot($service,array $data){$data['snapshot_hash']=MMD_Courses_Model_TmsContract::contentHash($data);return $service->preview($data);}
foreach(array('course_allowlist'=>'C916','provider_id'=>'tertiary-sg','website_id'=>'1','calendar_id'=>'sales@tertiarycourses.com.sg','access_verified'=>'1','public_origin'=>'http://localhost:18089') as $key=>$value) {
    Mage::getConfig()->saveConfig('mmd/tms_handover/'.$key,$value);
    Mage::app()->getStore()->setConfig('mmd/tms_handover/'.$key,$value);
}
$w->query("UPDATE core_config_data SET value='http://localhost:18089/' WHERE path IN ('web/unsecure/base_url','web/secure/base_url')");
foreach(array('web/unsecure/base_url'=>'http://localhost:18089/','web/secure/base_url'=>'http://localhost:18089/','web/secure/use_in_adminhtml'=>'0','web/secure/use_in_frontend'=>'0') as $key=>$value) { Mage::getConfig()->saveConfig($key,$value);Mage::app()->getStore()->setConfig($key,$value); }
Mage::getConfig()->reinit();
// The test network has no public DNS. Only the isolated test process disables
// the external MX lookup; production keeps the normal email validation observer.
Mage::getConfig()->setNode('global/events/customer_save_before/observers/mmd_email_validate_customer/type','disabled');
$productId=(int)$w->fetchOne("SELECT entity_id FROM catalog_product_entity WHERE sku='C916'");
if(!$productId){$w->insert('catalog_product_entity',array('entity_type_id'=>4,'attribute_set_id'=>4,'type_id'=>'simple','sku'=>'C916','has_options'=>0,'required_options'=>0));$productId=(int)$w->lastInsertId();$w->insert('catalog_product_website',array('product_id'=>$productId,'website_id'=>1));}
$learner=array('source_id'=>'test-learner','email'=>'pilotlearner@example.com','name'=>'Pilot Learner');
$trainer=array('source_id'=>'test-trainer','email'=>'pilottrainer@example.com','name'=>'Pilot Trainer','confirmed'=>true);
$data=array('schema_version'=>1,'source_provider_id'=>'tertiary-sg','source_run_key'=>'calendar:test:pilot','website_id'=>1,'course_code'=>'C916','course_title'=>'Pilot','calendar_id'=>'sales@tertiarycourses.com.sg','event_occurrences'=>array('pilot-event'),'revision'=>1,'request_id'=>'test-request','snapshot_hash'=>hash('sha256','version1'),'roster_complete'=>true,'cancelled'=>false,'sessions'=>array(array('key'=>'s1234567','source_id'=>'pilot-event','date'=>'2026-11-10','start_time'=>'09:30','end_time'=>'17:30','mode'=>1,'virtual_link'=>'','venue'=>'Room 1')),'learners'=>array($learner),'trainers'=>array($trainer),'courseware'=>array('learner_guide_url'=>'https://example.com/guide','trainer_slides_url'=>'https://example.com/slides'),'feedback_url'=>'https://example.com/feedback/pilot');
$data['handover_approval']=array('approved_at'=>'2026-10-21T00:00:00Z','approved_by'=>'isolated-operator','first_session_at'=>'2026-11-10T01:30:00.000Z');
$svc=Mage::getModel('courses/tmsImport');
check($svc instanceof MMD_Courses_Model_TmsImport,'Importer alias did not instantiate.');
$before=(int)$w->fetchOne('SELECT COUNT(*) FROM course_runs');$beforeUsers=(int)$w->fetchOne('SELECT COUNT(*) FROM admin_user');
$preview=previewSnapshot($svc,$data);
check($preview['action']==='create' && (int)$w->fetchOne('SELECT COUNT(*) FROM course_runs')===$before && (int)$w->fetchOne('SELECT COUNT(*) FROM admin_user')===$beforeUsers,'Dry run wrote class/account data.');
$w->insert('course_runs',array('class_id'=>'C990001','product_id'=>$productId,'course_sku'=>'C916','course_start_date'=>'2026-11-10','course_end_date'=>'2026-11-10','course_start_time'=>'09:30','course_end_time'=>'17:30','created_by'=>'Isolated fixture'));
$nativeRun=(int)$w->lastInsertId();check(previewSnapshot($svc,$data)['action']==='adopt','Existing class was not recognized during dry run.');
// Broad normal-operations scope is still C-only; funded validation precedes it.
Mage::app()->getStore()->setConfig('mmd/tms_handover/course_allowlist','C*');
check(previewSnapshot($svc,$data)['action']==='adopt','C* normal-operations scope did not accept the supported C course.');
try{previewSnapshot($svc,array_merge($data,array('course_code'=>'TGS-123')));throw new RuntimeException('C* scope accepted a funded course.');}catch(InvalidArgumentException $e){$checks++;}
$w->update('course_runs',array('gcal_event_id'=>'another-event'),array('run_id = ?'=>$nativeRun));
try{previewSnapshot($svc,$data);throw new RuntimeException('Preview adopted a conflicting Calendar event.');}catch(InvalidArgumentException $e){$checks++;}
try{applySnapshot($svc,$data);throw new RuntimeException('Import adopted a conflicting Calendar event.');}catch(InvalidArgumentException $e){$checks++;}
check((int)$w->fetchOne('SELECT COUNT(*) FROM mmd_tms_run_link')===0 && (int)$w->fetchOne('SELECT COUNT(*) FROM admin_user')===$beforeUsers,'Rejected duplicate changed accounts or source mappings.');
$w->update('course_runs',array('gcal_event_id'=>'pilot-event'),array('run_id = ?'=>$nativeRun));
$first=applySnapshot($svc,$data);$runId=$first['run_id'];
check($runId===$nativeRun && $first['class_id']==='C990001','Existing MMS class identity was not preserved.');
$nativeService=Mage::getModel('mmd_rolemanager/courseRunEnrolmentService');$findNative=new ReflectionMethod($nativeService,'_findOrCreateRun');$findNative->setAccessible(true);
$reusedNative=$findNative->invoke($nativeService,$productId,'C916','2026-11-10','2026-11-10','09:30','17:30',Mage::getModel('sales/order_item'));
check($reusedNative===$runId && (int)$w->fetchOne("SELECT IS_FREE_LOCK('mmd-class-id')")===1,'Native materialization did not reuse the imported class or release its allocator lock.');
check($first['success'] && $first['learners_added']===1,'First class/learner import failed.');
check((int)$w->fetchOne('SELECT COUNT(*) FROM course_run_enrolments WHERE run_id=?',array($runId))===1,'Roster count is incorrect.');
$replay=applySnapshot($svc,$data);check($replay['replayed']===true && $replay['run_id']===$runId,'Replay created another class.');
$learnerUser=(int)$w->fetchOne("SELECT user_id FROM admin_user WHERE email='pilotlearner@example.com'");
$trainerUser=(int)$w->fetchOne("SELECT user_id FROM admin_user WHERE email='pilottrainer@example.com'");
check($learnerUser>0 && $trainerUser>0,'Dashboard accounts were not provisioned.');
check((int)$w->fetchOne('SELECT trainer_user_id FROM course_runs WHERE run_id=?',array($runId))===$trainerUser,'Trainer account not assigned to run.');
$h=Mage::helper('mmd_rolemanager/handover');
check($h->canAccessRun($runId,'learner',$learnerUser,$learner['email']), 'Enrolled learner cannot access run.');
check(!$h->canAccessRun($runId,'learner',999,'other@example.com'),'Unrelated learner can access run.');
check($h->feedbackUrl($runId,'https://native.example/form')===$data['feedback_url'],'TMS feedback not adopted.');
check(Mage::getModel('mmd_rolemanager/cron_googleCalendarSync')->sync(true,$runId)!==null,'Calendar model did not instantiate.');
$invite=Mage::getModel('mmd_rolemanager/trainerInvitationService')->sendNextInvitation($runId);
check(!$invite['success'] && strpos($invite['message'],'TMS owns')!==false,'MMS attempted a duplicate trainer invitation.');
$password=$w->fetchOne('SELECT password FROM admin_user WHERE user_id=?',array($trainerUser));
$w->delete('course_run_enrolments',array('run_id = ?'=>$runId,'learner_email = ?'=>$learner['email']));
$restored=applySnapshot($svc,$data);
check($restored['replayed'] && $restored['learners_added']===1 && $restored['run_id']===$runId,'Same-revision retry did not reconcile a missing target enrolment.');
check($password===$w->fetchOne('SELECT password FROM admin_user WHERE user_id=?',array($trainerUser)),'Replay changed an existing password.');
Mage::app()->getStore()->setConfig('mmd/tms_handover/access_verified','0');
$unverified=applySnapshot($svc,$data);check($unverified['readiness']==='incomplete','Replay returned stale access readiness.');
Mage::app()->getStore()->setConfig('mmd/tms_handover/access_verified','1');
$verified=applySnapshot($svc,$data);check($verified['readiness']==='ready','Replay did not refresh corrected access readiness.');
$data['revision']=2;$data['snapshot_hash']=hash('sha256','version2');$data['learners'][]=array('source_id'=>'test-trainer','email'=>$trainer['email'],'name'=>$trainer['name']);
applySnapshot($svc,$data);check($password===$w->fetchOne('SELECT password FROM admin_user WHERE user_id=?',array($trainerUser)),'Adding learner role overwrote existing trainer password.');
$data['revision']=3;$data['snapshot_hash']=hash('sha256','version3');$data['learners']=array();
$removed=applySnapshot($svc,$data);check($removed['learners_removed']===2,'TMS withdrawals did not reconcile.');
check((int)$w->fetchOne('SELECT COUNT(*) FROM mmd_tms_member_link WHERE active=0')===2,'Withdrawal provenance was lost.');
try{applySnapshot($svc,array_merge($data,array('course_code'=>' tgs-123 ')));throw new RuntimeException('Funded snapshot accepted.');}catch(InvalidArgumentException $e){$checks++;}
try{applySnapshot($svc,array_merge($data,array('revision'=>1)));throw new RuntimeException('Old snapshot accepted.');}catch(InvalidArgumentException $e){$checks++;}
$data['revision']=4;$data['snapshot_hash']=hash('sha256','version4');$data['learners']=array($learner,array('source_id'=>'test-trainer','email'=>$trainer['email'],'name'=>$trainer['name']));applySnapshot($svc,$data);
$h->noteIndependentMembership($runId,$learner['email']);
$data['revision']=5;$data['snapshot_hash']=hash('sha256','version5');$data['learners']=array($data['learners'][1]);
$independent=applySnapshot($svc,$data);
check((int)$w->fetchOne('SELECT COUNT(*) FROM course_run_enrolments WHERE run_id=?',array($runId))===2,'Independent MMS registration was erased.');
check((bool)$independent['warnings'],'Independent membership conflict was not reported.');
$conflictReplay=applySnapshot($svc,$data);check((bool)$conflictReplay['warnings'],'Unresolved independent membership warning disappeared on replay.');
$data['revision']=6;$data['snapshot_hash']=hash('sha256','version6');$data['learners'][0]['source_id']='upgraded-stable-trainer-id';applySnapshot($svc,$data);
check((int)$w->fetchOne('SELECT COUNT(*) FROM course_run_enrolments WHERE run_id=?',array($runId))===2,'Source person-ID upgrade deleted the active enrolment.');
$data['revision']=7;$data['snapshot_hash']=hash('sha256','version7');$data['learners']=array();
$data['trainers']=array(array('source_id'=>'replacement-trainer','email'=>'replacement@example.com','name'=>'Replacement Trainer','confirmed'=>true));$replacement=applySnapshot($svc,$data);
check($replacement['learners_removed']===1,'Upgraded identity lost import ownership.');
check(!$h->canAccessRun($runId,'trainer',$trainerUser,$trainer['email']),'Replaced trainer still has teaching access.');
$data['revision']=8;$data['snapshot_hash']=hash('sha256','version8');$data['event_occurrences'][]='pilot-event-two';
$second=$data['sessions'][0];$second['key']='s2234567';$second['source_id']='pilot-event-two';$second['date']='2026-11-14';$data['sessions'][]=$second;applySnapshot($svc,$data);
$run=$w->fetchRow('SELECT * FROM course_runs WHERE run_id=?',array($runId));
$sessions=Mage::helper('mmd_attendance')->sessionsForRun($run);
check(count($sessions)===2 && $sessions[1]['key']==='s2234567','Imported attendance session identities were not used.');
check(Mage::helper('mmd_attendance')->classDaysForRun($run)===array('2026-11-10','2026-11-14'),'Gap days were invented as teaching days.');
$w->insert('mmd_course_run_attendance',array('run_id'=>$runId,'class_id'=>$first['class_id'],'learner_email'=>$learner['email'],'learner_name'=>$learner['name'],'session_key'=>'s1234567','is_present'=>1,'created_at'=>gmdate('Y-m-d H:i:s'),'updated_at'=>gmdate('Y-m-d H:i:s')));
$changed=$data;$changed['revision']=9;$changed['snapshot_hash']=hash('sha256','invalid-change');$changed['sessions'][1]['date']='2026-11-15';
try{applySnapshot($svc,$changed);throw new RuntimeException('Recorded attendance was relabelled.');}catch(InvalidArgumentException $e){$checks++;}
check((int)$w->fetchOne('SELECT revision FROM mmd_tms_run_link WHERE run_id=?',array($runId))===8,'Failed import advanced applied revision.');
check((int)$w->fetchOne('SELECT COUNT(*) FROM mmd_course_run_attendance WHERE run_id=?',array($runId))===1,'Synchronization lost historical attendance.');
$data['revision']=9;$data['snapshot_hash']=hash('sha256','version9');$data['cancelled']=true;applySnapshot($svc,$data);
check(!$h->canAccessRun($runId,'trainer',$trainerUser,$trainer['email']),'Cancelled run retains active teaching access.');
check(!$h->canAccessRun($runId,'learner',$learnerUser,$learner['email']),'Cancelled run allows an independently registered learner to enter.');
$new=$data;$new['source_run_key']='calendar:test:new-class';$new['event_occurrences']=array('new-event');$new['revision']=1;$new['snapshot_hash']=hash('sha256','new-class');$new['cancelled']=false;$new['sessions']=array($data['sessions'][0]);$new['sessions'][0]['date']='2026-12-10';
$new['handover_approval']['first_session_at']='2026-12-10T01:30:00Z';
$created=applySnapshot($svc,$new);check($created['run_id']!==$runId,'New class reused an unrelated run.');
$new['revision']=2;$new['snapshot_hash']=hash('sha256','rescheduled');$new['sessions'][0]['date']='2026-12-11';
$new['handover_approval']['approved_at']=gmdate('c');$new['handover_approval']['first_session_at']='2026-12-11T01:30:00Z';
$rescheduled=applySnapshot($svc,$new);
check($rescheduled['run_id']===$created['run_id'] && $rescheduled['class_id']===$created['class_id'],'Reschedule created another class.');
check((string)$w->fetchOne('SELECT course_start_date FROM course_runs WHERE run_id=?',array($created['run_id']))==='2026-12-11','Rescheduled date was not applied.');
$new['revision']=3;$new['learners']=array(array_merge($learner,array('active'=>false)));$inactive=applySnapshot($svc,$new);
check((int)$w->fetchOne('SELECT COUNT(*) FROM course_run_enrolments WHERE run_id=?',array($created['run_id']))===0 && (bool)$inactive['warnings'],'Inactive TMS learner retained access or was silently ignored.');
$new['revision']=4;$new['learners']=array(array('source_id'=>'email-change-user','email'=>'beforechange@example.com','name'=>'Before Change'));applySnapshot($svc,$new);
$emailUser=$w->fetchRow("SELECT user_id,password FROM admin_user WHERE email='beforechange@example.com'");
$new['revision']=5;$new['learners'][0]['email']='afterchange@example.com';$new['learners'][0]['name']='After Change';applySnapshot($svc,$new);
$afterUser=$w->fetchRow("SELECT user_id,password,firstname FROM admin_user WHERE email='afterchange@example.com'");
check($afterUser['user_id']===$emailUser['user_id'] && $afterUser['password']===$emailUser['password'],'Email change replaced an account or its password.');
check($afterUser['firstname']==='After' && (int)$w->fetchOne('SELECT COUNT(*) FROM course_run_enrolments WHERE run_id=? AND learner_email=?',array($created['run_id'],'afterchange@example.com'))===1,'Changed profile/email did not reach the class roster.');
check((int)$w->fetchOne('SELECT COUNT(*) FROM course_run_enrolments WHERE run_id=? AND learner_email=?',array($created['run_id'],'beforechange@example.com'))===0,'Old email retained active class membership.');
echo 'PASS: '.$checks." MMS database integration checks\n";
