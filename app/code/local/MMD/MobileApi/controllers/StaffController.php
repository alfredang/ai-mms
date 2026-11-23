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

    /** GET ?role=admin[&from=&to=] — the admin home lists, or a calendar range. */
    public function classesAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            if (!$this->_holds(array('admin', 'franchise_admin'))) {
                return $this->_error(403, 'This account does not have that role.', 'not_staff');
            }
            return $this->_ok(Mage::helper('mmd_mobileapi/staff')->adminClasses(
                (string) $this->_input('from', ''), (string) $this->_input('to', '')));
        });
    }

    /** GET ?role=developer — every non-WSQ course with its upcoming classes. */
    public function coursesAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            if (!$this->_holds(array('developer', 'admin'))) {
                return $this->_error(403, 'This account does not have that role.', 'not_staff');
            }
            return $this->_ok(Mage::helper('mmd_mobileapi/staff')->developerCourses());
        });
    }

    /** GET ?role=developer&id= — one course as the admin Edit Course page holds it (read-only). */
    public function courseAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            if (!$this->_holds(array('developer', 'admin'))) {
                return $this->_error(403, 'This account does not have that role.', 'not_staff');
            }
            $course = Mage::helper('mmd_mobileapi/staff')->developerCourse((int) $this->_input('id'));
            if ($course === null) {
                return $this->_error(404, 'Course not found.', 'no_course');
            }
            return $this->_ok($course);
        });
    }

    /** The requested role is one of $allowed and one this account holds on the website. */
    protected function _holds(array $allowed)
    {
        $role = (string) $this->_input('role');
        return !$this->_isDemo() && in_array($role, $allowed, true)
            && in_array($role, $this->_helper()->staffRoles($this->_email()), true);
    }
}
