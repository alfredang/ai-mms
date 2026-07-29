<?php
class MMD_RoleManager_Adminhtml_RolemanagementController extends Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('system');
        $role = (string) $this->getRequest()->getParam('role');
        $titles = array('admin' => 'Admin Users', 'learner' => 'Manage Learners', 'trainer' => 'Manage Trainers');
        $this->_title(isset($titles[$role]) ? $titles[$role] : 'Users');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/management.phtml');
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    /**
     * AJAX: Save (create or update) user with roles and status.
     * - If user_id is 0/empty, creates a new admin user (requires username,
     *   email, firstname, lastname, password).
     * - If user_id is set, updates the existing user (email is now editable).
     */
    public function saveAction()
    {
        $result = array('success' => false);
        if (!$this->getRequest()->isPost()) {
            return $this->_sendJson($result);
        }

        $userId          = (int) $this->getRequest()->getParam('user_id');
        $roles           = $this->getRequest()->getParam('roles', array());
        $isActive        = (int) $this->getRequest()->getParam('is_active', 1);
        $firstname       = trim((string) $this->getRequest()->getParam('firstname', ''));
        $lastname        = trim((string) $this->getRequest()->getParam('lastname', ''));
        $email           = trim((string) $this->getRequest()->getParam('email', ''));
        $password        = (string) $this->getRequest()->getParam('password', '');

        // Authorization is the admin session itself, consistent with the stock
        // Permissions/User flow which also dropped the current-password challenge
        // (see MMD_Adminhtml_Permissions_UserController). The password re-entry
        // check was unreliable and blocked legitimate admins: those who sign in
        // via OTP / Google, or whose admin password was set by account-sync or the
        // trainer import (a random or customer-synced hash they never typed),
        // can never satisfy it.
        $currentAdmin = Mage::getSingleton('admin/session')->getUser();
        if (!$currentAdmin || !$currentAdmin->getId()) {
            $result['message'] = 'Your admin session has expired - please log in again.';
            return $this->_sendJson($result);
        }
        // Login is email-based (see MMD_EmailLogin). The admin_user.username
        // column is still NOT NULL in the schema, so mirror email into it.
        $username  = $email;

        try {
            $resource  = Mage::getSingleton('core/resource');
            $write     = $resource->getConnection('core_write');
            $read      = $resource->getConnection('core_read');
            $userTable = $resource->getTableName('admin/user');
            $roleTable = $resource->getTableName('mmd_user_role_map');

            // === Create new admin user ===
            if (!$userId) {
                if (!$email || !$firstname || !$lastname || !$password) {
                    $result['message'] = 'Email, name and password are required';
                    return $this->_sendJson($result);
                }
                if (strlen($password) < 7) {
                    $result['message'] = 'Password must be at least 7 characters';
                    return $this->_sendJson($result);
                }
                if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                    $result['message'] = 'Invalid email address';
                    return $this->_sendJson($result);
                }
                $dup = $read->fetchOne(
                    "SELECT user_id FROM {$userTable} WHERE email = ? LIMIT 1",
                    array($email)
                );
                if ($dup) {
                    $result['message'] = 'A user with that email already exists';
                    return $this->_sendJson($result);
                }
                $newUser = Mage::getModel('admin/user')->setData(array(
                    'username'  => $username,
                    'firstname' => $firstname,
                    'lastname'  => $lastname,
                    'email'     => $email,
                    'password'  => $password,
                    'is_active' => $isActive,
                ))->save();
                $userId = (int) $newUser->getId();
            } else {
                // === Update existing user ===
                $updateData = array('is_active' => $isActive);
                if ($firstname) $updateData['firstname'] = $firstname;
                if ($lastname)  $updateData['lastname']  = $lastname;
                if ($email) {
                    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                        $result['message'] = 'Invalid email address';
                        return $this->_sendJson($result);
                    }
                    $dup = $read->fetchOne(
                        "SELECT user_id FROM {$userTable} WHERE email = ? AND user_id <> ? LIMIT 1",
                        array($email, $userId)
                    );
                    if ($dup) {
                        $result['message'] = 'Another user already uses that email';
                        return $this->_sendJson($result);
                    }
                    $updateData['email'] = $email;
                }
                if ($password !== '') {
                    if (strlen($password) < 7) {
                        $result['message'] = 'Password must be at least 7 characters';
                        return $this->_sendJson($result);
                    }
                    $updateData['password'] = Mage::helper('core')->getHash($password, 2);
                }
                $write->update($userTable, $updateData, 'user_id = ' . $userId);
            }

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

    /**
     * AJAX (Manage Learners): submit the selected learners' emails to the
     * MailerLite subscriber group for their country. A learner routes by
     * their home store (latest order's store, falling back to the
     * customer's own store_id): SG / MY / GH each have their own group.
     *
     * Opt-out guard: POST /subscribers is an upsert that would resurrect
     * an unsubscribed address, so emails MailerLite already knows as
     * unsubscribed / bounced / junk are skipped, never re-added (same
     * rule as MMD_Marketing_Helper_Mailerlite::subscribeLead).
     *
     * Successful submissions are recorded in mmd_learner_mailerlite,
     * which drives the read-only "submitted" checkbox in the grid.
     */
    public function mailerliteAction()
    {
        $result = array('success' => false, 'added' => 0, 'skipped' => 0, 'failed' => 0);
        if (!$this->getRequest()->isPost()) {
            return $this->_sendJson($result);
        }
        $ids = $this->getRequest()->getParam('customer_ids');
        if (!is_array($ids) || empty($ids)) {
            $result['message'] = 'Select at least one learner.';
            return $this->_sendJson($result);
        }
        if (count($ids) > 100) {
            $result['message'] = 'Select at most 100 learners per submit.';
            return $this->_sendJson($result);
        }
        $mailerlite = Mage::helper('mmd_marketing/mailerlite');
        if (!$mailerlite->isConfigured()) {
            $result['message'] = 'MailerLite API key is not configured (Dashboard → Company Setting → Integrations → MailerLite).';
            return $this->_sendJson($result);
        }

        // One MailerLite subscriber group per country store.
        $groupMap = array(
            'SG' => '97171109342873057',
            'MY' => '97171116217337309',
            'GH' => '194137224356300145',
        );

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $logTable = $resource->getTableName('mmd_learner_mailerlite');

        // store_id → country code. Store codes vary per install ('default',
        // 'sg', 'singapore', 'my', 'malaysia', …) so normalise both the
        // 2-letter and full-name forms; 'default'/'admin' = SG (the HQ store).
        $codeMap = array(
            'DEFAULT' => 'SG', 'ADMIN' => 'SG',
            'SG' => 'SG', 'SINGAPORE' => 'SG',
            'MY' => 'MY', 'MALAYSIA'  => 'MY',
            'GH' => 'GH', 'GHANA'     => 'GH',
        );
        $storeIdToCode = array();
        foreach ($read->fetchAll("SELECT store_id, code FROM " . $resource->getTableName('core/store')) as $sr) {
            $c = strtoupper((string) $sr['code']);
            $storeIdToCode[(int) $sr['store_id']] = isset($codeMap[$c]) ? $codeMap[$c] : $c;
        }

        $ids = array_map('intval', $ids);
        // Home store = store of the most recent order, per the grid's logic.
        $orderStores = $read->fetchPairs("
            SELECT customer_id,
                   SUBSTRING_INDEX(GROUP_CONCAT(store_id ORDER BY created_at DESC), ',', 1) AS last_store_id
              FROM " . $resource->getTableName('sales_flat_order') . "
             WHERE customer_id IN (" . implode(',', $ids) . ")
             GROUP BY customer_id
        ");

        // Every terminal outcome is recorded so the grid can show WHY an
        // email isn't in the group (excluded / unsubscribed / blocked).
        // Transient API failures are NOT recorded — the row stays selectable
        // for a retry.
        $recordOutcome = function ($email, $status, $code, $groupId) use ($write, $logTable) {
            $write->insertOnDuplicate($logTable, array(
                'email'        => $email,
                'group_id'     => (string) $groupId,
                'store_code'   => (string) $code,
                'status'       => $status,
                'submitted_at' => now(),
            ), array('group_id', 'store_code', 'status', 'submitted_at'));
        };

        $details = array();
        foreach ($ids as $id) {
            $customer = Mage::getModel('customer/customer')->load($id);
            $email = strtolower(trim((string) $customer->getEmail()));
            if (!$customer->getId() || $email === '') {
                $result['failed']++;
                continue;
            }
            $storeId = isset($orderStores[$id]) ? (int) $orderStores[$id] : (int) $customer->getStoreId();
            $code = isset($storeIdToCode[$storeId]) ? $storeIdToCode[$storeId] : '';
            if (!isset($groupMap[$code])) {
                $recordOutcome($email, 'excluded', $code, '');
                $result['skipped']++;
                $details[] = $email . ': excluded — no MailerLite group for store ' . ($code !== '' ? $code : '#' . $storeId);
                continue;
            }
            try {
                $existing = $mailerlite->findSubscriber($email);
                $status = is_array($existing) && isset($existing['status']) ? $existing['status'] : '';
                if ($status === 'unsubscribed') {
                    $recordOutcome($email, 'unsubscribed', $code, $groupMap[$code]);
                    $result['skipped']++;
                    $details[] = $email . ': unsubscribed — not re-added';
                    continue;
                }
                if (in_array($status, array('bounced', 'junk'), true)) {
                    $recordOutcome($email, 'blocked', $code, $groupMap[$code]);
                    $result['skipped']++;
                    $details[] = $email . ': ' . $status . ' — blocked, not re-added';
                    continue;
                }
                $mailerlite->addSubscriber($email, $groupMap[$code], array('name' => trim((string) $customer->getName())));
                $recordOutcome($email, 'submitted', $code, $groupMap[$code]);
                $result['added']++;
            } catch (Exception $e) {
                Mage::logException($e);
                $result['failed']++;
                $details[] = $email . ': ' . $e->getMessage();
            }
            // Stay under MailerLite's 120 req/min (2 API calls per learner).
            usleep(250000);
        }

        $result['success'] = true;
        $result['details'] = array_slice($details, 0, 10);
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
