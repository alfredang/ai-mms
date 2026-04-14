<?php
/**
 * MMD RoleManager — Install script
 * Creates mmd_user_role_map table and 4 ACL group roles with rules
 */

$installer = $this;
$installer->startSetup();

// 1. Create mmd_user_role_map table
// Get the exact column type from admin_user table
$adminUserTable = $installer->getTable('admin/user');
$colInfo = $installer->getConnection()->describeTable($adminUserTable);
$userIdType = 'INT UNSIGNED';
if (isset($colInfo['user_id'])) {
    $col = $colInfo['user_id'];
    $userIdType = $col['DATA_TYPE'];
    if ($col['UNSIGNED']) $userIdType .= ' UNSIGNED';
}

$installer->run("
    CREATE TABLE IF NOT EXISTS `{$installer->getTable('mmd_rolemanager/role_map')}` (
        `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `user_id` {$userIdType} NOT NULL,
        `role_code` VARCHAR(32) NOT NULL COMMENT 'learner, trainer, admin, super_admin',
        `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
        `created_at` DATETIME NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `UNQ_USER_ROLE` (`user_id`, `role_code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='User to Role mapping for MMD RoleManager';
");

// 2. Create 4 ACL group roles in admin_role
$roleTable = $installer->getTable('admin/role');
$ruleTable = $installer->getTable('admin/rule');

$roles = array(
    'Learner'     => 'learner',
    'Trainer'     => 'trainer',
    'Admin'       => 'admin',
    'Super Admin' => 'super_admin',
);

// ACL resources per role
$roleResources = array(
    'learner' => array(
        'admin/dashboard',
        'admin/catalog',
    ),
    'trainer' => array(
        'admin/dashboard',
        'admin/catalog',
        'admin/catalog/products',
        'admin/sales',
        'admin/sales/order',
        'admin/report',
    ),
    'admin' => array(
        'admin/dashboard',
        'admin/catalog',
        'admin/catalog/products',
        'admin/catalog/categories',
        'admin/sales',
        'admin/sales/order',
        'admin/sales/invoice',
        'admin/sales/shipment',
        'admin/sales/creditmemo',
        'admin/customer',
        'admin/promo',
        'admin/report',
        'admin/cms',
        'admin/global_search',
    ),
    'super_admin' => array(
        'admin',  // all resources
    ),
);

foreach ($roles as $roleName => $roleCode) {
    // Check if role already exists
    $exists = $installer->getConnection()->fetchOne(
        "SELECT role_id FROM {$roleTable} WHERE role_name = ? AND role_type = 'G'",
        array($roleName)
    );
    if ($exists) {
        continue;
    }

    // Insert group role
    $installer->getConnection()->insert($roleTable, array(
        'parent_id'  => 0,
        'tree_level' => 1,
        'sort_order' => 0,
        'role_type'  => 'G',
        'user_id'    => 0,
        'role_name'  => $roleName,
    ));
    $roleId = $installer->getConnection()->lastInsertId($roleTable);

    // Insert ACL rules
    $resources = $roleResources[$roleCode];
    if (in_array('admin', $resources)) {
        // Super Admin — allow all
        $installer->getConnection()->insert($ruleTable, array(
            'role_id'     => $roleId,
            'resource_id' => 'all',
            'privileges'  => null,
            'permission'  => 'allow',
        ));
    } else {
        // Allow specific resources
        foreach ($resources as $resource) {
            $installer->getConnection()->insert($ruleTable, array(
                'role_id'     => $roleId,
                'resource_id' => $resource,
                'privileges'  => null,
                'permission'  => 'allow',
            ));
        }
    }
}

$installer->endSetup();
