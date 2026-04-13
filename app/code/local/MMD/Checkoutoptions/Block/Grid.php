<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
class MMD_Checkoutoptions_Block_Grid  extends Mage_Adminhtml_Block_Widget_Grid
{
  public function __construct()
  {
      parent::__construct();
      
      $this->setId('checkoutoptionsgrid');
      $this->setDefaultSort('attribute_code');
      $this->setDefaultDir('ASC');
      $this->setSaveParametersInSession(true);
      $this->setTemplate('checkoutoptions/grid.phtml');
  }

  protected function _prepareCollection()
  {
      $type='mmd_checkout';
      
      $oResource = Mage::getResourceModel('eav/entity_attribute');
            
      $this->type=$type;
      
            $collection = Mage::getResourceModel('eav/entity_attribute_collection')
                ->setEntityTypeFilter( Mage::getModel('eav/entity')->setType($type)->getTypeId() )
            ;
            $collection->getSelect()->join(
                array('additional_table' => $oResource->getTable('catalog/eav_attribute')),
                'additional_table.attribute_id=main_table.attribute_id'
            );
      
      
      $this->setCollection($collection);
      return parent::_prepareCollection();
      
  }

  protected function _prepareColumns()
  {
      $this->addColumn('attribute_code', array(
            'header'=>Mage::helper('adminhtml')->__('Attribute Code'),
            'sortable'=>true,
            'index'=>'attribute_code'
        ));

        $this->addColumn('frontend_label', array(
            'header'=>Mage::helper('adminhtml')->__('Attribute Label'),
            'sortable'=>true,
            'index'=>'frontend_label'
        ));

        $this->addColumn('frontend_input', array(
            'header'=>Mage::helper('checkoutoptions')->__('Input Type'),
            'sortable'=>true,
            'index'=>'frontend_input',
            'type' => 'options',
            'options' => array(
                'text'          => Mage::helper('catalog')->__('Text Field'),
                'textarea'      => Mage::helper('catalog')->__('Text Area'),
                'date'          => Mage::helper('catalog')->__('Date'),
                'boolean'       => Mage::helper('catalog')->__('Yes/No'),
                'multiselect'   => Mage::helper('catalog')->__('Multiple Select'),
                'select'        => Mage::helper('catalog')->__('Dropdown'),
                'checkbox'      => Mage::helper('catalog')->__('Checkbox'),
                'radio'         => Mage::helper('catalog')->__('Radiobutton'),
        		'static'        => Mage::helper('catalog')->__('Static Text'),
            ),
        ));
        
        $this->addColumn('is_filterable', array(
            'header'=>Mage::helper('checkoutoptions')->__('Attribute Placeholder'),
            'sortable'=>true,
            'index'=>'is_filterable',
            'type' => 'options',
            'options' => array(
                '1' => Mage::helper('checkoutoptions')->__('On Top'),
                '2' => Mage::helper('checkoutoptions')->__('At the Bottom'),
            ),
            'align' => 'left',
        ));
        
        $this->addColumn('is_searchable', array(
            'header'=>Mage::helper('checkoutoptions')->__('Step (for one page)'),
            'sortable'=>true,
            'index'=>'is_searchable',
            'type' => 'options',
            'options' => Mage::helper('checkoutoptions')->getStepData('onepage', 'hash'),
#            'align' => 'center',
        ));
 
        $this->addColumn('is_comparable', array(
            'header'=>Mage::helper('checkoutoptions')->__('Step (for multi-address)'),
            'sortable'=>true,
            'index'=>'is_comparable',
            'type' => 'options',
            'options' => Mage::helper('checkoutoptions')->getStepData('multipage', 'hash'),
#            'align' => 'center',
        ));
        
        $this->addColumn('is_required', array(
            'header'=>Mage::helper('catalog')->__('Required'),
            'sortable'=>true,
            'index'=>'is_required',
            'type' => 'options',
            'options' => array(
                '1' => Mage::helper('adminhtml')->__('Yes'),
                '0' => Mage::helper('adminhtml')->__('No'),
            ),
            'width' => 100,
            'align' => 'center',
        ));
        
        $this->addColumn('mmd_registration_page', array(
            'header'=>Mage::helper('checkoutoptions')->__('On Registration'),
            'sortable'=>true,
            'index'=>'mmd_registration_page',
            'type' => 'options',
            'options' => array(
                '1' => Mage::helper('adminhtml')->__('Yes'),
                '0' => Mage::helper('adminhtml')->__('No'),
            ),
            'width' => 100,
            'align' => 'center',
        ));
        
        $this->addColumn('mmd_filterable', array(
            'header'=>Mage::helper('checkoutoptions')->__('On Sales Grid'),
            'sortable'=>true,
            'index'=>'mmd_filterable',
            'type' => 'options',
            'options' => array(
                '1' => Mage::helper('adminhtml')->__('Yes'),
                '0' => Mage::helper('adminhtml')->__('No'),
            ),
            'width' => 100,
            'align' => 'center',
        ));
 
      return parent::_prepareColumns();
  }

  public function addNewButton(){
  	return $this->getButtonHtml(
  		Mage::helper('checkoutoptions')->__('New Attribute'), //label
  		"setLocation('".$this->getUrl('*/*/new', array('attribute_id'=>0))."')", //url
  		"scalable add" //classe css
  		);
  }
  
  public function importButton(){
  	$connection = Mage::getSingleton('core/resource')->getConnection('core_read');
  	
  	$tables = $connection->fetchCol("SHOW TABLES LIKE 'mmd_sufm%'");
  	
  	if (!Mage::getStoreConfig('checkoutoptions/display_import', 0) && in_array('mmd_sufm_customer_entity_data', $tables) && in_array('mmd_sufm_custom_attribute_description', $tables) && in_array('mmd_sufm_custom_attribute_need_select', $tables)) /* Comment: MMD_Checkoutoptions_IndexController -> importAction() */
  	{
  		return $this->getButtonHtml(
	  		Mage::helper('checkoutoptions')->__('Import Custom Registration Fields module data'), //label
	  		"setLocation('".$this->getUrl('*/*/import')."')", //url
	  		"scalable add" //classe css
		);
  	}
	else 
	{
		return '';
	}
  }
  
  public function getRowUrl($row)
  {
      return $this->getUrl('*/*/edit', array('attribute_id' => $row->getAttributeId()));
  }
}

?>