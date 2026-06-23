<?php
class MMD_Trainer_Block_Adminhtml_Trainerlead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct()
    {
        parent::__construct();
        $this->setId('trainerLeadGrid');
        $this->setDefaultSort('created_at');
        $this->setDefaultDir('DESC');
        $this->setSaveParametersInSession(true);
        $this->setUseAjax(true);
    }

    protected function _prepareCollection()
    {
        $this->setCollection(Mage::getModel('mmd_trainer/lead')->getCollection());
        return parent::_prepareCollection();
    }

    protected function _prepareColumns()
    {
        $h = Mage::helper('mmd_trainer');
        $yn = array('yes' => 'Yes', 'no' => 'No', '' => '-');
        $this->addColumn('lead_id', array('header' => $h->__('ID'), 'index' => 'lead_id', 'width' => 50));
        $this->addColumn('created_at', array('header' => $h->__('Submission Date'), 'index' => 'created_at', 'type' => 'datetime', 'width' => 150));
        $this->addColumn('name', array('header' => $h->__('Name'), 'index' => 'name'));
        $this->addColumn('email', array('header' => $h->__('Email'), 'index' => 'email'));
        $this->addColumn('telephone', array('header' => $h->__('Phone'), 'index' => 'telephone'));
        $this->addColumn('qualification', array('header' => $h->__('Qualification'), 'index' => 'qualification'));
        $this->addColumn('expertise', array('header' => $h->__('Expertise'), 'index' => 'expertise'));
        $this->addColumn('aclp', array('header' => $h->__('ACLP'), 'index' => 'aclp', 'width' => 60, 'type' => 'options', 'options' => $yn));
        $this->addColumn('taepp', array('header' => $h->__('TAEPP'), 'index' => 'taepp', 'width' => 60, 'type' => 'options', 'options' => $yn));
        $this->addColumn('years_experience', array('header' => $h->__('Years Exp.'), 'index' => 'years_experience', 'width' => 80));
        $this->addColumn('message', array('header' => $h->__('Message'), 'index' => 'message', 'truncate' => 70));
        $this->addColumn('status', array(
            'header' => $h->__('Status'), 'index' => 'status', 'width' => 90,
            'type' => 'options', 'options' => array('new' => 'New', 'replied' => 'Replied', 'closed' => 'Closed'),
        ));
        return parent::_prepareColumns();
    }

    public function getGridUrl()
    {
        return $this->getUrl('*/*/grid', array('_current' => true));
    }

    public function getRowUrl($row)
    {
        return false;
    }
}
