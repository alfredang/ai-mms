<?php
/** Password/OTP/role-selection HTTP tests; only sanitized fixtures and internal Mailpit. */
if (getenv('MMS_HANDOVER_ISOLATED_TEST') !== '1') throw new RuntimeException('Isolated flag required.');
$root = dirname(__DIR__, 2);
$xml = simplexml_load_file($root . '/app/etc/local.xml');
$c = $xml->global->resources->default_setup->connection;
if ((string) $c->host !== 'mms-nonfunded-test-mysql' || (string) $c->dbname !== 'mms_handover_test') throw new RuntimeException('Fixture identity mismatch.');
foreach (array('app/code/local/MMD/Courses/Model/TmsImport.php','app/code/local/MMD/RoleManager/Helper/ClassAccess.php','app/code/local/MMD/RoleManager/Helper/Handover.php','app/code/local/MMD/RoleManager/Model/Observer.php','app/code/local/MMD/RoleManager/controllers/IndexController.php','app/code/local/MMD/RoleManager/controllers/Adminhtml/RoleselectController.php') as $file) {
    passthru(escapeshellarg(PHP_BINARY) . ' -l ' . escapeshellarg($root . '/' . $file), $status);
    if ($status !== 0) throw new RuntimeException('PHP lint failed.');
}
require $root . '/app/Mage.php';
Mage::app('admin');
$r = Mage::getSingleton('core/resource'); $w = $r->getConnection('core_write');
$checks = 0;
function accessCheck($condition, $message) { global $checks; if (!$condition) throw new RuntimeException($message); $checks++; }
function mailpit($path) {
    $curl = curl_init('http://mailpit:8025' . $path);
    curl_setopt_array($curl, array(CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 10));
    $body = curl_exec($curl); $status = curl_getinfo($curl, CURLINFO_HTTP_CODE); curl_close($curl);
    if ($status !== 200) throw new RuntimeException('Mailpit is unavailable.');
    return json_decode($body, true);
}
// Neither SMTP nor direct Gmail credentials may survive in the disposable fixture.
$w->query("DELETE FROM core_config_data WHERE path LIKE 'smtppro/%' OR path LIKE 'mmd_email/google/%'");
$settings = array('mmd/tms_handover/public_origin'=>'http://localhost:18089', 'mmd/tms_handover/course_allowlist'=>'C916', 'mmd/tms_handover/access_verified'=>'1',
    'web/unsecure/base_url'=>'http://localhost:18089/', 'web/secure/base_url'=>'http://localhost:18089/', 'web/secure/use_in_adminhtml'=>'0', 'web/secure/use_in_frontend'=>'0',
    'web/cookie/cookie_domain'=>'', 'web/cookie/cookie_path'=>'/', 'admin/security/use_form_key'=>'0', 'smtppro/general/option'=>'smtp', 'smtppro/general/smtp_host'=>'mailpit',
    'smtppro/general/smtp_port'=>'1025', 'smtppro/general/smtp_authentication'=>'none', 'smtppro/general/smtp_ssl'=>'none', 'smtppro/charset/utf8'=>'1',
    'trans_email/ident_general/email'=>'fixture@example.com', 'trans_email/ident_general/name'=>'Isolated MMS Test', 'system/smtp/disable'=>'0', 'dev/log/active'=>'1', 'smtppro/debug/log_debug'=>'1');
foreach ($settings as $key=>$value) { Mage::getConfig()->saveConfig($key,$value); Mage::app()->getStore()->setConfig($key,$value); }
$w->query("UPDATE core_config_data SET value='http://localhost:18089/' WHERE path IN ('web/unsecure/base_url','web/secure/base_url')");
Mage::getConfig()->reinit(); Mage::app()->cleanCache();
Mage::getConfig()->setNode('global/events/customer_save_before/observers/mmd_email_validate_customer/type','disabled');
$beforeMail = mailpit('/api/v1/messages')['total'];
$data = array('schema_version'=>1,'source_provider_id'=>'tertiary-sg','source_run_key'=>'calendar:test:class-access','website_id'=>1,'course_code'=>'C916','course_title'=>'Pilot','calendar_id'=>'sales@tertiarycourses.com.sg','event_occurrences'=>array('access-event'),'revision'=>1,'request_id'=>'access-test','roster_complete'=>true,'cancelled'=>false,
    'sessions'=>array(array('key'=>'sabc1234','source_id'=>'access-event','date'=>'2026-11-20','start_time'=>'09:30','end_time'=>'17:30','mode'=>1,'venue'=>'Fixture Room','virtual_link'=>'')),
    'learners'=>array(array('source_id'=>'entry-learner','email'=>'entrylearner@example.com','name'=>'Entry Learner'),array('source_id'=>'entry-dual','email'=>'entrydual@example.com','name'=>'Entry Dual')),
    'trainers'=>array(array('source_id'=>'entry-trainer','email'=>'entrytrainer@example.com','name'=>'Entry Trainer','confirmed'=>true)),
    'courseware'=>array('learner_guide_url'=>'https://example.com/guide','trainer_slides_url'=>'https://example.com/slides'),'feedback_url'=>'https://tms.example.com/feedback/access',
    'handover_approval'=>array('approved_at'=>'2026-10-21T00:00:00Z','approved_by'=>'isolated-operator','first_session_at'=>'2026-11-20T01:30:00Z'));
$data['snapshot_hash']=MMD_Courses_Model_TmsContract::contentHash($data);
$productId=(int)$w->fetchOne("SELECT entity_id FROM catalog_product_entity WHERE sku='C916'");
$w->insert('course_runs',array('class_id'=>'C990000','product_id'=>$productId,'course_sku'=>'C916','course_start_date'=>'2026-11-19','course_end_date'=>'2026-11-19','course_start_time'=>'09:30','course_end_time'=>'17:30','created_by'=>'Exact-run fixture'));
$decoyRun=(int)$w->lastInsertId();
$w->insert('course_run_enrolments',array('product_id'=>$productId,'run_id'=>$decoyRun,'learner_email'=>'entrylearner@example.com','learner_name'=>'Entry Learner'));
$svc=Mage::getModel('courses/tmsImport'); $result=$svc->apply($data); $runId=$result['run_id'];
$w->update('mmd_tms_run_link',array('feedback_url'=>''),array('run_id = ?'=>$runId));
accessCheck(isset($result['participant_class_url']) && $result['participant_class_url']==='http://localhost:18089/lmslogin/index/class/?run_id='.$runId,'Participant URL is not canonical/exact.');
accessCheck($result['snapshot_hash']===$data['snapshot_hash'],'Applied content hash missing.');
accessCheck(mailpit('/api/v1/messages')['total']===$beforeMail,'Import sent an unsolicited welcome or OTP.');
$dualId=(int)$w->fetchOne("SELECT user_id FROM admin_user WHERE email='entrydual@example.com'");
$w->insertOnDuplicate('mmd_user_role_map',array('user_id'=>$dualId,'role_code'=>'trainer','is_primary'=>0),array('is_primary'));
foreach (array('entrylearner@example.com','entrytrainer@example.com','entrydual@example.com') as $email) {
    $user=Mage::getModel('admin/user')->loadByUsername($email); $user->setPassword('Fixture-only-Access-2026!')->setMmdForcePasswordChange(0)->save();
}
Mage::app()->cleanCache();
$helper=Mage::helper('mmd_rolemanager/classAccess');
accessCheck($helper instanceof MMD_RoleManager_Helper_ClassAccess,'Class-access helper alias failed.');
try { $helper->remember('https://evil.example/'); throw new RuntimeException('URL accepted as run identity.'); } catch (InvalidArgumentException $e) { $checks++; }
// A complete import requires an explicit first-session approval, including direct API calls.
$invalid=$data;unset($invalid['handover_approval']);$invalid['snapshot_hash']=MMD_Courses_Model_TmsContract::contentHash($invalid);
try { $svc->apply($invalid); throw new RuntimeException('Missing run approval accepted.'); } catch (InvalidArgumentException $e) { $checks++; }
foreach(array('invalid-approval',array('approved_by'=>array('invalid'))) as $badApproval) {
    $invalid=$data;$invalid['handover_approval']=$badApproval;$invalid['snapshot_hash']=MMD_Courses_Model_TmsContract::contentHash($invalid);
    try { $svc->apply($invalid); throw new RuntimeException('Malformed approval accepted.'); } catch (InvalidArgumentException $e) { $checks++; }
}
$midway=$data;$midway['source_run_key']='calendar:test:midway';$midway['event_occurrences']=array('midway-event');$midway['sessions'][0]['date']='2026-10-22';$midway['handover_approval']['first_session_at']='2026-10-22T01:30:00Z';$midway['snapshot_hash']=MMD_Courses_Model_TmsContract::contentHash($midway);
try { $svc->apply($midway); throw new RuntimeException('Midway adoption accepted.'); } catch (InvalidArgumentException $e) { $checks++; }
function client() { $c=curl_init();curl_setopt_array($c,array(CURLOPT_RETURNTRANSFER=>true,CURLOPT_HEADER=>true,CURLOPT_COOKIEFILE=>'',CURLOPT_TIMEOUT=>30));return $c; }
function visit($curl,$url,$post=null) {
    $path=parse_url($url,PHP_URL_PATH)?:'/';$query=parse_url($url,PHP_URL_QUERY);
    curl_setopt($curl,CURLOPT_URL,'http://mms-nonfunded-test-api:8080'.$path.($query?'?'.$query:''));
    curl_setopt($curl,CURLOPT_POST,$post!==null);
    if($post!==null)curl_setopt($curl,CURLOPT_POSTFIELDS,http_build_query($post));
    $raw=curl_exec($curl);$code=curl_getinfo($curl,CURLINFO_HTTP_CODE);$size=curl_getinfo($curl,CURLINFO_HEADER_SIZE);
    if($raw===false)throw new RuntimeException(curl_error($curl));
    $headers=substr($raw,0,$size);$body=substr($raw,$size);preg_match('/^Location:\s*(.+)$/mi',$headers,$match);
    return array('code'=>$code,'location'=>trim($match[1]??''),'body'=>$body);
}
foreach (in_array('--otp-only',$argv,true)?array():array('entrylearner@example.com','entrytrainer@example.com') as $email) {
    $client=client();$entry=visit($client,$result['participant_class_url']);
    accessCheck($entry['code']===302 && strpos($entry['location'],'/lmslogin/')!==false,'Fresh class entry did not use LMS login.');
    $login=visit($client,'/lmslogin/index/login',array('email'=>$email,'password'=>'Fixture-only-Access-2026!'));
    accessCheck(strpos($login['location'],'/lmslogin/index/class/')!==false,'Password login lost the exact class. '.substr($login['body'],0,150));
    $landing=visit($client,$login['location']);
    accessCheck(strpos($landing['location'],'run='.$runId)!==false && strpos($landing['location'],'dashboard')!==false,'Authenticated entry lost run or failed authorization.');
    $detail=visit($client,$landing['location']);
    accessCheck($detail['code']===200 && strpos($detail['body'],'<span class="lcd-detail-label">Course Run ID</span><span class="lcd-detail-value">'.$result['class_id'].'</span>')!==false,'Class detail did not render the exact requested Course Run ID.');
    accessCheck(strpos($detail['body'],'The TMS feedback form has not been mapped for this class yet.')!==false,'Missing TMS feedback mapping used the wrong empty-state message.');
    if ($email==='entrylearner@example.com') accessCheck(strpos($detail['body'],'<div class="lcd-cert-title">In Progress</div>')!==false,'Imported learner roster membership was shown as not enrolled.');
    curl_close($client);
}
// OTP request must actually reach Mailpit; a generic endpoint success is insufficient.
$client=client();visit($client,$result['participant_class_url']);
$send=visit($client,'/lmslogin/index/send',array('email'=>'entrydual@example.com'));
accessCheck(!empty(json_decode($send['body'],true)['success']),'OTP request failed.');
$messages=mailpit('/api/v1/messages');$otp=null;
foreach($messages['messages']??array() as $message) foreach($message['To']??array() as $to) if(strtolower($to['Address']??'')==='entrydual@example.com') {
    $captured=mailpit('/api/v1/message/'.$message['ID']);if(preg_match('/(?<![0-9])([0-9]{6})(?![0-9])/',$captured['Text']??'',$match)){$otp=$match[1];break 2;}
}
accessCheck($otp!==null,'OTP not actually captured by isolated Mailpit (captured messages: '.($messages['total']??'unknown').').');
$verify=visit($client,'/lmslogin/index/verify',array('email'=>'entrydual@example.com','otp'=>$otp));$verified=json_decode($verify['body'],true);
accessCheck(!empty($verified['success']) && strpos($verified['redirect'],'roleselect')!==false,'Multi-role OTP did not reach role selection.');
$rolePage=visit($client,$verified['redirect']);
preg_match('/name="form_key" value="([^"]+)"/',$rolePage['body'],$formKey);
preg_match('/<form method="post" action="([^"]+)"/',$rolePage['body'],$formAction);
accessCheck(!empty($formKey[1]) && !empty($formAction[1]),'Role-selection form or CSRF token is missing.');
$select=visit($client,html_entity_decode($formAction[1]),array('role_code'=>'learner','form_key'=>$formKey[1]));
accessCheck(strpos($select['location'],'/lmslogin/index/class/')!==false,'Role selection lost class return destination.');
$landing=visit($client,$select['location']);
accessCheck(strpos($landing['location'],'run='.$runId)!==false,'OTP plus role selection did not return to the exact class.');
// Remove access and revisit the forwarded stable URL with the same signed-in account.
$w->update('admin_user',array('is_active'=>0),array('user_id = ?'=>$dualId));
$blocked=visit($client,$result['participant_class_url']);
accessCheck($blocked['code']===403,'A blocked account kept access through a cached logged-in session.');
$w->update('admin_user',array('is_active'=>1),array('user_id = ?'=>$dualId));
$w->delete('course_run_enrolments',array('run_id = ?'=>$runId,'learner_email = ?'=>'entrydual@example.com'));
$denied=visit($client,$result['participant_class_url'].'&next=https://evil.example/');
accessCheck($denied['code']===403 && strpos($denied['body'],'entrylearner@example.com')===false && strpos($denied['location'],'evil.example')===false,'Removed account/forwarded link bypassed exact-run access.');
curl_close($client);
echo 'PASS: '.$checks." MMS class-access, password, captured OTP and multi-role HTTP checks\n";
