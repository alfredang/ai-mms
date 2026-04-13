<?php

require_once 'Stripe/init.php';

class Stripe_Payments_Helper_WebhooksSetup extends Mage_Payment_Helper_Data
{
    const VERSION = 1;

    public $enabledEvents = array(
        "charge.captured",
        "charge.refunded",
        "charge.failed",
        "charge.succeeded",
        "payment_intent.succeeded",
        "payment_intent.payment_failed",
        "source.chargeable",
        "source.canceled",
        "source.failed",
        "invoice.payment_succeeded",
        "invoice.payment_failed",
        "product.created" // This is a dummy event for setting up webhooks
    );

    public $configurations = null;
    public $errorMessages = array();
    public $successMessages = array();

    public function __construct()
    {
        $this->cache = Mage::app()->getCache();
        $this->coreConfig = Mage::getModel('core/config');
        $this->webhookModel = Mage::getModel('stripe_payments/webhook');
        $this->webhookCollection = Mage::getResourceModel('stripe_payments/webhook_collection');
    }

    public function configure()
    {
        $this->errorMessages = [];
        $this->successMessages = [];
        $this->clearConfiguredWebhooks();
        $configurations = $this->createMissingWebhooks();
        $this->addDummyEventTo($configurations);
        $this->saveConfiguredWebhooks($configurations);
        $this->triggerDummyEvent($configurations);
    }

    public function triggerDummyEvent($configurations)
    {
        foreach ($configurations as $configuration)
        {
            \Stripe\Stripe::setApiKey($configuration['api_keys']['sk']);
            \Stripe\Product::create([
               'name' => 'Webhook Configuration',
               'type' => 'service',
               'metadata' => [
                    "store_code" => $configuration['code'],
                    "mode" => $configuration['mode'],
                    "pk" => $configuration['api_keys']['pk']
               ]
            ]);
            sleep(2); // Avoid DB concurrency problems when all webhook events pong at the same time
        }
    }

    public function saveConfiguredWebhooks($configurations)
    {
        $table = Mage::getSingleton('core/resource')->getTableName('stripe_webhooks');
        $rows = [];
        foreach ($configurations as $key => $configuration)
        {
            foreach ($configuration['webhooks'] as $webhook)
            {
                $rows[] = [
                    "webhook_id" => $webhook->id,
                    "publishable_key" => $configuration['api_keys']['pk'],
                    "store_code" => $configuration["code"],
                    "live_mode" => $webhook->livemode,
                    "api_version" => $webhook->api_version,
                    "url" => $webhook->url,
                    "enabled_events" => json_encode($webhook->enabled_events),
                ];
            }
        }
        if (!empty($rows))
        {
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');
            $write->insertMultiple($table, $rows);
        }
    }

    public function clearConfiguredWebhooks()
    {
        $connection = Mage::getSingleton('core/resource')->getConnection('core_write');
        $table = Mage::getSingleton('core/resource')->getTableName('stripe_webhooks');
        $connection->truncateTable($table);
    }

    // Adds the product.created webhook to all existing webhook configurations
    public function addDummyEventTo(&$configurations)
    {
        foreach ($configurations as &$configuration)
        {
            foreach ($configuration['webhooks'] as $i => $webhook)
            {
                 if (sizeof($webhook->enabled_events) === 1 && $webhook->enabled_events[0] == "*")
                    continue;

                $events = $webhook->enabled_events;
                if (!in_array("product.created", $webhook->enabled_events))
                {
                    $events[] = "product.created";
                    try
                    {
                        \Stripe\Stripe::setApiKey($configuration['api_keys']['sk']);
                        $configuration['webhooks'][$i] = \Stripe\WebhookEndpoint::update($webhook->id, [ 'enabled_events' => $events ]);
                    }
                    catch (\Exception $e)
                    {
                        $this->error("Failed to update Stripe webhook " . $this->getWebhookUrl() . ": " . $e->getMessage());
                    }
                }
            }
        }
    }

    public function getValidWebhookUrl()
    {
        $url = $this->getWebhookUrl();
        if ($this->isValidUrl($url))
            return $url;

        return null;
    }

    public function getWebhookUrl()
    {
        $url = Mage::getUrl('stripe/webhooks', [ "_secure" => true, '_nosid' => true ]);
        $url = filter_var($url, FILTER_SANITIZE_URL);
        $url = rtrim(trim($url), "/");
        return $url;
    }

    public function isValidUrl($url)
    {
        // Validate URL
        if (filter_var($url, FILTER_VALIDATE_URL) === false)
            return false;

        return true;
    }

    public function createMissingWebhooks()
    {
        $configurations = $this->getAllWebhookConfigurations();

        foreach ($configurations as $secretKey => &$configuration)
        {
            if (empty($configuration['webhooks']))
            {
                try
                {
                    $webhook = $this->createWebhook($secretKey, $this->getValidWebhookUrl());
                    if ($webhook)
                        $configuration['webhooks'] = [ $webhook ];
                    else
                        $configuration['webhooks'] = [];
                }
                catch (\Exception $e)
                {
                    $this->error("Failed to configure Stripe webhook for store " . $configuration['label'] . ": " . $e->getMessage());
                }
            }
        }

        return $this->configurations = $configurations;
    }

    public function createWebhook($secretKey, $webhookUrl)
    {
        if (empty($secretKey))
            throw new \Exception("Invalid secret API key");

        if (empty($webhookUrl))
            throw new \Exception("Invalid webhooks URL");

        \Stripe\Stripe::setApiKey($secretKey);

        return \Stripe\WebhookEndpoint::create([
            'url' => $webhookUrl,
            'api_version' => Stripe_Payments_Model_Method::STRIPE_API,
            'connect' => false,
            'enabled_events' => $this->enabledEvents,
        ]);
    }

    public function getAllWebhookConfigurations()
    {
        if (!empty($this->configurations))
            return $this->configurations;

        $configurations = $this->getStoreViewAPIKeys();

        foreach ($configurations as $secretKey => &$configuration)
        {
            try
            {
                $configuration['webhooks'] = $this->getConfiguredWebhooksForAPIKey($secretKey);
            }
            catch (\Exception $e)
            {
                $this->error("Failed to retrieve configured webhooks for store " . $configuration['label'] . ": " . $e->getMessage());
            }
        }

        return $this->configurations = $configurations;
    }

    public function error($msg)
    {
        $count = count($this->errorMessages) + 1;
        Mage::log("Error $count: $msg", null, 'stripe_payments_webhooks.log');
        $this->errorMessages[] = $msg;
    }

    public function getStoreViewAPIKeys()
    {
        $stores = Mage::app()->getStores();
        $configurations = array();

        foreach ($stores as $storeId => $store)
        {
            $testModeConfig = $this->getStoreViewAPIKey($store, $storeId, 'test');

            if (!empty($testModeConfig['api_keys']['sk']))
                $configurations[$testModeConfig['api_keys']['sk']] = $testModeConfig;

            $liveModeConfig = $this->getStoreViewAPIKey($store, $storeId, 'live');

            if (!empty($liveModeConfig['api_keys']['sk']))
                $configurations[$liveModeConfig['api_keys']['sk']] = $liveModeConfig;
        }

        return $configurations;
    }

    public function getStoreViewAPIKey($store, $storeId, $mode)
    {
        $secretKey = Mage::getStoreConfig("payment/stripe_payments/stripe_{$mode}_sk", $storeId);
        if (empty($secretKey))
            return null;

        return [
            'label' => $store['name'],
            'code' => $store['code'],
            'api_keys' => [
                'pk' => Mage::getStoreConfig("payment/stripe_payments/stripe_{$mode}_pk", $storeId),
                'sk' => $secretKey
            ],
            'mode' => $mode,
            'mode_label' => ucfirst($mode) . " Mode"
        ];
    }

    protected function getConfiguredWebhooksForAPIKey($key)
    {
        $webhooks = [];
        if (empty($key))
            return $webhooks;

        \Stripe\Stripe::setApiKey($key);
        $data = \Stripe\WebhookEndpoint::all(['limit' => 100]);
        foreach ($data->autoPagingIterator() as $webhook)
        {
            if ($webhook->status != "enabled")
                continue;

            if (stripos($webhook->url, "/stripe/webhooks") === false && stripos($webhook->url, "/cryozonic-stripe/webhooks") === false)
                continue;

            $webhooks[] = $webhook;
        }

        return $webhooks;
    }

    public function onWebhookCreated($event)
    {
        $storeCode = $event->data->object->metadata->store_code;
        $publishableKey = $event->data->object->metadata->pk;
        $mode = $event->data->object->metadata->mode;

        $collection = $this->webhookCollection;

        $webhooks = $collection->getWebhooks($storeCode, $publishableKey);

        foreach ($webhooks as $webhook)
        {
            $active = $webhook->getActive();
            $webhook->activate()->pong()->save();

            if ($this->isMisconfigured($webhook->getApiVersion(), json_decode($webhook->getEnabledEvents(), true)))
            {
                $url = $webhook->getUrl();
                $storeId = Mage::app()->getStore($storeCode)->getId();
                $configuration = $this->getStoreViewAPIKey(["name" => null, "code" => $storeCode], $storeId, $mode);
                if (empty($configuration['api_keys']['sk']))
                    continue;

                try
                {
                    \Stripe\Stripe::setApiKey($configuration['api_keys']['sk']);
                    $webhookEndpoint = \Stripe\WebhookEndpoint::retrieve($webhook->getWebhookId());

                    if ($this->isMisconfigured($webhookEndpoint->api_version, $webhookEndpoint->enabled_events))
                    {
                        $webhookEndpoint->delete();
                        $webhookEndpoint = $this->createWebhook($configuration['api_keys']['sk'], $url);
                    }

                    $collection->updateMultipleWebhooks($webhook->getWebhookId(), $webhookEndpoint->id, $webhookEndpoint->api_version, json_encode($webhookEndpoint->enabled_events));
                }
                catch (\Exception $e)
                {
                    // We may get here if the webhook is currently being reconfigured by another received product.created event
                    // i.e. it has already been deleted
                    continue;
                }

            }
        }

        $this->deleteProduct($event->data->object->id);
    }

    public function deleteProduct($productId)
    {
        try
        {
            $product = \Stripe\Product::retrieve($productId);
            if ($product)
                $product->delete();
        }
        catch (\Exception $e)
        {
            return;
        }
    }

    public function isMisconfigured($apiVersion, $events)
    {
        if ($apiVersion != Stripe_Payments_Model_Method::STRIPE_API)
            return true;

        $eventsMissing = array_diff($this->enabledEvents, $events);
        $unnecessaryEvents = array_diff($events, $this->enabledEvents);
        if (!empty($eventsMissing) || !empty($unnecessaryEvents))
            return true;

        return false;
    }
}
