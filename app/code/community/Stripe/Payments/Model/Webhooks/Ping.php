<?php

class Stripe_Payments_Model_Webhooks_Ping
{
    public function __construct() {
        $this->webhooksCollection = Mage::getResourceModel("stripe_payments/webhook_collection");
        $this->webhooksSetup = Mage::helper("stripe_payments/webhooksSetup");
    }

    public function run()
    {
        $configurations = $this->webhooksSetup->getStoreViewAPIKeys();
        $processed = [];

        foreach ($configurations as $configuration)
        {
            $secretKey = $configuration['api_keys']['sk'];
            if (empty($secretKey))
                continue;

            if (in_array($secretKey, $processed))
                continue;

            $processed[$secretKey] = $secretKey;

            \Stripe\Stripe::setApiKey($secretKey);
            $product = \Stripe\Product::create([
               'name' => 'Webhook Ping',
               'type' => 'service',
               'metadata' => [
                    "pk" => $configuration['api_keys']['pk']
               ]
            ]);
            $product->delete();
        }
    }
}
