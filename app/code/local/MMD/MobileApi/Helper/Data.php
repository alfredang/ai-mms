<?php
/**
 * Identity for the native learner apps: bearer tokens, email OTP and the
 * email + password check, plus the per-site facts the apps display.
 *
 * Who may sign in: anyone with a storefront customer account on THIS site, or
 * an active dashboard account holding the learner role — the same population
 * /lmslogin accepts for learners. Tokens and OTP codes are stored as SHA-256
 * hashes only (migration 1897).
 */
class MMD_MobileApi_Helper_Data extends Mage_Core_Helper_Abstract
{
    const TOKEN_TTL_DAYS   = 60;   // sliding: every request pushes expiry out
    const OTP_TTL          = 600;  // seconds — same as the web LMS
    const OTP_MAX_GUESSES  = 5;    // wrong codes per issued OTP
    const OTP_SENDS_EMAIL  = 3;    // per email per 10 minutes — same as the web LMS
    const OTP_SENDS_IP     = 20;   // per IP per hour (anti-spray)

    // ── Store-local time ─────────────────────────────────────────────────────

    /** Magento resets PHP to UTC; class dates are store-local. */
    public function today()
    {
        return Mage::getModel('core/date')->date('Y-m-d');
    }

    public function now()
    {
        return Mage::getModel('core/date')->date('Y-m-d H:i:s');
    }

    /** UTC timestamp for DB bookkeeping columns (sessions, OTPs). */
    public function utcNow($offsetSeconds = 0)
    {
        return gmdate('Y-m-d H:i:s', time() + $offsetSeconds);
    }

    // ── Site ─────────────────────────────────────────────────────────────────

    public function storeCode()
    {
        return (string) Mage::app()->getDefaultStoreView()->getCode();
    }

    /** SG / MY / GH from the store code (base = Singapore). */
    public function countryCode()
    {
        $code = $this->storeCode();
        if ($code === 'malaysia') return 'MY';
        if ($code === 'ghana')    return 'GH';
        $env = strtoupper((string) getenv('MMS_COUNTRY_CODE'));
        return in_array($env, array('MY', 'GH', 'NG'), true) ? $env : 'SG';
    }

    public function currencyCode()
    {
        $store = Mage::app()->getDefaultStoreView();
        return (string) ($store->getBaseCurrencyCode() ?: Mage::getStoreConfig('currency/options/base'));
    }

    public function siteInfo()
    {
        $store   = Mage::app()->getDefaultStoreView();
        $country = $this->countryCode();
        return array(
            'country'      => $country,
            'name'         => (string) Mage::getStoreConfig('general/store_information/name', $store) ?: 'Tertiary Courses',
            'website_url'  => rtrim((string) Mage::getStoreConfig('web/secure/base_url', $store), '/'),
            'currency'     => $this->currencyCode(),
            'timezone'     => (string) Mage::getStoreConfig('general/locale/timezone', $store),
            'phone'        => (string) Mage::getStoreConfig('general/store_information/phone', $store),
            'email'        => (string) Mage::getStoreConfig('trans_email/ident_general/email', $store),
            'academy'      => $country === 'MY' ? 'Tertiary Infotech Sdn. Bhd.' : (string) Mage::getStoreConfig('trans_email/ident_general/name', $store),
            // SG lists course fees before 9% GST; the partner sites list the payable fee.
            'price_note'   => $country === 'SG' ? 'before 9% GST' : '',
        );
    }

    // ── Accounts ─────────────────────────────────────────────────────────────

    public function normalizeEmail($email)
    {
        $email = strtolower(trim((string) $email));
        return filter_var($email, FILTER_VALIDATE_EMAIL) ? $email : '';
    }

    /** The storefront customer for this (single-store) site, or null. */
    public function loadCustomer($email)
    {
        try {
            $websiteId = (int) Mage::app()->getDefaultStoreView()->getWebsiteId();
            $customer  = Mage::getModel('customer/customer')->setWebsiteId($websiteId)->loadByEmail($email);
            return $customer->getId() ? $customer : null;
        } catch (Exception $e) {
            return null;
        }
    }

    /** The learner's dashboard (shadow) account, or null. */
    public function loadAdminUser($email)
    {
        $user = Mage::getModel('admin/user')->loadByUsername($email);
        if (!$user->getId()) {
            $id = (int) $this->_read()->fetchOne(
                'SELECT user_id FROM ' . $this->_table('admin/user') . ' WHERE LOWER(email) = ? LIMIT 1',
                array($email)
            );
            if ($id) $user = Mage::getModel('admin/user')->load($id);
        }
        return $user->getId() ? $user : null;
    }

    public function adminRoles($userId)
    {
        return (array) Mage::helper('mmd_rolemanager')->getUserRolesFromDb((int) $userId);
    }

    /** Can this email use the learner app on this site? */
    public function isLearner($email)
    {
        if ($this->loadCustomer($email)) {
            return true;
        }
        $user = $this->loadAdminUser($email);
        return $user && (int) $user->getIsActive() === 1 && in_array('learner', $this->adminRoles($user->getId()), true);
    }

    public function learnerProfile($email)
    {
        $customer = $this->loadCustomer($email);
        $user     = $this->loadAdminUser($email);
        $first = $customer ? (string) $customer->getFirstname() : ($user ? (string) $user->getFirstname() : '');
        $last  = $customer ? (string) $customer->getLastname()  : ($user ? (string) $user->getLastname()  : '');
        return array(
            'email'      => $email,
            'first_name' => $first,
            'last_name'  => $last,
            'full_name'  => trim($first . ' ' . $last),
        );
    }

    public function isDemoEmail($email)
    {
        $list = array_filter(array_map(function ($e) {
            return strtolower(trim($e));
        }, explode(',', (string) Mage::getStoreConfig('mmd_mobileapi/general/demo_emails'))));
        return in_array($email, $list, true);
    }

    /**
     * Email + password. Checks the storefront account first (the learner's own
     * credentials), then the dashboard account for learner-role users without a
     * storefront account. Shares the web LMS's per-email lockout.
     * Returns the email on success; throws with a user-facing message.
     */
    public function authenticatePassword($email, $password)
    {
        $email = $this->normalizeEmail($email);
        if ($email === '' || (string) $password === '') {
            throw new Exception('Please enter your email and password.');
        }
        if (MMD_EmailLogin_Model_User::isLoginLocked($email)) {
            throw new Exception(MMD_EmailLogin_Model_User::LOCK_MESSAGE);
        }

        // App Review account: no customer record, bcrypt hash in config (migration 1897).
        if ($this->isDemoEmail($email)) {
            $hash = (string) Mage::getStoreConfig('mmd_mobileapi/general/demo_password_hash');
            if ($hash === '' || !password_verify((string) $password, $hash)) {
                MMD_EmailLogin_Model_User::recordLoginFailure($email);
                throw new Exception('Your email or password is incorrect.');
            }
            MMD_EmailLogin_Model_User::clearLoginFailures($email);
            return $email;
        }

        $ok = false;
        $customer = $this->loadCustomer($email);
        if ($customer) {
            try {
                $ok = (bool) $customer->authenticate($email, $password);
            } catch (Exception $e) {
                $ok = false;   // unconfirmed / bad password — same answer
            }
        }
        if (!$ok) {
            $user = $this->loadAdminUser($email);
            if ($user && (int) $user->getIsActive() === 1
                && in_array('learner', $this->adminRoles($user->getId()), true)
                && Mage::helper('core')->validateHash($password, (string) $user->getPassword())) {
                $ok = true;
            }
        }
        if (!$ok) {
            MMD_EmailLogin_Model_User::recordLoginFailure($email);
            throw new Exception('Your email or password is incorrect.');
        }
        MMD_EmailLogin_Model_User::clearLoginFailures($email);
        return $email;
    }

    // ── Email OTP ────────────────────────────────────────────────────────────

    protected function _otpHash($email, $code)
    {
        return hash('sha256', $email . '|' . $code . '|' . (string) Mage::getConfig()->getNode('global/crypt/key'));
    }

    /**
     * Email a 6-digit login code. Always "succeeds" for a well-formed email so
     * the endpoint cannot be used to discover which emails have accounts.
     * Throws only for a malformed email or when rate-limited.
     */
    public function sendOtp($email, $ip)
    {
        $email = $this->normalizeEmail($email);
        if ($email === '') {
            throw new Exception('Please enter a valid email address.');
        }
        $tbl  = $this->_table('mmd_mobile_otp');
        $read = $this->_read();
        $sentToEmail = (int) $read->fetchOne(
            "SELECT COUNT(*) FROM `$tbl` WHERE email = ? AND created_at > ?",
            array($email, $this->utcNow(-600))
        );
        $sentFromIp = $ip === '' ? 0 : (int) $read->fetchOne(
            "SELECT COUNT(*) FROM `$tbl` WHERE ip = ? AND created_at > ?",
            array($ip, $this->utcNow(-3600))
        );
        if ($sentToEmail >= self::OTP_SENDS_EMAIL || $sentFromIp >= self::OTP_SENDS_IP) {
            throw new Exception('Too many codes requested. Please try again in a few minutes.');
        }

        // The App Review account signs in with its password; never mail it codes.
        if ($this->isDemoEmail($email) || !$this->isLearner($email)) {
            return;
        }

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $this->_write()->insert($tbl, array(
            'email'      => $email,
            'code_hash'  => $this->_otpHash($email, $code),
            'ip'         => $ip !== '' ? substr($ip, 0, 64) : null,
            'created_at' => $this->utcNow(),
            'expires_at' => $this->utcNow(self::OTP_TTL),
        ));

        $profile  = $this->learnerProfile($email);
        $site     = $this->siteInfo();
        $subject  = 'Your login code - ' . $site['name'];
        $fromName = (string) Mage::getStoreConfig('trans_email/ident_general/name');
        $fromMail = (string) Mage::getStoreConfig('trans_email/ident_general/email');
        $bodyHtml =
            '<p>Hi ' . htmlspecialchars($profile['first_name'] ?: 'there') . ',</p>' .
            '<p>Your one-time code for the ' . htmlspecialchars($site['name']) . ' learner app is: '
            . '<strong style="font-size:18px;letter-spacing:2px;">' . $code . '</strong></p>' .
            '<p>This code expires in 10 minutes.<br>' .
            'If you did not request this, please ignore this email.</p>' .
            '<p>— ' . htmlspecialchars($site['academy']) . '</p>';
        try {
            $gmail = Mage::helper('mmd_email/gmail');
            if ($gmail && $gmail->isConfigured()) {
                $gmail->send($email, $subject, $bodyHtml, $fromName);
            } else {
                Mage::getModel('core/email')
                    ->setToEmail($email)->setToName($profile['full_name'])
                    ->setSubject($subject)
                    ->setBody(strip_tags(str_replace('<br>', "\n", $bodyHtml)))
                    ->setFromEmail($fromMail)->setFromName($fromName)->setType('text')
                    ->send();
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /** Check a code against the newest live OTP. Returns the email; throws on failure. */
    public function verifyOtp($email, $code)
    {
        $email = $this->normalizeEmail($email);
        $code  = preg_replace('/\D/', '', (string) $code);
        if ($email === '' || strlen($code) !== 6) {
            throw new Exception('Please enter the 6-digit code from your email.');
        }
        $tbl = $this->_table('mmd_mobile_otp');
        $row = $this->_read()->fetchRow(
            "SELECT * FROM `$tbl` WHERE email = ? AND consumed_at IS NULL AND expires_at > ?
              ORDER BY otp_id DESC LIMIT 1",
            array($email, $this->utcNow())
        );
        if (!$row || (int) $row['attempts'] >= self::OTP_MAX_GUESSES) {
            throw new Exception('This code has expired. Please request a new one.');
        }
        if (!hash_equals((string) $row['code_hash'], $this->_otpHash($email, $code))) {
            $this->_write()->query("UPDATE `$tbl` SET attempts = attempts + 1 WHERE otp_id = ?", array((int) $row['otp_id']));
            throw new Exception('That code is incorrect. Please check your email and try again.');
        }
        // Single use: the conditional update wins only once under a race.
        $n = $this->_write()->update($tbl, array('consumed_at' => $this->utcNow()),
            array('otp_id = ?' => (int) $row['otp_id'], 'consumed_at IS NULL'));
        if (!$n) {
            throw new Exception('This code has already been used. Please request a new one.');
        }
        return $email;
    }

    // ── Bearer sessions ──────────────────────────────────────────────────────

    public function issueToken($email, $platform = '', $appVersion = '')
    {
        $token    = bin2hex(random_bytes(32));
        $customer = $this->loadCustomer($email);
        $this->_write()->insert($this->_table('mmd_mobile_session'), array(
            'token_hash'   => hash('sha256', $token),
            'email'        => $email,
            'customer_id'  => $customer ? (int) $customer->getId() : null,
            'is_demo'      => $this->isDemoEmail($email) ? 1 : 0,
            'platform'     => $platform !== '' ? substr(strtolower($platform), 0, 16) : null,
            'app_version'  => $appVersion !== '' ? substr($appVersion, 0, 32) : null,
            'created_at'   => $this->utcNow(),
            'last_used_at' => $this->utcNow(),
            'expires_at'   => $this->utcNow(self::TOKEN_TTL_DAYS * 86400),
        ));
        return $token;
    }

    /** The live session row for a bearer token, or null. Slides the expiry. */
    public function sessionForToken($token)
    {
        $token = trim((string) $token);
        if (!preg_match('/^[a-f0-9]{64}$/', $token)) {
            return null;
        }
        $tbl = $this->_table('mmd_mobile_session');
        $row = $this->_read()->fetchRow(
            "SELECT * FROM `$tbl` WHERE token_hash = ? AND revoked_at IS NULL AND expires_at > ? LIMIT 1",
            array(hash('sha256', $token), $this->utcNow())
        );
        if (!$row) {
            return null;
        }
        // A learner removed from the site since sign-in loses access at once.
        if (!(int) $row['is_demo'] && !$this->isLearner($row['email'])) {
            $this->revokeAll($row['email']);
            return null;
        }
        if (strtotime($row['last_used_at']) < time() - 3600) {
            $this->_write()->update($tbl, array(
                'last_used_at' => $this->utcNow(),
                'expires_at'   => $this->utcNow(self::TOKEN_TTL_DAYS * 86400),
            ), array('session_id = ?' => (int) $row['session_id']));
        }
        return $row;
    }

    public function revokeToken($token)
    {
        $this->_write()->update($this->_table('mmd_mobile_session'),
            array('revoked_at' => $this->utcNow()),
            array('token_hash = ?' => hash('sha256', trim((string) $token)), 'revoked_at IS NULL'));
    }

    public function revokeAll($email)
    {
        $this->_write()->update($this->_table('mmd_mobile_session'),
            array('revoked_at' => $this->utcNow()),
            array('email = ?' => $email, 'revoked_at IS NULL'));
    }

    // ── Account deletion (App Store 5.1.1(v) / Play account-deletion policy) ──

    /**
     * Delete the learner's login account: the storefront customer and its
     * learner-only dashboard shadow account, and every app session. Training
     * records the academy must keep (registrations/invoices, attendance,
     * certificates) are retained, keyed by email as before. Staff accounts
     * (any role besides learner) are never deleted from the app.
     */
    public function deleteAccount($email)
    {
        $user = $this->loadAdminUser($email);
        if ($user) {
            $others = array_diff($this->adminRoles($user->getId()), array('learner'));
            if ($others) {
                throw new Exception('This email is also a staff account and cannot be deleted from the app. Please contact us to close it.');
            }
        }
        $this->revokeAll($email);

        $customer = $this->loadCustomer($email);
        if ($customer) {
            Mage::register('isSecureArea', true, true);
            try {
                $customer->delete();
            } catch (Exception $e) {
                Mage::unregister('isSecureArea');
                throw $e;
            }
            Mage::unregister('isSecureArea');
        }
        if ($user) {
            $this->_write()->delete($this->_table('mmd_user_role_map'), array('user_id = ?' => (int) $user->getId()));
            $user->delete();
        }
        Mage::log('Learner app account deletion: ' . md5($email), Zend_Log::INFO, 'mmd_mobileapi.log', true);
    }

    // ── DB ───────────────────────────────────────────────────────────────────

    public function _read()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    public function _write()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_write');
    }

    public function _table($name)
    {
        return Mage::getSingleton('core/resource')->getTableName($name);
    }
}
