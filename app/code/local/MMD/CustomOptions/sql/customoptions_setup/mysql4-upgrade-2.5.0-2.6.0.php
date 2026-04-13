<?php
/**
 * MMD
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the MMD EULA that is bundled with
 * this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://www.magemobiledesign.com/LICENSE-1.0.html
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade the extension
 * to newer versions in the future. If you wish to customize the extension
 * for your needs please refer to http://www.magemobiledesign.com/ for more information
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @copyright  Copyright (c) 2012 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * Advanced Product Options extension
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @author     MMD Dev Team
 */

/* @var $installer MMD_CustomOptions_Model_Mysql4_Setup */
$installer = $this;
$installer->startSetup();


if ($installer->getConnection()->tableColumnExists($installer->getTable('customoptions/group'), 'store_id')) {
    $installer->run("ALTER TABLE `{$installer->getTable('customoptions/group')}` DROP `store_id`;");
}

$installer->run("-- DROP TABLE IF EXISTS `{$installer->getTable('customoptions/group_store')}`;
CREATE TABLE IF NOT EXISTS `{$installer->getTable('customoptions/group_store')}` (
  `group_store_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `group_id` int(10) unsigned NOT NULL,
  `store_id` smallint(5) unsigned NOT NULL,  
  `hash_options` longtext NOT NULL,
  PRIMARY KEY (`group_store_id`),
  UNIQUE KEY `UNQ_CUSTOM_OPTIONS_GROUP_STORE` (`group_id`,`store_id`),
  CONSTRAINT `FK_MAGEWORX_CUSTOM_OPTIONS_GROUP_STORE` FOREIGN KEY (`group_id`) REFERENCES `{$installer->getTable('customoptions/group')}` (`group_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;");
  
$installer->endSetup();