<?php
class MMD_OtpLogin_Adminhtml_OtpController extends Mage_Adminhtml_Controller_Action
{
    /**
     * Actions accessible without admin login
     */
    protected $_publicActions = array('send', 'verify');

    /**
     * Override preDispatch to skip admin auth for OTP actions.
     * Sets the request as internally forwarded to prevent the core
     * admin observer from redirecting to the login page.
     */
    public function preDispatch()
    {
        $action = strtolower($this->getRequest()->getActionName());
        if (in_array($action, $this->_publicActions)) {
            $this->getRequest()->setInternallyForwarded(true);
        }
        parent::preDispatch();
        return $this;
    }

    /**
     * Send OTP to email
     */
    public function sendAction()
    {
        $result = array('success' => false, 'message' => '');

        if (!$this->getRequest()->isPost()) {
            $result['message'] = 'Invalid request';
            $this->_sendJson($result);
            return;
        }

        $email = trim(strtolower($this->getRequest()->getParam('email', '')));
        if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $result['message'] = 'Please enter a valid email address';
            $this->_sendJson($result);
            return;
        }

        $session = Mage::getSingleton('core/session');

        // Rate limiting: max 3 attempts per 10 minutes
        $attempts = (array) $session->getOtpAttempts();
        $now = time();
        // Clean old attempts
        $attempts = array_filter($attempts, function ($t) use ($now) {
            return ($now - $t) < 600;
        });
        if (count($attempts) >= 3) {
            $result['message'] = 'Too many attempts. Please try again later.';
            $this->_sendJson($result);
            return;
        }
        $attempts[] = $now;
        $session->setOtpAttempts($attempts);

        // Always return success to avoid revealing if email exists
        $result['success'] = true;
        $result['message'] = 'If an account exists with this email, an OTP has been sent.';

        // Look up user by email
        $user = Mage::getModel('admin/user')->loadByUsername($email);
        if ($user->getId() && $user->getIsActive()) {
            // Generate 6-digit OTP
            $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

            // Store OTP in session
            $session->setAdminOtpCode($otp);
            $session->setAdminOtpEmail($email);
            $session->setAdminOtpExpires($now + 600); // 10 minutes

            // Send email. Admin OTP is served from the single (SG-team)
            // admin panel, so we route it through Gmail OAuth2 directly
            // and skip the SMTPPro path entirely. Falls back to the
            // stock mailer if Gmail credentials aren't configured.
            try {
                $subject  = 'Your Login OTP Code - Tertiary Infotech Academy';
                $fromName = (string) Mage::getStoreConfig('trans_email/ident_general/name');
                $fromMail = (string) Mage::getStoreConfig('trans_email/ident_general/email');
                $gmail    = Mage::helper('mmd_email/gmail');
                if ($gmail && $gmail->isConfigured()) {
                    $bodyHtml =
                        '<p>Hi ' . htmlspecialchars($user->getFirstname()) . ',</p>' .
                        '<p>Your one-time login code is: <strong style="font-size:18px;letter-spacing:2px;">'
                        . htmlspecialchars($otp) . '</strong></p>' .
                        '<p>This code expires in 10 minutes.<br>' .
                        'If you did not request this, please ignore this email.</p>' .
                        '<p>— Tertiary Infotech Academy</p>';
                    $gmail->send($email, $subject, $bodyHtml, $fromName);
                } else {
                    $mail = Mage::getModel('core/email');
                    $mail->setToEmail($email);
                    $mail->setToName($user->getFirstname() . ' ' . $user->getLastname());
                    $mail->setSubject($subject);
                    $mail->setBody(
                        "Hi " . $user->getFirstname() . ",\n\n" .
                        "Your one-time login code is: " . $otp . "\n\n" .
                        "This code expires in 10 minutes.\n" .
                        "If you did not request this, please ignore this email.\n\n" .
                        "— Tertiary Infotech Academy"
                    );
                    $mail->setFromEmail($fromMail);
                    $mail->setFromName($fromName);
                    $mail->setType('text');
                    $mail->send();
                }
            } catch (Exception $e) {
                Mage::logException($e);
            }
        }

        $this->_sendJson($result);
    }

    /**
     * Verify OTP and log user in
     */
    public function verifyAction()
    {
        $result = array('success' => false, 'message' => '');

        if (!$this->getRequest()->isPost()) {
            $result['message'] = 'Invalid request';
            $this->_sendJson($result);
            return;
        }

        $email = trim(strtolower($this->getRequest()->getParam('email', '')));
        $otp   = trim($this->getRequest()->getParam('otp', ''));

        if (!$email || !$otp || strlen($otp) !== 6) {
            $result['message'] = 'Invalid OTP';
            $this->_sendJson($result);
            return;
        }

        $session = Mage::getSingleton('core/session');
        $storedCode    = $session->getAdminOtpCode();
        $storedEmail   = $session->getAdminOtpEmail();
        $storedExpires = $session->getAdminOtpExpires();

        // Validate OTP
        if (!$storedCode || !$storedEmail || !$storedExpires) {
            $result['message'] = 'No OTP found. Please request a new one.';
            $this->_sendJson($result);
            return;
        }

        if (time() > $storedExpires) {
            $session->unsAdminOtpCode();
            $session->unsAdminOtpEmail();
            $session->unsAdminOtpExpires();
            $result['message'] = 'OTP has expired. Please request a new one.';
            $this->_sendJson($result);
            return;
        }

        if ($otp !== $storedCode || strtolower($email) !== strtolower($storedEmail)) {
            $result['message'] = 'Invalid OTP. Please try again.';
            $this->_sendJson($result);
            return;
        }

        // OTP is valid — clear it
        $session->unsAdminOtpCode();
        $session->unsAdminOtpEmail();
        $session->unsAdminOtpExpires();
        $session->unsOtpAttempts();

        // Load user and log in
        $user = Mage::getModel('admin/user')->loadByUsername($email);
        if (!$user->getId() || !$user->getIsActive()) {
            $result['message'] = 'Account not found or disabled.';
            $this->_sendJson($result);
            return;
        }

        // Check user has a role assigned
        if (!$user->hasAssigned2Role($user->getId())) {
            $result['message'] = 'This account has no role assigned.';
            $this->_sendJson($result);
            return;
        }

        try {
            $adminSession = Mage::getSingleton('admin/session');
            $adminSession->setUser($user);
            $adminSession->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());
            // Assigned password (bulk default / admin reset): the RoleManager
            // predispatch gate holds this session on the account screen until
            // the user picks their own password.
            $adminSession->setMmdForcePasswordChange((bool) $user->getMmdForcePasswordChange());

            // Fire the same event Magento's password login fires so
            // RoleManager picks up the roles, sets needsRoleSelect, and
            // the predispatch observer can redirect multi-role users
            // to the role-selection page. The original code dispatched
            // `admin_user_authenticate_after` here, but RoleManager
            // listens on `admin_session_user_login_success` — so the
            // OTP path was silently bypassing the role flow and
            // dumping users straight on the dashboard with whatever
            // ACL they had.
            Mage::dispatchEvent('admin_session_user_login_success', array(
                'user' => $user,
            ));

            // Refresh ACL after RoleManager may have changed it
            $adminSession->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());

            // Multi-role users need to land on the role-select page.
            // Single-role users get the dashboard. RoleManager's
            // onAdminLogin sets `needsRoleSelect` accordingly.
            $needsRoleSelect = (bool) $adminSession->getNeedsRoleSelect();
            $result['success']  = true;
            $result['redirect'] = $needsRoleSelect
                ? Mage::helper('adminhtml')->getUrl('adminhtml/roleselect/index')
                : Mage::helper('adminhtml')->getUrl('adminhtml/dashboard');
            // Commit the session before the JSON reply — the browser follows
            // result.redirect immediately; without this the next request can
            // read a stale DB session row (role-select loop / double-click race).
            session_write_close();
        } catch (Exception $e) {
            Mage::logException($e);
            $result['message'] = 'Login failed. Please try again.';
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
     * Allow access without being logged in
     */
    protected function _isAllowed()
    {
        return true;
    }
}
