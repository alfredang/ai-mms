<?php
/**
 * Google OAuth2 sign-in for the OpenMage admin.
 *
 * Flow:
 *   GET  /tigerdragon/googlelogin/start    → redirect to Google with state nonce
 *   GET  /tigerdragon/googlelogin/callback → exchange code, verify email matches
 *                                            an active admin_user row, set admin
 *                                            session, redirect to dashboard.
 *
 * Strict policy: this controller NEVER creates new admin_user rows. Only emails
 * that already exist in admin_user (and have is_active=1) can sign in. Role
 * Management remains the single source of truth for who has admin access.
 */
class MMD_GoogleLogin_Adminhtml_GoogleloginController extends Mage_Adminhtml_Controller_Action
{
    const SESSION_STATE_KEY = 'mmd_gl_state';
    /** Set when the sign-in was started by a native app (holds the app's challenge); see _finishMobile. */
    const SESSION_MOBILE_KEY = 'mmd_gl_mobile';

    /**
     * Bypass the admin auth gate — by definition this controller IS the
     * authentication step. Without this override, Magento's preDispatch
     * would 302 us back to the login page in a loop.
     */
    public function _isAllowed()
    {
        return true;
    }

    public function preDispatch()
    {
        // Skip Mage_Adminhtml_Controller_Action::preDispatch's auth redirect
        // by calling its grandparent directly. Standard pattern used by
        // forgotpassword in core.
        $this->getRequest()->setDispatched(true);
        // Don't call parent::preDispatch() — it would force a login redirect.
        // Instead invoke the bare action initialization so events still fire.
        Mage_Core_Controller_Varien_Action::preDispatch();
        return $this;
    }

    /**
     * Redirect the browser to Google's OAuth2 consent screen.
     */
    public function startAction()
    {
        $helper = Mage::helper('mmd_googlelogin');
        if (!$helper->isConfigured()) {
            Mage::getSingleton('adminhtml/session')->addError(
                'Google sign-in is not configured. Set GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET in .env.'
            );
            $this->_redirect('adminhtml');
            return;
        }

        // Generate cryptographic state nonce — prevents CSRF on the callback.
        $state = bin2hex(random_bytes(16));
        Mage::getSingleton('core/session')->setData(self::SESSION_STATE_KEY, $state);

        // A native app (TC LMS) started this: remember its challenge so the callback
        // answers the app instead of opening an admin session in this browser.
        $mobile = (string) $this->getRequest()->getParam('mobile');
        Mage::getSingleton('core/session')->setData(
            self::SESSION_MOBILE_KEY, preg_match('/^[a-f0-9]{64}$/', $mobile) ? $mobile : null
        );

        $params = array(
            'client_id'     => $helper->getClientId(),
            'redirect_uri'  => $helper->getRedirectUri(),
            'response_type' => 'code',
            'scope'         => 'openid email profile',
            'state'         => $state,
            'prompt'        => 'select_account',
            'access_type'   => 'online',
        );
        $url = 'https://accounts.google.com/o/oauth2/v2/auth?' . http_build_query($params);
        Mage::app()->getResponse()->setRedirect($url)->sendResponse();
        exit;
    }

    /**
     * Google redirects here with ?code=... &state=... .
     */
    public function callbackAction()
    {
        $req = $this->getRequest();
        $session = Mage::getSingleton('core/session');
        $adminSession = Mage::getSingleton('adminhtml/session');
        $helper = Mage::helper('mmd_googlelogin');

        // State must match the value we generated in startAction.
        $expectedState = (string) $session->getData(self::SESSION_STATE_KEY);
        $session->unsetData(self::SESSION_STATE_KEY);
        $mobile = (string) $session->getData(self::SESSION_MOBILE_KEY);
        $session->unsetData(self::SESSION_MOBILE_KEY);
        if ($mobile !== '') {
            return $this->_finishMobile($mobile, $expectedState);
        }
        $receivedState = (string) $req->getParam('state');
        if ($expectedState === '' || !hash_equals($expectedState, $receivedState)) {
            $adminSession->addError('Google sign-in failed: state mismatch. Try again.');
            $this->_redirect('adminhtml');
            return;
        }

        $code = (string) $req->getParam('code');
        if ($code === '') {
            $err = (string) $req->getParam('error');
            $adminSession->addError('Google sign-in cancelled or failed' . ($err !== '' ? ': ' . $err : '.'));
            $this->_redirect('adminhtml');
            return;
        }

        // Exchange the authorization code for an access + id token.
        $tokenResp = $this->_postForm(
            'https://oauth2.googleapis.com/token',
            array(
                'code'          => $code,
                'client_id'     => $helper->getClientId(),
                'client_secret' => $helper->getClientSecret(),
                'redirect_uri'  => $helper->getRedirectUri(),
                'grant_type'    => 'authorization_code',
            )
        );
        if (!$tokenResp || !isset($tokenResp['access_token'])) {
            $adminSession->addError('Google sign-in failed: token exchange error.');
            $this->_redirect('adminhtml');
            return;
        }

        // Use the access token to fetch the user's verified email.
        $userInfo = $this->_getJson(
            'https://www.googleapis.com/oauth2/v3/userinfo',
            $tokenResp['access_token']
        );
        if (!$userInfo || empty($userInfo['email']) || empty($userInfo['email_verified'])) {
            $adminSession->addError('Google sign-in failed: could not verify your email with Google.');
            $this->_redirect('adminhtml');
            return;
        }

        $email = (string) $userInfo['email'];
        $user = $helper->findActiveAdminByEmail($email);
        if (!$user) {
            $adminSession->addError(sprintf(
                'No active admin account found for %s. Ask a Super Admin to create one in Users.',
                $email
            ));
            $this->_redirect('adminhtml');
            return;
        }

        // All checks passed — log the admin in.
        $adminSession->setUser($user);
        $adminSession->setUpdatedAt(time());
        $adminSession->renewSession();

        // Touch the user's logdate so the Users grid shows the activity.
        try {
            $user->getResource()->recordLogin($user);
        } catch (Exception $e) { /* non-fatal */ }

        // RoleManager.applyRoleAcl handles single-role users; multi-role users
        // hit the role-select page via the existing onAdminLogin observer.
        Mage::dispatchEvent('admin_user_authenticate_after', array(
            'username' => $user->getUsername(),
            'password' => '',
            'user'     => $user,
            'result'   => true,
        ));

        $this->_redirect('adminhtml');
    }

    /**
     * The callback for a sign-in started by a native app. Never opens an admin
     * session in this browser: it sends the app a single-use code (for an allowed
     * admin) or an error, at the app's own URL scheme.
     */
    protected function _finishMobile($challenge, $expectedState)
    {
        $req    = $this->getRequest();
        $helper = Mage::helper('mmd_googlelogin');
        $mobile = Mage::helper('mmd_mobileapi');
        $back   = $mobile->appScheme() . '://auth?';
        $fail   = function ($message) use ($back) {
            return Mage::app()->getResponse()->setRedirect($back . 'error=' . rawurlencode($message));
        };

        if ($expectedState === '' || !hash_equals($expectedState, (string) $req->getParam('state'))) {
            return $fail('Google sign-in failed. Please try again.');
        }
        $code = (string) $req->getParam('code');
        if ($code === '') {
            return $fail('Google sign-in was cancelled.');
        }
        $tokenResp = $this->_postForm('https://oauth2.googleapis.com/token', array(
            'code'          => $code,
            'client_id'     => $helper->getClientId(),
            'client_secret' => $helper->getClientSecret(),
            'redirect_uri'  => $helper->getRedirectUri(),
            'grant_type'    => 'authorization_code',
        ));
        if (!$tokenResp || !isset($tokenResp['access_token'])) {
            return $fail('Google sign-in failed. Please try again.');
        }
        $userInfo = $this->_getJson('https://www.googleapis.com/oauth2/v3/userinfo', $tokenResp['access_token']);
        if (!$userInfo || empty($userInfo['email']) || empty($userInfo['email_verified'])) {
            return $fail('Google could not verify your email.');
        }
        if (!$mobile->mayUseGoogleAdminLogin((string) $userInfo['email'])) {
            return $fail('This Google account is not allowed to sign in as an admin.');
        }
        return Mage::app()->getResponse()->setRedirect(
            $back . 'code=' . $mobile->saveGoogleCode((string) $userInfo['email'], $challenge)
        );
    }

    /**
     * POST application/x-www-form-urlencoded, decode JSON response.
     */
    protected function _postForm($url, array $fields)
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query($fields),
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_HTTPHEADER     => array('Accept: application/json'),
        ));
        $body = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($code < 200 || $code >= 300 || !$body) {
            Mage::log('GoogleLogin token exchange HTTP ' . $code . ' body=' . substr((string)$body, 0, 500), null, 'mmd-google.log');
            return null;
        }
        $json = json_decode($body, true);
        return is_array($json) ? $json : null;
    }

    /**
     * GET with bearer token, decode JSON.
     */
    protected function _getJson($url, $bearer)
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_HTTPHEADER     => array(
                'Authorization: Bearer ' . $bearer,
                'Accept: application/json',
            ),
        ));
        $body = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($code < 200 || $code >= 300 || !$body) {
            Mage::log('GoogleLogin userinfo HTTP ' . $code, null, 'mmd-google.log');
            return null;
        }
        $json = json_decode($body, true);
        return is_array($json) ? $json : null;
    }
}
