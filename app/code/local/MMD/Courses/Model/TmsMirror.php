<?php
/** Continuous Master List mirroring. Pending data does not block class creation. */
class MMD_Courses_Model_TmsMirror extends MMD_Courses_Model_TmsImport
{
    protected function matchRun(array $data, $productId)
    {
        $w = $this->_write;
        $alias = $w->fetchRow('SELECT a.*,l.run_id FROM ' . $this->table('mmd_tms_source_alias') . ' a JOIN ' . $this->table('mmd_tms_run_link') . ' l ON l.link_id=a.link_id WHERE a.provider_id=? AND a.source_run_key=?', array($data['source_provider_id'],$data['source_run_key']));
        $link = $alias ? $w->fetchRow('SELECT * FROM ' . $this->table('mmd_tms_run_link') . ' WHERE link_id=?', array($alias['link_id'])) : $w->fetchRow('SELECT * FROM ' . $this->table('mmd_tms_run_link') . ' WHERE provider_id=? AND source_run_key=?', array($data['source_provider_id'],$data['source_run_key']));
        if ($link) {
            $run = $w->fetchRow('SELECT * FROM ' . $this->table('course_runs') . ' WHERE run_id=?', array($link['run_id']));
            if (!$run || (int)$run['product_id'] !== (int)$productId) throw new InvalidArgumentException('Mapped course code changed.');
            if (!empty($data['class_start_date']) && !empty($data['class_end_date']) && ($run['course_start_date'] !== $data['class_start_date'] || $run['course_end_date'] !== $data['class_end_date'])) {
                $match=$w->fetchRow('SELECT * FROM ' . $this->table('course_runs') . ' WHERE product_id=? AND course_start_date=? AND course_end_date=? ORDER BY run_id LIMIT 1',array($productId,$data['class_start_date'],$data['class_end_date']));
                if ($match) {
                    $run=$match;
                    $targetLink=$w->fetchRow('SELECT * FROM ' . $this->table('mmd_tms_run_link') . ' WHERE run_id=?',array($run['run_id']));
                    if ($targetLink) $link=$targetLink;
                }
            }
            return array($run,$link,$alias);
        }
        // The date range, not title, time or Calendar identity, identifies a class.
        $run = null;
        if (!empty($data['class_start_date']) && !empty($data['class_end_date'])) {
            $run = $w->fetchRow('SELECT * FROM ' . $this->table('course_runs') . ' WHERE product_id=? AND course_start_date=? AND course_end_date=? ORDER BY run_id LIMIT 1', array($productId,$data['class_start_date'],$data['class_end_date']));
        }
        if ($run) $link = $w->fetchRow('SELECT * FROM ' . $this->table('mmd_tms_run_link') . ' WHERE run_id=?', array($run['run_id']));
        return array($run,$link,$alias);
    }

    public function preview(array $input)
    {
        list($data,$provider,$website,$productId) = $this->prepare($input);
        list($run) = $this->matchRun($data,$productId);
        return array('success'=>true,'dry_run'=>true,'action'=>$run?'update':'create','run_id'=>$run?(int)$run['run_id']:null,'source_run_key'=>$data['source_run_key'],'learners'=>count($data['learners']),'trainer_confirmation_pending'=>!count($data['trainers']));
    }

    public function apply(array $input)
    {
        list($data,$provider,$website,$productId) = $this->prepare($input);
        $w = $this->_write;
        $lock = 'mmd-class-product-' . $productId;
        if (!(int)$w->fetchOne('SELECT GET_LOCK(?,15)',array($lock))) throw new RuntimeException('Class synchronization is busy.');
        try {
            $w->beginTransaction();
            list($run,$link,$alias) = $this->matchRun($data,$productId);
            $previous = $alias ?: ($link && $link['source_run_key'] === $data['source_run_key'] ? $link : null);
            if ($previous && ($data['revision'] < (int)$previous['revision'] || ($data['revision'] === (int)$previous['revision'] && !hash_equals($previous['snapshot_hash'],$data['snapshot_hash'])))) throw new InvalidArgumentException('Stale or conflicting source revision.');
            $replayed = $previous && $data['revision'] === (int)$previous['revision'];
            if (!$run) {
                if (!(int)$w->fetchOne('SELECT GET_LOCK(?,15)',array('mmd-class-id'))) throw new RuntimeException('Class ID allocator is busy.');
                $this->_idLockHeld = true;
                $w->insert($this->table('course_runs'),array('class_id'=>MMD_RoleManager_Helper_Data::nextClassId($w,$this->table('course_runs'),MMD_RoleManager_Helper_Data::CLASS_ID_PREFIX),'product_id'=>$productId,'course_sku'=>$data['course_code'],'course_start_date'=>$data['class_start_date']??null,'course_end_date'=>$data['class_end_date']??null,'vacancy'=>'A','created_by'=>'LMS Master List sync','created_at'=>gmdate('Y-m-d H:i:s')));
                $run = $w->fetchRow('SELECT * FROM ' . $this->table('course_runs') . ' WHERE run_id=?',array((int)$w->lastInsertId()));
            }
            $runId = (int)$run['run_id'];
            $warnings = $data['source_notes'] ?? array();
            $pendingLearners = $data['pending_learners'] ?? array();
            $pendingTrainers = $data['pending_trainers'] ?? array();
            $trainerIds = array();
            foreach ($data['cancelled'] ? array() : $data['trainers'] as $trainer) {
                if (($trainer['active']??true) === false) continue;
                $w->query('SAVEPOINT mms_participant');
                try { $trainerIds[] = $this->account($trainer,'trainer',$provider,$website); }
                catch (InvalidArgumentException | Mage_Core_Exception $e) { $w->query('ROLLBACK TO SAVEPOINT mms_participant'); $pendingTrainers[] = $trainer; $warnings[] = $e->getMessage(); }
                $w->query('RELEASE SAVEPOINT mms_participant');
            }
            // Null explicitly clears an MMS trainer when LMS has not assigned one.
            $first = $data['sessions'][0] ?? array();
            $last = $data['sessions'] ? $data['sessions'][count($data['sessions'])-1] : array();
            $details=$data['class_details']??array();
            $w->update($this->table('course_runs'),array('course_start_date'=>$data['class_start_date']??null,'course_end_date'=>$data['class_end_date']??null,'course_start_time'=>$first['start_time']??null,'course_end_time'=>$last['end_time']??null,'num_sessions'=>count($data['sessions']),'room'=>$first['venue']??($details['venue']??''),'virtual_link'=>$first['virtual_link']??($details['virtual_link']??''),'mode_of_training'=>$first['mode']??($details['mode']??1),'trainer_user_id'=>$trainerIds?reset($trainerIds):null,'trainer_option_id'=>null,'invitation_paused'=>1,'invitation_replies_blocked'=>1),array('run_id = ?'=>$runId));
            $row = array('provider_id'=>$provider,'source_run_key'=>$link?$link['source_run_key']:$data['source_run_key'],'run_id'=>$runId,'course_code'=>$data['course_code'],'revision'=>$data['revision'],'snapshot_hash'=>$data['snapshot_hash'],'active'=>$data['cancelled']?0:1,'sessions_json'=>json_encode($data['sessions']),'feedback_url'=>$data['feedback_url']??'','synced_at'=>gmdate('Y-m-d H:i:s'));
            if ($link) { $linkId=(int)$link['link_id']; $w->update($this->table('mmd_tms_run_link'),$row,array('link_id = ?'=>$linkId)); }
            else { $row['handover_at']=gmdate('Y-m-d H:i:s'); $w->insert($this->table('mmd_tms_run_link'),$row); $linkId=(int)$w->lastInsertId(); }
            $w->insertOnDuplicate($this->table('mmd_tms_source_alias'),array('provider_id'=>$provider,'source_run_key'=>$data['source_run_key'],'link_id'=>$linkId,'revision'=>$data['revision'],'snapshot_hash'=>$data['snapshot_hash']),array('link_id','revision','snapshot_hash'));
            // Import valid rows while retaining unresolved details in the sync result.
            $valid = $data; $valid['learners'] = array();
            foreach ($data['learners'] as $learner) {
                $w->query('SAVEPOINT mms_participant');
                try { if (($learner['active']??true) !== false) $this->account($learner,'learner',$provider,$website); }
                catch (InvalidArgumentException | Mage_Core_Exception $e) { $w->query('ROLLBACK TO SAVEPOINT mms_participant'); $pendingLearners[]=$learner; $warnings[]=$e->getMessage(); }
                $w->query('RELEASE SAVEPOINT mms_participant');
                $valid['learners'][]=$learner;
            }
            // An incomplete source cannot safely withdraw unmentioned learners.
            $counts = $this->mirrorRoster($valid,$linkId,$runId,$productId,$pendingLearners);
            $this->courseware($productId,$data['courseware']??array());
            if (!$data['sessions'] || !empty($data['pending_sessions'])) $warnings[]='Session schedule is pending in LMS.';
            foreach ($data['sessions'] as $session) if ($session['mode']===2 && empty($session['virtual_link'])) { $warnings[]='A virtual session is missing its meeting link.'; break; }
            if (!$trainerIds && !$data['cancelled']) $warnings[]='Trainer assignment is pending in LMS.';
            if ($pendingLearners || $pendingTrainers) $warnings[]='Some participant account details are pending; class information is synchronized.';
            if (!Mage::getStoreConfigFlag('mmd/tms_handover/access_verified')) $warnings[]='Participant access verification is pending.';
            $resources=$w->fetchRow('SELECT * FROM ' . $this->table('course_courseware') . ' WHERE product_id=?',array($productId));
            if (!$resources || empty($resources['learner_guide_url']) || empty($resources['trainer_slides_url'])) $warnings[]='Required courseware is pending.';
            if (empty($data['feedback_url'])) $warnings[]='Feedback route is pending.';
            $urls=array();
            try { $urls=Mage::helper('mmd_rolemanager/classAccess')->urls($runId); } catch (InvalidArgumentException $e) { $warnings[]=$e->getMessage(); }
            $result=array_merge(array('success'=>true,'source_run_key'=>$data['source_run_key'],'revision'=>$data['revision'],'snapshot_hash'=>$data['snapshot_hash'],'run_id'=>$runId,'class_id'=>$run['class_id'],'readiness'=>$data['cancelled']?'cancelled':($warnings?'incomplete':'ready'),'warnings'=>array_values(array_unique($warnings)),'pending_learners'=>$pendingLearners,'pending_trainers'=>$pendingTrainers,'pending_sessions'=>$data['pending_sessions']??array(),'class_details'=>$details,'trainers'=>$data['trainers'],'trainer_user_ids'=>$trainerIds,'native_registrations'=>$this->nativeRegistrations($runId,$linkId),'replayed'=>(bool)$replayed),$counts,$urls);
            $result['class_url']=Mage::helper('adminhtml')->getUrl('adminhtml/dashboard/index',array('course_id'=>$productId,'_query'=>array('run'=>$runId),'_nosecret'=>true));
            $w->update($this->table('mmd_tms_run_link'),array('result_json'=>json_encode($result)),array('link_id = ?'=>$linkId));
            $w->insert($this->table('mmd_tms_sync_log'),array('provider_id'=>$provider,'source_run_key'=>$data['source_run_key'],'revision'=>$data['revision'],'result_json'=>json_encode($result),'created_at'=>gmdate('Y-m-d H:i:s')));
            $w->commit();
            return $result;
        } catch (Exception $e) { $w->rollBack(); throw $e; }
        finally {
            if ($this->_idLockHeld) { $w->fetchOne('SELECT RELEASE_LOCK(?)',array('mmd-class-id')); $this->_idLockHeld=false; }
            $w->fetchOne('SELECT RELEASE_LOCK(?)',array($lock));
        }
    }

    protected function mirrorRoster(array $data,$linkId,$runId,$productId,array $pending)
    {
        $w=$this->_write; $table=$this->table('course_run_enrolments'); $members=$this->table('mmd_tms_member_link');
        $counts=array('learners_added'=>0,'learners_updated'=>0,'learners_removed'=>0); $emails=array();
        foreach ($data['cancelled']?array():$data['learners'] as $learner) {
            if (($learner['active']??true)===false) continue;
            $email=$learner['email']; $emails[]=$email;
            $existing=$w->fetchRow("SELECT * FROM `$table` WHERE run_id=? AND LOWER(TRIM(learner_email))=?",array($runId,$email));
            $member=$w->fetchRow("SELECT * FROM `$members` WHERE link_id=? AND email=? AND role_code='learner' ORDER BY active DESC LIMIT 1",array($linkId,$email));
            $w->insertOnDuplicate($table,array('product_id'=>$productId,'run_id'=>$runId,'learner_email'=>$email,'learner_name'=>$learner['name']),array('learner_name'));
            $w->insertOnDuplicate($members,array('link_id'=>$linkId,'source_id'=>$learner['source_id'],'email'=>$email,'role_code'=>'learner','active'=>1,'import_owned'=>$member?(int)$member['import_owned']:($existing?0:1),'independent_membership'=>$member?(int)$member['independent_membership']:($existing?1:0)),array('email','active'));
            if (!$existing) $counts['learners_added']++;
            elseif ($existing['learner_name']!==$learner['name']) $counts['learners_updated']++;
        }
        if (!$pending && !empty($data['roster_complete'])) {
            $old=$w->fetchAll("SELECT * FROM `$members` WHERE link_id=? AND role_code='learner' AND active=1",array($linkId));
            foreach ($old as $member) if (!in_array($member['email'],$emails,true)) {
                if ((int)$member['import_owned'] && !(int)$member['independent_membership']) { $w->delete($table,array('run_id = ?'=>$runId,'learner_email = ?'=>$member['email'])); $counts['learners_removed']++; }
                $w->update($members,array('active'=>0),array('id = ?'=>$member['id']));
            }
        }
        return $counts;
    }

    protected function nativeRegistrations($runId,$linkId)
    {
        return $this->_write->fetchAll('SELECT LOWER(TRIM(e.learner_email)) email,MIN(e.learner_name) name FROM ' . $this->table('course_run_enrolments') . ' e JOIN ' . $this->table('course_runs') . ' r ON r.run_id=e.run_id JOIN ' . $this->table('course_runs') . ' target ON target.run_id=? WHERE (r.run_id=target.run_id OR (target.course_start_date IS NOT NULL AND target.course_end_date IS NOT NULL AND r.product_id=target.product_id AND r.course_start_date=target.course_start_date AND r.course_end_date=target.course_end_date)) AND NOT EXISTS (SELECT 1 FROM ' . $this->table('mmd_tms_member_link') . ' m JOIN ' . $this->table('mmd_tms_run_link') . " l ON l.link_id=m.link_id WHERE l.run_id=e.run_id AND m.email=LOWER(TRIM(e.learner_email)) AND m.role_code='learner' AND m.import_owned=1 AND m.independent_membership=0) GROUP BY LOWER(TRIM(e.learner_email))",array($runId));
    }
}
