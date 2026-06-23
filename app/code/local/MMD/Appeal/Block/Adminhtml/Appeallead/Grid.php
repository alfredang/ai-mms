<?php
class MMD_Appeal_Block_Adminhtml_Appeallead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct() { parent::__construct(); $this->setId('appealLeadGrid'); $this->setDefaultSort('created_at'); $this->setDefaultDir('DESC'); $this->setSaveParametersInSession(true); $this->setUseAjax(true); }
    protected function _prepareCollection() { $this->setCollection(Mage::getModel('mmd_appeal/lead')->getCollection()); return parent::_prepareCollection(); }
    protected function _prepareColumns() {
        $h = Mage::helper('mmd_appeal');
        $this->addColumn('lead_id', array('header'=>$h->__('ID'),'index'=>'lead_id','width'=>50));
        $this->addColumn('created_at', array('header'=>$h->__('Submission Date'),'index'=>'created_at','type'=>'datetime','width'=>140));
        $this->addColumn('name', array('header'=>$h->__('Name'),'index'=>'name'));
        $this->addColumn('nric', array('header'=>$h->__('NRIC'),'index'=>'nric','width'=>90));
        $this->addColumn('email', array('header'=>$h->__('Email'),'index'=>'email'));
        $this->addColumn('telephone', array('header'=>$h->__('Phone'),'index'=>'telephone'));
        $this->addColumn('course', array('header'=>$h->__('Course Title'),'index'=>'course'));
        $this->addColumn('course_code', array('header'=>$h->__('Course Code'),'index'=>'course_code'));
        $this->addColumn('course_start_date', array('header'=>$h->__('Start Date'),'index'=>'course_start_date'));
        $this->addColumn('course_end_date', array('header'=>$h->__('End Date'),'index'=>'course_end_date'));
        $this->addColumn('assessment_date', array('header'=>$h->__('Assessment Date'),'index'=>'assessment_date'));
        $this->addColumn('message', array('header'=>$h->__('Reason'),'index'=>'message','truncate'=>50));
        $this->addColumn('status', array('header'=>$h->__('Status'),'index'=>'status','width'=>90,'type'=>'options','options'=>array('new'=>'New','reviewed'=>'Reviewed','closed'=>'Closed')));
        return parent::_prepareColumns();
    }
    public function getGridUrl() { return $this->getUrl('*/*/grid', array('_current'=>true)); }
    public function getRowUrl($r) { return false; }
}
