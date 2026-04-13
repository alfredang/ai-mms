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
/**
* @copyright  Copyright (c) 2009 MMD, Inc. 
*/

$installer = $this;

$installer->startSetup();

$installer->run("

-- DROP TABLE IF EXISTS `mmd_order_entity_custom`;
CREATE TABLE IF NOT EXISTS `mmd_order_entity_custom` (
  `value_id` int(11) NOT NULL auto_increment,
  `attribute_id` smallint(5) unsigned NOT NULL default '0',
  `entity_id` int(10) unsigned NOT NULL default '0',
  `value` text NOT NULL,
  PRIMARY KEY  (`value_id`),
  UNIQUE KEY `UNQ_MMD_ENTITY_ATTRIBUTE` (`entity_id`,`attribute_id`),
  KEY `FK_mmd_order_entity_custom_attribute` (`attribute_id`),
  KEY `FK_mmd_order_entity_custom` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `mmd_order_entity_custom`
  ADD CONSTRAINT `mmd_order_entity_custom_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `mmd_order_entity_custom_ibfk_2` FOREIGN KEY (`entity_id`) REFERENCES `".$installer->getTable('sales_flat_order')."` (`entity_id`) ON DELETE CASCADE ON UPDATE CASCADE;
  
-- DROP TABLE IF EXISTS `mmd_custom_attribute_description`;
CREATE TABLE IF NOT EXISTS `mmd_custom_attribute_description` (
  `attribute_id` smallint(5) unsigned NOT NULL default '0',
  `store_id` smallint(5) unsigned NOT NULL default '0',
  `value` text NOT NULL,
  UNIQUE KEY `UNQ_MMD_DESC_ATTRIBUTE` (`store_id`,`attribute_id`),
  KEY `FK_mmd_attr_custom_attribute` (`attribute_id`),
  KEY `FK_mmd_desc_custom_attribute` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `mmd_custom_attribute_description`
  CHANGE COLUMN `attribute_id` `attribute_id` smallint(5) unsigned NOT NULL default '0',
  CHANGE COLUMN `store_id` `store_id` smallint(5) unsigned NOT NULL default '0',
  ADD CONSTRAINT `mmd_custom_attribute_description_ibfk_2` FOREIGN KEY (`store_id`) REFERENCES `".$installer->getTable('core_store')."` (`store_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `mmd_custom_attribute_description_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE;


-- DROP TABLE IF EXISTS `mmd_custom_attribute_need_select`;
CREATE TABLE IF NOT EXISTS `mmd_custom_attribute_need_select` (
  `attribute_id` smallint(5) unsigned NOT NULL default '0',
  `store_id` smallint(5) unsigned NOT NULL default '0',
  `value` text NOT NULL,
  UNIQUE KEY `UNQ_MMD_NEED_SEL_ATTRIBUTE` (`store_id`,`attribute_id`),
  KEY `FK_mmd_need_sel_custom_attribute_attr` (`attribute_id`),
  KEY `FK_mmd_need_sel_custom_attribute_store` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `mmd_custom_attribute_need_select`
  CHANGE COLUMN `attribute_id` `attribute_id` smallint(5) unsigned NOT NULL default '0',
  CHANGE COLUMN `store_id` `store_id` smallint(5) unsigned NOT NULL default '0',
  ADD CONSTRAINT `mmd_custom_attribute_need_select_ibfk_2` FOREIGN KEY (`store_id`) REFERENCES `".$installer->getTable('core_store')."` (`store_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `mmd_custom_attribute_need_select_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE;

");
    $eavTypeTable = $installer->getTable('eav_entity_type');
    $typeExists = $installer->getConnection()->fetchOne("SELECT count(*) FROM `{$eavTypeTable}` WHERE `entity_type_code`='mmd_checkout'");
    if(!$typeExists)
    {
        $data = $installer->getConnection()->insert($eavTypeTable, array('entity_type_code'=>'mmd_checkout'));
    }

$installer->endSetup();