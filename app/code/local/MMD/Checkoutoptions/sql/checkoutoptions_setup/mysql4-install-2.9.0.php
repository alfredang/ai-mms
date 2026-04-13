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
//script contains all data from previous installations and upgrages

//1.5.0-1.5.1 data
$installer->run("

-- DROP TABLE IF EXISTS `mmd_order_entity_custom`;
-- DROP TABLE IF EXISTS `".$installer->getTable('mmd_order_entity_custom')."`;
CREATE TABLE `".$installer->getTable('mmd_order_entity_custom')."` (
  `value_id` int(11) NOT NULL AUTO_INCREMENT,
  `attribute_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `entity_id` int(10) unsigned NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  PRIMARY KEY (`value_id`),
  UNIQUE KEY `UNQ_MMD_ENTITY_ATTRIBUTE` (`entity_id`,`attribute_id`),
  KEY `FK_mmd_order_entity_custom_attribute` (`attribute_id`),
  KEY `FK_mmd_order_entity_custom` (`entity_id`),
  CONSTRAINT `mmd_order_entity_custom_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `mmd_order_entity_custom_ibfk_2` FOREIGN KEY (`entity_id`) REFERENCES `".$installer->getTable('sales_flat_order')."` (`entity_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- DROP TABLE IF EXISTS `mmd_custom_attribute_description`;
-- DROP TABLE IF EXISTS `".$installer->getTable('mmd_custom_attribute_description')."`;
CREATE TABLE IF NOT EXISTS `".$installer->getTable('mmd_custom_attribute_description')."` (
  `attribute_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `store_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  UNIQUE KEY `UNQ_MMD_DESC_ATTRIBUTE` (`store_id`,`attribute_id`),
  KEY `FK_mmd_attr_custom_attribute` (`attribute_id`),
  KEY `FK_mmd_desc_custom_attribute` (`store_id`),
  CONSTRAINT `mmd_custom_attribute_description_ibfk_2` FOREIGN KEY (`store_id`) REFERENCES `".$installer->getTable('core_store')."` (`store_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `mmd_custom_attribute_description_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- DROP TABLE IF EXISTS `mmd_custom_attribute_need_select`;
-- DROP TABLE IF EXISTS `".$installer->getTable('mmd_custom_attribute_need_select')."`;
CREATE TABLE IF NOT EXISTS `".$installer->getTable('mmd_custom_attribute_need_select')."` (
  `attribute_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `store_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  UNIQUE KEY `UNQ_MMD_NEED_SEL_ATTRIBUTE` (`store_id`,`attribute_id`),
  KEY `FK_mmd_need_sel_custom_attribute_attr` (`attribute_id`),
  KEY `FK_mmd_need_sel_custom_attribute_store` (`store_id`),
  CONSTRAINT `mmd_custom_attribute_need_select_ibfk_2` FOREIGN KEY (`store_id`) REFERENCES `".$installer->getTable('core_store')."` (`store_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `mmd_custom_attribute_need_select_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

");

$eavTypeTable = $installer->getTable('eav_entity_type');
$typeExists = $installer->getConnection()->fetchOne("SELECT count(*) FROM `{$eavTypeTable}` WHERE `entity_type_code`='mmd_checkout'");
if(!$typeExists)
{
    $data = $installer->getConnection()->insert($eavTypeTable, array('entity_type_code'=>'mmd_checkout'));
}
//1.5.1-1.6.0 data
$installer->run("
-- DROP TABLE IF EXISTS `mmd_customer_entity_data`;
-- DROP TABLE IF EXISTS `".$installer->getTable('mmd_customer_entity_data')."`;
CREATE TABLE `".$installer->getTable('mmd_customer_entity_data')."` (
  `value_id` int(11) NOT NULL AUTO_INCREMENT,
  `attribute_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `entity_id` int(10) unsigned NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  PRIMARY KEY (`value_id`),
  UNIQUE KEY `UNQ_MMD_CUSTOMER_ATTRIBUTE` (`attribute_id`,`entity_id`),
  KEY `FK_mmd_customer_entity_data` (`entity_id`),
  KEY `FK_mmd_customer_attribute_data` (`attribute_id`),
  CONSTRAINT `mmd_customer_entity_data_ibfk_1` FOREIGN KEY (`entity_id`) REFERENCES `".$installer->getTable('customer_entity')."` (`entity_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `mmd_customer_entity_data_ibfk_2` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE {$this->getTable('catalog_eav_attribute')}
  ADD COLUMN `mmd_registration_page` tinyint(1) NOT NULL  DEFAULT '0' after `is_wysiwyg_enabled`,
  ADD COLUMN `mmd_registration_place` tinyint(1) NOT NULL DEFAULT '0' after `mmd_registration_page`,
  ADD COLUMN `mmd_registration_position` int(11) NOT NULL DEFAULT '0' after `mmd_registration_place`, ".
  //mysql4-upgrade-2.4.3-2.4.4
  "ADD COLUMN `mmd_filterable` tinyint(1) NOT NULL  DEFAULT '0' after `mmd_registration_place`, ".
  //mysql4-upgrade-2.4.7-2.5.0
  "ADD COLUMN `is_display_in_invoice` tinyint(1) NOT NULL  DEFAULT '0' after `mmd_filterable`, ".
  //mysql4-upgrade-2.5.0-2.5.1
  "ADD COLUMN `mmd_in_excel` tinyint(1) NOT NULL  DEFAULT '0' after `is_display_in_invoice`, ".
  //mysql4-upgrade-2.6.3-2.6.4
  "ADD COLUMN `mmd_product_category_dependant` tinyint(1) NOT NULL  DEFAULT '0' after `mmd_in_excel`;
");

//mysql4-upgrade-2.5.11-2.6.0
$installer->run("
-- DROP TABLE IF EXISTS `mmd_custom_attribute_cg`;
-- DROP TABLE IF EXISTS `".$installer->getTable('mmd_custom_attribute_cg')."`;
CREATE TABLE IF NOT EXISTS `".$installer->getTable('mmd_custom_attribute_cg')."` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `attribute_id` int(11) NOT NULL,
  `customer_group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `attribute_id` (`attribute_id`),
  KEY `customer_group_id` (`customer_group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
");

//mysql4-upgrade-2.6.3-2.6.4
$installer->run("
-- DROP TABLE IF EXISTS `mmd_custom_attribute_cat_refs`;
-- DROP TABLE IF EXISTS `".$installer->getTable('mmd_custom_attribute_cat_refs')."`;
CREATE TABLE IF NOT EXISTS `".$installer->getTable('mmd_custom_attribute_cat_refs')."` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `attribute_id` int(11) NOT NULL,
  `type` varchar(80) NOT NULL,
  `value` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `attribute_id` (`attribute_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
");

//mysql4-upgrade-2.7.9-2.7.10
$installer->run("
-- DROP TABLE IF EXISTS `mmd_recurring_profile_entity_custom`;
-- DROP TABLE IF EXISTS `".$installer->getTable('mmd_recurring_profile_entity_custom')."`;
CREATE TABLE IF NOT EXISTS `".$installer->getTable('mmd_recurring_profile_entity_custom')."` (
  `value_id` int(11) NOT NULL AUTO_INCREMENT,
  `attribute_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `entity_id` int(10) unsigned NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  PRIMARY KEY (`value_id`),
  UNIQUE KEY `UNQ_MMD_ENTITY_ATTRIBUTE` (`entity_id`,`attribute_id`),
  KEY `FK_mmd_recurring_profile_entity_custom_attribute` (`attribute_id`),
  KEY `FK_mmd_recurring_profile_entity_custom` (`entity_id`),
  CONSTRAINT `mmd_recurring_profile_entity_custom_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `mmd_recurring_profile_entity_custom_ibfk_2` FOREIGN KEY (`entity_id`) REFERENCES `".$installer->getTable('sales_recurring_profile')."` (`profile_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
");
$installer->endSetup();