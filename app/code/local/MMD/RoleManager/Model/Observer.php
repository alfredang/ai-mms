<?php
class MMD_RoleManager_Model_Observer
{
    /**
     * On admin login, load user roles into session and set active role
     */
    public function onAdminLogin(Varien_Event_Observer $observer)
    {
        try {
            $user    = $observer->getEvent()->getUser();
            $helper  = Mage::helper('mmd_rolemanager');
            $session = Mage::getSingleton('admin/session');

            // Load all roles for this user
            $roles = $helper->getUserRolesFromDb($user->getId());

            // Store roles in session
            $session->setUserRoles($roles);

            // Find primary role
            $primaryRole = null;
            try {
                $collection = Mage::getModel('mmd_rolemanager/role_map')->getCollection()
                    ->addFieldToFilter('user_id', $user->getId())
                    ->addFieldToFilter('is_primary', 1);
                if ($collection->getSize()) {
                    $primaryRole = $collection->getFirstItem()->getRoleCode();
                }
            } catch (Exception $e) {
                // Table may not exist yet
            }
            if (!$primaryRole) {
                $primaryRole = $roles[0];
            }

            // Set active role and update ACL
            $session->setActiveRoleCode($primaryRole);
            $helper->applyRoleAcl($user->getId(), $primaryRole);
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }
}
