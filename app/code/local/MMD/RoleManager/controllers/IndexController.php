<?php
/**
 * Learner login — /learnerlogin (every site: SG, MY, GH run the same code).
 *
 * Storefront learners sign in here with their CUSTOMER email + password and
 * land straight on the learner dashboard — no role-selection screen, ever
 * (staff keep using /tigerdragon unchanged). Works because MMD_AccountSync
 * keeps a shadow admin_user for every customer with an IDENTICAL password
 * hash and the 'learner' role, and the RoleManager predispatch lockdown
 * confines an active learner role to the learner allowlist.
 *
 * Registered under the 'learnerlogin' ADMIN router (config.xml) so the login
 * lands in the same adminhtml session the dashboard uses. Public access for
 * the two actions is granted by Observer::allowLearnerloginAction — the same
 * mechanism the OTP login uses.
 */
class MMD_RoleManager_IndexController extends Mage_Adminhtml_Controller_Action
{
    protected $_publicActions = array('index', 'login', 'send', 'verify', 'register', 'class');

    const MAX_ATTEMPTS = 5;      // per session
    const ATTEMPT_WINDOW = 600;  // seconds

    /**
     * Roles that may sign in at /lmslogin. Admin + Super Admin
     * (training_provider) use /adminlogin, which accepts every role.
     */
    protected $_lmsRoles = array('learner', 'trainer', 'developer', 'marketing');

    /**
     * Skip admin auth for the public actions (same recipe as
     * MMD_OtpLogin_Adminhtml_OtpController::preDispatch).
     */
    public function preDispatch()
    {
        $action = strtolower($this->getRequest()->getActionName());
        if (in_array($action, $this->_publicActions, true)) {
            $this->getRequest()->setInternallyForwarded(true);
        }
        parent::preDispatch();
        return $this;
    }

    /** Show the learner login form (or bounce a logged-in learner onward). */
    public function indexAction()
    {
        $adminSession = Mage::getSingleton('admin/session');
        if ($adminSession->isLoggedIn()) {
            $this->getResponse()->setRedirect(Mage::helper('mmd_rolemanager/classAccess')->destination($adminSession->getNeedsRoleSelect()));
            return;
        }
        $this->getResponse()->setBody($this->_renderPage());
    }

    /** Stable participant entry; authentication and exact membership are checked on every visit. */
    public function classAction()
    {
        $helper = Mage::helper('mmd_rolemanager/classAccess');
        $session = Mage::getSingleton('admin/session');
        try {
            $runId = $this->getRequest()->getParam('run_id');
            $helper->remember($runId);
            if (!$session->isLoggedIn()) {
                return $this->getResponse()->setRedirect($helper->urls($runId)['participant_login_url']);
            }
            if ($session->getNeedsRoleSelect()) return $this->getResponse()->setRedirect($helper->destination(true));
            if ($session->getMmdForcePasswordChange()) return $this->_redirect('adminhtml/system_account/index');
            $target = $helper->enter((int) $runId);
            Mage::getSingleton('core/session')->unsMmsClassRunId();
            if (!$target) throw new InvalidArgumentException('Class access is unavailable. Please contact training support using the email registered for your class.');
            return $this->getResponse()->setRedirect($target);
        } catch (InvalidArgumentException $e) {
            Mage::getSingleton('core/session')->unsMmsClassRunId();
            $this->getResponse()->setHttpResponseCode(403)->setBody(Mage::helper('core')->escapeHtml($e->getMessage()));
        }
    }

    /** Handle the login POST. */
    public function loginAction()
    {
        if (!$this->getRequest()->isPost()) {
            $this->_redirect('*/*/index');
            return;
        }

        $session = Mage::getSingleton('core/session');
        $email    = strtolower(trim((string) $this->getRequest()->getParam('email')));
        $password = (string) $this->getRequest()->getParam('password');

        try {
            // Simple per-session rate limit (same shape as the OTP limiter).
            $now = time();
            $attempts = array_filter((array) $session->getLearnerLoginAttempts(), function ($t) use ($now) {
                return ($now - $t) < self::ATTEMPT_WINDOW;
            });
            if (count($attempts) >= self::MAX_ATTEMPTS) {
                throw new Exception('Too many attempts. Please try again in a few minutes.');
            }
            $attempts[] = $now;
            $session->setLearnerLoginAttempts($attempts);

            if ($email === '' || strpos($email, '@') === false || $password === '') {
                throw new Exception('Please enter your email and password.');
            }

            // Authenticate against the dashboard account (password hash is
            // kept identical to the storefront account by MMD_AccountSync).
            /** @var Mage_Admin_Model_User $user */
            $user = Mage::getModel('admin/user');
            $ok = false;
            try {
                $ok = $user->authenticate($email, $password);
            } catch (Mage_Core_Exception $e) {
                // inactive / no role — treated the same as a bad password
                // below, but see the shadow-account fallback first.
                $ok = false;
            }

            if (!$ok) {
                // A lockout must not be bypassed through the storefront check.
                if (MMD_EmailLogin_Model_User::isLoginLocked($email)) {
                    throw new Exception(MMD_EmailLogin_Model_User::LOCK_MESSAGE);
                }
                // Legacy learner whose shadow account predates AccountSync (or
                // was never backfilled): validate the STOREFRONT account and
                // create/sync the shadow on the fly, then retry once.
                $ok = $this->_tryCustomerFallback($email, $password, $user);
                if ($ok) {
                    MMD_EmailLogin_Model_User::clearLoginFailures($email);
                }
            }
            if (!$ok || !$user->getId()) {
                throw new Exception('Your email or password is incorrect.');
            }

            // Must hold at least one LMS role (learner / trainer / developer /
            // marketing). Admin + Super Admin accounts use /adminlogin.
            $helper   = Mage::helper('mmd_rolemanager');
            $roles    = $helper->getUserRolesFromDb($user->getId());
            $lmsRoles = array_values(array_intersect($roles, $this->_lmsRoles));
            if (!$lmsRoles) {
                throw new Exception('This login is for LMS users. Admins should sign in at the staff portal.');
            }

            // Establish the session confined to the LMS roles. One role →
            // applied immediately; several → the role-selection page decides.
            $needsRoleSelect = $this->_establishLmsSession($user, $lmsRoles);

            $session->unsLearnerLoginAttempts();
            // Commit the session BEFORE redirecting — PHP writes sessions at
            // shutdown (after the response), so a fast browser can hit the
            // dashboard while the DB row is stale and get bounced (same race
            // as the role-select double-click / redirect-loop incidents).
            $destination = Mage::helper('mmd_rolemanager/classAccess')->destination($needsRoleSelect);
            session_write_close();
            $this->getResponse()->setRedirect($destination);
            return;
        } catch (Exception $e) {
            $session->setLearnerLoginError($e->getMessage());
            $session->setLearnerLoginEmail($email);
            $this->_redirect('*/*/index');
            return;
        }
    }

    /**
     * Send a login OTP to the learner's email — mirror of the staff
     * MMD_OtpLogin send action (same rate limit, same anti-enumeration
     * "always success" reply, same Gmail-first transport), but scoped to
     * learner session keys and accepting STOREFRONT-only accounts too.
     */
    public function sendAction()
    {
        $result = array('success' => false, 'message' => '');
        if (!$this->getRequest()->isPost()) {
            $result['message'] = 'Invalid request';
            return $this->_json($result);
        }
        $email = trim(strtolower($this->getRequest()->getParam('email', '')));
        if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $result['message'] = 'Please enter a valid email address';
            return $this->_json($result);
        }

        $session = Mage::getSingleton('core/session');
        // Rate limiting: max 3 sends per 10 minutes (same as staff OTP)
        $now = time();
        $attempts = array_filter((array) $session->getLearnerOtpAttempts(), function ($t) use ($now) {
            return ($now - $t) < 600;
        });
        if (count($attempts) >= 3) {
            $result['message'] = 'Too many attempts. Please try again later.';
            return $this->_json($result);
        }
        $attempts[] = $now;
        $session->setLearnerOtpAttempts($attempts);

        // Always report success so the form can't be used to probe emails.
        $result['success'] = true;
        $result['message'] = 'If an account exists with this email, an OTP has been sent.';

        // A learner is anyone with a dashboard learner account OR a storefront
        // customer account (shadow gets created at verify time).
        $firstname = $this->_resolveLearnerFirstname($email);
        if ($firstname !== null) {
            $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
            $session->setLearnerOtpCode($otp);
            $session->setLearnerOtpEmail($email);
            $session->setLearnerOtpExpires($now + 600);
            $session->unsLearnerOtpFailures();

            try {
                $subject  = 'Your Learner Login OTP - Tertiary Infotech Academy';
                $fromName = (string) Mage::getStoreConfig('trans_email/ident_general/name');
                $fromMail = (string) Mage::getStoreConfig('trans_email/ident_general/email');
                $bodyHtml =
                    '<p>Hi ' . htmlspecialchars($firstname) . ',</p>' .
                    '<p>Your one-time learner login code is: <strong style="font-size:18px;letter-spacing:2px;">'
                    . htmlspecialchars($otp) . '</strong></p>' .
                    '<p>This code expires in 10 minutes.<br>' .
                    'If you did not request this, please ignore this email.</p>' .
                    '<p>— Tertiary Infotech Academy</p>';
                $gmail = Mage::helper('mmd_email/gmail');
                if ($gmail && $gmail->isConfigured()) {
                    $gmail->send($email, $subject, $bodyHtml, $fromName);
                } else {
                    $mail = Mage::getModel('core/email');
                    $mail->setToEmail($email)->setToName($firstname)
                        ->setSubject($subject)
                        ->setBody(strip_tags(str_replace('<br>', "\n", $bodyHtml)))
                        ->setFromEmail($fromMail)->setFromName($fromName)->setType('text');
                    $mail->send();
                }
            } catch (Exception $e) {
                Mage::logException($e);
            }
        }
        return $this->_json($result);
    }

    /**
     * Verify the OTP and establish the learner session — role FORCED to
     * learner, never a role-selection screen.
     */
    public function verifyAction()
    {
        $result = array('success' => false, 'message' => '');
        if (!$this->getRequest()->isPost()) {
            $result['message'] = 'Invalid request';
            return $this->_json($result);
        }
        $email = trim(strtolower($this->getRequest()->getParam('email', '')));
        $otp   = trim($this->getRequest()->getParam('otp', ''));
        if (!$email || !$otp || strlen($otp) !== 6) {
            $result['message'] = 'Invalid OTP';
            return $this->_json($result);
        }

        $session = Mage::getSingleton('core/session');
        $storedCode    = $session->getLearnerOtpCode();
        $storedEmail   = $session->getLearnerOtpEmail();
        $storedExpires = $session->getLearnerOtpExpires();

        if (!$storedCode || !$storedEmail || !$storedExpires) {
            $result['message'] = 'No OTP found. Please request a new one.';
            return $this->_json($result);
        }
        if (time() > $storedExpires) {
            $session->unsLearnerOtpCode()->unsLearnerOtpEmail()->unsLearnerOtpExpires();
            $result['message'] = 'OTP has expired. Please request a new one.';
            return $this->_json($result);
        }
        if (!hash_equals((string) $storedCode, $otp) || strtolower($email) !== strtolower($storedEmail)) {
            // Cap guesses per issued code — 6 digits is brute-forceable otherwise.
            $failures = (int) $session->getLearnerOtpFailures() + 1;
            if ($failures >= 5) {
                $session->unsLearnerOtpCode()->unsLearnerOtpEmail()->unsLearnerOtpExpires()->unsLearnerOtpFailures();
                $result['message'] = 'Too many incorrect codes. Please request a new one.';
                return $this->_json($result);
            }
            $session->setLearnerOtpFailures($failures);
            $result['message'] = 'Invalid OTP. Please try again.';
            return $this->_json($result);
        }

        // OTP valid — clear it
        $session->unsLearnerOtpCode()->unsLearnerOtpEmail()->unsLearnerOtpExpires()->unsLearnerOtpFailures();
        $session->unsLearnerOtpAttempts();

        try {
            /** @var Mage_Admin_Model_User $user */
            $user = Mage::getModel('admin/user')->loadByUsername($email);
            if (!$user->getId()) {
                // Storefront-only learner: the OTP already proved email
                // ownership, so create the shadow dashboard account now.
                $customer = $this->_loadCustomerByEmail($email);
                if ($customer && $customer->getId()) {
                    Mage::helper('mmd_accountsync')->onCustomerSaved($customer);
                    $user->loadByUsername($email);
                }
            }
            if (!$user->getId() || (int) $user->getIsActive() !== 1) {
                $result['message'] = 'Account not found or disabled.';
                return $this->_json($result);
            }

            $helper   = Mage::helper('mmd_rolemanager');
            $roles    = $helper->getUserRolesFromDb($user->getId());
            $lmsRoles = array_values(array_intersect($roles, $this->_lmsRoles));
            if (!$lmsRoles) {
                $result['message'] = 'This login is for LMS users. Admins should sign in at the staff portal.';
                return $this->_json($result);
            }

            $needsRoleSelect = $this->_establishLmsSession($user, $lmsRoles);

            $result['success']  = true;
            $result['redirect'] = Mage::helper('mmd_rolemanager/classAccess')->destination($needsRoleSelect);
            // Commit the session before the JSON reply — the browser follows
            // result.redirect immediately and must see the fresh session row.
            session_write_close();
        } catch (Exception $e) {
            Mage::logException($e);
            $result['message'] = 'Login failed. Please try again.';
        }
        return $this->_json($result);
    }

    /**
     * Establish the admin session for an /lmslogin sign-in, confined to the
     * user's LMS roles (already intersected with $_lmsRoles by the caller —
     * admin/training_provider never appear here, so a Super Admin who also
     * teaches signs in at /lmslogin as trainer, never as Super Admin).
     *
     * @param  Mage_Admin_Model_User $user
     * @param  array                 $lmsRoles non-empty, validated
     * @return bool  true when the user still has to pick a role
     */
    protected function _establishLmsSession(Mage_Admin_Model_User $user, array $lmsRoles)
    {
        $helper       = Mage::helper('mmd_rolemanager');
        $adminSession = Mage::getSingleton('admin/session');
        $adminSession->setUser($user);
        $adminSession->setUserRoles($lmsRoles);
        // Password was assigned (bulk default / admin reset) — the predispatch
        // gate confines this session to the change-password screen.
        $adminSession->setMmdForcePasswordChange((bool) $user->getMmdForcePasswordChange());
        if (count($lmsRoles) === 1) {
            $adminSession->setActiveRoleCode($lmsRoles[0]);
            $adminSession->setNeedsRoleSelect(false);
            $helper->applyRoleAcl($user->getId(), $lmsRoles[0]);
            $adminSession->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());
            return false;
        }
        $adminSession->setActiveRoleCode(null);
        $adminSession->setNeedsRoleSelect(true);
        return true;
    }

    /**
     * Firstname for the OTP email when the address belongs to a learner
     * (dashboard account or storefront customer); null when unknown.
     */
    protected function _resolveLearnerFirstname($email)
    {
        $user = Mage::getModel('admin/user')->loadByUsername($email);
        if ($user->getId() && (int) $user->getIsActive() === 1) {
            return (string) $user->getFirstname();
        }
        $customer = $this->_loadCustomerByEmail($email);
        if ($customer && $customer->getId()) {
            return (string) $customer->getFirstname();
        }
        return null;
    }

    /** Load the storefront customer for this (single-store) site by email. */
    protected function _loadCustomerByEmail($email)
    {
        try {
            $websiteId = 1;
            foreach (Mage::app()->getWebsites() as $w) {
                $websiteId = (int) $w->getId();
                break;
            }
            $customer = Mage::getModel('customer/customer')->setWebsiteId($websiteId);
            $customer->loadByEmail($email);
            return $customer;
        } catch (Exception $e) {
            return null;
        }
    }

    /**
     * Self-registration from the login page's left column: Name + Email +
     * Class Code (the C###### class_id the admin hands out) + Role.
     *
     *  - Learner: storefront customer is created (MMD_AccountSync then makes
     *    the ACTIVE learner dashboard account), the learner is added to the
     *    class roster (course_run_enrolments, INSERT IGNORE = idempotent) and
     *    gets a welcome email telling them to sign in with OTP.
     *  - Trainer: an INACTIVE dashboard account with the trainer role is
     *    created — a class code alone must never hand out trainer access —
     *    and the admin is emailed to approve it (Users page → activate). The
     *    class's assigned trainer is left for the admin to set.
     *
     * The reply never says whether the email already had an account.
     */
    public function registerAction()
    {
        $result = array('success' => false, 'message' => '');
        $req = $this->getRequest();
        if (!$req->isPost() || !$this->_validateFormKey()) {
            $result['message'] = 'Your session has expired. Please refresh the page and try again.';
            return $this->_json($result);
        }

        $name      = trim(preg_replace('/\s+/u', ' ', (string) $req->getParam('name')));
        $email     = strtolower(trim((string) $req->getParam('email')));
        $classCode = strtoupper(trim((string) $req->getParam('class_code')));
        $role      = $req->getParam('role') === 'trainer' ? 'trainer' : 'learner';
        $okMessage = $role === 'trainer'
            ? 'Thank you! Your trainer registration is pending approval. We have emailed you the details.'
            : 'You are registered! We have emailed you a welcome message — you can now sign in with your email and an OTP.';

        // Honeypot: bots fill every field; pretend success, do nothing.
        if (trim((string) $req->getParam('website')) !== '') {
            $result['success'] = true;
            $result['message'] = $okMessage;
            return $this->_json($result);
        }

        $session = Mage::getSingleton('core/session');
        $now = time();
        $attempts = array_filter((array) $session->getLmsRegisterAttempts(), function ($t) use ($now) {
            return ($now - $t) < self::ATTEMPT_WINDOW;
        });
        if (count($attempts) >= self::MAX_ATTEMPTS) {
            $result['message'] = 'Too many attempts. Please try again in a few minutes.';
            return $this->_json($result);
        }
        $attempts[] = $now;
        $session->setLmsRegisterAttempts($attempts);

        if (mb_strlen($name) < 2 || mb_strlen($name) > 80) {
            $result['message'] = 'Please enter your name.';
            return $this->_json($result);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $result['message'] = 'Please enter a valid email address.';
            return $this->_json($result);
        }
        $run = preg_match('/^C\d{6}$/', $classCode) ? $this->_loadOpenClass($classCode) : null;
        if (!$run) {
            $result['message'] = 'That Course Run ID is not valid or the class has ended. Please check it with your course administrator.';
            return $this->_json($result);
        }

        try {
            if ($role === 'trainer') {
                $this->_registerTrainer($name, $email, $run);
            } else {
                $this->_registerLearner($name, $email, $run);
            }
            $session->unsLmsRegisterAttempts();
            $result['success'] = true;
            $result['message'] = $okMessage;
        } catch (Mage_Core_Exception $e) {
            // e.g. MMD_Email rejects a domain with no MX record
            $result['message'] = $e->getMessage();
        } catch (Exception $e) {
            Mage::logException($e);
            $result['message'] = 'Registration failed. Please try again or contact us.';
        }
        return $this->_json($result);
    }

    /** The class for this code, if it has not ended yet (else null). */
    protected function _loadOpenClass($classCode)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $run  = $read->fetchRow(
            "SELECT run_id, product_id, class_id, course_start_date, course_start_time
               FROM `" . $res->getTableName('course_runs') . "`
              WHERE class_id = ? AND COALESCE(course_end_date, course_start_date) >= CURDATE()
              LIMIT 1",
            array($classCode)
        );
        if (!$run) {
            return null;
        }
        $run['course_name'] = (string) Mage::getResourceModel('catalog/product')
            ->getAttributeRawValue((int) $run['product_id'], 'name', 0);
        return $run;
    }

    protected function _registerLearner($name, $email, array $run)
    {
        $res     = Mage::getSingleton('core/resource');
        $read    = $res->getConnection('core_read');
        $write   = $res->getConnection('core_write');
        $adminId = (int) $read->fetchOne(
            "SELECT user_id FROM `" . $res->getTableName('admin_user') . "` WHERE LOWER(email) = ? LIMIT 1",
            array($email)
        );
        $customer = $this->_loadCustomerByEmail($email);
        if (!$customer) {
            Mage::throwException('Registration is unavailable right now. Please try again later.');
        }

        if ($customer->getId()) {
            // Existing storefront learner — make sure the dashboard account exists.
            Mage::helper('mmd_accountsync')->onCustomerSaved($customer);
        } elseif ($adminId) {
            // Staff member without a storefront account: just add the learner
            // role. Creating a customer here would push its fresh password hash
            // onto their existing dashboard login (AccountSync sync).
            Mage::helper('mmd_accountsync')->_addLearnerRole($adminId, false);
        } else {
            list($first, $last) = $this->_splitName($name);
            // loadByEmail() on a miss wipes the model data (website_id too),
            // so set scope explicitly — the site's one store view.
            $store   = Mage::app()->getDefaultStoreView();
            $storeId = (int) $store->getId();
            $customer->setWebsiteId((int) $store->getWebsiteId())
                ->setFirstname($first)
                ->setLastname($last)
                ->setEmail($email)
                ->setStoreId($storeId)
                ->setGroupId((int) Mage::getStoreConfig(Mage_Customer_Model_Group::XML_PATH_DEFAULT_ID, $storeId))
                ->setPassword(Mage::helper('core')->getRandomString(24))
                ->save(); // customer_save_after -> AccountSync creates the learner dashboard account
        }

        $write->query(
            "INSERT IGNORE INTO `" . $res->getTableName('course_run_enrolments') . "`
                (product_id, run_id, learner_email, learner_name) VALUES (?, ?, ?, ?)",
            array((int) $run['product_id'], (int) $run['run_id'], $email, $name)
        );
        Mage::helper('mmd_rolemanager/handover')->noteIndependentMembership($run['run_id'], $email);

        $this->_sendMail($email, $name, 'Welcome to Tertiary Infotech Academy', $this->_emailHtml(
            'Welcome to Tertiary Infotech Academy',
            $name,
            '<p>You are registered for <strong>' . $this->_esc($run['course_name']) . '</strong>'
                . ' (Class <strong>' . $this->_esc($run['class_id']) . '</strong>'
                . $this->_classDateText($run) . ').</p>'
                . '<p><strong>Please log in to the Learning Management System to download the latest course'
                . ' material</strong> before your class:</p>'
                . '<ol style="padding-left:20px;margin:0 0 16px;">'
                . '<li>Open the login page using the button below.</li>'
                . '<li>Enter <strong>' . $this->_esc($email) . '</strong> and click <strong>Send OTP</strong>.</li>'
                . '<li>Enter the 6-digit code we email you. No password needed.</li>'
                . '<li>Open your class and download the latest course material.</li></ol>',
            'Log in to download course material'
        ));
    }

    protected function _registerTrainer($name, $email, array $run)
    {
        $res     = Mage::getSingleton('core/resource');
        $read    = $res->getConnection('core_read');
        $write   = $res->getConnection('core_write');
        $auTbl   = $res->getTableName('admin_user');
        $adminId = (int) $read->fetchOne("SELECT user_id FROM `$auTbl` WHERE LOWER(email) = ? LIMIT 1", array($email));
        $status  = 'Existing account #' . $adminId . ' — roles NOT changed; add the trainer role in Users if appropriate.';

        if (!$adminId) {
            // Raw insert (no admin_user_save_after): reuse the storefront hash
            // when the person is already a customer so AccountSync never
            // overwrites their storefront password with a random one.
            $customer = $this->_loadCustomerByEmail($email);
            $hash = ($customer && $customer->getId()) ? (string) $customer->getPasswordHash() : '';
            if ($hash === '') {
                $hash = Mage::helper('core')->getHash(
                    Mage::helper('core')->getRandomString(24),
                    Mage_Admin_Model_User::HASH_SALT_LENGTH
                );
            }
            list($first, $last) = $this->_splitName($name);
            $nowGmt = Mage::getModel('core/date')->gmtDate();
            $write->insert($auTbl, array(
                'firstname'       => mb_substr($first, 0, 32),
                'lastname'        => mb_substr($last, 0, 32),
                'email'           => substr($email, 0, 128),
                'username'        => substr($email, 0, 40),
                'password'        => $hash,
                'is_active'       => 0, // pending admin approval
                'created'         => $nowGmt,
                'modified'        => $nowGmt,
                'lognum'          => 0,
                'reload_acl_flag' => 0,
            ));
            $adminId = (int) $write->lastInsertId();
            $write->query(
                "INSERT IGNORE INTO `" . $res->getTableName('mmd_user_role_map') . "`
                    (user_id, role_code, is_primary, created_at) VALUES (?, 'trainer', 1, ?)",
                array($adminId, $nowGmt)
            );
            Mage::helper('mmd_rolemanager')->applyRoleAcl($adminId, 'trainer');
            $status = 'New INACTIVE trainer account #' . $adminId . ' — activate it in Users to approve.';
        }

        $this->_sendMail($email, $name, 'Your trainer registration - Tertiary Infotech Academy', $this->_emailHtml(
            'Thank you for registering as a trainer',
            $name,
            '<p>We have received your trainer registration for <strong>' . $this->_esc($run['course_name']) . '</strong>'
                . ' (Class <strong>' . $this->_esc($run['class_id']) . '</strong>' . $this->_classDateText($run) . ').</p>'
                . '<p>Your account is <strong>pending approval</strong> by our team. Once approved,'
                . ' <strong>please log in to download the latest course material</strong> for this class:'
                . ' sign in with <strong>' . $this->_esc($email) . '</strong>, click <strong>Send OTP</strong>'
                . ' and enter the 6-digit code we email you, then open the class to download the material.</p>',
            'Go to the login page'
        ));

        $adminMail = (string) Mage::getStoreConfig('trans_email/ident_general/email');
        if ($adminMail !== '') {
            $this->_sendMail($adminMail, 'Admin', 'Trainer sign-up awaiting approval: ' . $name, $this->_emailHtml(
                'Trainer sign-up awaiting approval',
                'Admin',
                '<p><strong>' . $this->_esc($name) . '</strong> (' . $this->_esc($email) . ') registered as a'
                    . ' <strong>trainer</strong> with Course Run ID <strong>' . $this->_esc($run['class_id']) . '</strong>'
                    . ' — ' . $this->_esc($run['course_name']) . $this->_classDateText($run) . '.</p>'
                    . '<p>' . $this->_esc($status) . '</p>',
                null
            ));
        }
    }

    /** "Jane Tan Mei Ling" -> ['Jane', 'Tan Mei Ling']; one word -> [word, '-']. */
    protected function _splitName($name)
    {
        $parts = explode(' ', $name, 2);
        return array($parts[0], isset($parts[1]) && $parts[1] !== '' ? $parts[1] : '-');
    }

    protected function _classDateText(array $run)
    {
        if (empty($run['course_start_date'])) {
            return '';
        }
        return ', starting ' . date('j M Y', strtotime($run['course_start_date']));
    }

    protected function _esc($s)
    {
        return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8');
    }

    /** Branded HTML email body; $cta = button label linking to /lmslogin (null = none). */
    protected function _emailHtml($heading, $name, $bodyHtml, $cta)
    {
        $loginUrl = Mage::getUrl('lmslogin', array('_nosid' => true));
        $button = $cta === null ? '' :
            '<p style="margin:24px 0;"><a href="' . $this->_esc($loginUrl) . '" style="display:inline-block;'
            . 'background:#2563eb;color:#ffffff;text-decoration:none;font-weight:600;padding:12px 24px;'
            . 'border-radius:8px;">' . $this->_esc($cta) . '</a></p>'
            . '<p style="font-size:12px;color:#64748b;">Or copy this link: ' . $this->_esc($loginUrl) . '</p>';
        return '<div style="background:#f1f5f9;padding:24px 12px;font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;">'
            . '<div style="max-width:560px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;border:1px solid #e2e8f0;">'
            . '<div style="background:#0f2350;color:#ffffff;padding:20px 28px;font-size:13px;letter-spacing:1px;'
            . 'text-transform:uppercase;font-weight:600;">Tertiary Infotech Academy</div>'
            . '<div style="padding:28px;color:#1e293b;font-size:15px;line-height:1.6;">'
            . '<h1 style="font-size:20px;margin:0 0 16px;color:#0f172a;">' . $this->_esc($heading) . '</h1>'
            . '<p>Hi ' . $this->_esc($name) . ',</p>' . $bodyHtml . $button
            . '<p style="margin-top:24px;">— Tertiary Infotech Academy</p></div></div></div>';
    }

    /** Gmail-first transport, same as the OTP mail in sendAction(). Never throws. */
    protected function _sendMail($to, $toName, $subject, $bodyHtml)
    {
        try {
            $fromName = (string) Mage::getStoreConfig('trans_email/ident_general/name');
            $fromMail = (string) Mage::getStoreConfig('trans_email/ident_general/email');
            $gmail = Mage::helper('mmd_email/gmail');
            if ($gmail && $gmail->isConfigured()) {
                $gmail->send($to, $subject, $bodyHtml, $fromName);
            } else {
                Mage::getModel('core/email')
                    ->setToEmail($to)->setToName($toName)
                    ->setSubject($subject)->setBody($bodyHtml)
                    ->setFromEmail($fromMail)->setFromName($fromName)->setType('html')
                    ->send();
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /** Send a JSON response. */
    protected function _json(array $data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(Mage::helper('core')->jsonEncode($data));
    }

    /**
     * Validate the storefront customer credentials; on success ensure the
     * shadow admin_user exists (AccountSync helper) and load it. Returns true
     * when $user ends up loaded + authenticated.
     */
    protected function _tryCustomerFallback($email, $password, Mage_Admin_Model_User $user)
    {
        try {
            $websiteId = (int) Mage::app()->getWebsite(true)->getId();
            // Single-store sites: any non-admin website works; default store's
            // website is the real one.
            foreach (Mage::app()->getWebsites() as $w) {
                $websiteId = (int) $w->getId();
                break;
            }
            /** @var Mage_Customer_Model_Customer $customer */
            $customer = Mage::getModel('customer/customer')->setWebsiteId($websiteId);
            if (!$customer->authenticate($email, $password)) {
                return false;
            }
            // Storefront credentials are valid — create/sync the shadow
            // dashboard account, then load it.
            Mage::helper('mmd_accountsync')->onCustomerSaved($customer);
            $user->loadByUsername($email);
            return (bool) $user->getId() && (int) $user->getIsActive() === 1;
        } catch (Exception $e) {
            return false;
        }
    }

    /** Render the standalone learner login page (no admin layout). */
    protected function _renderPage()
    {
        $session   = Mage::getSingleton('core/session');
        $error     = (string) $session->getLearnerLoginError();
        $prevEmail = (string) $session->getLearnerLoginEmail();
        $session->unsLearnerLoginError();
        $session->unsLearnerLoginEmail();

        $logoUrl   = Mage::getBaseUrl('skin') . 'adminhtml/default/default/images/admin-logo.png';
        // Post back to whichever frontName served the page (/lmslogin, or the
        // legacy /learnerlogin alias) so the session cookie path stays put.
        $route     = $this->getRequest()->getModuleName() === 'learnerlogin' ? 'learnerlogin' : 'lmslogin';
        $postUrl   = Mage::getUrl($route . '/index/login');
        $sendUrl   = Mage::getUrl($route . '/index/send');
        $verifyUrl = Mage::getUrl($route . '/index/verify');
        $registerUrl = Mage::getUrl($route . '/index/register');
        $forgotUrl = Mage::getUrl('customer/account/forgotpassword');
        $formKey   = Mage::getSingleton('core/session')->getFormKey();
        $siteName  = Mage::app()->getStore()->getFrontendName();
        $siteUrl   = Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB, true);

        ob_start();
        include Mage::getDesign()->getTemplateFilename('rolemanager/learner-login.phtml');
        return ob_get_clean();
    }

    /** Public page — access decided by the pre-dispatch machinery above. */
    protected function _isAllowed()
    {
        return true;
    }
}
