<?php
/**
 * Rewrite of Mage_Adminhtml_Block_Page_Menu
 * - Adds active role code to cache key so each role gets its own cached menu
 * - Renames and filters menu items for the LMS/TMS portal
 */
class MMD_RoleManager_Block_Page_Menu extends Mage_Adminhtml_Block_Page_Menu
{
    /**
     * Menu label renames for the LMS portal
     */
    protected $_menuRenames = array(
        'sales'     => 'Course Registration',
        'catalog'   => 'Course Management',
        'customer'  => 'View Learners',
        'system'    => 'Company Setting',
        'marketing' => 'Marketing Management',
    );

    /**
     * Menu items to remove entirely
     */
    protected $_menuRemove = array('report', 'newsletter');

    public function getCacheKeyInfo()
    {
        $info = parent::getCacheKeyInfo();
        $info[] = 'role_' . Mage::helper('mmd_rolemanager')->getActiveRoleCode();
        return $info;
    }

    public function getMenuArray()
    {
        $menu = parent::getMenuArray();

        // Remove unwanted items
        foreach ($this->_menuRemove as $key) {
            unset($menu[$key]);
        }

        // Rename items
        foreach ($this->_menuRenames as $key => $newLabel) {
            if (isset($menu[$key])) {
                $menu[$key]['label'] = $newLabel;
            }
        }

        // Rename sales sub-items: Orders → Registrations
        if (isset($menu['sales']['children'])) {
            $salesRenames = array(
                'order' => 'Registrations',
            );
            foreach ($salesRenames as $childKey => $childLabel) {
                if (isset($menu['sales']['children'][$childKey])) {
                    $menu['sales']['children'][$childKey]['label'] = $childLabel;
                }
            }
        }

        // Rename customer sub-items: Customer → Learner
        if (isset($menu['customer']['children'])) {
            $childRenames = array(
                'manage' => 'Manage Learners',
                'group'  => 'Learner Groups',
                'online' => 'Online Learners',
            );
            foreach ($childRenames as $childKey => $childLabel) {
                if (isset($menu['customer']['children'][$childKey])) {
                    $menu['customer']['children'][$childKey]['label'] = $childLabel;
                }
            }
        }

        // Add Role Management as a top-level menu item for Super Admin
        $roleCode = Mage::helper('mmd_rolemanager')->getActiveRoleCode();
        if ($roleCode === 'training_provider') {
            $roleMgmtUrl = Mage::helper('adminhtml')->getUrl('adminhtml/rolemanagement/index');
            $menu['role_management'] = array(
                'label'      => 'Role Management',
                'url'        => $roleMgmtUrl,
                'active'     => false,
                'level'      => 0,
                'sort_order' => 85,
                'children'   => array(),
                'last'       => false,
            );
        }

        // Move Promotions under Marketing Management as a child
        if (isset($menu['promo']) && isset($menu['marketing'])) {
            if (!isset($menu['marketing']['children'])) {
                $menu['marketing']['children'] = array();
            }
            $menu['marketing']['children']['promo'] = $menu['promo'];
            $menu['marketing']['children']['promo']['label'] = 'Promotions';
            unset($menu['promo']);
        }

        return $menu;
    }
}
