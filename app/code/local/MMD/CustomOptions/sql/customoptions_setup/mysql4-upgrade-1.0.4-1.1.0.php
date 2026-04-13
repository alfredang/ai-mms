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
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@magemobiledesign.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade the extension
 * to newer versions in the future. If you wish to customize the extension
 * for your needs please refer to http://www.magemobiledesign.com/ for more information
 * or send an email to sales@magemobiledesign.com
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @copyright  Copyright (c) 2013 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * Custom Options extension
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @author     MMD Dev Team <developers@magemobiledesign.com>
 */

/* @var $installer MMD_CustomOptions_Model_Mysql4_Setup */
$installer = $this;

$installer->startSetup();

if (!$installer->getConnection()->tableColumnExists($installer->getTable('catalog/product_option'), 'image_path')) {
    $installer->getConnection()->addColumn(
        $installer->getTable('catalog/product_option'),
        'image_path',
        "varchar (255) default ''"
    );
}    

//if (!$installer->getConnection()->tableColumnExists($installer->getTable('catalog/product_option_type_value'), 'image_path')) {
//    $installer->getConnection()->addColumn(
//        $installer->getTable('catalog/product_option_type_value'),
//        'image_path',
//        "varchar (255) default ''"
//    );
//}

$installer->endSetup();
