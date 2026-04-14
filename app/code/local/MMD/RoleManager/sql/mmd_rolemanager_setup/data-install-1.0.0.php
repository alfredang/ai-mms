<?php
/**
 * MMD RoleManager — Data install script
 * Seeds existing users into mmd_user_role_map
 */

$installer = $this;
$installer->startSetup();

$roleMapTable = $installer->getTable('mmd_rolemanager/role_map');
$roleTable    = $installer->getTable('admin/role');
$now          = now();

// Super Admin users: alfred.ang (25), alisha (29), evan (30)
// Give them super_admin (primary) + admin + trainer roles
$superAdminUsers = array(25, 29, 30);
foreach ($superAdminUsers as $userId) {
    $rows = array(
        array('user_id' => $userId, 'role_code' => 'super_admin', 'is_primary' => 1, 'created_at' => $now),
        array('user_id' => $userId, 'role_code' => 'admin',       'is_primary' => 0, 'created_at' => $now),
        array('user_id' => $userId, 'role_code' => 'trainer',     'is_primary' => 0, 'created_at' => $now),
    );
    foreach ($rows as $row) {
        try {
            $installer->getConnection()->insert($roleMapTable, $row);
        } catch (Exception $e) {
            // Ignore duplicate key errors
        }
    }
}

// Admin users: ranjeet (6), soikching (17), saeid (21)
$adminUsers = array(6, 17, 21);
foreach ($adminUsers as $userId) {
    try {
        $installer->getConnection()->insert($roleMapTable, array(
            'user_id'    => $userId,
            'role_code'  => 'admin',
            'is_primary' => 1,
            'created_at' => $now,
        ));
    } catch (Exception $e) {
        // Ignore duplicate key errors
    }
}

// Update admin_role parent_id for Super Admin users to point at "Super Admin" group role
$superAdminRoleId = $installer->getConnection()->fetchOne(
    "SELECT role_id FROM {$roleTable} WHERE role_name = 'Super Admin' AND role_type = 'G'"
);
if ($superAdminRoleId) {
    foreach ($superAdminUsers as $userId) {
        $installer->getConnection()->update(
            $roleTable,
            array('parent_id' => $superAdminRoleId),
            "user_id = {$userId} AND role_type = 'U'"
        );
    }
}

// Update admin_role parent_id for Admin users to point at "Admin" group role
$adminRoleId = $installer->getConnection()->fetchOne(
    "SELECT role_id FROM {$roleTable} WHERE role_name = 'Admin' AND role_type = 'G'"
);
if ($adminRoleId) {
    foreach ($adminUsers as $userId) {
        $installer->getConnection()->update(
            $roleTable,
            array('parent_id' => $adminRoleId),
            "user_id = {$userId} AND role_type = 'U'"
        );
    }
}

$installer->endSetup();
