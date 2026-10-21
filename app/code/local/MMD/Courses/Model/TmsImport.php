<?php
/** Transactional, revisioned import into the existing MMS class/account models. */
class MMD_Courses_Model_TmsImport
{
    protected $_write;
    protected $_resource;
    protected $_idLockHeld = false;
    protected function table($name) { return $this->_resource->getTableName($name); }

    protected function prepare(array $input)
    {
        // Validate funded exclusion before any account/class/roster write.
        $data = MMD_Courses_Model_TmsContract::validate($input);
        $provider = (string) (Mage::getStoreConfig('mmd/tms_handover/provider_id') ?: 'tertiary-sg');
        $calendar = (string) (Mage::getStoreConfig('mmd/tms_handover/calendar_id') ?: 'sales@tertiarycourses.com.sg');
        $website = (int) (Mage::getStoreConfig('mmd/tms_handover/website_id') ?: 1);
        $allowlist = array_filter(array_map('trim', explode(',', strtoupper((string) Mage::getStoreConfig('mmd/tms_handover/course_allowlist')))));
        if ($data['source_provider_id'] !== $provider || $data['calendar_id'] !== $calendar || $data['website_id'] !== $website
            || !in_array($data['course_code'], $allowlist, true)) throw new InvalidArgumentException('Snapshot is outside the configured provider/calendar/store/pilot scope.');
        $this->_resource = Mage::getSingleton('core/resource');
        $this->_write = $this->_resource->getConnection('core_write');
        $w = $this->_write;
        $products = $w->fetchAll('SELECT p.entity_id,p.sku FROM ' . $this->table('catalog/product') . ' p JOIN ' . $this->table('catalog/product_website') . ' pw ON pw.product_id=p.entity_id WHERE UPPER(TRIM(p.sku))=? AND pw.website_id=?', array($data['course_code'],$website));
        if (count($products) !== 1) throw new InvalidArgumentException('Resolve one existing MMS course in the configured website.');
        $productId = (int) $products[0]['entity_id'];
        MMD_Courses_Model_TmsContract::courseCode($products[0]['sku']);
        return array($data,$provider,$website,$productId);
    }

    public function preview(array $input)
    {
        list($data,$provider,$website,$productId)=$this->prepare($input);
        $w=$this->_write;
        $link=$w->fetchRow('SELECT l.*,r.product_id FROM ' . $this->table('mmd_tms_run_link') . ' l JOIN ' . $this->table('course_runs') . ' r ON r.run_id=l.run_id WHERE l.provider_id=? AND l.source_run_key=?',array($provider,$data['source_run_key']));
        if($link && (int)$link['product_id']!==$productId)throw new InvalidArgumentException('Mapped course identity changed.');
        $first=$data['sessions'][0];$last=$data['sessions'][count($data['sessions'])-1];
        $rows=$link?array():$w->fetchAll('SELECT run_id,class_id FROM ' . $this->table('course_runs') . ' WHERE product_id=? AND course_start_date=? AND course_end_date=? AND course_start_time=? AND course_end_time=?',array($productId,$first['date'],$last['date'],$first['start_time'],$last['end_time']));
        if(count($rows)>1)throw new InvalidArgumentException('Multiple existing MMS runs match; resolve the duplicate first.');
        if($rows && $w->fetchOne('SELECT link_id FROM ' . $this->table('mmd_tms_run_link') . ' WHERE run_id=?',array($rows[0]['run_id'])))throw new InvalidArgumentException('Existing MMS run belongs to another source mapping.');
        return array('success'=>true,'dry_run'=>true,'action'=>$link?'update':($rows?'adopt':'create'),'run_id'=>$link?(int)$link['run_id']:($rows?(int)$rows[0]['run_id']:null),'source_run_key'=>$data['source_run_key'],'learners'=>count($data['learners']),'trainer_confirmation_pending'=>empty($data['trainers'][0]['confirmed']));
    }

    public function apply(array $input)
    {
        list($data,$provider,$website,$productId)=$this->prepare($input);
        $calendar=$data['calendar_id'];
        $w=$this->_write;
        $lock = 'mmd-class-product-' . $productId;
        if (!(int) $w->fetchOne('SELECT GET_LOCK(?,15)',array($lock))) throw new RuntimeException('Class synchronization is busy.');
        try {
            $w->beginTransaction();
            $linkTable = $this->table('mmd_tms_run_link');
            $link = $w->fetchRow("SELECT * FROM `$linkTable` WHERE provider_id=? AND source_run_key=? FOR UPDATE",array($provider,$data['source_run_key']));
            $replayed = false;
            if ($link) {
                $currentSku = $w->fetchOne('SELECT p.sku FROM ' . $this->table('course_runs') . ' r JOIN ' . $this->table('catalog/product') . ' p ON p.entity_id=r.product_id WHERE r.run_id=?',array($link['run_id']));
                if (!$currentSku || MMD_Courses_Model_TmsContract::courseCode($currentSku) !== $data['course_code']) throw new InvalidArgumentException('Mapped course identity changed.');
                if ($data['revision'] < (int) $link['revision']) throw new InvalidArgumentException('An older snapshot cannot replace a newer revision.');
                if ($data['revision'] === (int) $link['revision']) {
                    if (!hash_equals($link['snapshot_hash'],$data['snapshot_hash'])) throw new InvalidArgumentException('Same revision has different content.');
                    // Reconcile the current target too: an operator may have fixed a
                    // blocked account/resource or removed a roster row since the last try.
                    // Upserts preserve identity/passwords and send no onboarding messages.
                    $replayed = true;
                }
            }
            $runId = $link ? (int) $link['run_id'] : $this->resolveRun($data,$productId);
            $run = $w->fetchRow('SELECT * FROM ' . $this->table('course_runs') . ' WHERE run_id=? FOR UPDATE',array($runId));
            if (!$run || (int) $run['product_id'] !== $productId) throw new InvalidArgumentException('MMS class/product mapping conflicts.');
            $oldSessions = $link ? json_decode($link['sessions_json'],true) : array();
            $marks = (int) $w->fetchOne('SELECT COUNT(*) FROM ' . $this->table('mmd_course_run_attendance') . ' WHERE run_id=?',array($runId));
            $sessionIdentity=function(array $sessions){return array_map(function($s){return array_intersect_key($s,array_flip(array('key','source_id','date','start_time','end_time')));},$sessions);};
            if ($marks && (!$oldSessions || $sessionIdentity($oldSessions)!==$sessionIdentity($data['sessions']))) throw new InvalidArgumentException('Class sessions already have attendance; resolve the schedule mapping/change explicitly.');
            $row = array('provider_id'=>$provider,'source_run_key'=>$data['source_run_key'],'run_id'=>$runId,'course_code'=>$data['course_code'],'revision'=>$data['revision'],'snapshot_hash'=>$data['snapshot_hash'],'active'=>$data['cancelled']?0:1,'sessions_json'=>json_encode($data['sessions']),'feedback_url'=>(string)($data['feedback_url']??''),'synced_at'=>gmdate('Y-m-d H:i:s'));
            if ($link) $w->update($linkTable,$row,array('link_id = ?'=>$link['link_id']));
            else { $w->insert($linkTable,$row); $link = array('link_id'=>(int)$w->lastInsertId()); }
            $linkId = (int) $link['link_id'];
            foreach ($data['event_occurrences'] as $event) {
                $hash = hash('sha256',$provider . "\n" . $calendar . "\n" . $event);
                $owner = $w->fetchOne('SELECT link_id FROM ' . $this->table('mmd_tms_event_link') . ' WHERE identity_hash=?',array($hash));
                if ($owner && (int)$owner !== $linkId) throw new InvalidArgumentException('Calendar occurrence is already mapped to another MMS run.');
                $w->insertOnDuplicate($this->table('mmd_tms_event_link'),array('link_id'=>$linkId,'calendar_id'=>$calendar,'event_id'=>$event,'identity_hash'=>$hash),array('link_id'));
            }
            $warnings = array(); $trainerId = null;
            foreach ($data['trainers'] as $trainer) {
                if ($data['cancelled'] || !$trainer['confirmed'] || ($trainer['active']??true) === false) continue;
                $trainerId = $this->account($trainer,'trainer',$provider,$website);
            }
            if (!$trainerId && !$data['cancelled']) $warnings[] = 'Trainer confirmation/active account is missing.';
            foreach($data['sessions'] as $session)if($session['mode']===2 && empty($session['virtual_link'])){$warnings[]='A virtual session is missing its class-specific meeting link.';break;}
            $first = $data['sessions'][0]; $last = $data['sessions'][count($data['sessions'])-1];
            $w->update($this->table('course_runs'),array('course_start_date'=>$first['date'],'course_end_date'=>$last['date'],'course_start_time'=>$first['start_time'],'course_end_time'=>$last['end_time'],'num_sessions'=>count($data['sessions']),'room'=>$first['venue'],'virtual_link'=>$first['virtual_link'],'mode_of_training'=>$first['mode'],'trainer_user_id'=>$trainerId,'trainer_option_id'=>null,'invitation_paused'=>1,'invitation_replies_blocked'=>1,'gcal_event_id'=>$data['event_occurrences'][0]),array('run_id = ?'=>$runId));
            $counts = $this->roster($data,$linkId,$runId,$productId,$provider,$website,$warnings);
            $this->courseware($productId,$data['courseware']??array());
            $resources = $w->fetchRow('SELECT * FROM ' . $this->table('course_courseware') . ' WHERE product_id=?',array($productId));
            if (!$resources || empty($resources['learner_guide_url']) || empty($resources['trainer_slides_url'])) $warnings[]='Required learner guide/trainer slides need verification.';
            if (empty($data['feedback_url'])) $warnings[]='Mapped TMS feedback form is missing; native MMS feedback is suppressed.';
            // Permission tests require the actual roles; never infer access from a URL string.
            if (!Mage::getStoreConfigFlag('mmd/tms_handover/access_verified')) $warnings[]='Pilot login/courseware access verification is pending.';
            $classUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard/index',array('course_id'=>$productId,'_query'=>array('run'=>$runId),'_nosecret'=>true));
            $result = array_merge(array('success'=>true,'source_run_key'=>$data['source_run_key'],'revision'=>$data['revision'],'run_id'=>$runId,'class_id'=>$run['class_id'],'class_url'=>$classUrl,'readiness'=>$data['cancelled']?'cancelled':($warnings?'incomplete':'ready'),'warnings'=>$warnings,'request_id'=>$data['request_id']??'','replayed'=>$replayed),$counts);
            $w->update($linkTable,array('result_json'=>json_encode($result)),array('link_id = ?'=>$linkId));
            $w->insert($this->table('mmd_tms_sync_log'),array('provider_id'=>$provider,'source_run_key'=>$data['source_run_key'],'revision'=>$data['revision'],'result_json'=>json_encode($result),'created_at'=>gmdate('Y-m-d H:i:s')));
            $w->commit();
            return $result;
        } catch (Exception $e) { $w->rollBack(); throw $e; }
        finally {
            if ($this->_idLockHeld) { $w->fetchOne('SELECT RELEASE_LOCK(?)',array('mmd-class-id')); $this->_idLockHeld=false; }
            $w->fetchOne('SELECT RELEASE_LOCK(?)',array($lock));
        }
    }

    protected function resolveRun(array $data,$productId)
    {
        $w=$this->_write; $table=$this->table('course_runs');
        $owners=array();
        foreach($data['event_occurrences'] as $event) {
            $id=$w->fetchOne('SELECT l.run_id FROM ' . $this->table('mmd_tms_event_link') . ' e JOIN ' . $this->table('mmd_tms_run_link') . ' l ON l.link_id=e.link_id WHERE e.identity_hash=?',array(hash('sha256',$data['source_provider_id']."\n".$data['calendar_id']."\n".$event)));
            if($id)$owners[(int)$id]=true;
        }
        if($owners) throw new InvalidArgumentException('This event already has a source mapping; retain its original source key.');
        $first=$data['sessions'][0]; $last=$data['sessions'][count($data['sessions'])-1];
        $rows=$w->fetchAll("SELECT * FROM `$table` WHERE product_id=? AND course_start_date=? AND course_end_date=? AND course_start_time=? AND course_end_time=?",array($productId,$first['date'],$last['date'],$first['start_time'],$last['end_time']));
        if(count($rows)>1)throw new InvalidArgumentException('Multiple MMS runs match; operations must resolve the duplicate.');
        if($rows) {
            $claimed=$w->fetchOne('SELECT link_id FROM ' . $this->table('mmd_tms_run_link') . ' WHERE run_id=?',array($rows[0]['run_id']));
            if($claimed)throw new InvalidArgumentException('Existing MMS run is owned by another source mapping.');
            $days=Mage::helper('mmd_attendance')->classDaysForRun($rows[0]);
            $sourceDays=array_values(array_unique(array_column($data['sessions'],'date')));
            if(count($sourceDays)>1 && $days && $days!==$sourceDays)throw new InvalidArgumentException('Existing order session dates conflict with the TMS schedule.');
            return (int)$rows[0]['run_id'];
        }
        $idLock='mmd-class-id';
        if(!(int)$w->fetchOne('SELECT GET_LOCK(?,15)',array($idLock)))throw new RuntimeException('Class ID allocator is busy.');
        $this->_idLockHeld=true;
            $classId=MMD_RoleManager_Helper_Data::nextClassId($w,$table,MMD_RoleManager_Helper_Data::CLASS_ID_PREFIX);
            $w->insert($table,array('class_id'=>$classId,'product_id'=>$productId,'course_sku'=>$data['course_code'],'course_start_date'=>$first['date'],'course_end_date'=>$last['date'],'course_start_time'=>$first['start_time'],'course_end_time'=>$last['end_time'],'vacancy'=>'A','created_by'=>'TMS handover','created_at'=>gmdate('Y-m-d H:i:s')));
            return (int)$w->lastInsertId();
    }

    protected function account(array $person,$role,$provider,$website)
    {
        $w=$this->_write; $users=$this->table('admin_user'); $links=$this->table('mmd_tms_person_link');
        $linked=$w->fetchRow("SELECT * FROM `$links` WHERE provider_id=? AND source_id=?",array($provider,$person['source_id']));
        $byEmail=$w->fetchAll("SELECT * FROM `$users` WHERE LOWER(TRIM(email))=?",array($person['email']));
        if(count($byEmail)>1)throw new InvalidArgumentException('Multiple MMS accounts share this email.');
        if($linked && $byEmail && (int)$linked['user_id']!==(int)$byEmail[0]['user_id'])throw new InvalidArgumentException('Changed email belongs to another MMS account.');
        $user=$linked?$w->fetchRow("SELECT * FROM `$users` WHERE user_id=?",array($linked['user_id'])):($byEmail?$byEmail[0]:null);
        if($linked && !$user)throw new InvalidArgumentException('Linked MMS account was deleted.');
        if($user && !(int)$user['is_active'])throw new InvalidArgumentException('MMS account is blocked; administrator review is required.');
        $name=preg_split('/\s+/',trim((string)$person['name']),2);
        $first=mb_substr($name[0]?:'Learner',0,32,'UTF-8'); $last=mb_substr($name[1]??'-',0,32,'UTF-8');
        if($user && strtolower($user['email'])!==$person['email']) {
            // Username/email collisions cannot be safely resolved by creating a second account.
            if(strlen($person['email'])>40)throw new InvalidArgumentException('Changed email exceeds current dashboard username storage.');
            $w->update($users,array('email'=>$person['email'],'username'=>$person['email']),array('user_id = ?'=>$user['user_id']));
            $w->update($this->table('customer/entity'),array('email'=>$person['email']),array('email = ?'=>$linked['email']));
            $user=$w->fetchRow("SELECT * FROM `$users` WHERE user_id=?",array($linked['user_id']));
        }
        if($role==='learner') {
            $customer=Mage::getModel('customer/customer')->setWebsiteId($website)->loadByEmail($person['email']);
            if(!$customer->getId()) {
                $customer->setWebsiteId($website)->setEmail($person['email'])->setFirstname($first)->setLastname($last);
                // A trainer/operator becoming a learner keeps their existing MMS password.
                if($user)$customer->setPasswordHash($user['password']);
                else $customer->setPassword(bin2hex(random_bytes(24)));
                $customer->save();
            } else { $customer->setFirstname($first)->setLastname($last)->save(); }
            Mage::helper('mmd_accountsync')->onCustomerSaved($customer);
        }
        if(!$user) $user=$w->fetchRow("SELECT * FROM `$users` WHERE LOWER(email)=?",array($person['email']));
        if(!$user) {
            if(strlen($person['email'])>40)throw new InvalidArgumentException('New trainer email exceeds current dashboard username storage.');
            $model=Mage::getModel('admin/user')->setData(array('email'=>$person['email'],'username'=>$person['email'],'firstname'=>$first,'lastname'=>$last,'password'=>bin2hex(random_bytes(24)),'is_active'=>1));
            $model->save(); $user=$model->getData();
        }
        $userId=(int)($user['user_id']??0);
        if(!$userId || strtolower($user['email'])!==$person['email'] || !(int)$user['is_active'])throw new InvalidArgumentException('Dashboard account provisioning failed.');
        $profile=array('firstname'=>$first,'lastname'=>$last,'modified'=>gmdate('Y-m-d H:i:s'));
        if(!empty($person['phone']))$profile['tel']=substr((string)$person['phone'],0,20);
        $w->update($users,$profile,array('user_id = ?'=>$userId));
        $roles=$this->table('mmd_user_role_map');
        $hasRoles=(int)$w->fetchOne("SELECT COUNT(*) FROM `$roles` WHERE user_id=?",array($userId));
        $w->insertOnDuplicate($roles,array('user_id'=>$userId,'role_code'=>$role,'is_primary'=>$hasRoles?0:1,'created_at'=>gmdate('Y-m-d H:i:s')),array('role_code'));
        if(!$hasRoles)Mage::helper('mmd_rolemanager')->applyRoleAcl($userId,$role);
        $w->insertOnDuplicate($links,array('provider_id'=>$provider,'source_id'=>$person['source_id'],'user_id'=>$userId,'email'=>$person['email']),array('email'));
        return $userId;
    }

    protected function roster(array $data,$linkId,$runId,$productId,$provider,$website,array &$warnings)
    {
        $w=$this->_write; $table=$this->table('course_run_enrolments'); $members=$this->table('mmd_tms_member_link');
        $old=$w->fetchAll("SELECT * FROM `$members` WHERE link_id=? AND role_code='learner' AND (active=1 OR independent_membership=1)",array($linkId));
        $active=array(); $activeEmails=array(); $counts=array('learners_added'=>0,'learners_updated'=>0,'learners_removed'=>0);
        foreach($data['cancelled']?array():$data['learners'] as $learner) {
            if(($learner['active']??true)===false){$warnings[]='An inactive TMS learner was excluded from active class access.';continue;}
            $this->account($learner,'learner',$provider,$website);
            $existing=$w->fetchRow("SELECT * FROM `$members` WHERE link_id=? AND source_id=? AND role_code='learner'",array($linkId,$learner['source_id']));
            $priorEmailMember=$existing?:$w->fetchRow("SELECT * FROM `$members` WHERE link_id=? AND email=? AND role_code='learner' ORDER BY active DESC,id DESC LIMIT 1",array($linkId,$learner['email']));
            if($existing && $existing['email']!==$learner['email']) {
                if((int)$existing['independent_membership'])throw new InvalidArgumentException('Email changed on an independently registered learner; resolve membership first.');
                $w->delete($table,array('run_id = ?'=>$runId,'learner_email = ?'=>$existing['email']));
            }
            $enrol=$w->fetchRow("SELECT * FROM `$table` WHERE run_id=? AND LOWER(learner_email)=?",array($runId,$learner['email']));
            $w->insertOnDuplicate($table,array('product_id'=>$productId,'run_id'=>$runId,'learner_email'=>$learner['email'],'learner_name'=>$learner['name']),array('learner_name'));
            $w->insertOnDuplicate($members,array('link_id'=>$linkId,'source_id'=>$learner['source_id'],'email'=>$learner['email'],'role_code'=>'learner','active'=>1,'import_owned'=>$priorEmailMember?(int)$priorEmailMember['import_owned']:($enrol?0:1),'independent_membership'=>$priorEmailMember?(int)$priorEmailMember['independent_membership']:($enrol?1:0)),array('email','active'));
            $active[$learner['source_id']]=true; $activeEmails[$learner['email']]=true;
            if(!$enrol)$counts['learners_added']++;
            elseif($enrol['learner_name']!==$learner['name'])$counts['learners_updated']++;
        }
        foreach($old as $member) if(!isset($active[$member['source_id']])) {
            if(isset($activeEmails[$member['email']])) {
                // Person gained a stable TMS user ID; the active enrolment survives the source-ID upgrade.
            } elseif((int)$member['import_owned'] && !(int)$member['independent_membership']) {
                $w->delete($table,array('run_id = ?'=>$runId,'learner_email = ?'=>$member['email'])); $counts['learners_removed']++;
            } else { $warnings[]='Independent MMS membership retained after TMS removal; operations review is required.'; }
            $w->update($members,array('active'=>0),array('id = ?'=>$member['id']));
        }
        return $counts;
    }
    protected function courseware($productId,array $links)
    {
        $allowed=array('learner_guide_url','learner_slides_url','trainer_slides_url','lesson_plan_url','lab_url','courseware_link','brochure_link');
        $existing=$this->_write->fetchRow('SELECT * FROM ' . $this->table('course_courseware') . ' WHERE product_id=?',array($productId));
        $row=array('product_id'=>$productId);
        foreach($allowed as $key)if(!empty($links[$key]) && empty($existing[$key]))$row[$key]=$links[$key];
        if(count($row)>1)$this->_write->insertOnDuplicate($this->table('course_courseware'),$row,array_keys(array_diff_key($row,array('product_id'=>true))));
    }
}
