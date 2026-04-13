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
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Checkoutoptions_Model_Rewrite_FrontCustomerCustomer extends Mage_Customer_Model_Customer
{
    protected $_cfmCustomFields;

    protected function _beforeSave()
    {
        $oReq = Mage::app()->getFrontController()->getRequest();
        
        $data = $oReq->getPost('mmdreg');
        
        if($data && !Mage::registry('mmd_customer_saved') && !Mage::registry('mmd_customer_to_save'))
        {
            $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
            foreach ($data as $sKey => $sVal)
            {
                $oAttribute->setCustomValue($sKey, $sVal, 'register');
            }
            Mage::register('mmd_customer_to_save', true);
        }
         
        return parent::_beforeSave();
    }
    protected function _afterSave()
    {
        $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
        if(Mage::registry('mmd_customer_to_save') && !Mage::registry('mmd_customer_saved'))
        {
            $customerId = $this->getId();
            $oAttribute->saveCustomerData($customerId);
            $oAttribute->clearCheckoutSession('register');
            Mage::unregister('mmd_customer_to_save');
            Mage::register('mmd_customer_saved', true);
            
            Mage::dispatchEvent('mmdcfm_customer_save_after', array('customer' => $this, 'checkoutfields' => $this->getCustomFields()));
        }
        $oAttribute->clearCheckoutSession('register');
        return parent::_afterSave();       
    }
    
    /**
     * Get CFM data for this customer
     * 
     * @param bool $forceReload Forces tranport object to be reloaded. Default: false.
     * 
     * @return MMD_Checkoutoptions_Model_Transport
     */    
    public function getCustomFields($forceReload = false)
    {
        if(is_null($this->_cfmCustomFields) || $forceReload)
        {
            $this->_cfmCustomFields = Mage::getModel('checkoutoptions/transport')->loadByCustomer($this);
        }
        return $this->_cfmCustomFields;
    }
}