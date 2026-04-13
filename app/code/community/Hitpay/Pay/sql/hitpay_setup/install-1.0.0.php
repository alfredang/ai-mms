<?php
$installer = $this;
$installer->startSetup();

$sql = <<<SQLTEXT
        drop table if exists {$this->getTable('hitpay_payments')}; 
        create table {$this->getTable('hitpay_payments')} (
            id int not null auto_increment,
            payment_id varchar(255) not null,
            payment_request_id varchar(255),
            transaction_id varchar(255),
            reference varchar(255),
            status varchar(255),
            whs_status varchar(255),
            quote_id int not null,
            order_id int not null,
            order_increment_id varchar(255),
            amount decimal(20,6),	
            currency_id varchar(255),
            customer_id int not null,
            is_paid boolean  not null,
            is_refunded boolean  not null,
            refunded_amount decimal(20,6),
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            extra text,
            primary key(id)
        ) CHARACTER SET utf8;      
SQLTEXT;
$installer->run($sql);

$sql = <<<SQLTEXT
        ALTER TABLE {$this->getTable('hitpay_payments')} ADD INDEX `hitpay_payments_order_id` (`order_id`);
SQLTEXT;
$installer->run($sql);

$sql = <<<SQLTEXT
        drop table if exists {$this->getTable('hitpay_webhook_order')}; 
        create table {$this->getTable('hitpay_webhook_order')} (
            id int not null auto_increment,
            order_id int not null,
            primary key(id)
        ) CHARACTER SET utf8;      
SQLTEXT;
$installer->run($sql);

$installer->endSetup();
?>
