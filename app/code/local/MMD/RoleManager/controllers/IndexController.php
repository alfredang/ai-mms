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
    protected $_publicActions = array('index', 'login', 'send', 'verify');

    const MAX_ATTEMPTS = 5;      // per session
    const ATTEMPT_WINDOW = 600;  // seconds

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
            $this->_redirect('adminhtml/dashboard');
            return;
        }
        $this->getResponse()->setBody($this->_renderPage());
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
                // Legacy learner whose shadow account predates AccountSync (or
                // was never backfilled): validate the STOREFRONT account and
                // create/sync the shadow on the fly, then retry once.
                $ok = $this->_tryCustomerFallback($email, $password, $user);
            }
            if (!$ok || !$user->getId()) {
                throw new Exception('Your email or password is incorrect.');
            }

            // Must actually be a learner — staff-only accounts use /tigerdragon.
            $helper = Mage::helper('mmd_rolemanager');
            $roles  = $helper->getUserRolesFromDb($user->getId());
            if (!in_array('learner', $roles, true)) {
                throw new Exception('This login is for learners. Staff should sign in at the staff portal.');
            }

            // Establish the learner session — role FORCED to learner, no
            // role-selection step regardless of any other roles on the account.
            $adminSession = Mage::getSingleton('admin/session');
            $adminSession->setUser($user);
            $adminSession->setUserRoles(array('learner'));
            $adminSession->setActiveRoleCode('learner');
            $adminSession->setNeedsRoleSelect(false);
            $helper->applyRoleAcl($user->getId(), 'learner');
            $adminSession->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());

            $session->unsLearnerLoginAttempts();
            $this->_redirect('adminhtml/dashboard');
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
        if ($otp !== $storedCode || strtolower($email) !== strtolower($storedEmail)) {
            $result['message'] = 'Invalid OTP. Please try again.';
            return $this->_json($result);
        }

        // OTP valid — clear it
        $session->unsLearnerOtpCode()->unsLearnerOtpEmail()->unsLearnerOtpExpires();
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

            $helper = Mage::helper('mmd_rolemanager');
            $roles  = $helper->getUserRolesFromDb($user->getId());
            if (!in_array('learner', $roles, true)) {
                $result['message'] = 'This login is for learners. Staff should sign in at the staff portal.';
                return $this->_json($result);
            }

            $adminSession = Mage::getSingleton('admin/session');
            $adminSession->setUser($user);
            $adminSession->setUserRoles(array('learner'));
            $adminSession->setActiveRoleCode('learner');
            $adminSession->setNeedsRoleSelect(false);
            $helper->applyRoleAcl($user->getId(), 'learner');
            $adminSession->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());

            $result['success']  = true;
            $result['redirect'] = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard');
        } catch (Exception $e) {
            Mage::logException($e);
            $result['message'] = 'Login failed. Please try again.';
        }
        return $this->_json($result);
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
        $postUrl   = Mage::getUrl('learnerlogin/index/login');
        $sendUrl   = Mage::getUrl('learnerlogin/index/send');
        $verifyUrl = Mage::getUrl('learnerlogin/index/verify');
        $forgotUrl = Mage::getUrl('customer/account/forgotpassword');
        $formKey   = Mage::getSingleton('core/session')->getFormKey();
        $siteName  = Mage::app()->getStore()->getFrontendName();

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
