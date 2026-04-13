<?php

$installer = $this;

$installer->startSetup();

$table = $installer->getConnection()
    ->newTable($installer->getTable('stripe_customers')) //this will select your table
    ->addColumn('id', Varien_Db_Ddl_Table::TYPE_INTEGER, 11, array(
        'auto_increment' => true,
        'unsigned' => true,
        'identity'  => true,
        'nullable'  => false,
        'primary'   => true
        ), 'ID')
    ->addColumn('customer_id', Varien_Db_Ddl_Table::TYPE_INTEGER, 11, array(
        'unsigned' => true,
        'nullable'  => false
        ), 'Magento Customer Id')
    ->addColumn('stripe_id', Varien_Db_Ddl_Table::TYPE_VARCHAR, 255, array(
        'nullable'  => false
        ), 'Stripe Customer Id')
    ->addColumn('last_retrieved', Varien_Db_Ddl_Table::TYPE_INTEGER, 11, array(
        'nullable'  => false,
        'default' => '0'
        ), 'Out Time')
    ->addColumn('customer_email', Varien_Db_Ddl_Table::TYPE_VARCHAR, 255, array(
        'default' => null
        ), 'Customer Email')
    ->addColumn('session_id', Varien_Db_Ddl_Table::TYPE_VARCHAR, 255, array(
        'default' => null
        ), 'Magento Session ID')
    ->addIndex($installer->getIdxName('stripe_customers', array('customer_email')),
        array('customer_email'))
    ->addIndex($installer->getIdxName('stripe_customers', array('session_id')),
        array('session_id'));

$installer->getConnection()->createTable($table);

if ($installer->tableExists('cryozonic_stripesubscriptions_customers'))
{
    $select = $installer->getConnection()->select()->from(['customers' => $installer->getTable('cryozonic_stripesubscriptions_customers')]);
    $insertArray = [
        'id',
        'customer_id',
        'stripe_id',
        'last_retrieved',
        'customer_email',
        'session_id'
    ];
    $sqlQuery = $select->insertFromSelect(
        $installer->getTable('stripe_customers'),
        $insertArray,
        false
    );
    $installer->getConnection()->query($sqlQuery);
}

$installer->endSetup();
