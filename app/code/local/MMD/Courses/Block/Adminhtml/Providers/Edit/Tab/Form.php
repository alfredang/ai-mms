<?php

class MMD_Courses_Block_Adminhtml_Providers_Edit_Tab_Form extends Mage_Adminhtml_Block_Widget_Form
{
  protected function _prepareForm()
  {
	  if ( Mage::getSingleton('adminhtml/session')->getTrainersData() )
      {
		  $data = Mage::getSingleton('adminhtml/session')->getTrainersData();
		  Mage::getSingleton('adminhtml/session')->setTrainersData(null);
      } elseif ( Mage::registry('providers_data') ) {
         
		  $data = Mage::registry('providers_data')->getData();
		  
      } else {
	  
	  	  $data = array();
	  }
	  
	  
      $form = new Varien_Data_Form();
      $this->setForm($form);
      $fieldset = $form->addFieldset('providers_form', array('legend'=>Mage::helper('courses')->__('Provider information')));
      
	  
	  $provider[] = array(
							  'value'     => '',
							  'label'     => Mage::helper('courses')->__('-- Please select --'),
              		);
					
	  $code = Mage::getStoreConfig('courses/general/provider_code');
	  if($code){
		  $providers = Mage::getModel('eav/config')->getAttribute('catalog_product',$code);	
		  
		  foreach ( $providers->getSource()->getAllOptions(true, true) as $option){
				if($option['value']!=''){
					$provider[] = array(
								  'value'     => $option['value'],
								  'label'     => Mage::helper('courses')->__($option['label']),
								);
				}
		  }
	  }
	  
	  
	  $provider1[] = array(
							  'value'     => '',
							  'label'     => Mage::helper('courses')->__('-- Please select --'),
              		);
					
	  $code1 = Mage::getStoreConfig('courses/general/provider_code');
	  if($code1){
		  $providers1 = Mage::getModel('eav/config')->getAttribute('catalog_product',$code1);	
		  
		  foreach ( $providers1->getSource()->getAllOptions(true, true) as $option1){
				if($option1['value']!=''){
					$provider1[] = array(
								  'value'     => $option1['label'],
								  'label'     => Mage::helper('courses')->__($option1['label']),
								);
				}
		  }
	  }
	 
	 
	 
	 $providerspe[] = array(
							  'value'     => '',
							  'label'     => Mage::helper('courses')->__('-- Please select --'),
              		);
					
	  $codespe = Mage::getStoreConfig('courses/general/pro_spec_code');
	  if($codespe){
		  $providersspe = Mage::getModel('eav/config')->getAttribute('catalog_product',$codespe);	
		  
		  foreach ( $providersspe->getSource()->getAllOptions(true, true) as $optionspe){
				if($optionspe['value']!=''){
					$providerspe[] = array(
								  'value'     => $optionspe['value'],
								  'label'     => Mage::helper('courses')->__($optionspe['label']),
								);
				}
		  }
	  }
	 
	 $providerarea[] = array(
							  'value'     => '',
							  'label'     => Mage::helper('courses')->__('-- Please select --'),
              		);
					
	  $codearea = Mage::getStoreConfig('courses/general/provider_area_code');
	  if($codearea){
		  $providersarea = Mage::getModel('eav/config')->getAttribute('catalog_product',$codearea);	
		  
		  foreach ( $providersarea->getSource()->getAllOptions(true, true) as $optionarea){
				if($optionarea['value']!=''){
					$providerarea[] = array(
								  'value'     => $optionarea['value'],
								  'label'     => Mage::helper('courses')->__($optionarea['label']),
								);
				}
		  }
	  }
	 
	
	 
	 
	  $fieldset->addField('title', 'select', array(
          'label'     => Mage::helper('courses')->__('Company Name'),
          'name'      => 'title',
		  'required'  => true,
          'values'    => $provider1,
      ));
	    	
	 
	 
	  
	    $fieldset->addField('relation_id', 'select', array(
          'label'     => Mage::helper('courses')->__('Provider'),
          'name'      => 'relation_id',
		  'required'  => true,
          'values'    => $provider,
      ));
	    	  
	 
	  $fieldset->addField('providerspecialty', 'select', array(
          'label'     => Mage::helper('courses')->__('Provider Speciality'),
          'name'      => 'providerspecialty',
		  'values'    => $providerspe,
      ));
	  
	  $fieldset->addField('providerarea', 'select', array(
          'label'     => Mage::helper('courses')->__('Provider Area'),
          'name'      => 'providerarea',
		  'values'    => $providerarea,
      ));
	  
	 
	  $fieldset->addField('address', 'editor', array(
          'name'      => 'address',
          'label'     => Mage::helper('courses')->__('Provider Address'),
          'title'     => Mage::helper('courses')->__('Provider Address'),
          'style'     => 'width:275px; height:100px;',
          'wysiwyg'   => false,
          'required'  => false,
      ));
	   
	
	  
    
	  
	 
	  
	  $fieldset->addField('email', 'text', array(
          'label'     => Mage::helper('courses')->__('Email'),
		  'class'     => 'required-entry validate-email',
          'required'  => true,
          'name'      => 'email',
      ));
	  
	   $fieldset->addField('tel', 'text', array(
          'label'     => Mage::helper('courses')->__('Telephone'),
		  'class'     => 'required-entry',
          'required'  => true,
          'name'      => 'tel',
      ));
	  
	  
	  
	   $fieldset->addField('website', 'text', array(
          'label'     => Mage::helper('courses')->__('Webiste'),
		  'class'     => 'required-entry',
          'required'  => true,
          'name'      => 'website',
      ));
	  
	  
	
	
		
	  $fieldset->addField('profile_image', 'image', array(
          'label'     => Mage::helper('courses')->__('Provider Logo'),
          'required'  => false,
          'name'      => 'profile_image',
	  ));
	 
	 
	 
      $fieldset->addField('status', 'select', array(
          'label'     => Mage::helper('courses')->__('Status'),
          'name'      => 'status',
          'values'    => array(
              array(
                  'value'     => 1,
                  'label'     => Mage::helper('courses')->__('Enabled'),
              ),

              array(
                  'value'     => 0,
                  'label'     => Mage::helper('courses')->__('Disabled'),
              ),
          ),
      ));
	
			
	 
	  $form->setValues($data);		
     
			
     
      
      return parent::_prepareForm();
  }
}