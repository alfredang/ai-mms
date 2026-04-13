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
class MMD_Checkoutoptions_Block_Rewrite_AdminSalesOrderViewInfo  extends Mage_Adminhtml_Block_Sales_Order_View_Info
{     
    public function getOrderCustomData()
    {
        $isInvoice = $this->getIsInvoice();
        $iStoreId = $this->getOrder()->getStoreId();

        $oFront = Mage::app()->getFrontController();
        $params = $oFront->getRequest()->getParams();
        if(!empty($params['order_id']))
        {
            $iOrderId =  $params['order_id'];       
        }
        elseif(!empty($params['invoice_id']))
        {
            $iOrderId = Mage::getModel('sales/order_invoice')->load($params['invoice_id'])->getOrder()->getId();  
              
        }
        else
        {
            return false;
        }
        $oCheckoutoptions  = Mage::getModel('checkoutoptions/checkoutoptions');

        if(!empty($isInvoice))
        {
            $aCustomAtrrList = $oCheckoutoptions->getInvoiceCustomData($iOrderId, $iStoreId);      
        }
        else
        {
            $aCustomAtrrList = $oCheckoutoptions->getOrderCustomData($iOrderId, $iStoreId, true, true);    
        }
        
        !$aCustomAtrrList ? $aCustomAtrrList = array() : false;
        
        return $aCustomAtrrList;
    }
    
    // new function
    public function getEditUrl()
    {
        $oFront = Mage::app()->getFrontController();
        
        $iOrderId = $oFront->getRequest()->getParam('order_id');
        
        $order = Mage::getModel('sales/order')->load($iOrderId);
        $orderStore = $order->getStore();
        $orderStoreId = $orderStore->getId();
        $orderWebsiteId = $orderStore->getWebsite()->getId();
        
        /* {#MMD_COMMENT_END#}
        $performer = MMD_Mmdsys_Abstract_Service::get()->platform()->getModule('MMD_Checkoutoptions')->getLicense()->getPerformer();
        $ruler = $performer->getRuler();
        if (!($ruler->checkRule('store',$orderStoreId,'store') || $ruler->checkRule('store',$orderWebsiteId,'website')))
        {
            return false;
        }
        {#MMD_COMMENT_START#} */
        
        return $this->getUrl('checkoutoptions/index/orderedit', array('order_id' => $iOrderId));
    }
}