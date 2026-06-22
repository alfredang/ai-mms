<?php
class MMD_Hiring_Block_Adminhtml_Hiringlead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct() { parent::__construct(); $this->setId('hiringLeadGrid'); $this->setDefaultSort('created_at'); $this->setDefaultDir('DESC'); $this->setSaveParametersInSession(true); $this->setUseAjax(true); }
    protected function _prepareCollection() { $this->setCollection(Mage::getModel('mmd_hiring/lead')->getCollection()); return parent::_prepareCollection(); }
    protected function _prepareColumns() {
        $h = Mage::helper('mmd_hiring');
        $this->addColumn('lead_id', array('header'=>$h->__('ID'),'index'=>'lead_id','width'=>50));
        $this->addColumn('created_at', array('header'=>$h->__('Received'),'index'=>'created_at','type'=>'datetime','width'=>150));
        $this->addColumn('name', array('header'=>$h->__('Name'),'index'=>'name'));
        $this->addColumn('email', array('header'=>$h->__('Email'),'index'=>'email'));
        $this->addColumn('telephone', array('header'=>$h->__('Phone'),'index'=>'telephone'));
        $this->addColumn('position', array('header'=>$h->__('Position'),'index'=>'position'));
        $this->addColumn('years_experience', array('header'=>$h->__('Years Exp.'),'index'=>'years_experience','width'=>80));
        $this->addColumn('expertise', array('header'=>$h->__('Expertise'),'index'=>'expertise'));
        $this->addColumn('linkedin', array('header'=>$h->__('LinkedIn/Resume'),'index'=>'linkedin'));
        $this->addColumn('message', array('header'=>$h->__('Cover Note'),'index'=>'message','truncate'=>60));
        $this->addColumn('status', array('header'=>$h->__('Status'),'index'=>'status','width'=>90,'type'=>'options','options'=>array('new'=>'New','replied'=>'Replied','closed'=>'Closed')));
        return parent::_prepareColumns();
    }
    public function getGridUrl() { return $this->getUrl('*/*/grid', array('_current'=>true)); }
    public function getRowUrl($r) { return false; }
}
