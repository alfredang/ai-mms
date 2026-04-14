<?php
class MMD_RoleManager_Block_Page_Header_RoleSwitcher extends Mage_Adminhtml_Block_Template
{
    /**
     * Get all roles for current user
     */
    public function getUserRoles()
    {
        return Mage::helper('mmd_rolemanager')->getUserRoles();
    }

    /**
     * Get active role code
     */
    public function getActiveRoleCode()
    {
        return Mage::helper('mmd_rolemanager')->getActiveRoleCode();
    }

    /**
     * Get role label
     */
    public function getRoleLabel($code)
    {
        return Mage::helper('mmd_rolemanager')->getRoleLabel($code);
    }

    /**
     * Get role icon
     */
    public function getRoleIcon($code)
    {
        return Mage::helper('mmd_rolemanager')->getRoleIcon($code);
    }

    /**
     * Get the AJAX switch URL
     */
    public function getSwitchUrl()
    {
        return $this->getUrl('adminhtml/roleswitch/switch');
    }

    /**
     * Should show switcher (only if user has multiple roles)
     */
    public function shouldShow()
    {
        return count($this->getUserRoles()) > 1;
    }
}
