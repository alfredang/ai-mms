<?php
class MMD_Courses_Block_Providers extends Mage_Core_Block_Template
{
	public function _prepareLayout()
    {
		return parent::_prepareLayout();
    }
    
     public function getProviders()     
     { 
        return Mage::getModel('courses/providers')->getCollection();
        
    }
	
	public function getSearchResults()     
    { 
        return Mage::registry('provider_results');
        
    }
	
	public function getProviderByArea($id)     
    { 
		$results = Mage::getModel('courses/providers')->getCollection()
					->addFieldToFilter('relation_id', array('eq' => $id));
        return $results;
        
    }
	
	public function getProviderByProviderspecialty($id)     
    { 
		$results = Mage::getModel('courses/providers')->getCollection()
					->addFieldToFilter('providerspecialty', array('eq' => $id));
        return $results;
        
    }
	
	
	public function getProviderByProviderarea($id)     
    { 
		$results = Mage::getModel('courses/providers')->getCollection()
					->addFieldToFilter('providerarea', array('eq' => $id));
        return $results;
        
    }
	
	
}