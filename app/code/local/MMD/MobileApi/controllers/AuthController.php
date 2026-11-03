<?php
/**
 * Learner-app sign-in: email + password, or a 6-digit code emailed to the
 * learner. Both return {"token": "...", "learner": {...}}.
 */
class MMD_MobileApi_AuthController extends MMD_MobileApi_Controller_Base
{
    /** POST {email, password, platform?, app_version?} */
    public function passwordAction()
    {
        if (!$this->_requirePost()) return;
        return $this->_guard(function () {
            try {
                $email = $this->_helper()->authenticatePassword($this->_input('email'), (string) $this->_input('password'));
            } catch (Exception $e) {
                return $this->_error(401, $e->getMessage(), 'invalid_credentials');
            }
            return $this->_signedIn($email);
        });
    }

    /** POST {email} — always answers ok for a well-formed email (no account probing). */
    public function otpsendAction()
    {
        if (!$this->_requirePost()) return;
        return $this->_guard(function () {
            try {
                $this->_helper()->sendOtp($this->_input('email'), $this->_clientIp());
            } catch (Exception $e) {
                return $this->_error(429, $e->getMessage(), 'otp_rejected');
            }
            return $this->_ok(array('message' => 'If this email has an account, a 6-digit code is on its way. It expires in 10 minutes.'));
        });
    }

    /** POST {email, code, platform?, app_version?} */
    public function otpverifyAction()
    {
        if (!$this->_requirePost()) return;
        return $this->_guard(function () {
            try {
                $email = $this->_helper()->verifyOtp($this->_input('email'), $this->_input('code'));
            } catch (Exception $e) {
                return $this->_error(401, $e->getMessage(), 'invalid_code');
            }
            return $this->_signedIn($email);
        });
    }

    /** GET — the signed-in learner. */
    public function meAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            return $this->_ok(array(
                'learner' => $this->_profile(),
                'site'    => $this->_helper()->siteInfo(),
            ));
        });
    }

    /** POST — revoke this device's token. */
    public function logoutAction()
    {
        if (!$this->_requirePost()) return;
        return $this->_guard(function () {
            $this->_helper()->revokeToken($this->_bearer());
            return $this->_ok();
        });
    }

    /** POST {confirm: "DELETE"} — delete the learner's login account. */
    public function deleteAction()
    {
        if (!$this->_requirePost() || !$this->_requireLearner()) return;
        return $this->_guard(function () {
            if (strtoupper(trim((string) $this->_input('confirm'))) !== 'DELETE') {
                return $this->_error(400, 'Please confirm the deletion.', 'confirmation_required');
            }
            if ($this->_isDemo()) {
                // The App Review account is shared by every reviewer: sign it
                // out, but keep it so the next review can still sign in.
                $this->_helper()->revokeToken($this->_bearer());
                return $this->_ok(array('message' => 'Sample account: you have been signed out. Real accounts are deleted permanently.'));
            }
            try {
                $this->_helper()->deleteAccount($this->_email());
            } catch (Exception $e) {
                return $this->_error(409, $e->getMessage(), 'cannot_delete');
            }
            return $this->_ok(array('message' => 'Your account has been deleted.'));
        });
    }

    protected function _signedIn($email)
    {
        $token = $this->_helper()->issueToken(
            $email,
            (string) $this->_input('platform', ''),
            (string) $this->_input('app_version', '')
        );
        $this->_session = $this->_helper()->sessionForToken($token);
        return $this->_ok(array(
            'token'   => $token,
            'learner' => $this->_profile(),
            'site'    => $this->_helper()->siteInfo(),
        ));
    }

    protected function _profile()
    {
        if ($this->_isDemo()) {
            return Mage::helper('mmd_mobileapi/demo')->profile($this->_email());
        }
        return $this->_helper()->learnerProfile($this->_email());
    }
}
