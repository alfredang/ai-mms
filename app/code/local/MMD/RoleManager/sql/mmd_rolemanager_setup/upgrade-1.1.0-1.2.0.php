<?php
/**
 * Add `course_image_url` product attribute (text, global scope).
 * Lets admins paste a direct external image URL to use as the course
 * thumbnail. The Learner My Classes view prefers this URL when set,
 * falling back to the standard uploaded image otherwise.
 *
 * Auto-runs on every environment when the module version bumps to 1.2.0.
 * Idempotent — uses the catalog setup helper which checks for existence.
 */

/** @var Mage_Catalog_Model_Resource_Eav_Mysql4_Setup $installer */
$installer = Mage::getResourceModel('catalog/setup', 'core_setup');
$installer->startSetup();

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
        'note'              => 'Paste a direct image URL (https://...) to use as the course thumbnail. Overrides the uploaded image if set.',
    ));
}

$installer->endSetup();
