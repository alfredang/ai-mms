<?php
require_once Mage::getModuleDir('controllers', 'Mage_Adminhtml') . '/System/AccountController.php';

class MMD_Adminhtml_System_AccountController extends Mage_Adminhtml_System_AccountController
{
    /**
     * The parent gates My Account behind the `system/myaccount` ACL
     * resource, which only Super Admin / Administrators groups grant.
     * That's wrong for this LMS — a Learner / Trainer / Marketing user
     * still has to be able to view and edit their own profile (name,
     * email, password, profile image). Allow any authenticated admin
     * regardless of role group; this only exposes their OWN record,
     * not other users'.
     *
     * @return bool
     */
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isLoggedIn();
    }

    /**
     * Save account without requiring current password.
     * Handles profile fields + image upload.
     */
    public function saveAction()
    {
        $userId = Mage::getSingleton('admin/session')->getUser()->getId();
        $user = Mage::getModel('admin/user')->load($userId);

        // Snapshot the email BEFORE setEmail() rewrites it. If the user
        // changes their email on My Profile, the courses_trainers row
        // is matched by the OLD email (the existing key) — we then
        // re-write that row's email column to the new value so the
        // join stays intact for future saves.
        $oldEmail = strtolower((string) $user->getEmail());

        $user->setId($userId)
            ->setUsername($this->getRequest()->getParam('username', $user->getUsername()))
            ->setFirstname($this->getRequest()->getParam('firstname', false))
            ->setLastname($this->getRequest()->getParam('lastname', false))
            ->setEmail(strtolower($this->getRequest()->getParam('email', false)));

        // Profile fields — saved directly via SQL since core model
        // _beforeSave() only persists a whitelist of fields
        $profileData = array();
        $profileFields = array('tel', 'gender', 'race', 'nationality', 'dob', 'nric_fin', 'linkedin_url', 'trainer_description');
        foreach ($profileFields as $field) {
            $value = $this->getRequest()->getParam($field, null);
            $profileData[$field] = ($value !== '' && $value !== null) ? $value : null;
        }

        // Profile image upload — pushed to Cloudflare R2 so it survives
        // Coolify redeploys (which wipe /media/admin/profile/ because
        // that dir isn't a persistent volume and is .dockerignored from
        // the build context). The full R2 public URL is stored in
        // admin_user.profile_image; the template renderers check for
        // an http(s)://-prefixed value and use it as-is.
        if (isset($_FILES['profile_image']) && $_FILES['profile_image']['name']) {
            try {
                $tmpName    = (string) $_FILES['profile_image']['tmp_name'];
                $clientName = (string) $_FILES['profile_image']['name'];
                $ext        = strtolower(pathinfo($clientName, PATHINFO_EXTENSION));
                $allowed    = array(
                    'jpg'  => 'image/jpeg',
                    'jpeg' => 'image/jpeg',
                    'png'  => 'image/png',
                    'gif'  => 'image/gif',
                );
                if (!isset($allowed[$ext])) {
                    throw new Exception('Only jpg / jpeg / png / gif uploads are allowed.');
                }
                if (!is_uploaded_file($tmpName)) {
                    throw new Exception('Upload failed (not a valid uploaded file).');
                }
                $bytes = @file_get_contents($tmpName);
                if ($bytes === false || $bytes === '') {
                    throw new Exception('Upload appears empty.');
                }
                if (strlen($bytes) > 8 * 1024 * 1024) {
                    throw new Exception('Profile image must be under 8 MB.');
                }

                // Compress before upload — phone photos arrive at several
                // MB but the avatar renders at 90px; downscale + JPEG
                // re-encode cuts a ~1MB PNG to ~30KB. Falls back to the
                // original bytes if GD can't decode the file.
                $compressed = $this->_compressProfileImage($bytes);
                if ($compressed !== null) {
                    $bytes = $compressed;
                    $ext   = 'jpg';
                }

                // R2 key — include user_id + timestamp for cache-busting
                // on re-upload (R2 PUT overwrites by key; a fresh key
                // means the browser fetches the new image even when the
                // CDN cached the old one under the previous URL).
                $r2Key = 'admin/profile/user_' . $userId . '_' . time() . '.' . $ext;
                $r2    = Mage::helper('mmd_courseimage/r2');
                $res   = $r2->putObject($r2Key, $bytes, $allowed[$ext]);
                if (empty($res['url'])) {
                    throw new Exception('R2 putObject returned no url.');
                }
                $profileData['profile_image'] = $res['url'];
            } catch (Exception $e) {
                Mage::logException($e);
                Mage::getSingleton('adminhtml/session')->addError('Image upload failed: ' . $e->getMessage());
            }
        }

        if ($this->getRequest()->getParam('new_password', false)) {
            $user->setNewPassword($this->getRequest()->getParam('new_password', false));
        }
        if ($this->getRequest()->getParam('password_confirmation', false)) {
            $user->setPasswordConfirmation($this->getRequest()->getParam('password_confirmation', false));
        }

        // Skip current password validation
        $result = $user->validate();
        if (is_array($result)) {
            foreach ($result as $error) {
                Mage::getSingleton('adminhtml/session')->addError($error);
            }
            $this->getResponse()->setRedirect($this->getUrl('*/*/'));
            return;
        }

        try {
            $user->save();

            // Save profile fields directly (bypasses model whitelist)
            $resource = Mage::getSingleton('core/resource');
            $write = $resource->getConnection('core_write');
            $write->update(
                $resource->getTableName('admin/user'),
                $profileData,
                'user_id = ' . (int)$userId
            );

            // Mirror My Profile fields into the courses_trainers row
            // that shares this user's email, so the View Trainers grid
            // stays in sync with what the trainer just saved. Silent
            // no-op if no matching row exists by email. Sync field map
            // (admin_user → courses_trainers):
            //   firstname + lastname → title (display name)
            //   tel                  → telephone
            //   gender               → gender
            //   linkedin_url         → linkedin_url
            //   trainer_description  → description
            // Skipped (no equivalent in courses_trainers):
            //   race, dob, nric_fin
            // Skipped (path scheme differs — admin uploads to
            // /media/admin/profile/, trainer uploads to
            // /media/courses/trainers/):
            //   profile_image
            try {
                $trainerSync = array();

                $titleParts = array_filter(array(
                    trim((string) $user->getFirstname()),
                    trim((string) $user->getLastname()),
                ), 'strlen');
                if ($titleParts) {
                    $trainerSync['title'] = implode(' ', $titleParts);
                }
                if (array_key_exists('tel', $profileData)) {
                    $trainerSync['telephone'] = $profileData['tel'];
                }
                if (array_key_exists('gender', $profileData)) {
                    $trainerSync['gender'] = $profileData['gender'];
                }
                if (array_key_exists('linkedin_url', $profileData)) {
                    $trainerSync['linkedin_url'] = $profileData['linkedin_url'];
                }
                if (array_key_exists('trainer_description', $profileData)) {
                    $trainerSync['description'] = $profileData['trainer_description'];
                }

                // If the user changed their email, rewrite the match
                // key on courses_trainers FIRST (using the snapshotted
                // old email), then continue updating the rest of the
                // fields against the new email. Without this step the
                // sync would silently start hitting zero rows.
                $newEmail = strtolower((string) $user->getEmail());
                if ($oldEmail !== '' && $newEmail !== '' && $oldEmail !== $newEmail) {
                    $write->update(
                        $resource->getTableName('courses_trainers'),
                        ['email' => $newEmail],
                        ['email = ?' => $oldEmail]
                    );
                }

                if ($trainerSync) {
                    $write->update(
                        $resource->getTableName('courses_trainers'),
                        $trainerSync,
                        ['email = ?' => $newEmail !== '' ? $newEmail : $oldEmail]
                    );
                }
            } catch (Exception $_syncEx) {
                Mage::logException($_syncEx);
            }

            Mage::getSingleton('adminhtml/session')->addSuccess(
                Mage::helper('adminhtml')->__('The account has been saved.')
            );
        } catch (Mage_Core_Exception $e) {
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
        } catch (Exception $e) {
            // Log the real exception — the user-facing message is
            // intentionally generic, but a swallowed trace makes
            // prod-only failures (e.g. admin_user schema drift)
            // impossible to diagnose. See var/log/exception.log.
            Mage::logException($e);
            Mage::getSingleton('adminhtml/session')->addError(
                Mage::helper('adminhtml')->__('An error occurred while saving account.')
            );
        }
        $this->getResponse()->setRedirect($this->getUrl('*/*/'));
    }

    /**
     * Downscale to max 512px on the longest side and re-encode as JPEG
     * q85, flattening any alpha onto white. Returns null when GD can't
     * decode the bytes (caller then uploads the original untouched).
     *
     * @param string $bytes
     * @return string|null
     */
    protected function _compressProfileImage($bytes)
    {
        if (!function_exists('imagecreatefromstring')) {
            return null;
        }
        $src = @imagecreatefromstring($bytes);
        if (!$src) {
            return null;
        }

        $w = imagesx($src);
        $h = imagesy($src);
        $max = 512;
        $scale = min(1, $max / max($w, $h));
        $nw = max(1, (int) round($w * $scale));
        $nh = max(1, (int) round($h * $scale));

        $dst = imagecreatetruecolor($nw, $nh);
        $white = imagecolorallocate($dst, 255, 255, 255);
        imagefill($dst, 0, 0, $white);
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);
        imagedestroy($src);

        ob_start();
        $ok = imagejpeg($dst, null, 85);
        $out = ob_get_clean();
        imagedestroy($dst);

        return ($ok && $out !== '' && strlen($out) < strlen($bytes)) ? $out : null;
    }
}
