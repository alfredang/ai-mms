<?php
class MMD_Corporate_Block_Adminhtml_Corporatelead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct()
    {
        parent::__construct();
        $this->setId('corporateLeadGrid'); $this->setDefaultSort('created_at'); $this->setDefaultDir('DESC');
        $this->setSaveParametersInSession(true); $this->setUseAjax(true);
    }
    protected function _prepareCollection() { $this->setCollection(Mage::getModel('mmd_corporate/lead')->getCollection()); return parent::_prepareCollection(); }
    protected function _prepareColumns()
    {
        $h = Mage::helper('mmd_corporate');
        $this->addColumn('lead_id', array('header'=>$h->__('ID'),'index'=>'lead_id','width'=>50));
        $this->addColumn('created_at', array('header'=>$h->__('Received'),'index'=>'created_at','type'=>'datetime','width'=>150));
        $this->addColumn('name', array('header'=>$h->__('Name'),'index'=>'name'));
        $this->addColumn('email', array('header'=>$h->__('Email'),'index'=>'email'));
        $this->addColumn('telephone', array('header'=>$h->__('Phone'),'index'=>'telephone'));
        $this->addColumn('company', array('header'=>$h->__('Company'),'index'=>'company'));
        $this->addColumn('num_pax', array('header'=>$h->__('Pax'),'index'=>'num_pax','width'=>60));
        $this->addColumn('training_topic', array('header'=>$h->__('Topic'),'index'=>'training_topic'));
        $this->addColumn('preferred_dates', array('header'=>$h->__('Preferred Dates'),'index'=>'preferred_dates'));
        $this->addColumn('message', array('header'=>$h->__('Message'),'index'=>'message','truncate'=>60));
        $this->addColumn('status', array('header'=>$h->__('Status'),'index'=>'status','width'=>90,'type'=>'options','options'=>array('new'=>'New','replied'=>'Replied','closed'=>'Closed')));
        return parent::_prepareColumns();
    }
    public function getGridUrl() { return $this->getUrl('*/*/grid', array('_current'=>true)); }
    public function getRowUrl($row) { return false; }
}
