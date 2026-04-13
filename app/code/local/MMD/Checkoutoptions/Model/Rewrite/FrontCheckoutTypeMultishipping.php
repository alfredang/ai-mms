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
class MMD_Checkoutoptions_Model_Rewrite_FrontCheckoutTypeMultishipping extends Mage_Checkout_Model_Type_Multishipping
{
    public function createOrders()
    {
        $data = Mage::app()->getFrontController()->getRequest()->getPost('multi');
        $cfmModel = Mage::getModel('checkoutoptions/checkoutoptions');
        
        if ($data) {
            foreach ($data as $key => $val) {
                $cfmModel->setCustomValue($key, $val, 'multishipping');
            }
        }
        
        $result = parent::createOrders();

        // save attribute data to DB
        $orderIdHash = Mage::getSingleton('core/session')->getOrderIds(true);
        Mage::getSingleton('core/session')->setOrderIds($orderIdHash);

        if ($orderIdHash) {
            foreach ($orderIdHash as $orderId => $val) {
                $cfmModel->saveCustomOrderData($orderId, 'multishipping');
                
                $order = Mage::getModel('sales/order')->load($orderId);
                Mage::dispatchEvent('mmdcfm_order_save_after', array('order' => $order, 'checkoutfields' => $order->getCustomFields()));
            }
            
            $cfmModel->clearCheckoutSession('multishipping');
        }
        
        return $result;
    }    
}