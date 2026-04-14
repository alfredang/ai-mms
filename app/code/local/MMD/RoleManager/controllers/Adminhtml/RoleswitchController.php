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
