<?php
/**
 * Add `course_image_url` product attribute (text, global scope).
 * Idempotent — wraps in try/catch to handle duplicate entries.
 */

/** @var Mage_Catalog_Model_Resource_Eav_Mysql4_Setup $installer */
$installer = Mage::getResourceModel('catalog/setup', 'core_setup');
$installer->startSetup();

try {
    $entityTypeId = $installer->getEntityTypeId('catalog_product');
    $attrCode     = 'course_image_url';

    if (!$installer->getAttributeId($entityTypeId, $attrCode)) {
        $installer->addAttribute('catalog_product', $attrCode, array(
            'group'             => 'General',
            'label'             => 'Course Image URL',
            'type'              => 'varchar',
            'input'             => 'text',
            'class'             => 'validate-url',
            'global'            => Mage_Catalog_Model_Resource_Eav_Attribute::SCOPE_GLOBAL,
            'visible'           => true,
            'required'          => false,
            'user_defined'      => true,
            'searchable'        => false,
            'filterable'        => false,
            'comparable'        => false,
            'visible_on_front'  => false,
            'used_in_product_listing' => true,
            'unique'            => false,
            'default'           => '',
        ));
    }
} catch (Exception $e) {
    // Attribute already exists — safe to ignore
    Mage::log('RoleManager upgrade 1.1.0-1.2.0: ' . $e->getMessage(), Zend_Log::NOTICE);
}

$installer->endSetup();
