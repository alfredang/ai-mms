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

class MMD_Checkoutoptions_Model_Rewrite_FrontCheckoutTypeOnepage extends Mage_Checkout_Model_Type_Onepage
{
    // overwrite parent
    public function saveBilling($data, $customerAddressId)
    {
        if ($data)
        {
            $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
            
            foreach ($data as $sKey => $sVal)
            {
                $oAttribute->setCustomValue($sKey, $sVal, 'onepage');
            }
        }

        return parent::saveBilling($data, $customerAddressId);
    }

    // overwrite parent
    public function saveShipping($data, $customerAddressId)
    {
        $canSave = true;        
            $billing = Mage::app()->getRequest()->getPost('billing', array());
            $canSave = empty($billing['use_for_shipping']);
            
       
        if ($data)
        {
            $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
            
            foreach ($data as $sKey => $sVal)
            {
                $oAttribute->setCustomValue($sKey, $sVal, 'onepage');
            }
        }

        return ($canSave ? parent::saveShipping($data, $customerAddressId) : $this);
    }

    // overwrite parent
    public function saveShippingMethod($shippingMethod)
    {
        $oReq = Mage::app()->getFrontController()->getRequest();
        
        $data = $oReq->getPost('shippmethod');
        
        if ($data)
        {
            $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
            
            foreach ($data as $sKey => $sVal)
            {
                $oAttribute->setCustomValue($sKey, $sVal, 'onepage');
            }
        }
        
    /************** MMD DELIVERY DATE COMPATIBILITY MODE: START ********************/
        
        $val = Mage::getConfig()->getNode('modules/AdjustWare_Deliverydate/active');
        if ((string)$val == 'true')
        {
            $errors = Mage::getModel('adjdeliverydate/step')->process('shippingMethod');
            if ($errors)
                return $errors;
        }
    
    /************** MMD DELIVERY DATE COMPATIBILITY MODE: FINISH ********************/

        return parent::saveShippingMethod($shippingMethod);
    }
    
    // overwrite parent
    public function savePayment($data)
    {
        $return = parent::savePayment($data);
        
        if ($data)
        {
            $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
            
            foreach ($data as $sKey => $sVal)
            {
                $oAttribute->setCustomValue($sKey, $sVal, 'onepage');
            }
        }

        return $return;
    }

    // overwrite parent
    public function saveOrder()
    {
	
        // set review attributes data
        
        $oReq = Mage::app()->getFrontController()->getRequest();
        foreach ($oReq->getParams() as $_param)
        {
            if(is_array($_param))
            {
               // Mage::helper('mmdcheckout/checkoutoptions')->saveCustomData($_param); 
            }
        }
        $data = $oReq->getPost('customreview');
        
		
        if ($data)
        {
            $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
            
            foreach ($data as $sKey => $sVal)
            {
                $oAttribute->setCustomValue($sKey, $sVal, 'onepage');
            }
        }
       
        $oResult = parent::saveOrder();

        // save attribute data to DB
        
        $order = Mage::getModel('sales/order');
        $order->load($this->getCheckout()->getLastOrderId());
        
        $iOrderId = $this->getCheckout()->getLastOrderId();
        
        if ($iOrderId)
        {
            $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');

            $oAttribute->saveCustomOrderData($iOrderId, 'onepage');
            $oAttribute->clearCheckoutSession('onepage');
        }
        
        Mage::dispatchEvent('mmdcfm_order_save_after', array('order' => $order, 'checkoutfields' => $order->getCustomFields()));
        
        return $oResult;
    }
    
    // overwrite parent
    protected function _involveNewCustomer()
    {
        parent::_involveNewCustomer();
        
        $customerId = $this->getQuote()->getCustomer()->getId();
        Mage::getModel('checkoutoptions/checkoutoptions')->saveCustomerData($customerId, true);
    }
    
    /**
     *
     * @return MMD_Checkoutoptions_Helper_Data
     */
    public function getCheckoutoptionsHelper()
    {
        return Mage::helper('checkoutoptions');
    }
}