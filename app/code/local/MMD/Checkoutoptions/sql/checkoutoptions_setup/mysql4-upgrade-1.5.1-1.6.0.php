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

-- DROP TABLE IF EXISTS `mmd_customer_entity_data`;
CREATE TABLE `mmd_customer_entity_data` (
  `value_id` int(11) NOT NULL AUTO_INCREMENT,
  `attribute_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `entity_id` int(10) unsigned NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  PRIMARY KEY (`value_id`),
  UNIQUE KEY `UNQ_MMD_CUSTOMER_ATTRIBUTE` (`attribute_id`,`entity_id`),
  KEY `FK_mmd_customer_entity_data` (`entity_id`),
  KEY `FK_mmd_customer_attribute_data` (`attribute_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `mmd_customer_entity_data`
  ADD CONSTRAINT `mmd_customer_entity_data_ibfk_1` FOREIGN KEY (`entity_id`) REFERENCES `".$installer->getTable('customer_entity')."` (`entity_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `mmd_customer_entity_data_ibfk_2` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE {$this->getTable('catalog_eav_attribute')}
  ADD COLUMN `mmd_registration_page` tinyint(1) NOT NULL  DEFAULT '0' after `is_wysiwyg_enabled`,
  ADD COLUMN `mmd_registration_place` tinyint(1) NOT NULL DEFAULT '0' after `mmd_registration_page`,
  ADD COLUMN `mmd_registration_position` int(11) NOT NULL DEFAULT '0' after `mmd_registration_place`;

");

$installer->endSetup();