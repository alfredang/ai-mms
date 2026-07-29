<?php
class MMD_Customised_Block_Adminhtml_Customisedlead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct()
    {
        parent::__construct();
        $this->setId('customisedLeadGrid'); $this->setDefaultSort('created_at'); $this->setDefaultDir('DESC');
        $this->setSaveParametersInSession(true); $this->setUseAjax(true);
    }
    protected function _prepareCollection() { $this->setCollection(Mage::getModel('mmd_customised/lead')->getCollection()); return parent::_prepareCollection(); }
    protected function _prepareColumns()
    {
        $h = Mage::helper('mmd_customised');
        $this->addColumn('lead_id', array('header'=>$h->__('ID'),'index'=>'lead_id','width'=>50));
        $this->addColumn('created_at', array('header'=>$h->__('Submission Date'),'index'=>'created_at','type'=>'datetime','width'=>150));
        $this->addColumn('name', array('header'=>$h->__('Name'),'index'=>'name'));
        $this->addColumn('email', array('header'=>$h->__('Email'),'index'=>'email'));
        $this->addColumn('telephone', array('header'=>$h->__('Phone'),'index'=>'telephone'));
        $this->addColumn('company', array('header'=>$h->__('Company'),'index'=>'company'));
        $this->addColumn('num_pax', array('header'=>$h->__('Pax'),'index'=>'num_pax','width'=>60));
        $this->addColumn('training_topic', array('header'=>$h->__('Topic'),'index'=>'training_topic'));
        $this->addColumn('preferred_dates', array('header'=>$h->__('Preferred Dates'),'index'=>'preferred_dates'));
        $this->addColumn('message', array('header'=>$h->__('Message'),'index'=>'message','truncate'=>60));
        $this->addColumn('status', array('header'=>$h->__('Status'),'index'=>'status','width'=>90,'type'=>'options','options'=>array('new'=>'New','replied'=>'Replied','closed'=>'Closed')));
        $this->addColumn('mailerlite_status', array('header'=>$h->__('MailerLite'),'index'=>'mailerlite_status','type'=>'options','width'=>'100px','options'=>array('sent'=>'Sent','skipped'=>'Excluded','unsubscribed'=>'Unsubscribed','blocked'=>'Blocked','failed'=>'Failed'),'renderer'=>'MMD_Leads_Block_Adminhtml_Leads_Grid_Renderer_Mailerlite'));
        return parent::_prepareColumns();
    }
    protected function _prepareMassaction()
    {
        $this->setMassactionIdField('lead_id');
        $this->getMassactionBlock()->setFormFieldName('leads');
        $this->getMassactionBlock()->addItem('mailerlite', array(
            'label' => Mage::helper('mmd_customised')->__('Send to MailerLite'),
            'url'   => $this->getUrl('*/*/massMailerlite'),
        ));
        return $this;
    }
    public function getGridUrl() { return $this->getUrl('*/*/grid', array('_current'=>true)); }
    public function getRowUrl($row) { return false; }
}
