<?php
/**
 * Direct image-upload endpoint for the Course Details "Image URL Link" field.
 *
 * Flow: admin clicks "Upload" beside Image URL Link → file POSTed here →
 * file is saved into media/catalog/product/<a>/<b>/<filename> using Magento's
 * standard dispersion + image validation → JSON { success, url } returned →
 * client fills the Image URL Link input with the URL.
 *
 * The course_image_url attribute itself is NOT written here; the existing
 * CoursesaveController save flow handles that when the user clicks Save Changes.
 * That keeps this endpoint additive — the page works unchanged if the upload
 * fails or the new UI is disabled.
 */
class MMD_RoleManager_Adminhtml_CourseimageController extends Mage_Adminhtml_Controller_Action
{
    public function uploadAction()
    {
        $result = ['success' => false];
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            if (empty($_FILES['image']) || empty($_FILES['image']['name'])) {
                throw new Exception('No file uploaded');
            }

            $uploader = Mage::getModel('core/file_uploader', 'image');
            $uploader->setAllowedExtensions(Varien_Io_File::ALLOWED_IMAGES_EXTENSIONS);
            $uploader->addValidateCallback(
                'catalog_product_image',
                Mage::helper('catalog/image'),
                'validateUploadFile'
            );
            $uploader->setAllowRenameFiles(true);
            $uploader->setFilesDispersion(true);
            $uploader->addValidateCallback(
                Mage_Core_Model_File_Validator_Image::NAME,
                Mage::getModel('core/file_validator_image'),
                'validate'
            );

            $mediaConfig = Mage::getSingleton('catalog/product_media_config');
            $saved = $uploader->save($mediaConfig->getBaseMediaPath());

            if (empty($saved['file'])) {
                throw new Exception('Upload failed');
            }

            $relative = str_replace(DS, '/', $saved['file']);
            $url      = $mediaConfig->getMediaUrl($relative);

            $result['success'] = true;
            $result['url']     = $url;
            $result['file']    = $relative;
        } catch (Exception $e) {
            $result['success'] = false;
            $result['message'] = $e->getMessage();
        }

        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
    }

    protected function _isAllowed()
    {
        // Same gate as CoursesaveController — anyone who can edit a course
        // can upload its image.
        return Mage::helper('mmd_rolemanager')->isRoleAllowed([
            'training_provider', 'admin', 'developer', 'trainer',
        ]);
    }
}
