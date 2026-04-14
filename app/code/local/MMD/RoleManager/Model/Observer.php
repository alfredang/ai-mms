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

            // Check if the user has an explicit mapping in mmd_user_role_map
            $hasMapping = false;
            $primaryRole = null;
            try {
                $collection = Mage::getModel('mmd_rolemanager/role_map')->getCollection()
                    ->addFieldToFilter('user_id', $user->getId());
                if ($collection->getSize()) {
                    $hasMapping = true;
                    foreach ($collection as $item) {
                        if ($item->getIsPrimary()) {
                            $primaryRole = $item->getRoleCode();
                            break;
                        }
                    }
                    if (!$primaryRole) {
                        $primaryRole = $collection->getFirstItem()->getRoleCode();
                    }
                }
            } catch (Exception $e) {
                // Table may not exist yet — treat as unmapped
            }

            if ($hasMapping && $primaryRole) {
                // Store roles from DB mapping only
                $roles = $helper->getUserRolesFromDb($user->getId());
                $session->setUserRoles($roles);
                $session->setActiveRoleCode($primaryRole);
                $helper->applyRoleAcl($user->getId(), $primaryRole);
            } else {
                // No explicit mapping — leave the user's existing admin_role
                // assignment untouched. Still expose a role code in session so
                // the dashboard/UI can render something sensible.
                $session->setUserRoles(array($helper::ROLE_SUPER_ADMIN));
                $session->setActiveRoleCode($helper::ROLE_SUPER_ADMIN);
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }
}
