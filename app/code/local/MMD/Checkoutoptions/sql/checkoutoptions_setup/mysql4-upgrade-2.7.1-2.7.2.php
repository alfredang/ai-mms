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
    ALTER TABLE `mmd_custom_attribute_cg` ADD `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST
");

$installer->endSetup();