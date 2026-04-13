<?php

class MMD_Courses_Block_Adminhtml_Providers_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
  public function __construct()
  {
      parent::__construct();
      $this->setId('providersGrid');
      $this->setDefaultSort('providers_id');
      $this->setDefaultDir('ASC');
      $this->setSaveParametersInSession(true);
  }

  protected function _prepareCollection()
  {
      $collection = Mage::getModel('courses/providers')->getCollection();
      $this->setCollection($collection);
      return parent::_prepareCollection();
  }

  protected function _prepareColumns()
  {
      $this->addColumn('providers_id', array(
          'header'    => Mage::helper('courses')->__('ID'),
          'align'     =>'right',
          'width'     => '50px',
          'index'     => 'providers_id',
      ));
	  
	 
	   $this->addColumn('title', array(
          'header'    => Mage::helper('courses')->__('Company Name'),
          'align'     =>'left',
          'index'     => 'title',
		  ));
	     
      	  
	  
	$this->addColumn('relation_id', array(
          'header'    => Mage::helper('courses')->__('Provider'),
          'align'     =>'left',
          'index'     => 'relation_id',
		  'renderer'  => 'MMD_Courses_Block_Adminhtml_Providers_Grid_Renderer_Area'
      ));
	  
	  $this->addColumn('telephone', array(
          'header'    => Mage::helper('courses')->__('Tel'),
          'align'     =>'left',
          'index'     => 'tel',
      ));
	  
	  $this->addColumn('email', array(
          'header'    => Mage::helper('courses')->__('Email'),
          'align'     =>'left',
          'index'     => 'email',
      ));
	  

	   
	  $this->addColumn('status', array(
          'header'    => Mage::helper('courses')->__('Status'),
          'align'     => 'left',
          'width'     => '80px',
          'index'     => 'status',
          'type'      => 'options',
          'options'   => array(
              1 => 'Enabled',
              0 => 'Disabled',
          ),
      ));
      $this->addColumn('action',
            array(
                'header'    =>  Mage::helper('courses')->__('Action'),
                'width'     => '100',
                'type'      => 'action',
                'getter'    => 'getId',
                'actions'   => array(
                    array(
                        'caption'   => Mage::helper('courses')->__('Edit'),
                        'url'       => array('base'=> '*/*/edit'),
                        'field'     => 'id'
                    )
                ),
                'filter'    => false,
                'sortable'  => false,
                'index'     => 'stores',
                'is_system' => true,
        ));
		
		$this->addExportType('*/*/exportCsv', Mage::helper('courses')->__('CSV'));
		$this->addExportType('*/*/exportXml', Mage::helper('courses')->__('XML'));
	  
      return parent::_prepareColumns();
  }

    protected function _prepareMassaction()
    {
        $this->setMassactionIdField('providers_id');
        $this->getMassactionBlock()->setFormFieldName('providers');

        $this->getMassactionBlock()->addItem('delete', array(
             'label'    => Mage::helper('courses')->__('Delete'),
             'url'      => $this->getUrl('*/*/massDelete'),
             'confirm'  => Mage::helper('courses')->__('Are you sure?')
        ));

        $statuses = Mage::getSingleton('courses/status')->getOptionArray();

        array_unshift($statuses, array('label'=>'', 'value'=>''));
        $this->getMassactionBlock()->addItem('status', array(
             'label'=> Mage::helper('courses')->__('Change status'),
             'url'  => $this->getUrl('*/*/massStatus', array('_current'=>true)),
             'additional' => array(
                    'visibility' => array(
                         'name' => 'status',
                         'type' => 'select',
                         'class' => 'required-entry',
                         'label' => Mage::helper('courses')->__('Status'),
                         'values' => $statuses
                     )
             )
        ));
        return $this;
    }


  public function getRowUrl($row)
  {
      return $this->getUrl('*/*/edit', array('id' => $row->getId()));
  }

}