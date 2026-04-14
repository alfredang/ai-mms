<?php
class MMD_Adminhtml_Block_System_Account_Edit extends Mage_Adminhtml_Block_System_Account_Edit
{
    public function __construct()
    {
        parent::__construct();
        $this->setTemplate('system/account/profile.phtml');
    }

    public function getUser()
    {
        $userId = Mage::getSingleton('admin/session')->getUser()->getId();
        return Mage::getModel('admin/user')->load($userId);
    }

    public function getUserRoles()
    {
        $helper = Mage::helper('mmd_rolemanager');
        $userId = Mage::getSingleton('admin/session')->getUser()->getId();
        return $helper->getUserRolesFromDb($userId);
    }

    public function getRoleLabel($code)
    {
        return Mage::helper('mmd_rolemanager')->getRoleLabel($code);
    }

    public function getSaveUrl()
    {
        return $this->getUrl('*/system_account/save');
    }

    public function getMinPasswordLength()
    {
        return Mage::getModel('admin/user')->getMinAdminPasswordLength();
    }
}
