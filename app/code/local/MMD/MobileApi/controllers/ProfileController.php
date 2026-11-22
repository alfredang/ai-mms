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
            foreach (array('first_name', 'last_name', 'phone', 'theme', 'linkedin_url') as $key) {
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

    /** GET: the signed-in person's picture (JPEG). POST {image: base64} sets it; POST {remove: 1} deletes it. */
    public function avatarAction()
    {
        if (!$this->_requireLearner()) return;
        return $this->_guard(function () {
            $h = $this->_helper();
            if (!$this->getRequest()->isPost()) {
                $bytes = $h->avatarBytes($this->_email());
                if ($bytes === null) {
                    return $this->_error(404, 'No picture yet.', 'no_avatar');
                }
                $this->getResponse()->setHttpResponseCode(200)
                    ->setHeader('Content-Type', 'image/jpeg', true)
                    ->setHeader('Cache-Control', 'private, max-age=86400', true)
                    ->setBody($bytes);
                return $this;
            }
            if ($this->_input('remove')) {
                $h->clearAvatar($this->_email());
            } else {
                $raw = base64_decode((string) $this->_input('image'), true);
                if ($raw === false || $raw === '') {
                    return $this->_error(422, 'Please choose a picture.', 'invalid_avatar');
                }
                try {
                    $h->saveAvatar($this->_email(), $raw);
                } catch (Exception $e) {
                    return $this->_error(422, $e->getMessage(), 'invalid_avatar');
                }
            }
            $profile = $this->_isDemo()
                ? Mage::helper('mmd_mobileapi/demo')->profile($this->_email())
                : $h->learnerProfile($this->_email());
            return $this->_ok(array('learner' => $profile, 'message' => 'Picture updated.'));
        });
    }
}
