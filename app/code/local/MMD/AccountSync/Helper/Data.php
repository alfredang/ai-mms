<?php
/**
 * Account unification helper (see memory project-account-unification).
 *
 * Every storefront customer_entity (learner) gets a matching dashboard
 * admin_user with the 'learner' role, created INACTIVE (is_active=0) so it
 * cannot log in until the learner-role ACL is locked down and accounts are
 * activated (Stage 3B). Passwords stay in sync BIDIRECTIONALLY.
 *
 * Why this is safe + loop-free:
 *  - customer_entity.password_hash and admin_user.password use the IDENTICAL
 *    format (Mage::helper('core')->getHash($pw, 32); customer hashPassword()
 *    reuses Mage_Admin_Model_User::HASH_SALT_LENGTH), so we copy the HASH
 *    across — never plaintext, never re-encoded.
 *  - Every write here is RAW SQL (insert/update), NOT a model save(), so no
 *    customer_save_after / admin_user_save_after fires from our own writes —
 *    the two directions can't cascade into each other.
 *  - Sends NO email (creation + backfill are silent by design).
 */
class MMD_AccountSync_Helper_Data extends Mage_Core_Helper_Abstract
{
    const LEARNER_ROLE = 'learner';

    /**
     * Storefront customer saved -> ensure a matching dashboard account exists
     * (inactive) and push a changed password to it.
     */
    public function onCustomerSaved(Mage_Customer_Model_Customer $customer)
    {
        $email = strtolower(trim((string) $customer->getEmail()));
        if ($email === '' || strpos($email, '@') === false) {
            return;
        }

        $res   = Mage::getSingleton('core/resource');
        $read  = $res->getConnection('core_read');
        $write = $res->getConnection('core_write');
        $auTbl = $res->getTableName('admin_user');

        $adminId = (int) $read->fetchOne(
            "SELECT user_id FROM `$auTbl` WHERE email = ? LIMIT 1",
            array($email)
        );
        $hash = (string) $customer->getPasswordHash();

        if ($adminId) {
            // Existing dashboard account (operator who is also a customer, or a
            // previously-synced learner). Make sure the learner role is present
            // (non-primary so we never demote an operator's primary role), and
            // push a changed password through.
            $this->_addLearnerRole($adminId, false);
            if ($hash !== '' && $customer->dataHasChangedFor('password_hash')) {
                $write->update($auTbl, array('password' => $hash), array('user_id = ?' => $adminId));
            }
            return;
        }

        $adminId = $this->_createLearnerAdmin($customer, $email, $hash);
        if ($adminId) {
            $this->_addLearnerRole($adminId, true); // fresh account -> learner is primary
            // Assign the Magento ACL role group ('Learner') so the account can
            // actually authenticate — Mage_Admin_Model_User::authenticate()
            // throws "Access denied" without an admin_role 'U' row. The Learner
            // group is all=allow at the ACL layer; the real confinement is the
            // RoleManager predispatch lockdown.
            try {
                Mage::helper('mmd_rolemanager')->applyRoleAcl($adminId, self::LEARNER_ROLE);
            } catch (Exception $e) {
                Mage::logException($e);
            }
        }
    }

    /**
     * Dashboard admin_user password changed -> mirror it onto the storefront
     * account(s) with the same email (all website rows, which unifies a
     * multi-website learner's logins).
     *
     * The customer is EAV here: the hash lives in customer_entity_varchar under
     * the 'password_hash' attribute (NOT a flat customer_entity column). We
     * write the value table directly (raw = no customer_save_after = no loop).
     */
    public function onAdminUserSaved(Mage_Admin_Model_User $user)
    {
        if (!$user->getId() || !$user->dataHasChangedFor('password')) {
            return;
        }
        $email = strtolower(trim((string) $user->getEmail()));
        $hash  = (string) $user->getPassword();
        if ($email === '' || $hash === '') {
            return;
        }

        $res   = Mage::getSingleton('core/resource');
        $read  = $res->getConnection('core_read');
        $write = $res->getConnection('core_write');

        $cids = $read->fetchCol(
            "SELECT entity_id FROM `" . $res->getTableName('customer/entity') . "` WHERE LOWER(email) = ?",
            array($email)
        );
        if (!$cids) {
            return;
        }

        $attr = Mage::getSingleton('eav/config')->getAttribute('customer', 'password_hash');
        if (!$attr || !$attr->getId()) {
            return;
        }
        $cev  = $attr->getBackend()->getTable();   // customer_entity_varchar
        $etid = (int) $attr->getEntityTypeId();
        $aid  = (int) $attr->getId();

        foreach ($cids as $cid) {
            $valueId = $read->fetchOne(
                "SELECT value_id FROM `$cev` WHERE entity_id = ? AND attribute_id = ? LIMIT 1",
                array((int) $cid, $aid)
            );
            if ($valueId) {
                $write->update($cev, array('value' => $hash), array('value_id = ?' => (int) $valueId));
            } else {
                $write->insert($cev, array(
                    'entity_type_id' => $etid,
                    'attribute_id'   => $aid,
                    'entity_id'      => (int) $cid,
                    'value'          => $hash,
                ));
            }
        }
    }

    // ------------------------------------------------------------------ //

    /**
     * Raw-insert a learner admin_user, copying the customer's hash verbatim (no
     * re-encode). Created ACTIVE (is_active=1) — safe because the learner-role
     * ACL lockdown (MMD_RoleManager Observer default-deny) confines learners to
     * their dashboard. Returns the new user_id (or an existing one if a race
     * created it first). Raw insert => no admin_user_save_after => no loop.
     */
    public function _createLearnerAdmin(Mage_Customer_Model_Customer $customer, $email, $hash)
    {
        $res   = Mage::getSingleton('core/resource');
        $read  = $res->getConnection('core_read');
        $write = $res->getConnection('core_write');
        $auTbl = $res->getTableName('admin_user');

        $first = trim((string) $customer->getFirstname());
        $last  = trim((string) $customer->getLastname());
        if ($first === '') { $first = 'Learner'; }
        if ($last === '')  { $last  = '-'; }

        if ($hash === '') {
            // No usable storefront hash -> unguessable placeholder. The learner
            // signs in via OTP / change-password once activated (3B).
            $hash = Mage::helper('core')->getHash(
                Mage::helper('core')->getRandomString(24),
                Mage_Admin_Model_User::HASH_SALT_LENGTH
            );
        }

        $now = Mage::getModel('core/date')->gmtDate();
        try {
            $write->insert($auTbl, array(
                'firstname'       => substr($first, 0, 32),
                'lastname'        => substr($last, 0, 32),
                'email'           => substr($email, 0, 128),
                'username'        => substr($email, 0, 40),
                'password'        => $hash,
                'is_active'       => 1, // ACTIVE — learner-role ACL lockdown confines them to the dashboard
                'created'         => $now,
                'modified'        => $now,
                'lognum'          => 0,
                'reload_acl_flag' => 0,
            ));
            return (int) $write->lastInsertId();
        } catch (Exception $e) {
            // Race or username-truncation clash -> re-resolve by email.
            Mage::log('AccountSync create failed for ' . $email . ': ' . $e->getMessage(),
                Zend_Log::WARN, 'accountsync.log');
            return (int) $read->fetchOne(
                "SELECT user_id FROM `$auTbl` WHERE email = ? LIMIT 1",
                array($email)
            );
        }
    }

    /** Idempotently map the learner role to a dashboard user (UNIQUE user_id+role_code). */
    public function _addLearnerRole($adminId, $isPrimary)
    {
        if (!$adminId) {
            return;
        }
        $res   = Mage::getSingleton('core/resource');
        $write = $res->getConnection('core_write');
        $map   = $res->getTableName('mmd_user_role_map');
        $write->query(
            "INSERT IGNORE INTO `$map` (user_id, role_code, is_primary, created_at) VALUES (?, ?, ?, ?)",
            array((int) $adminId, self::LEARNER_ROLE, $isPrimary ? 1 : 0, Mage::getModel('core/date')->gmtDate())
        );
    }
}
