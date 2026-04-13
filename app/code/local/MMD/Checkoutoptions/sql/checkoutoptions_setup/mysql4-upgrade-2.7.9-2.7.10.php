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

-- DROP TABLE IF EXISTS `mmd_recurring_profile_entity_custom`;
CREATE TABLE IF NOT EXISTS `mmd_recurring_profile_entity_custom` (
  `value_id` int(11) NOT NULL auto_increment,
  `attribute_id` smallint(5) unsigned NOT NULL default '0',
  `entity_id` int(10) unsigned NOT NULL default '0',
  `value` text NOT NULL,
  PRIMARY KEY  (`value_id`),
  UNIQUE KEY `UNQ_MMD_ENTITY_ATTRIBUTE` (`entity_id`,`attribute_id`),
  KEY `FK_mmd_recurring_profile_entity_custom_attribute` (`attribute_id`),
  KEY `FK_mmd_recurring_profile_entity_custom` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `mmd_recurring_profile_entity_custom`
  ADD CONSTRAINT `mmd_recurring_profile_entity_custom_ibfk_1` FOREIGN KEY (`attribute_id`) REFERENCES `".$installer->getTable('eav_attribute')."` (`attribute_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `mmd_recurring_profile_entity_custom_ibfk_2` FOREIGN KEY (`entity_id`) REFERENCES `".$installer->getTable('sales_recurring_profile')."` (`profile_id`) ON DELETE CASCADE ON UPDATE CASCADE;
");
    
$installer->endSetup();