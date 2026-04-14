<?php
require_once Mage::getModuleDir('controllers', 'Mage_Adminhtml') . '/System/AccountController.php';

class MMD_Adminhtml_System_AccountController extends Mage_Adminhtml_System_AccountController
{
    /**
     * Save account without requiring current password.
     * Handles profile fields + image upload.
     */
    public function saveAction()
    {
        $userId = Mage::getSingleton('admin/session')->getUser()->getId();
        $user = Mage::getModel('admin/user')->load($userId);

        $user->setId($userId)
            ->setUsername($this->getRequest()->getParam('username', $user->getUsername()))
            ->setFirstname($this->getRequest()->getParam('firstname', false))
            ->setLastname($this->getRequest()->getParam('lastname', false))
            ->setEmail(strtolower($this->getRequest()->getParam('email', false)));

        // Profile fields — saved directly via SQL since core model
        // _beforeSave() only persists a whitelist of fields
        $profileData = array();
        $profileFields = array('tel', 'gender', 'race', 'dob', 'nric_fin', 'linkedin_url');
        foreach ($profileFields as $field) {
            $value = $this->getRequest()->getParam($field, null);
            $profileData[$field] = ($value !== '' && $value !== null) ? $value : null;
        }

        // Profile image upload
        if (isset($_FILES['profile_image']) && $_FILES['profile_image']['name']) {
            try {
                $uploader = new Varien_File_Uploader('profile_image');
                $uploader->setAllowedExtensions(array('jpg', 'jpeg', 'png', 'gif'));
                $uploader->setAllowRenameFiles(true);
                $uploader->setFilesDispersion(false);

                $path = Mage::getBaseDir('media') . DS . 'admin' . DS . 'profile';
                $filename = 'user_' . $userId . '_' . time() . '.' . pathinfo($_FILES['profile_image']['name'], PATHINFO_EXTENSION);
                $uploader->save($path, $filename);

                // Delete old image
                $resource = Mage::getSingleton('core/resource');
                $oldImage = $resource->getConnection('core_read')->fetchOne(
                    'SELECT profile_image FROM ' . $resource->getTableName('admin/user') . ' WHERE user_id = ?',
                    array($userId)
                );
                if ($oldImage) {
                    $oldPath = $path . DS . $oldImage;
                    if (file_exists($oldPath)) {
                        @unlink($oldPath);
                    }
                }

                $profileData['profile_image'] = $filename;
            } catch (Exception $e) {
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

            Mage::getSingleton('adminhtml/session')->addSuccess(
                Mage::helper('adminhtml')->__('The account has been saved.')
            );
        } catch (Mage_Core_Exception $e) {
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
        } catch (Exception $e) {
            Mage::getSingleton('adminhtml/session')->addError(
                Mage::helper('adminhtml')->__('An error occurred while saving account.')
            );
        }
        $this->getResponse()->setRedirect($this->getUrl('*/*/'));
    }
}
