<?php
/**
 * Admin user auth override: when the login form sends an email address,
 * skip the case-sensitive username comparison (which would always fail
 * since the row is loaded by email but $this->getUsername() is the
 * original username).
 */
class MMD_EmailLogin_Model_User extends Mage_Admin_Model_User
{
    /**
     * Brute-force lockout: this OpenMage build has no admin login lockout,
     * and /adminlogin + /lmslogin both land here. Counted per login
     * identifier in the cache (per-IP is useless behind the proxy), so
     * dropping the session cookie does not reset it.
     */
    const LOCK_MAX_FAILURES = 10;
    const LOCK_WINDOW       = 900; // seconds, sliding from the last failure
    const LOCK_MESSAGE      = 'Too many failed sign-in attempts. Please wait 15 minutes, or sign in with an email code.';

    protected static function _lockCacheId($identifier)
    {
        return 'MMD_LOGIN_FAIL_' . md5(strtolower(trim((string) $identifier)));
    }

    public static function isLoginLocked($identifier)
    {
        return (int) Mage::app()->getCache()->load(self::_lockCacheId($identifier)) >= self::LOCK_MAX_FAILURES;
    }

    public static function recordLoginFailure($identifier)
    {
        $id = self::_lockCacheId($identifier);
        $count = (int) Mage::app()->getCache()->load($id) + 1;
        Mage::app()->getCache()->save((string) $count, $id, array(), self::LOCK_WINDOW);
    }

    public static function clearLoginFailures($identifier)
    {
        Mage::app()->getCache()->remove(self::_lockCacheId($identifier));
    }

    public function authenticate($username, $password)
    {
        $username = new Mage_Core_Model_Security_Obfuscated($username);
        $password = new Mage_Core_Model_Security_Obfuscated($password);

        if (self::isLoginLocked((string) $username)) {
            Mage::throwException(Mage::helper('adminhtml')->__(self::LOCK_MESSAGE));
        }

        $config = Mage::getStoreConfigFlag('admin/security/use_case_sensitive_login');
        $result = false;

        try {
            Mage::dispatchEvent('admin_user_authenticate_before', [
                'username' => $username,
                'user'     => $this,
            ]);
            $this->loadByUsername($username);

            $identifier = (string) $username;
            $isEmail = strpos($identifier, '@') !== false;

            if ($isEmail) {
                // Case-insensitive email match (emails are case-insensitive per RFC)
                $sensitive = strcasecmp($identifier, (string) $this->getEmail()) === 0;
            } else {
                $sensitive = ($config) ? $identifier == $this->getUsername() : true;
            }

            if ($sensitive && $this->getId() && $this->validatePasswordHash($password, $this->getPassword())) {
                if ($this->getIsActive() != '1') {
                    Mage::throwException(Mage::helper('adminhtml')->__('This account is inactive.'));
                }
                if (!$this->hasAssigned2Role($this->getId())) {
                    Mage::throwException(Mage::helper('adminhtml')->__('Access denied.'));
                }
                $result = true;
            }

            Mage::dispatchEvent('admin_user_authenticate_after', [
                'username' => $username,
                'password' => $password,
                'user'     => $this,
                'result'   => $result,
            ]);
        } catch (Mage_Core_Exception $e) {
            $this->unsetData();
            throw $e;
        }

        if (!$result) {
            self::recordLoginFailure((string) $username);
            $this->unsetData();
        } else {
            self::clearLoginFailures((string) $username);
        }
        return $result;
    }
}
