<?php
class MMD_Reschedule_Block_Adminhtml_Reschedulelead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct() { parent::__construct(); $this->setId('rescheduleLeadGrid'); $this->setDefaultSort('created_at'); $this->setDefaultDir('DESC'); $this->setSaveParametersInSession(true); $this->setUseAjax(true); }
    protected function _prepareCollection() { $this->setCollection(Mage::getModel('mmd_reschedule/lead')->getCollection()); return parent::_prepareCollection(); }
    protected function _prepareColumns() {
        $h = Mage::helper('mmd_reschedule');
        $this->addColumn('lead_id', array('header'=>$h->__('ID'),'index'=>'lead_id','width'=>50));
        $this->addColumn('created_at', array('header'=>$h->__('Received'),'index'=>'created_at','type'=>'datetime','width'=>150));
        $this->addColumn('name', array('header'=>$h->__('Name'),'index'=>'name'));
        $this->addColumn('email', array('header'=>$h->__('Email'),'index'=>'email'));
        $this->addColumn('telephone', array('header'=>$h->__('Phone'),'index'=>'telephone'));
        $this->addColumn('course', array('header'=>$h->__('Course'),'index'=>'course'));
        $this->addColumn('current_date', array('header'=>$h->__('Current Date'),'index'=>'current_date'));
        $this->addColumn('preferred_date', array('header'=>$h->__('Preferred Date'),'index'=>'preferred_date'));
        $this->addColumn('status', array('header'=>$h->__('Status'),'index'=>'status','width'=>90,'type'=>'options','options'=>array('new'=>'New','confirmed'=>'Confirmed','closed'=>'Closed')));
        return parent::_prepareColumns();
    }
    public function getGridUrl() { return $this->getUrl('*/*/grid', array('_current'=>true)); }
    public function getRowUrl($r) { return false; }
}
