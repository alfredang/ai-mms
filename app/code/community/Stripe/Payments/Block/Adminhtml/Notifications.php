<?php

class Stripe_Payments_Block_Adminhtml_Notifications extends Mage_Adminhtml_Block_Template
{
    public $configurations = null;
    public $displayText = null;

    protected function getWarning()
    {
        if (!empty($this->displayedText))
            return $this->displayedText;

        $webhooksSetup = Mage::helper("stripe_payments/webhooksSetup");
        $this->webhookModel = Mage::getModel("stripe_payments/webhook");
        $this->webhooksCollection = Mage::getResourceModel("stripe_payments/webhook_collection");

        $stores = $stores = Mage::app()->getStores();
        $configurations = array();

        foreach ($stores as $storeId => $store)
        {
            $configurations[] = $webhooksSetup->getStoreViewAPIKey($store, $storeId, 'test');
            $configurations[] = $webhooksSetup->getStoreViewAPIKey($store, $storeId, 'live');
        }

        $configurations = $webhooksSetup->getStoreViewAPIKeys();
        $allWebhooks = $this->webhooksCollection->getAllWebhooks();

        if ($allWebhooks->count() == 0)
        {
            $this->displayedText = "An initial configuration of Stripe Webhooks is necessary from System &rarr; Configuration &rarr; Sales &rarr; Payment Methods &rarr; Stripe Payments &rarr; Webhooks.";

            return $this->displayedText;
        }

        $activePublishableKeys = [];
        $duplicateWebhookPublishableKeys = [];
        $staleWebhookPublishableKeys = [];
        $inactiveStores = [];
        $duplicateWebhookStores = [];
        $staleWebhookStores = [];

        // Figure out active, duplicate and stale webhooks
        foreach ($allWebhooks as $webhook)
        {
            $key = $webhook->getPublishableKey();

            $createdAtTimestamp = strtotime($webhook->getCreatedAt());
            $wasJustCreated = ((time() - $createdAtTimestamp) <= 300);
            $inactivityPeriod = (time() - $webhook->getLastEvent());
            if ($webhook->getActive() > 0 || ($webhook->getActive() == 0 && $wasJustCreated))
                $activePublishableKeys[$key] = $key;

            if ($webhook->getActive() > 1)
                $duplicateWebhookPublishableKeys[$key] = $key;

            $sixHours = 6 * 60 * 60;
            if ($webhook->getActive() > 0 && $inactivityPeriod > $sixHours && !$wasJustCreated)
                $staleWebhookPublishableKeys[$key] = $key;
        }

        foreach ($configurations as $configuration)
        {
            if (!empty($configuration['api_keys']['pk']) && !in_array($configuration['api_keys']['pk'], $activePublishableKeys))
                $inactiveStores[] = $configuration;

            if (in_array($configuration['api_keys']['pk'], $duplicateWebhookPublishableKeys))
                $duplicateWebhookStores[] = $configuration;

            if (in_array($configuration['api_keys']['pk'], $staleWebhookPublishableKeys))
                $staleWebhookStores[] = $configuration;
        }

        if (!empty($inactiveStores))
        {
            $storeNames = [];

            foreach ($inactiveStores as $store) {
                $storeNames[] = $store['label'] . " (" . $store['mode_label'] . ")";
            }

            $storeNamesText = implode(", ", $storeNames);

            $this->displayedText = "Stripe Webhooks have not yet been configured for: $storeNamesText - You can configure them from System &rarr; Configuration &rarr; Sales &rarr; Payment Methods &rarr; Stripe Payments &rarr; Webhooks.";

            return $this->displayedText;
        }

        if (!empty($duplicateWebhookStores))
        {
            $storeNames = [];

            foreach ($duplicateWebhookStores as $store) {
                $storeNames[] = $store['label'] . " (" . $store['mode_label'] . ")";
            }

            $storeNamesText = implode(", ", $storeNames);

            $this->displayedText = "Duplicate webhooks configuration detected for: $storeNamesText - Please ensure that you only have a single webhook configured per Stripe account.";

            return $this->displayedText;
        }

        if (!empty($staleWebhookStores))
        {
            $storeNames = [];

            foreach ($staleWebhookStores as $store) {
                $storeNames[] = $store['label'] . " (" . $store['mode_label'] . ")";
            }

            $storeNamesText = implode(", ", $storeNames);

            $this->displayedText = "No webhook events have been received for: $storeNamesText - Please ensure that your webhooks URL is externally accessible and your cron jobs are running.";

            return $this->displayedText;
        }

        return null;
    }
}
