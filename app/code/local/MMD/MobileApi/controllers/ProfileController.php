<?php
/**
 * The signed-in person's own profile: name, phone and appearance (System /
 * Light / Dark). GET reads it, POST changes the keys that are sent.
 */
class MMD_MobileApi_ProfileController extends MMD_MobileApi_Controller_Base
{
    public function indexAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $demo = Mage::helper('mmd_mobileapi/demo');
            if (!$this->getRequest()->isPost()) {
                return $this->_ok(array('learner' => $this->_isDemo()
                    ? $demo->profile($this->_email())
                    : $this->_helper()->learnerProfile($this->_email())));
            }
            $in = array();
            foreach (array('first_name', 'last_name', 'phone', 'theme') as $key) {
                $v = $this->_input($key);
                if ($v !== null) $in[$key] = $v;
            }
            try {
                $profile = $this->_isDemo()
                    ? $demo->saveProfile($this->_email(), $in)
                    : $this->_helper()->saveProfile($this->_email(), $in);
            } catch (Exception $e) {
                return $this->_error(422, $e->getMessage(), 'invalid_profile');
            }
            return $this->_ok(array('learner' => $profile, 'message' => 'Profile updated.'));
        });
    }
}
