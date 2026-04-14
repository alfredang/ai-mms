<?php
/**
 * Admin user auth override: when the login form sends an email address,
 * skip the case-sensitive username comparison (which would always fail
 * since the row is loaded by email but $this->getUsername() is the
 * original username).
 */
class MMD_EmailLogin_Model_User extends Mage_Admin_Model_User
{
    public function authenticate($username, $password)
    {
        $username = new Mage_Core_Model_Security_Obfuscated($username);
        $password = new Mage_Core_Model_Security_Obfuscated($password);

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
            $this->unsetData();
        }
        return $result;
    }
}
