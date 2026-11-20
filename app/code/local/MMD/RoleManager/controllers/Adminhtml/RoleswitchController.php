<?php
class MMD_RoleManager_Adminhtml_RoleswitchController extends Mage_Adminhtml_Controller_Action
{
    /**
     * AJAX action to switch role
     */
    public function switchAction()
    {
        $result = array('success' => false);

        try {
            $roleCode = $this->getRequest()->getParam('role_code');
            $helper   = Mage::helper('mmd_rolemanager');
            $session  = Mage::getSingleton('admin/session');
            $user     = $session->getUser();

            if (!$user) {
                $result['message'] = 'Not logged in';
                $this->_sendJson($result);
                return;
            }

            // Validate user has this role
            $userRoles = $helper->getUserRolesFromDb($user->getId());
            if (!in_array($roleCode, $userRoles)) {
                $result['message'] = 'You do not have this role';
                $this->_sendJson($result);
                return;
            }

            // Set active role in session
            $session->setActiveRoleCode($roleCode);
            $session->setUserRoles($userRoles);

            // Update ACL group assignment
            $helper->applyRoleAcl($user->getId(), $roleCode);

            // Clear menu cache
            Mage::app()->cleanCache(array('BACKEND_MAINMENU'));

            $result['success']  = true;
            $result['role']     = $roleCode;
            $result['redirect'] = $this->getUrl('adminhtml/dashboard');

        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
            Mage::logException($e);
        }

        $this->_sendJson($result);
    }

    /**
     * AJAX: save the theme choice (system / light / dark) on the account.
     */
    public function themeAction()
    {
        $result = array('success' => false);
        $user   = Mage::getSingleton('admin/session')->getUser();
        $pref   = (string) $this->getRequest()->getPost('theme');
        if ($user && $this->_validateFormKey()
            && Mage::helper('mmd_rolemanager')->saveUserThemePref($user->getId(), $pref)) {
            /* Keep the session copy current so a later core saveExtra()
               (System Config fieldset state) does not drop the key. */
            $extra = $user->getExtra();
            $extra = is_array($extra) ? $extra : array();
            $extra['admin_theme'] = $pref;
            $user->setExtra($extra);
            $result['success'] = true;
        }
        $this->_sendJson($result);
    }

    /**
     * Send JSON response
     */
    protected function _sendJson($data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json')
            ->setBody(Mage::helper('core')->jsonEncode($data));
    }

    /**
     * ACL check — all logged-in admins can switch their own role
     */
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isLoggedIn();
    }
}
