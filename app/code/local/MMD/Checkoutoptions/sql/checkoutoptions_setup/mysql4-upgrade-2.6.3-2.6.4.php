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
* @copyright  Copyright (c) 2011 MMD, Inc. 
*/

$installer = $this;

$installer->startSetup();

$installer->run("

ALTER TABLE {$this->getTable('catalog_eav_attribute')}
  ADD COLUMN `mmd_product_category_dependant` tinyint(1) NOT NULL  DEFAULT '0' after `mmd_in_excel`;
");

$installer->run("-- DROP TABLE IF EXISTS `mmd_custom_attribute_cat_refs`;
CREATE TABLE IF NOT EXISTS `mmd_custom_attribute_cat_refs` (
`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
`attribute_id` INT NOT NULL ,
`type` VARCHAR( 80 ) NOT NULL ,
`value` INT NOT NULL,
  KEY `attribute_id` (`attribute_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
");

$installer->endSetup();