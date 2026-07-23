<?php
/**
 * Create operations-staff admin accounts (admin role only).
 *
 * WHY THIS IS A SCRIPT, NOT A MIGRATION
 * OpenMage admin passwords are `sha256(password:salt):salt` with a random
 * per-user salt. A .sql migration cannot generate that safely — it would have
 * to hard-code a literal hash, which would publish a working credential for
 * these real staff accounts into the public GitHub repo's history. This script
 * hashes through Magento's own model at run time instead, so nothing sensitive
 * lands in git. Run once per install (SG here); it is idempotent.
 *
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/create-ops-admin-accounts.php
 *
 * Accounts get the DEFAULT password `password12345` and are flagged to change
 * it on next login (extra.force_password_change). Grants role_code='admin'
 * only — deliberately NOT the trainer role, so they stay out of the trainer
 * invite picker.
 */

require_once dirname(__FILE__) . '/../../app/Mage.php';
Mage::app('admin');

$DEFAULT_PASSWORD = 'password12345';

$people = array(
    array('sylvia',   'sylvia@tertiaryinfotech.com'),
    array('zulaikha', 'zulaikha@tertiaryinfotech.com'),
    array('sales',    'sales@tertiarycourses.com.sg'),
    array('tanwm',    'tanwm@tertiaryinfotech.com'),
    array('marcus',   'marcus@tertiaryinfotech.com'),
);

$res   = Mage::getSingleton('core/resource');
$read  = $res->getConnection('core_read');
$write = $res->getConnection('core_write');
$auTbl = $res->getTableName('admin_user');
$rmTbl = $res->getTableName('mmd_user_role_map');
$arTbl = $res->getTableName('admin_role');

// ACL parent group for the "Admin" role (from admin_role role_type='G').
$adminGroupId = (int) $read->fetchOne(
    "SELECT role_id FROM `$arTbl` WHERE role_type = 'G' AND role_name = 'Admin' LIMIT 1"
);
if (!$adminGroupId) {
    // Fall back to Administrators (full access) so login still works if the
    // per-role ACL groups were never seeded on this instance.
    $adminGroupId = (int) $read->fetchOne(
        "SELECT role_id FROM `$arTbl` WHERE role_type = 'G' AND role_name = 'Administrators' LIMIT 1"
    );
}
echo "Admin ACL group role_id = $adminGroupId\n";

foreach ($people as $p) {
    list($first, $email) = $p;

    $existing = (int) $read->fetchOne("SELECT user_id FROM `$auTbl` WHERE email = ?", array($email));
    if ($existing) {
        echo "SKIP  $email already exists (uid=$existing)\n";
        continue;
    }

    // Create through the admin/user model so the password is hashed exactly the
    // way login validation expects. username = email (this portal is email-only
    // login; username is a write-only mirror of email).
    $user = Mage::getModel('admin/user');
    $user->setData(array(
        'username'  => $email,
        'firstname' => ucfirst($first),
        'lastname'  => '',
        'email'     => $email,
        'password'  => $DEFAULT_PASSWORD,
        'is_active' => 1,
    ));
    $user->save();
    $uid = (int) $user->getId();

    // Force a password change on first login.
    $extra = array('force_password_change' => true);
    $write->update($auTbl, array('extra' => serialize($extra)), array('user_id = ?' => $uid));

    // Bridge to the Magento ACL group (admin_role U-row pointing at the Admin group).
    $write->insert($arTbl, array(
        'parent_id' => $adminGroupId,
        'tree_level' => 2,
        'sort_order' => 0,
        'role_type' => 'U',
        'user_id'   => $uid,
        'role_name' => ucfirst($first),
    ));

    // Custom role map — admin only, primary.
    $write->insert($rmTbl, array(
        'user_id'    => $uid,
        'role_code'  => 'admin',
        'is_primary' => 1,
    ));

    echo "CREATE $email uid=$uid role=admin (default password set, change-on-login)\n";
}

echo "Done.\n";
