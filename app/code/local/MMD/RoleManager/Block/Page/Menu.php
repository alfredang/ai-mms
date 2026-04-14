<?php
/**
 * Rewrite of Mage_Adminhtml_Block_Page_Menu
 * Adds active role code to cache key so each role gets its own cached menu
 */
class MMD_RoleManager_Block_Page_Menu extends Mage_Adminhtml_Block_Page_Menu
{
    public function getCacheKeyInfo()
    {
        $info = parent::getCacheKeyInfo();
        $info[] = 'role_' . Mage::helper('mmd_rolemanager')->getActiveRoleCode();
        return $info;
    }
}
