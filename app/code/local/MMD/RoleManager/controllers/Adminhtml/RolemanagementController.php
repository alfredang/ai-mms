<?php
class MMD_RoleManager_Adminhtml_RolemanagementController extends Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('system');
        $this->_title('Role Management');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/management.phtml');
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    /**
     * AJAX: Save user roles and status
     */
    public function saveAction()
    {
        $result = array('success' => false);
        if (!$this->getRequest()->isPost()) {
            return $this->_sendJson($result);
        }

        $userId   = (int) $this->getRequest()->getParam('user_id');
        $roles    = $this->getRequest()->getParam('roles', array());
        $isActive = (int) $this->getRequest()->getParam('is_active', 1);
        $firstname = $this->getRequest()->getParam('firstname', '');
        $lastname  = $this->getRequest()->getParam('lastname', '');
        $password  = (string) $this->getRequest()->getParam('password', '');

        if (!$userId) {
            $result['message'] = 'Invalid user';
            return $this->_sendJson($result);
        }

        try {
            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $userTable = $resource->getTableName('admin/user');
            $roleTable = $resource->getTableName('mmd_user_role_map');

            // Update user status, name, and (optionally) password
            $updateData = array('is_active' => $isActive);
            if ($firstname) $updateData['firstname'] = $firstname;
            if ($lastname)  $updateData['lastname'] = $lastname;
            if ($password !== '') {
                if (strlen($password) < 7) {
                    $result['message'] = 'Password must be at least 7 characters';
                    return $this->_sendJson($result);
                }
                $updateData['password'] = Mage::helper('core')->getHash($password, 2);
            }
            $write->update($userTable, $updateData, 'user_id = ' . $userId);

            // Replace roles
            $write->delete($roleTable, 'user_id = ' . $userId);
            if (is_array($roles)) {
                foreach ($roles as $i => $roleCode) {
                    $write->insert($roleTable, array(
                        'user_id'    => $userId,
                        'role_code'  => $roleCode,
                        'is_primary' => ($i === 0) ? 1 : 0,
                        'created_at' => now(),
                    ));
                }
            }

            // Mirror the primary role into Magento's standard admin_role
            // table so hasAssigned2Role() at login succeeds. applyRoleAcl()
            // upserts the 'U' row pointing at the matching G group; without
            // this, the user has roles in our custom map but no admin_role
            // membership and gets "Access denied" on login.
            if (is_array($roles) && count($roles) > 0) {
                Mage::helper('mmd_rolemanager')->applyRoleAcl($userId, $roles[0]);
            }

            $result['success'] = true;
            $result['message'] = 'User updated successfully';
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
            Mage::logException($e);
        }

        $this->_sendJson($result);
    }

    /**
     * AJAX: Toggle user active/disabled
     */
    public function toggleAction()
    {
        $result = array('success' => false);
        $userId = (int) $this->getRequest()->getParam('user_id');
        $currentUserId = Mage::getSingleton('admin/session')->getUser()->getId();

        if (!$userId || $userId == $currentUserId) {
            $result['message'] = 'Cannot modify your own account';
            return $this->_sendJson($result);
        }

        try {
            $user = Mage::getModel('admin/user')->load($userId);
            $newStatus = $user->getIsActive() ? 0 : 1;
            $resource = Mage::getSingleton('core/resource');
            $resource->getConnection('core_write')->update(
                $resource->getTableName('admin/user'),
                array('is_active' => $newStatus),
                'user_id = ' . $userId
            );
            $result['success'] = true;
            $result['is_active'] = $newStatus;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }

        $this->_sendJson($result);
    }

    /**
     * AJAX: Delete user
     */
    public function deleteAction()
    {
        $result = array('success' => false);
        $userId = (int) $this->getRequest()->getParam('user_id');
        $currentUserId = Mage::getSingleton('admin/session')->getUser()->getId();

        if (!$userId || $userId == $currentUserId) {
            $result['message'] = 'Cannot delete your own account';
            return $this->_sendJson($result);
        }

        try {
            $resource = Mage::getSingleton('core/resource');
            $write = $resource->getConnection('core_write');
            $write->delete($resource->getTableName('mmd_user_role_map'), 'user_id = ' . $userId);
            Mage::getModel('admin/user')->load($userId)->delete();
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }

        $this->_sendJson($result);
    }

    protected function _sendJson($data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json')
            ->setBody(Mage::helper('core')->jsonEncode($data));
    }

    protected function _isAllowed()
    {
        // Role assignment + user enable/disable + delete — only roles
        // that are themselves administrative. A learner / trainer /
        // marketing user URL-typing here would otherwise be able to grant
        // themselves Super Admin.
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array(
            'training_provider', 'admin',
        ));
    }
}
