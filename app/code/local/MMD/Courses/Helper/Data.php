<?php
class MMD_Courses_Helper_Data extends Mage_Core_Helper_Abstract

{

	
	public function getStates($countrycode){
		
		    if ($countrycode != '') {
				$statearray = Mage::getModel('directory/region')->getResourceCollection()->addCountryFilter($countrycode)->load();
				
				if(count($statearray)>0){
					
					$state[] = array(
								  'value'     => '',
								  'label'     => Mage::helper('courses')->__('--Please Select--')
								);			   
					  
					foreach ($statearray as $_state) {
						 $state[] = array(
									  'value'     => $_state->getCode(),
									  'label'     => $_state->getDefaultName()
									);
					}
				}
				
			}
			else{
				$state[] = array(
								  'value'     => '',
								  'label'     => Mage::helper('courses')->__('--Please Select--')
				);		
			}
		return $state;
		
	
	}
	
	public function getFirstName()
    {
        if (!Mage::getSingleton('customer/session')->isLoggedIn()) {
            return '';
        }
        $customer = Mage::getSingleton('customer/session')->getCustomer();
        return trim($customer->getFirstname());
    }
	
	public function getLastName()
    {
        if (!Mage::getSingleton('customer/session')->isLoggedIn()) {
            return '';
        }
        $customer = Mage::getSingleton('customer/session')->getCustomer();
        return trim($customer->getLastname());
    }

    public function getUserEmail()
    {
        if (!Mage::getSingleton('customer/session')->isLoggedIn()) {
            return '';
        }
        $customer = Mage::getSingleton('customer/session')->getCustomer();
        return $customer->getEmail();
    }
	
	
	public function getProfileImage($path,$name){
	
		return Mage::getBaseUrl('media').$path.'/'.$name;
	}
	
	
}