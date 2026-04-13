<?php
class MMD_Courses_Block_Adminhtml_Providers extends Mage_Adminhtml_Block_Widget_Grid_Container
{
  public function __construct()
  {
    $this->_controller = 'adminhtml_providers';
    $this->_blockGroup = 'courses';
    $this->_headerText = Mage::helper('courses')->__('Providers');
    $this->_addButtonLabel = Mage::helper('courses')->__('Add Item');
    parent::__construct();
  }
}