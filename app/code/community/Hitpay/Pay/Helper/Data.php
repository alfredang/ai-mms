<?php
class Hitpay_Pay_Helper_Data extends Mage_Payment_Helper_Data
{
    public function getStoreConfig($key)
    {
        $store = Mage::app()->getStore();
        return Mage::getStoreConfig($key, $store);
    }
    
    public function log($message)
    {
        $debug = $this->getStoreConfig('payment/hitpay/debug');
        if ($debug) {
            Mage::log($message, null, 'hitpay.log', true);
        }
    }
    
    public function getOrder()
    {
        $session = Mage::getSingleton('checkout/session');
        if ($session->getLastRealOrderId()) {
            $order = Mage::getModel('sales/order')->loadByIncrementId($session->getLastRealOrderId());
            if ($order->getId()) {
                return $order;
            }
        }
        return false;
    }
    
    public function isWebhookTriggered($order_id)
    {
        $resource = Mage::getSingleton('core/resource');
        $connection = $resource->getConnection('core_read');
        $tableName = $resource->getTableName('hitpay_webhook_order');
        $query = "select id from {$tableName} where order_id=".(int)($order_id);
        return (int)$connection->fetchOne($query);
    }
    
    public function updateWebhookTrigger($order_id)
    {
        $resource = Mage::getSingleton('core/resource');
        $connection = $resource->getConnection('core_write');
        $tableName = $resource->getTableName('hitpay_webhook_order');
        $connection->insert($tableName, ['order_id' => $order_id]);
    }
    
    public function getOrderState($status)
    {
        $resource = Mage::getSingleton('core/resource');
        $connection = $resource->getConnection('core_read');
        $tableName = $resource->getTableName('sales_order_status_state');
        $query = "select state from {$tableName} where status='".($status)."'";
        return $connection->fetchOne($query);
    }
}
