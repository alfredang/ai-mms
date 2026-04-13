<?php

class MMD_Courses_Block_Adminhtml_Providers_Edit_Tabs extends Mage_Adminhtml_Block_Widget_Tabs
{

  public function __construct()
  {
      parent::__construct();
      $this->setId('providers_tabs');
      $this->setDestElementId('edit_form');
      $this->setTitle(Mage::helper('courses')->__('Providers'));
  }

  protected function _beforeToHtml()
  {
      $this->addTab('form_section', array(
          'label'     => Mage::helper('courses')->__('Providers Information'),
          'title'     => Mage::helper('courses')->__('Providers Information'),
          'content'   => $this->getLayout()->createBlock('courses/adminhtml_providers_edit_tab_form')->toHtml(),
      ));
     
      return parent::_beforeToHtml();
  }
}