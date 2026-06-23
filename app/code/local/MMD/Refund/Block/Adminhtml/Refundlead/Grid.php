<?php
class MMD_Refund_Block_Adminhtml_Refundlead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct() { parent::__construct(); $this->setId('refundLeadGrid'); $this->setDefaultSort('created_at'); $this->setDefaultDir('DESC'); $this->setSaveParametersInSession(true); $this->setUseAjax(true); }
    protected function _prepareCollection() { $this->setCollection(Mage::getModel('mmd_refund/lead')->getCollection()); return parent::_prepareCollection(); }
    protected function _prepareColumns() {
        $h = Mage::helper('mmd_refund');
        $this->addColumn('lead_id', array('header'=>$h->__('ID'),'index'=>'lead_id','width'=>50));
        $this->addColumn('created_at', array('header'=>$h->__('Submission Date'),'index'=>'created_at','type'=>'datetime','width'=>150));
        $this->addColumn('name', array('header'=>$h->__('Name'),'index'=>'name'));
        $this->addColumn('email', array('header'=>$h->__('Email'),'index'=>'email'));
        $this->addColumn('telephone', array('header'=>$h->__('Phone'),'index'=>'telephone'));
        $this->addColumn('course', array('header'=>$h->__('Course'),'index'=>'course'));
        $this->addColumn('order_ref', array('header'=>$h->__('Order / Invoice'),'index'=>'order_ref'));
        $this->addColumn('message', array('header'=>$h->__('Reason'),'index'=>'message','truncate'=>70));
        $this->addColumn('status', array('header'=>$h->__('Status'),'index'=>'status','width'=>90,'type'=>'options','options'=>array('new'=>'New','reviewed'=>'Reviewed','closed'=>'Closed')));
        return parent::_prepareColumns();
    }
    public function getGridUrl() { return $this->getUrl('*/*/grid', array('_current'=>true)); }
    public function getRowUrl($r) { return false; }
}
