<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
$installer = $this;

$installer->startSetup();

$tablesToCheck = array(
    'mmd_order_entity_custom',
    'mmd_custom_attribute_description',
    'mmd_custom_attribute_need_select',
    'mmd_customer_entity_data',
    'mmd_custom_attribute_cg',
    'mmd_custom_attribute_cat_refs',
    'mmd_recurring_profile_entity_custom'
);
foreach($tablesToCheck as $table) {
    try {
        $installer->run("
            RENAME TABLE `".$table."` TO `".$installer->getTable($table)."` ;
        ");
    } catch(Exception $e)
    {
        //well, maybe tables were not exisits after all
    }
}

$installer->endSetup();