<?php
/** Read-side ownership/session helpers; native classes retain existing behavior. */
class MMD_RoleManager_Helper_Handover extends Mage_Core_Helper_Abstract
{
    protected $_available;
    public function available()
    {
        if($this->_available===null) {
            $r=Mage::getSingleton('core/resource');
            $this->_available=$r->getConnection('core_read')->isTableExists($r->getTableName('mmd_tms_run_link'));
        }
        return $this->_available;
    }
    public function link($runId)
    {
        if(!(int)$runId || !$this->available())return null;
        $r=Mage::getSingleton('core/resource');
        return $r->getConnection('core_read')->fetchRow('SELECT * FROM ' . $r->getTableName('mmd_tms_run_link') . ' WHERE run_id=?',array((int)$runId))?:null;
    }
    public function isManaged($runId) { return (bool)$this->link($runId); }
    public function isActive($runId) { $link=$this->link($runId); return !$link || (int)$link['active']===1; }
    public function canAccessRun($runId,$role,$userId,$email,$productId=0)
    {
        $link=$this->link($runId);
        if(!$link)return true;
        $r=Mage::getSingleton('core/resource');$read=$r->getConnection('core_read');
        $run=$read->fetchRow('SELECT * FROM ' . $r->getTableName('course_runs') . ' WHERE run_id=?',array((int)$runId));
        if(!$run || ($productId && (int)$run['product_id']!==(int)$productId))return false;
        if(in_array($role,array('admin','super_admin','training_provider','developer'),true))return true;
        if(!(int)$link['active'])return false;
        if($role==='trainer')return (int)$run['trainer_user_id']===(int)$userId;
        if($role==='learner')return (bool)$read->fetchOne('SELECT enrolment_id FROM ' . $r->getTableName('course_run_enrolments') . ' WHERE run_id=? AND LOWER(learner_email)=?',array((int)$runId,strtolower(trim($email))));
        return false;
    }
    public function sessions($runId)
    {
        $link=$this->link($runId);
        return $link?(json_decode($link['sessions_json'],true)?:array()):array();
    }
    public function feedbackUrl($runId,$nativeUrl)
    {
        $link=$this->link($runId);
        return $link?((int)$link['active']?(string)$link['feedback_url']:''):$nativeUrl;
    }
    public function noteIndependentMembership($runId,$email)
    {
        if(!$this->available())return;
        $r=Mage::getSingleton('core/resource');
        $r->getConnection('core_write')->query('UPDATE ' . $r->getTableName('mmd_tms_member_link') . ' m JOIN ' . $r->getTableName('mmd_tms_run_link') . ' l ON l.link_id=m.link_id SET m.independent_membership=1 WHERE l.run_id=? AND LOWER(m.email)=?',array((int)$runId,strtolower(trim($email))));
    }
}
