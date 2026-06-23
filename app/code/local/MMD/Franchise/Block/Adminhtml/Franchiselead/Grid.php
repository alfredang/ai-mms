<?php
class MMD_Franchise_Block_Adminhtml_Franchiselead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct()
    {
        parent::__construct();
        $this->setId('franchiseLeadGrid');
        $this->setDefaultSort('created_at');
        $this->setDefaultDir('DESC');
        $this->setSaveParametersInSession(true);
        $this->setUseAjax(true);
    }

    protected function _prepareCollection()
    {
        $this->setCollection(Mage::getModel('mmd_franchise/lead')->getCollection());
        return parent::_prepareCollection();
    }

    protected function _prepareColumns()
    {
        $h = Mage::helper('mmd_franchise');
        $this->addColumn('lead_id', array('header' => $h->__('ID'), 'index' => 'lead_id', 'width' => 50));
        $this->addColumn('created_at', array('header' => $h->__('Submission Date'), 'index' => 'created_at', 'type' => 'datetime', 'width' => 150));
        $this->addColumn('name', array('header' => $h->__('Name'), 'index' => 'name'));
        $this->addColumn('email', array('header' => $h->__('Email'), 'index' => 'email'));
        $this->addColumn('telephone', array('header' => $h->__('Phone / WhatsApp'), 'index' => 'telephone'));
        $this->addColumn('country', array('header' => $h->__('Country / Region'), 'index' => 'country'));
        $this->addColumn('company', array('header' => $h->__('Company'), 'index' => 'company'));
        $this->addColumn('message', array('header' => $h->__('Message'), 'index' => 'message', 'truncate' => 80));
        $this->addColumn('store_code', array('header' => $h->__('Store'), 'index' => 'store_code', 'width' => 70));
        $this->addColumn('status', array(
            'header'  => $h->__('Status'),
            'index'   => 'status',
            'width'   => 90,
            'type'    => 'options',
            'options' => array('new' => 'New', 'replied' => 'Replied', 'closed' => 'Closed'),
        ));
        return parent::_prepareColumns();
    }

    public function getGridUrl()
    {
        return $this->getUrl('*/*/grid', array('_current' => true));
    }
}
