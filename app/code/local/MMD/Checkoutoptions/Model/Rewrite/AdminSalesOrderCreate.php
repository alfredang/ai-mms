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


class MMD_Checkoutoptions_Model_Rewrite_AdminSalesOrderCreate extends Mage_Adminhtml_Model_Sales_Order_Create
{
    // overwrite parent
    public function createOrder()
    {
        $mainModel = Mage::getModel('checkoutoptions/checkoutoptions');
        $oldOrderId='';
        
        /* {#MMD_COMMENT_END#}
        if(isset($_SESSION['adminhtml_quote']['order_id'])||isset($_SESSION['adminhtml_quote']['reordered']))
        {
            $oldOrderId=isset($_SESSION['adminhtml_quote']['order_id'])?$_SESSION['adminhtml_quote']['order_id']:$_SESSION['adminhtml_quote']['reordered'];
            $oldOrder = Mage::getModel('sales/order')->load($oldOrderId);
            $storeId = $oldOrder->getStoreId();
            $websiteId = $oldOrder->getStore()->getWebsiteId();
        }else{
        	$quote = $this->getQuote();
        	$storeId = $quote->getStoreId();
            $websiteId = $quote->getStore()->getWebsiteId();
        }
        
        $performer = MMD_Mmdsys_Abstract_Service::get()->platform()->getModule('MMD_Checkoutoptions')->getLicense()->getPerformer();
        $ruler = $performer->getRuler();
        if (!($ruler->checkRule('store',$storeId,'store') || $ruler->checkRule('store',$websiteId,'website')))
        {
        	if($oldOrderId)
        	{
        		$oldData = $mainModel->getOrderCustomData($oldOrderId, $storeId, true);
        		foreach ($oldData as $oldAttr){
        			if(in_array($oldAttr['type'],array('checkbox','radio','select','multiselect')))
        			{
        				$oldAttr['rawval'] = explode(',',$oldAttr['rawval']);
        			}
        			$_SESSION['mmd_checkout_used']['adminorderfields'][$oldAttr['id']]=$oldAttr['rawval'];
        		} 
        	}
        }
        else 
        {
        {#MMD_COMMENT_START#} */
            $attributeCollection = $mainModel->getAttributeCollecton();
            $data = Mage::app()->getRequest()->getPost('mmd_checkout_fields');
            
            foreach($attributeCollection as $attribute)
            {
                if(isset($data[$attribute->getAttributeCode()]))
                {
                    if($attribute->getFrontend()->getInputType()!=='static')
                    {
                        $_SESSION['mmd_checkout_used']['adminorderfields'][$attribute->getId()]=$data[$attribute->getAttributeCode()];
                    }
                }
            }
        /* {#MMD_COMMENT_END#}
        }
        {#MMD_COMMENT_START#} */
        
   	/************** MMD DELIVERY DATE COMPATIBILITY MODE: START ********************/
        
        $val = Mage::getConfig()->getNode('modules/AdjustWare_Deliverydate/active');
        if ((string)$val == 'true')
        {
        	// START MMD DELIVERY DATE
            $errors = Mage::getModel('adjdeliverydate/step')->process('shippingMethod');
            
            if (!empty($errors)) {
                foreach ($errors as $error) {
                    $this->getSession()->addError($error);
                }
                Mage::throwException('');
            }
            
    		// FINISH MMD DELIVERY DATE
            
            $this->_validate();
    
            if (!$this->getQuote()->getCustomerIsGuest()) {
                $this->_putCustomerIntoQuote();
            }
    
            $quoteConvert = Mage::getModel('sales/convert_quote');
    
            /* @var $quoteConvert Mage_Sales_Model_Convert_Quote */
    
            $quote = $this->getQuote();
            if (!$this->getSession()->getOrder()->getId()) {
                $quote->reserveOrderId();
            }
    
            if ($this->getQuote()->getIsVirtual()) {
                $order = $quoteConvert->addressToOrder($quote->getBillingAddress());
            }
            else {
                $order = $quoteConvert->addressToOrder($quote->getShippingAddress());
            }
            $order->setBillingAddress($quoteConvert->addressToOrderAddress($quote->getBillingAddress()))
                ->setPayment($quoteConvert->paymentToOrderPayment($quote->getPayment()));
            if (!$this->getQuote()->getIsVirtual()) {
                $order->setShippingAddress($quoteConvert->addressToOrderAddress($quote->getShippingAddress()));
            }
    
            if (!$this->getQuote()->getIsVirtual()) {
                foreach ($quote->getShippingAddress()->getAllItems() as $item) {
                    /* @var $item Mage_Sales_Model_Quote_Item */
                    $orderItem = $quoteConvert->itemToOrderItem($item);
                    $options = array();
                    if ($productOptions = $item->getProduct()->getTypeInstance(true)->getOrderOptions($item->getProduct())) {
                        $productOptions['info_buyRequest']['options'] = $this->_prepareOptionsForRequest($item);
                        $options = $productOptions;
                    }
                    if ($addOptions = $item->getOptionByCode('additional_options')) {
                        $options['additional_options'] = unserialize($addOptions->getValue());
                    }
                    if ($options) {
                        $orderItem->setProductOptions($options);
                    }
    
                    if ($item->getParentItem()) {
                        $orderItem->setParentItem($order->getItemByQuoteItemId($item->getParentItem()->getId()));
                    }
    
                    $order->addItem($orderItem);
                }
            }
            if ($this->getQuote()->hasVirtualItems()) {
                foreach ($quote->getBillingAddress()->getAllItems() as $item) {
                    /* @var $item Mage_Sales_Model_Quote_Item */
                    $orderItem = $quoteConvert->itemToOrderItem($item);
                    $options = array();
                    if ($productOptions = $item->getProduct()->getTypeInstance(true)->getOrderOptions($item->getProduct())) {
                        $productOptions['info_buyRequest']['options'] = $this->_prepareOptionsForRequest($item);
                        $options = $productOptions;
                    }
                    if ($addOptions = $item->getOptionByCode('additional_options')) {
                        $options['additional_options'] = unserialize($addOptions->getValue());
                    }
                    if ($options) {
                        $orderItem->setProductOptions($options);
                    }
    
                    if ($item->getParentItem()) {
                        $orderItem->setParentItem($order->getItemByQuoteItemId($item->getParentItem()->getId()));
                    }
    
                    $order->addItem($orderItem);
                }
            }
    
            if ($this->getSendConfirmation()) {
                $order->setEmailSent(true);
            }
    
            if ($this->getSession()->getOrder()->getId()) {
                $oldOrder = $this->getSession()->getOrder();
    
                $originalId = $oldOrder->getOriginalIncrementId() ? $oldOrder->getOriginalIncrementId() : $oldOrder->getIncrementId();
                $order->setOriginalIncrementId($originalId);
                $order->setRelationParentId($oldOrder->getId());
                $order->setRelationParentRealId($oldOrder->getIncrementId());
                $order->setEditIncrement($oldOrder->getEditIncrement()+1);
                $order->setIncrementId($originalId.'-'.$order->getEditIncrement());
            }
    
            $order->place();
            $this->_saveCustomerAfterOrder($order);
            $order->save();
    
            if ($this->getSession()->getOrder()->getId()) {
                $oldOrder = $this->getSession()->getOrder();
    
                $this->getSession()->getOrder()->setRelationChildId($order->getId());
                $this->getSession()->getOrder()->setRelationChildRealId($order->getIncrementId());
                $this->getSession()->getOrder()->cancel()
                    ->save();
                $order->save();
            }
    
    		// MMD DELIVERY DATE
            $fields = Mage::getSingleton('adjdeliverydate/session')->getShippingMethod();
            
            //only one step and only two field for the first module version
            if (is_array($fields)){
                
                // fix for delivery time
                if (Mage::getStoreConfig('checkout/adjdeliverydate/show_time') AND !empty($fields['delivery_date']) AND !empty($fields['delivery_time']))
                {
                    $fields['delivery_date'] .= ' ' . implode(':', $fields['delivery_time']);
                    
                    unset($fields['delivery_time']);
                }
                
                foreach ($fields as $name=>$value){
                   $order->setData($name, $value);
                   $order->setData($name . '_is_formated', true);
                }
                $order->save();
            }
            
            Mage::getSingleton('adjdeliverydate/session')->setShippingMethod(null);
    		// END MMD DELIVERY DATE
    
            if ($this->getSendConfirmation()) {
                $order->sendNewOrderEmail();
            }
        }
        else
        {
        	$order = parent::createOrder();
        }
    /************** MMD DELIVERY DATE COMPATIBILITY MODE: FINISH ********************/
            
        if (isset($_SESSION['mmd_checkout_used']['new_customer']))
        {
            $_SESSION['mmd_checkout_used']['register'] = $_SESSION['mmd_checkout_used']['adminorderfields'];
            $customerId = $order->getCustomerId();
            $mainModel->saveCustomerData($customerId);
        }
        
        $orderId = $order->getId();
        $mainModel->saveCustomOrderData($orderId, 'adminorderfields');
        
        Mage::dispatchEvent('mmdcfm_order_save_after', array('order' => $order, 'checkoutfields' => $order->getCustomFields()));
        
        $mainModel->clearCheckoutSession('adminorderfields');
        Mage::getSingleton('adminhtml/session')->unsetData('checkoutoptions_admin_post_data');
           		
        return $order;
    }
    
    // overwrite parent
    public function importPostData($data){
        $toReturn = parent::importPostData($data);
        		
		if($postData = Mage::app()->getRequest()->getPost('mmd_checkout_fields'))
		{
		    if(!Mage::getSingleton('adminhtml/session')->hasData('checkoutoptions_admin_post_data'))
			{
			    Mage::getSingleton('adminhtml/session')->addData(array('checkoutoptions_admin_post_data'=>$postData));
			}
			elseif($postData != Mage::getSingleton('adminhtml/session')->getData('checkoutoptions_admin_post_data'))
			{
			    Mage::getSingleton('adminhtml/session')->addData(array('checkoutoptions_admin_post_data'=>$postData));
			}
		}
		        
        return $toReturn; 
    }
}