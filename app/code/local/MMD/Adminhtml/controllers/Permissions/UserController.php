<?php
/**
 * Override Mage_Adminhtml_Permissions_UserController to drop the
 * "Current Admin Password" anti-hijack challenge.
 *
 * MMD_Adminhtml_Block_Permissions_User_Edit_Tab_Main strips the
 * `current_password` input from BOTH new-user AND edit-user forms (see
 * the Block override — its docblock literally says "Remove current admin
 * password requirement"). But the parent saveAction still calls
 * _validateCurrentPassword(null) and errors out with "Current password
 * field cannot be empty", which then wipes the password fields on the
 * redirect — making it look like the passwords reset themselves.
 *
 * Since the field is permanently gone from the form, the validation can
 * never succeed and any attempt to save a user (new or edit) is blocked.
 * Skip the check entirely so the form actually works. The admin's session
 * is already proof of authorization for both flows.
 *
 * Loaded via the existing
 *   <adminhtml><args><modules>
 *     <MMD_Adminhtml before="Mage_Adminhtml">MMD_Adminhtml</MMD_Adminhtml>
 *   ...
 * routing arg in MMD_Adminhtml/etc/config.xml.
 */
require_once Mage::getModuleDir('controllers', 'Mage_Adminhtml')
    . DS . 'Permissions' . DS . 'UserController.php';

class MMD_Adminhtml_Permissions_UserController extends Mage_Adminhtml_Permissions_UserController
{
    /**
     * @param string|null $password
     * @return mixed true | array of errors
     */
    protected function _validateCurrentPassword($password)
    {
        return true;
    }
}
