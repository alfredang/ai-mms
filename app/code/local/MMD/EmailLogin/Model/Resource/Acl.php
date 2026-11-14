<?php
/**
 * Slim session ACL.
 *
 * Stock loadAcl() registers EVERY admin_role row. Since the account-unification
 * refactor each storefront learner has a shadow admin_user with its own 'U' role
 * row (~9.9k on SG), so the ACL object stored in every admin session grew to
 * ~1.9 MB and was read from and written back to the session store on every
 * admin request.
 *
 * A session only ever checks its own user's role ('U<user_id>'), which inherits
 * from group roles. So when an admin session user is known, register all group
 * roles plus that user's own 'U' row(s) only. Rules are loaded exactly as stock.
 * Permission results for the session user are identical; with no session user
 * (CLI, API, anonymous) the stock full ACL is returned.
 */
class MMD_EmailLogin_Model_Resource_Acl extends Mage_Admin_Model_Resource_Acl
{
    public function loadAcl()
    {
        $userId = 0;
        // Read the already-instantiated session only; never create one here.
        $session = Mage::registry('_singleton/admin/session');
        if ($session && $session->getUser() && $session->getUser()->getId()) {
            $userId = (int) $session->getUser()->getId();
        }
        return $userId ? $this->loadAclForUser($userId) : parent::loadAcl();
    }

    /**
     * @param  int $userId
     * @return Mage_Admin_Model_Acl
     */
    public function loadAclForUser($userId)
    {
        $acl = Mage::getModel('admin/acl');
        Mage::getSingleton('admin/config')->loadAclResources($acl);

        $adapter = $this->_getReadAdapter();

        $select = $adapter->select()
            ->from($this->getTable('admin/role'))
            ->where('role_type = ?', Mage_Admin_Model_Acl::ROLE_TYPE_GROUP)
            ->orWhere('user_id = ?', (int) $userId)
            ->order('tree_level');
        $this->loadRoles($acl, $adapter->fetchAll($select));

        $select = $adapter->select()
            ->from(['r' => $this->getTable('admin/rule')])
            ->joinLeft(
                ['a' => $this->getTable('admin/assert')],
                'a.assert_id = r.assert_id',
                ['assert_type', 'assert_data'],
            );
        $this->loadRules($acl, $adapter->fetchAll($select));

        return $acl;
    }
}
