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


$installer->run("-- DROP TABLE IF EXISTS `mmd_custom_attribute_cg`;
CREATE TABLE IF NOT EXISTS `mmd_custom_attribute_cg` (
  `attribute_id` int(11) NOT NULL,
  `customer_group_id` int(11) NOT NULL,
  KEY `attribute_id` (`attribute_id`),
  KEY `customer_group_id` (`customer_group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
");

$installer->endSetup();