<?php
class MMD_RoleManager_Helper_Data extends Mage_Core_Helper_Abstract
{
    const ROLE_LEARNER     = 'learner';
    const ROLE_TRAINER     = 'trainer';
    const ROLE_ADMIN       = 'admin';
    const ROLE_SUPER_ADMIN = 'super_admin';

    protected $_roleLabels = array(
        'learner'     => 'Learner',
        'trainer'     => 'Trainer',
        'admin'       => 'Admin',
        'super_admin' => 'Super Admin',
    );

    protected $_roleIcons = array(
        'learner'     => '&#x1F393;',  // 🎓
        'trainer'     => '&#x1F3EB;',  // 🏫
        'admin'       => '&#x1F6E0;',  // 🛠️
        'super_admin' => '&#x1F451;',  // 👑
    );

    protected $_rolePriority = array(
        'learner'     => 1,
        'trainer'     => 2,
        'admin'       => 3,
        'super_admin' => 4,
    );

    /**
     * Get all role codes/labels
     */
    public function getAllRoles()
    {
        return $this->_roleLabels;
    }

    /**
     * Get role label
     */
    public function getRoleLabel($code)
    {
        return isset($this->_roleLabels[$code]) ? $this->_roleLabels[$code] : $code;
    }

    /**
     * Get role icon HTML entity
     */
    public function getRoleIcon($code)
    {
        return isset($this->_roleIcons[$code]) ? $this->_roleIcons[$code] : '';
    }

    /**
     * Get active role code from session
     */
    public function getActiveRoleCode()
    {
        $session = Mage::getSingleton('admin/session');
        $code = $session->getActiveRoleCode();
        return $code ? $code : self::ROLE_SUPER_ADMIN;
    }

    /**
     * Get all roles assigned to current user from session
     */
    public function getUserRoles()
    {
        $session = Mage::getSingleton('admin/session');
        $roles = $session->getUserRoles();
        return is_array($roles) ? $roles : array(self::ROLE_SUPER_ADMIN);
    }

    /**
     * Get user roles from database
     */
    public function getUserRolesFromDb($userId)
    {
        $collection = Mage::getModel('mmd_rolemanager/role_map')->getCollection()
            ->addFieldToFilter('user_id', $userId);

        $roles = array();
        foreach ($collection as $item) {
            $roles[] = $item->getRoleCode();
        }

        // Sort by priority (highest first)
        usort($roles, function ($a, $b) {
            $pa = isset($this->_rolePriority[$a]) ? $this->_rolePriority[$a] : 0;
            $pb = isset($this->_rolePriority[$b]) ? $this->_rolePriority[$b] : 0;
            return $pb - $pa;
        });

        return $roles;
    }

    /**
     * Apply ACL group role to a user by updating admin_role parent_id
     */
    public function applyRoleAcl($userId, $roleCode)
    {
        $roleLabel = $this->getRoleLabel($roleCode);
        $resource  = Mage::getSingleton('core/resource');
        $write     = $resource->getConnection('core_write');
        $roleTable = $resource->getTableName('admin/role');

        // Find the group role_id for this role label
        $groupRoleId = $write->fetchOne(
            "SELECT role_id FROM {$roleTable} WHERE role_name = ? AND role_type = 'G'",
            array($roleLabel)
        );

        if (!$groupRoleId) {
            return false;
        }

        // Update the user's role row to point at this group
        $write->update(
            $roleTable,
            array('parent_id' => $groupRoleId),
            "user_id = {$userId} AND role_type = 'U'"
        );

        // Reload ACL in session
        Mage::getSingleton('admin/session')->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());

        return true;
    }
}
