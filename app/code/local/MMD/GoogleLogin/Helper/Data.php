<?php
/**
 * Google OAuth2 credentials: the environment variables (.env injected into Apache
 * via docker-compose) when set, otherwise the database (System > Configuration >
 * Advanced > Admin > Google Sign-in; the secret stored encrypted). Never hard-code
 * secrets. Returns empty string when unset so the login template can hide the
 * button gracefully.
 */
class MMD_GoogleLogin_Helper_Data extends Mage_Core_Helper_Abstract
{
    const ENV_CLIENT_ID     = 'GOOGLE_OAUTH_CLIENT_ID';
    const ENV_CLIENT_SECRET = 'GOOGLE_OAUTH_CLIENT_SECRET';

    const XML_CLIENT_ID     = 'admin/mmd_googlelogin/client_id';
    const XML_CLIENT_SECRET = 'admin/mmd_googlelogin/client_secret';

    public function getClientId()
    {
        $env = trim((string) getenv(self::ENV_CLIENT_ID));
        return $env !== '' ? $env : trim((string) Mage::getStoreConfig(self::XML_CLIENT_ID, 0));
    }

    public function getClientSecret()
    {
        $env = trim((string) getenv(self::ENV_CLIENT_SECRET));
        if ($env !== '') {
            return $env;
        }
        $stored = (string) Mage::getStoreConfig(self::XML_CLIENT_SECRET, 0);
        return $stored === '' ? '' : trim((string) Mage::helper('core')->decrypt($stored));
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
        /** @var Mage_Admin_Model_User $user */
        $user = Mage::getModel('admin/user')->loadByEmail($email);
        if (!$user || !$user->getId()) {
            return null;
        }
        if (!$user->getIsActive()) {
            return null;
        }
        return $user;
    }
}
