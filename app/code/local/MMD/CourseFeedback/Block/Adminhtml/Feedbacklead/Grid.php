<?php
class MMD_CourseFeedback_Block_Adminhtml_Feedbacklead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct() { parent::__construct(); $this->setId('feedbackLeadGrid'); $this->setDefaultSort('created_at'); $this->setDefaultDir('DESC'); $this->setSaveParametersInSession(true); $this->setUseAjax(true); }
    protected function _prepareCollection() { $this->setCollection(Mage::getModel('mmd_coursefeedback/lead')->getCollection()); return parent::_prepareCollection(); }
    protected function _prepareColumns() {
        $h = Mage::helper('mmd_coursefeedback');
        $this->addColumn('lead_id', array('header'=>$h->__('ID'),'index'=>'lead_id','width'=>50));
        $this->addColumn('created_at', array('header'=>$h->__('Received'),'index'=>'created_at','type'=>'datetime','width'=>140));
        $this->addColumn('name', array('header'=>$h->__('Name'),'index'=>'name'));
        $this->addColumn('email', array('header'=>$h->__('Email'),'index'=>'email'));
        $this->addColumn('course', array('header'=>$h->__('Course'),'index'=>'course'));
        $this->addColumn('trainer', array('header'=>$h->__('Trainer'),'index'=>'trainer'));
        $this->addColumn('rating_objectives', array('header'=>$h->__('Objectives'),'index'=>'rating_objectives','width'=>70,'align'=>'center'));
        $this->addColumn('rating_trainer', array('header'=>$h->__('Trainer'),'index'=>'rating_trainer','width'=>70,'align'=>'center'));
        $this->addColumn('rating_environment', array('header'=>$h->__('Env.'),'index'=>'rating_environment','width'=>60,'align'=>'center'));
        $this->addColumn('message', array('header'=>$h->__('Comments'),'index'=>'message','truncate'=>60));
        $this->addColumn('status', array('header'=>$h->__('Status'),'index'=>'status','width'=>90,'type'=>'options','options'=>array('new'=>'New','reviewed'=>'Reviewed','closed'=>'Closed')));
        return parent::_prepareColumns();
    }
    public function getGridUrl() { return $this->getUrl('*/*/grid', array('_current'=>true)); }
    public function getRowUrl($r) { return false; }
}
