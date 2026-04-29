<?php
class MMD_RoleManager_Helper_Data extends Mage_Core_Helper_Abstract
{
    const ROLE_LEARNER           = 'learner';
    const ROLE_TRAINER           = 'trainer';
    const ROLE_MARKETING         = 'marketing';
    const ROLE_ADMIN             = 'admin';
    const ROLE_TRAINING_PROVIDER = 'training_provider';
    const ROLE_DEVELOPER         = 'developer';

    protected $_roleLabels = array(
        'learner'           => 'Learner',
        'trainer'           => 'Trainer',
        'developer'         => 'Developer',
        'marketing'         => 'Marketing',
        'admin'             => 'Admin',
        'training_provider' => 'Super Admin',
    );

    protected $_roleIcons = array(
        'learner'           => '&#x1F4DA;',  // 📚
        'trainer'           => '&#x1F468;&#x200D;&#x1F3EB;', // 👨‍🏫
        'developer'         => '&#x1F4BB;',  // 💻
        'marketing'         => '&#x1F4E3;',  // 📣
        'admin'             => '&#x2699;&#xFE0F;',  // ⚙️
        'training_provider' => '&#x1F6E1;&#xFE0F;',  // 🛡️
    );

    protected $_roleDescriptions = array(
        'learner'           => 'Access courses and track your learning progress',
        'trainer'           => 'Manage classes and grade assessments',
        'developer'         => 'System development and technical configuration',
        'marketing'         => 'Manage campaigns, promotions, and CMS',
        'admin'             => 'Manage users, classes, and system settings',
        'training_provider' => 'Full system access and configuration',
    );

    protected $_rolePriority = array(
        'learner'           => 1,
        'trainer'           => 2,
        'developer'         => 3,
        'marketing'         => 4,
        'admin'             => 5,
        'training_provider' => 6,
    );

    // Maps a role code to the admin_role group name (role_type='G') that
    // applyRoleAcl() should point the user's parent_id at. Group rows + their
    // admin_rule grants live in install-1.0.0.php / upgrade-1.0.0-1.1.0.php /
    // migration 031-developer-acl-group.sql. Note the asymmetry:
    // training_provider is labeled "Super Admin" everywhere in the UI and
    // gets the wildcard-grant Super Admin group, not the narrower
    // "Training Provider" group seeded in upgrade-1.0.0-1.1.0.php.
    protected $_roleAclGroup = array(
        'learner'           => 'Learner',
        'trainer'           => 'Trainer',
        'developer'         => 'Developer',
        'marketing'         => 'Marketing',
        'admin'             => 'Admin',
        'training_provider' => 'Super Admin',
    );

    public function getAllRoles()
    {
        return $this->_roleLabels;
    }

    public function getRoleLabel($code)
    {
        return isset($this->_roleLabels[$code]) ? $this->_roleLabels[$code] : $code;
    }

    public function getRoleIcon($code)
    {
        return isset($this->_roleIcons[$code]) ? $this->_roleIcons[$code] : '';
    }

    public function getRoleDescription($code)
    {
        return isset($this->_roleDescriptions[$code]) ? $this->_roleDescriptions[$code] : '';
    }

    public function getActiveRoleCode()
    {
        $session = Mage::getSingleton('admin/session');
        $code = $session->getActiveRoleCode();
        return $code ? $code : self::ROLE_ADMIN;
    }

    public function getUserRoles()
    {
        $session = Mage::getSingleton('admin/session');
        $roles = $session->getUserRoles();
        return is_array($roles) ? $roles : array(self::ROLE_ADMIN);
    }

    public function getUserRolesFromDb($userId)
    {
        try {
            $model = Mage::getModel('mmd_rolemanager/role_map');
            if (!$model) {
                return array(self::ROLE_ADMIN);
            }
            $collection = $model->getCollection()
                ->addFieldToFilter('user_id', $userId);

            $roles = array();
            foreach ($collection as $item) {
                $roles[] = $item->getRoleCode();
            }

            if (empty($roles)) {
                return array(self::ROLE_ADMIN);
            }

            $priorities = $this->_rolePriority;
            usort($roles, function ($a, $b) use ($priorities) {
                $pa = isset($priorities[$a]) ? $priorities[$a] : 0;
                $pb = isset($priorities[$b]) ? $priorities[$b] : 0;
                return $pa - $pb;
            });

            return $roles;
        } catch (Exception $e) {
            return array(self::ROLE_ADMIN);
        }
    }

    public function applyRoleAcl($userId, $roleCode)
    {
        $resource  = Mage::getSingleton('core/resource');
        $write     = $resource->getConnection('core_write');
        $roleTable = $resource->getTableName('admin/role');

        // Resolve the ACL group for this role; fall back to Administrators
        // so a missing group row never locks an admin out.
        $groupName   = isset($this->_roleAclGroup[$roleCode])
            ? $this->_roleAclGroup[$roleCode]
            : 'Administrators';
        $groupRoleId = $write->fetchOne(
            "SELECT role_id FROM {$roleTable} WHERE role_name = ? AND role_type = 'G'",
            $groupName
        );

        if (!$groupRoleId && $groupName !== 'Administrators') {
            $groupRoleId = $write->fetchOne(
                "SELECT role_id FROM {$roleTable} WHERE role_name = 'Administrators' AND role_type = 'G'"
            );
        }

        if (!$groupRoleId) {
            return false;
        }

        $write->update(
            $roleTable,
            array('parent_id' => $groupRoleId),
            $write->quoteInto("user_id = ? AND role_type = 'U'", (int) $userId)
        );

        Mage::getSingleton('admin/session')->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());
        return true;
    }
}
