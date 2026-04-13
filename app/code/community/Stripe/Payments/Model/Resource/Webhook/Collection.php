<?php

class Stripe_Payments_Model_Resource_Webhook_Collection extends Mage_Core_Model_Resource_Db_Collection_Abstract
 {
    public function _construct()
    {
        parent::_construct();
        $this->_init('stripe_payments/webhook');
    }

    public function getWebhooks($storeCode, $publishableKey)
    {
        $collection = $this
            ->addFieldToSelect('*')
            ->addFieldToFilter('store_code', ['eq' => $storeCode])
            ->addFieldToFilter('publishable_key', ['eq' => $publishableKey]);

        return $collection;
    }

    public function getAllWebhooks()
    {
        $collection = $this
            ->addFieldToSelect('*');

        return $collection;
    }

    public function updateMultipleWebhooks($webhookId, $newWebhookId, $apiVersion, $enabledEvents)
    {
        $collection = $this
            ->addFieldToSelect('*')
            ->addFieldToFilter('webhook_id', ['eq' => $webhookId]);

        foreach ($collection as $webhook)
        {
            $webhook->setWebhookId($newWebhookId);
            $webhook->setApiVersion($apiVersion);
            $webhook->setEnabledEvents($enabledEvents);
        }

        $collection->save();
    }

    public function pong($publishableKey)
    {
        $collection = $this
            ->addFieldToSelect('*')
            ->addFieldToFilter('publishable_key', ['eq' => $publishableKey]);

        foreach ($collection as $webhook)
        {
            $webhook->setLastEvent(time());
        }

        $collection->save();
    }
}
