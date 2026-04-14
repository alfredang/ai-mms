<?php
/**
 * MMD RoleManager — Upgrade 1.0.0 → 1.1.0
 * Add Marketing and Training Provider roles, remove Super Admin,
 * migrate user role mappings, assign angch@tertiaryinfotech.com all roles
 */

$installer = $this;
$installer->startSetup();

$roleTable    = $installer->getTable('admin/role');
$ruleTable    = $installer->getTable('admin/rule');
$roleMapTable = $installer->getTable('mmd_rolemanager/role_map');
$userTable    = $installer->getTable('admin/user');
$conn         = $installer->getConnection();

// Ensure mmd_user_role_map table exists (in case install-1.0.0 failed)
$tableExists = $conn->isTableExists($roleMapTable);
if (!$tableExists) {
    $adminCreateSql = $conn->fetchOne("SHOW CREATE TABLE `{$userTable}`", array(), 1);
    preg_match('/`user_id`\s+(\S+)/i', $adminCreateSql, $matches);
    $userIdDef = isset($matches[1]) ? $matches[1] : 'int';

    $installer->run("
        CREATE TABLE IF NOT EXISTS `{$roleMapTable}` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `user_id` {$userIdDef} NOT NULL,
            `role_code` VARCHAR(32) NOT NULL,
            `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` DATETIME NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `UNQ_USER_ROLE` (`user_id`, `role_code`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    ");
}

// 1. Create "Marketing" group role if not exists
$marketingRoleId = $conn->fetchOne(
    "SELECT role_id FROM {$roleTable} WHERE role_name = 'Marketing' AND role_type = 'G'"
);
if (!$marketingRoleId) {
    $conn->insert($roleTable, array(
        'parent_id' => 0, 'tree_level' => 1, 'sort_order' => 0,
        'role_type' => 'G', 'user_id' => 0, 'role_name' => 'Marketing',
    ));
    $marketingRoleId = $conn->lastInsertId($roleTable);
    foreach (array('admin/dashboard', 'admin/promo', 'admin/cms', 'admin/catalog') as $res) {
        $conn->insert($ruleTable, array(
            'role_id' => $marketingRoleId, 'resource_id' => $res,
            'privileges' => null, 'permission' => 'allow',
        ));
    }
}

// 2. Create "Training Provider" group role if not exists
$tpRoleId = $conn->fetchOne(
    "SELECT role_id FROM {$roleTable} WHERE role_name = 'Training Provider' AND role_type = 'G'"
);
if (!$tpRoleId) {
    $conn->insert($roleTable, array(
        'parent_id' => 0, 'tree_level' => 1, 'sort_order' => 0,
        'role_type' => 'G', 'user_id' => 0, 'role_name' => 'Training Provider',
    ));
    $tpRoleId = $conn->lastInsertId($roleTable);
    foreach (array('admin/dashboard', 'admin/catalog', 'admin/sales', 'admin/report') as $res) {
        $conn->insert($ruleTable, array(
            'role_id' => $tpRoleId, 'resource_id' => $res,
            'privileges' => null, 'permission' => 'allow',
        ));
    }
}

// 3. Ensure Learner, Trainer, Admin group roles exist (from install)
foreach (array('Learner', 'Trainer', 'Admin') as $roleName) {
    $exists = $conn->fetchOne(
        "SELECT role_id FROM {$roleTable} WHERE role_name = ? AND role_type = 'G'",
        array($roleName)
    );
    if (!$exists) {
        $conn->insert($roleTable, array(
            'parent_id' => 0, 'tree_level' => 1, 'sort_order' => 0,
            'role_type' => 'G', 'user_id' => 0, 'role_name' => $roleName,
        ));
        $newRoleId = $conn->lastInsertId($roleTable);
        if ($roleName === 'Admin') {
            $conn->insert($ruleTable, array(
                'role_id' => $newRoleId, 'resource_id' => 'all',
                'privileges' => null, 'permission' => 'allow',
            ));
        } elseif ($roleName === 'Learner') {
            foreach (array('admin/dashboard', 'admin/catalog') as $res) {
                $conn->insert($ruleTable, array(
                    'role_id' => $newRoleId, 'resource_id' => $res,
                    'privileges' => null, 'permission' => 'allow',
                ));
            }
        } elseif ($roleName === 'Trainer') {
            foreach (array('admin/dashboard', 'admin/catalog', 'admin/sales', 'admin/report') as $res) {
                $conn->insert($ruleTable, array(
                    'role_id' => $newRoleId, 'resource_id' => $res,
                    'privileges' => null, 'permission' => 'allow',
                ));
            }
        }
    }
}

// 4. Migrate super_admin role mappings → admin + training_provider
$now = now();
$superAdminRows = $conn->fetchAll(
    "SELECT user_id FROM {$roleMapTable} WHERE role_code = 'super_admin'"
);
foreach ($superAdminRows as $row) {
    $uid = $row['user_id'];
    // Add training_provider if not exists
    try {
        $conn->insert($roleMapTable, array(
            'user_id' => $uid, 'role_code' => 'training_provider',
            'is_primary' => 0, 'created_at' => $now,
        ));
    } catch (Exception $e) {}
    // Add marketing if not exists
    try {
        $conn->insert($roleMapTable, array(
            'user_id' => $uid, 'role_code' => 'marketing',
            'is_primary' => 0, 'created_at' => $now,
        ));
    } catch (Exception $e) {}
    // Ensure admin exists
    try {
        $conn->insert($roleMapTable, array(
            'user_id' => $uid, 'role_code' => 'admin',
            'is_primary' => 0, 'created_at' => $now,
        ));
    } catch (Exception $e) {}
}

// Update primary from super_admin to admin
$conn->update($roleMapTable,
    array('role_code' => 'admin', 'is_primary' => 1),
    "role_code = 'super_admin' AND is_primary = 1"
);
// Delete remaining super_admin entries
$conn->delete($roleMapTable, "role_code = 'super_admin'");

// 5. Find angch@tertiaryinfotech.com and assign all roles
$angchUserId = $conn->fetchOne(
    "SELECT user_id FROM {$userTable} WHERE email = 'angch@tertiaryinfotech.com'"
);
if ($angchUserId) {
    $allRoles = array('learner', 'trainer', 'marketing', 'admin', 'training_provider');
    foreach ($allRoles as $i => $roleCode) {
        try {
            $conn->insert($roleMapTable, array(
                'user_id' => $angchUserId,
                'role_code' => $roleCode,
                'is_primary' => ($roleCode === 'admin') ? 1 : 0,
                'created_at' => $now,
            ));
        } catch (Exception $e) {}
    }
}

// 6. Ensure alfred.ang (25), alisha (29), evan (30) have all 5 roles
$superUsers = array(25, 29, 30);
$allRoles = array('learner', 'trainer', 'marketing', 'admin', 'training_provider');
foreach ($superUsers as $uid) {
    foreach ($allRoles as $roleCode) {
        try {
            $conn->insert($roleMapTable, array(
                'user_id' => $uid, 'role_code' => $roleCode,
                'is_primary' => ($roleCode === 'admin') ? 1 : 0,
                'created_at' => $now,
            ));
        } catch (Exception $e) {}
    }
}

$installer->endSetup();
