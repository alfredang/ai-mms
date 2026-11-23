<?php
/**
 * Google OAuth2 credentials for admin sign-in (the admin login page and the TC LMS
 * apps' Admin sign-in): the environment variables (.env injected into Apache via
 * docker-compose) when set, otherwise Company Settings > Google > Admin Sign-in
 * with Google (core_config_data mmd_company/google/signin_client_id and
 * signin_client_secret). Never hard-code secrets. Returns empty string when unset
 * so the login template can hide the button gracefully.
 */
class MMD_GoogleLogin_Helper_Data extends Mage_Core_Helper_Abstract
{
    const ENV_CLIENT_ID     = 'GOOGLE_OAUTH_CLIENT_ID';
    const ENV_CLIENT_SECRET = 'GOOGLE_OAUTH_CLIENT_SECRET';
    const XML_CLIENT_ID     = 'mmd_company/google/signin_client_id';
    const XML_CLIENT_SECRET = 'mmd_company/google/signin_client_secret';

    public function getClientId()
    {
        return $this->_setting(self::ENV_CLIENT_ID, self::XML_CLIENT_ID);
    }

    public function getClientSecret()
    {
        return $this->_setting(self::ENV_CLIENT_SECRET, self::XML_CLIENT_SECRET);
    }

    protected function _setting($env, $path)
    {
        $value = trim((string) getenv($env));
        return $value !== '' ? $value : trim((string) Mage::getStoreConfig($path, 0));
    }

    public function isConfigured()
    {
        return $this->getClientId() !== '' && $this->getClientSecret() !== '';
    }

    /**
     * Redirect URI registered in Google Cloud Console must match this exactly.
     * Uses adminhtml URL builder so it picks up the right secure key and the
     * current admin frontName (tigerdragon).
     */
    public function getRedirectUri()
    {
        return Mage::helper('adminhtml')->getUrl(
            'adminhtml/googlelogin/callback',
            array('_nosecret' => true)
        );
    }

    public function getStartUrl()
    {
        return Mage::helper('adminhtml')->getUrl(
            'adminhtml/googlelogin/start',
            array('_nosecret' => true)
        );
    }

    /**
     * Find an active admin_user by email. Returns the loaded user or null.
     * Strict — never auto-creates an account.
     */
    public function findActiveAdminByEmail($email)
    {
        $email = trim((string) $email);
        if ($email === '') {
            return null;
        }
        // Mage_Admin_Model_User has no loadByEmail(): calling it threw "Invalid method"
        // and every Google sign-in on the staff login ended on the error page.
        $resource = Mage::getSingleton('core/resource');
        $id = (int) $resource->getConnection('core_read')->fetchOne(
            'SELECT user_id FROM ' . $resource->getTableName('admin/user')
            . ' WHERE LOWER(email) = LOWER(?) ORDER BY is_active DESC, user_id ASC LIMIT 1',
            array($email)
        );
        if (!$id) {
            return null;
        }
        /** @var Mage_Admin_Model_User $user */
        $user = Mage::getModel('admin/user')->load($id);
        if (!$user->getId()) {
            return null;
        }
        if (!$user->getIsActive()) {
            return null;
        }
        return $user;
    }
}
