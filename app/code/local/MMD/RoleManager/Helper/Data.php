<?php
class MMD_RoleManager_Helper_Data extends Mage_Core_Helper_Abstract
{
    const ROLE_LEARNER           = 'learner';
    const ROLE_TRAINER           = 'trainer';
    const ROLE_MARKETING         = 'marketing';
    const ROLE_ADMIN             = 'admin';
    const ROLE_TRAINING_PROVIDER = 'training_provider';

    protected $_roleLabels = array(
        'learner'           => 'Learner',
        'trainer'           => 'Trainer',
        'marketing'         => 'Marketing',
        'admin'             => 'Admin',
        'training_provider' => 'Training Provider',
    );

    protected $_roleIcons = array(
        'learner'           => '&#x1F4DA;',  // 📚
        'trainer'           => '&#x1F468;&#x200D;&#x1F3EB;', // 👨‍🏫
        'marketing'         => '&#x1F4E3;',  // 📣
        'admin'             => '&#x2699;&#xFE0F;',  // ⚙️
        'training_provider' => '&#x1F3E2;',  // 🏢
    );

    protected $_roleDescriptions = array(
        'learner'           => 'Access courses and track your learning progress',
        'trainer'           => 'Manage classes and grade assessments',
        'marketing'         => 'Manage campaigns, promotions, and CMS',
        'admin'             => 'Manage users, classes, and system settings',
        'training_provider' => 'Manage organization and course catalog',
    );

    protected $_rolePriority = array(
        'learner'           => 1,
        'trainer'           => 2,
        'marketing'         => 3,
        'admin'             => 4,
        'training_provider' => 5,
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

        // Temporarily assign all roles to Administrators (full access)
        // TODO: restore per-role ACL once role permissions are configured
        $groupRoleId = $write->fetchOne(
            "SELECT role_id FROM {$roleTable} WHERE role_name = 'Administrators' AND role_type = 'G'"
        );

        if (!$groupRoleId) {
            return false;
        }

        $write->update(
            $roleTable,
            array('parent_id' => $groupRoleId),
            "user_id = {$userId} AND role_type = 'U'"
        );

        Mage::getSingleton('admin/session')->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());
        return true;
    }
}
