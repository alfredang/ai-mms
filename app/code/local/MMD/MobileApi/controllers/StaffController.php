<?php
/**
 * Staff dashboards for the native apps: one glanceable screen per staff role
 * (Admin, Marketing, Developer, Franchise Admin). Read-only. The reply is a
 * list of cards and short lists the app renders as-is, so a dashboard can
 * change here without an app release.
 */
class MMD_MobileApi_StaffController extends MMD_MobileApi_Controller_Base
{
    public function dashboardAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $role = (string) $this->_input('role');
            // The role must be one this account holds on the website; the app's
            // "View as" picker is a convenience, this is the gate.
            if ($this->_isDemo() || !in_array($role, $this->_helper()->staffRoles($this->_email()), true)) {
                return $this->_error(403, 'This account does not have that role.', 'not_staff');
            }
            return $this->_ok(Mage::helper('mmd_mobileapi/staff')->dashboard($role));
        });
    }
}
