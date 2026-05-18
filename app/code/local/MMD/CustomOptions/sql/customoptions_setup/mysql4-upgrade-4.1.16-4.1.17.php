<?php
/**
 * Scheduler snapshot storage for immutable order-side audit trail.
 */
$installer = $this;
$installer->startSetup();

$table = $installer->getTable('custom_options_schedule_snapshot');
$conn  = $installer->getConnection();

if (!$conn->isTableExists($table)) {
    $tbl = $conn->newTable($table)
        ->addColumn('snapshot_id', Varien_Db_Ddl_Table::TYPE_INTEGER, null, array(
            'identity' => true,
            'unsigned' => true,
            'nullable' => false,
            'primary'  => true,
        ), 'Snapshot ID')
        ->addColumn('order_id', Varien_Db_Ddl_Table::TYPE_INTEGER, null, array(
            'unsigned' => true,
            'nullable' => false,
        ), 'Order ID')
        ->addColumn('order_item_id', Varien_Db_Ddl_Table::TYPE_INTEGER, null, array(
            'unsigned' => true,
            'nullable' => false,
        ), 'Order Item ID')
        ->addColumn('product_id', Varien_Db_Ddl_Table::TYPE_INTEGER, null, array(
            'unsigned' => true,
            'nullable' => false,
            'default'  => 0,
        ), 'Product ID')
        ->addColumn('option_id', Varien_Db_Ddl_Table::TYPE_INTEGER, null, array(
            'unsigned' => true,
            'nullable' => false,
            'default'  => 0,
        ), 'Option ID')
        ->addColumn('option_type_id', Varien_Db_Ddl_Table::TYPE_INTEGER, null, array(
            'unsigned' => true,
            'nullable' => false,
            'default'  => 0,
        ), 'Option Type ID')
        ->addColumn('schedule_label', Varien_Db_Ddl_Table::TYPE_TEXT, 255, array(
            'nullable' => false,
            'default'  => '',
        ), 'Schedule Label')
        ->addColumn('schedule_text', Varien_Db_Ddl_Table::TYPE_TEXT, 255, array(
            'nullable' => false,
            'default'  => '',
        ), 'Schedule Text')
        ->addColumn('seat_qty', Varien_Db_Ddl_Table::TYPE_DECIMAL, '12,4', array(
            'nullable' => false,
            'default'  => '0.0000',
        ), 'Seat Quantity')
        ->addColumn('unit_price', Varien_Db_Ddl_Table::TYPE_DECIMAL, '12,4', array(
            'nullable' => false,
            'default'  => '0.0000',
        ), 'Unit Price')
        ->addColumn('delivery_mode', Varien_Db_Ddl_Table::TYPE_TEXT, 64, array(
            'nullable' => false,
            'default'  => '',
        ), 'Delivery Mode')
        ->addColumn('snapshot_json', Varien_Db_Ddl_Table::TYPE_TEXT, '64k', array(
            'nullable' => true,
        ), 'Snapshot JSON')
        ->addColumn('created_at', Varien_Db_Ddl_Table::TYPE_DATETIME, null, array(
            'nullable' => false,
        ), 'Created At')
        ->addIndex($installer->getIdxName($table, array('order_id')), array('order_id'))
        ->addIndex($installer->getIdxName($table, array('order_item_id')), array('order_item_id'))
        ->addIndex($installer->getIdxName($table, array('option_type_id')), array('option_type_id'))
        ->addForeignKey(
            $installer->getFkName($table, 'order_id', $installer->getTable('sales/order'), 'entity_id'),
            'order_id',
            $installer->getTable('sales/order'),
            'entity_id',
            Varien_Db_Ddl_Table::ACTION_CASCADE,
            Varien_Db_Ddl_Table::ACTION_CASCADE
        )
        ->addForeignKey(
            $installer->getFkName($table, 'order_item_id', $installer->getTable('sales/order_item'), 'item_id'),
            'order_item_id',
            $installer->getTable('sales/order_item'),
            'item_id',
            Varien_Db_Ddl_Table::ACTION_CASCADE,
            Varien_Db_Ddl_Table::ACTION_CASCADE
        )
        ->setComment('Custom Options Schedule Snapshot');

    $conn->createTable($tbl);
}

$installer->endSetup();
