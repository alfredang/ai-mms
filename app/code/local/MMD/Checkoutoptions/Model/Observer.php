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
class MMD_Checkoutoptions_Model_Observer
{
    protected $_isHtmlObserverAllowed = false;
    protected $_isAddressChangeAllowed = false;
    protected $_isAdressChangeObserverExists = false;
    protected $_default_format = false;
    protected $_isMultishipping = false;
    
    public function frontCheckoutMultishippingAddressesPost($object)
    {
         if(!Mage::app()->getRequest()->getParam('continue')) {
             $oReq = Mage::app()->getFrontController()->getRequest();
            
             $sKey  = 'multi';
            
             $data = $oReq->getPost($sKey);
    
             if ($data)
             {
                 $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
                
                 foreach ($data as $sKey => $sVal)
                 {
                     $oAttribute->setCustomValue($sKey, $sVal, 'multishipping');
                 }
             }
         }
    }

    public function onPaypalExpressOrderPlaceAfter(Varien_Event_Observer $observer)
    {   
        
        $this->onPaypalExpressOrderPlace($observer);
        
        $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');
		
        $orderId = $observer->getEvent()->getOrderId();
        if ($orderId)
        {
            $oAttribute->saveCustomOrderData($orderId, 'onepage');
            $oAttribute->clearCheckoutSession('onepage');
        }

        $recurringProfileIds = $observer->getEvent()->getRecurringProfileIds();
        if(isset($recurringProfileIds) && count($recurringProfileIds) > 0)
        {
            $oAttribute->saveCustomRecurrentProfileData($recurringProfileIds, 'onepage');
            $oAttribute->clearCheckoutSession('onepage');
        }        
    }
    
    public function onPaypalExpressOrderPlace($observer)
    {   
        $data = Mage::app()->getRequest()->getPost('mmdpaypalexpress');
        
        if($data)
        {
            $mainModel = Mage::getModel('checkoutoptions/checkoutoptions');
            
            foreach ($data as $key => $value)
            {
			    $mainModel->setCustomValue($key, $value, 'onepage');
            }
        }
    }

    public function predispatchSagepaysuitePaymentOnepageSaveOrder($observer)
    {
        /* Presaving review CFM fields if payment method was set as sagepay */
        $oReq = Mage::app()->getFrontController()->getRequest();

        $data = $oReq->getPost('customreview');

        if ($data)
        {
            $oAttribute = Mage::getModel('checkoutoptions/checkoutoptions');

            foreach ($data as $sKey => $sVal)
            {
                $oAttribute->setCustomValue($sKey, $sVal, 'onepage');
            }
        }
    }
    
    public function onPredispatchCheckoutOnepageProgress($observer)
    {
        $this->allowAbstractToHtmlAfter();
        $this->_isAddressChangeAllowed = true;
    }
    
    public function onPredispatchCheckoutMultishipping($observer)
    {
        $this->allowAbstractToHtmlAfter();
        $this->_isAddressChangeAllowed = true;
        $this->_isMultishipping = true;
    }

    public function allowAbstractToHtmlAfter($observer = false)
    {
        $this->_isHtmlObserverAllowed = true;
    }
    
    public function onCoreBlockAbstractToHtmlAfter($observer)
    {
        if(!$this->_isHtmlObserverAllowed) 
        {
            return false;
        }
        $this->_processShippingMethodInfo($observer);
        $this->_processPaymentMethodInfo($observer);
        $this->_processMultishippingMethodInfo($observer);
    }

    public function onCustomerAddressFormat($observer)
    {
        if(!$this->_isAddressChangeAllowed) {
            return false;
        }
        //set flag that observer exists and data was parsed, for 1.4.1.1 compatibility
        $this->_isAdressChangeObserverExists = true;
        $address = $observer->getAddress();
        $type = $address->getAddressType();
        if($this->_isMultishipping)
        {
            $type = 'mult_'.$type;
        }

        $iStepId = Mage::helper('checkoutoptions')->getStepId($type);
        if (!$iStepId) return false;
        
        /* Type class is equal for shipping and billing, so we store old value to be able to hide billing fields on shipping step */
        if($this->_default_format) 
        {
            $default_format = $this->_default_format;
            $observer->getType()->setDefaultFormat($default_format);
        } else 
        {
            $default_format = $observer->getType()->getDefaultFormat();
            $this->_default_format = $default_format;
        }

        if($data = $this->_getFieldsText($type)) 
        {
            $observer->getType()->setDefaultFormat(
                $data['top'] . $default_format . '<br />' . $data['bottom']
            );
        }
    }
    
    protected function _processShippingMethodInfo($observer)
    {
        if(!$observer->getBlock() instanceof Mage_Checkout_Block_Onepage_Progress) 
        {
            return false;
        }
        if(!$observer->getTransport())
        {
            /** Checking if this version of magento allow us to change html via transport class.
            * Should work fine with any 1.4.1+ magento
            */
            return false;
        }
        if($this->_isMultishipping)
        {
            return false;
        }
        if($data = $this->_getFieldsText('shippmethod')) 
        {
            $html = $observer->getTransport()->getHtml();
            //searching id for link in shipping method and replacing data in next dd block after it
            $result = preg_replace('|#shipping_method(.*)\<dd class="complete"\>(.*)\<\/dd\>|Uis',
                    '#shipping_method$1<dd class="complete">'.$data['top'].'$2<br />'.$data['bottom'].'</dd>'
                    , $html);
            $observer->getTransport()->setHtml($result);
        }
        if(!$this->_isAdressChangeObserverExists)
        {
            /** Compatibility with magento 1.4.1.1 and when 'customer_address_format' event don't exist */
            $types = array('billing', 'shipping');
            foreach($types as $type) 
            {
                if($data = $this->_getFieldsText($type)) 
                {
                    $html = $observer->getTransport()->getHtml();
                    //searching id for link in shipping method and replacing data in next dd block after it
                    $result = preg_replace('|'.$type.'(.*)\<dd class="complete"\>(.*)\<address\>(.*)\<\/address\>(.*)\<\/dd\>|Uis',
                            $type.'$1<dd class="complete"><address>'.$data['top'].'$3<br />'.$data['bottom'].'</address></dd>'
                            , $html);
                    $observer->getTransport()->setHtml($result);
                }
            }
            
        }
    }

    protected function _processMultishippingMethodInfo($observer)
    {
        if(!$this->_isMultishipping)
        {
            return false;
        }
        if(!$observer->getBlock() instanceof Mage_Checkout_Block_Multishipping_Overview)
        {
            return false;
        }
        if(!$observer->getTransport())
        {
            /** Checking if this version of magento allow us to change html via transport class.
            * Should work fine with any 1.4.1+ magento
            */
            return false;
        }
        if($data = $this->_getFieldsText('mult_shippinfo'))
        {
            $html = $observer->getTransport()->getHtml();
            //searching id for link in shipping method and replacing data in next dd block after it
            $result = preg_replace('|backtoshipping(.*)\<div class="box-content"\>(.*)\<\/div\>|Uis',
                    '#backtoshipping$1<div class="box-content">'.$data['top'].'$2<br />'.$data['bottom'].'</div>'
                    , $html);
            $observer->getTransport()->setHtml($result);
        }
    }

    protected function _processPaymentMethodInfo($observer)
    {
        if(!$observer->getBlock() instanceof Mage_Checkout_Block_Onepage_Payment_Info/* && !$observer->getBlock() instanceof  Mage_Checkout_Block_Multishipping_Payment_Info*/)
        {
            return false;
        }
        $type = 'payment';
        /*if($this->_isMultishipping)
        {
            $type = 'mult_billing'; //This is needed if you will need to show mult_billing fields near Payment Options, not in billing address field
        }*/
        if($data = $this->_getFieldsText($type)) 
        {
            $html = $observer->getTransport()->getHtml();
            $observer->getTransport()->setHtml(
                $data['top'] . $html . '<br />' . $data['bottom']
            );
        }
    }

    protected function _getFieldsText($type, $checkoutType = 'onepage')
    {
        if($this->_isMultishipping)
        {
            $checkoutType = 'multishipping';
        }
        $helper = Mage::helper('checkoutoptions');
        $top = $helper->getCustomFieldTextValues($type, 1, $checkoutType);
        $bottom = $helper->getCustomFieldTextValues($type, 2, $checkoutType);
        if($top || $bottom) 
        {
            return array('top'=>$top, 'bottom'=>$bottom);
        }
        return false;
    }

}