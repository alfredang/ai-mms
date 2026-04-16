<?php
/**
 * Ensure course_image_url is in the General group of EVERY product attribute set.
 * The 1.2.0 upgrade only added it to the default set; this fixes the rest.
 */

/** @var Mage_Catalog_Model_Resource_Eav_Mysql4_Setup $installer */
$installer = Mage::getResourceModel('catalog/setup', 'core_setup');
$installer->startSetup();

$entityTypeId = $installer->getEntityTypeId('catalog_product');
$attrCode     = 'course_image_url';
$attributeId  = $installer->getAttributeId($entityTypeId, $attrCode);

if (!$attributeId) {
    // Attribute doesn't exist at all — create it first
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
        'note'              => 'Paste a direct image URL (https://...) to use as the course thumbnail.',
    ));
    $attributeId = $installer->getAttributeId($entityTypeId, $attrCode);
}

// Now ensure the attribute is in every attribute set's General group
$sets = $installer->getConnection()->fetchAll(
    "SELECT attribute_set_id FROM eav_attribute_set WHERE entity_type_id = ?",
    array($entityTypeId)
);

foreach ($sets as $set) {
    $setId = (int) $set['attribute_set_id'];

    // Find the "General" group for this set
    $groupId = $installer->getConnection()->fetchOne(
        "SELECT attribute_group_id FROM eav_attribute_group WHERE attribute_set_id = ? AND attribute_group_name = 'General'",
        array($setId)
    );
    if (!$groupId) {
        continue; // no General group — skip
    }

    // Check if already assigned
    $exists = $installer->getConnection()->fetchOne(
        "SELECT 1 FROM eav_entity_attribute WHERE attribute_set_id = ? AND attribute_id = ?",
        array($setId, $attributeId)
    );
    if ($exists) {
        continue; // already there
    }

    // Get next sort_order
    $maxSort = (int) $installer->getConnection()->fetchOne(
        "SELECT MAX(sort_order) FROM eav_entity_attribute WHERE attribute_set_id = ? AND attribute_group_id = ?",
        array($setId, $groupId)
    );

    $installer->getConnection()->insert('eav_entity_attribute', array(
        'entity_type_id'   => $entityTypeId,
        'attribute_set_id' => $setId,
        'attribute_group_id' => $groupId,
        'attribute_id'     => $attributeId,
        'sort_order'       => $maxSort + 1,
    ));
}

$installer->endSetup();
