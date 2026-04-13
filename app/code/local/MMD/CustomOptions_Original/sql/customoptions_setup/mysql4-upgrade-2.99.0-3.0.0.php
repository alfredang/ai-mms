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

if (!$installer->getConnection()->tableColumnExists($installer->getTable('catalog/product_option'), 'div_class')) {
    $installer->getConnection()->addColumn(
        $installer->getTable('catalog/product_option'),
        'div_class',
        "varchar(64) NOT NULL default ''"
    );
}

if (!$installer->getConnection()->tableColumnExists($installer->getTable('catalog/product_option_type_value'), 'weight')) {
    $installer->getConnection()->addColumn(
        $installer->getTable('catalog/product_option_type_value'),
        'weight',
        "DECIMAL( 12, 4 ) NOT NULL DEFAULT '0'"
    );
}

if (!$installer->getConnection()->tableColumnExists($installer->getTable('catalog/product'), 'absolute_weight')) {
    $installer->getConnection()->addColumn(
        $installer->getTable('catalog/product'),
        'absolute_price',
        "TINYINT (1) NOT NULL DEFAULT 0"
    );
    
    $installer->getConnection()->addColumn(
        $installer->getTable('catalog/product'),
        'absolute_weight',
        "TINYINT (1) NOT NULL DEFAULT 0"
    );
}


if (!$installer->getConnection()->tableColumnExists($installer->getTable('customoptions/group'), 'absolute_weight')) {    
    $installer->getConnection()->addColumn(
        $installer->getTable('customoptions/group'),
        'absolute_price',
        "TINYINT (1) NOT NULL DEFAULT 0"
    );
    
    $installer->getConnection()->addColumn(
        $installer->getTable('customoptions/group'),
        'absolute_weight',
        "TINYINT (1) NOT NULL DEFAULT 0"
    );
}



$installer->endSetup();