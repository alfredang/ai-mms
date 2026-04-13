<?php
$installer = $this;
$installer->startSetup();

$sql = <<<SQLTEXT
        ALTER TABLE {$this->getTable('hitpay_payments')} ADD payment_type VARCHAR(255);
        ALTER TABLE {$this->getTable('hitpay_payments')} ADD fees decimal(20,6);
SQLTEXT;
$installer->run($sql);

$installer->endSetup();
