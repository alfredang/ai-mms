<?php

$installer = $this;

$installer->startSetup();

$table = $installer->getConnection()
  ->newTable($installer->getTable('stripe_webhooks')) //this will select your table
  ->addColumn(
      'id',
      Varien_Db_Ddl_Table::TYPE_INTEGER,
      null,
      ['identity' => true, 'unsigned' => true, 'nullable' => false, 'primary' => true],
      'Entity ID'
  )->addColumn(
      'config_version',
      Varien_Db_Ddl_Table::TYPE_INTEGER,
      null,
      ['nullable' => false, 'default' => Stripe_Payments_Helper_WebhooksSetup::VERSION],
      'Webhooks Configuration Version'
  )->addColumn(
      'webhook_id',
      Varien_Db_Ddl_Table::TYPE_TEXT,
      255,
      ['nullable' => false],
      'Webhook ID'
  )->addColumn(
      'publishable_key',
      Varien_Db_Ddl_Table::TYPE_TEXT,
      255,
      ['nullable' => false],
      'Stripe API Publishable Key'
  )->addColumn(
      'store_code',
      Varien_Db_Ddl_Table::TYPE_TEXT,
      255,
      ['nullable' => false],
      'Store Code'
  )->addColumn(
      'live_mode',
      Varien_Db_Ddl_Table::TYPE_INTEGER,
      null,
      ['nullable' => false, 'default' => 0],
      'Live Mode'
  )->addColumn(
      'active',
      Varien_Db_Ddl_Table::TYPE_INTEGER,
      null,
      ['nullable' => false, 'default' => 0],
      'Active'
  )->addColumn(
      'last_event',
      Varien_Db_Ddl_Table::TYPE_INTEGER,
      null,
      ['nullable' => false, 'unsigned' => true, 'default' => 0],
      'Timestamp of last received event'
  )->addColumn(
      'api_version',
      Varien_Db_Ddl_Table::TYPE_TEXT,
      255,
      ['nullable' => true],
      'Stripe API Version'
  )->addColumn(
      'url',
      Varien_Db_Ddl_Table::TYPE_TEXT,
      2000,
      ['nullable' => true],
      'Webhook URL'
  )->addColumn(
      'api_version',
      Varien_Db_Ddl_Table::TYPE_TEXT,
      255,
      ['nullable' => true],
      'Stripe API Version'
  )->addColumn(
      'enabled_events',
      Varien_Db_Ddl_Table::TYPE_TEXT,
      10000,
      ['nullable' => true],
      'Enabled Webhook Events'
  )->addColumn(
      'connect',
      Varien_Db_Ddl_Table::TYPE_INTEGER,
      null,
      ['nullable' => false, 'default' => 0],
      'Connected Accounts'
  )->addColumn(
      'created_at',
      Varien_Db_Ddl_Table::TYPE_TIMESTAMP,
      null,
      ['nullable' => false, 'default' => Varien_Db_Ddl_Table::TIMESTAMP_INIT],
      'Created At'
  );

$installer->getConnection()->createTable($table);

$installer->endSetup();
