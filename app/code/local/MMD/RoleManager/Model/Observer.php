<?php
class MMD_RoleManager_Model_Observer
{
    /**
     * On admin login, load user roles into session and set active role
     */
    public function onAdminLogin(Varien_Event_Observer $observer)
    {
        $user    = $observer->getEvent()->getUser();
        $helper  = Mage::helper('mmd_rolemanager');
        $session = Mage::getSingleton('admin/session');

        // Load all roles for this user
        $roles = $helper->getUserRolesFromDb($user->getId());

        if (empty($roles)) {
            // Fallback: assign super_admin if user has no roles yet (backwards compat)
            $roles = array('super_admin');
        }

        // Store roles in session
        $session->setUserRoles($roles);

        // Find primary role
        $primaryRole = null;
        $collection = Mage::getModel('mmd_rolemanager/role_map')->getCollection()
            ->addFieldToFilter('user_id', $user->getId())
            ->addFieldToFilter('is_primary', 1);
        if ($collection->getSize()) {
            $primaryRole = $collection->getFirstItem()->getRoleCode();
        }
        if (!$primaryRole) {
            $primaryRole = $roles[0];
        }

        // Set active role and update ACL
        $session->setActiveRoleCode($primaryRole);
        $helper->applyRoleAcl($user->getId(), $primaryRole);
    }
}
