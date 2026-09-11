<?php
class MMD_RoleManager_Adminhtml_AiproviderController extends Mage_Adminhtml_Controller_Action
{
    public function saveAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost() || !$this->_validateFormKey() || !$this->_isAllowed()) {
                $this->getResponse()->setHttpResponseCode(403);
                throw new DomainException('An administrator session and valid form key are required.');
            }
            $auth = null;
            if (isset($_FILES['oauth_file']) && $_FILES['oauth_file']['error'] !== UPLOAD_ERR_NO_FILE) {
                $file = $_FILES['oauth_file'];
                if ($file['error'] !== UPLOAD_ERR_OK || $file['size'] > 65536 || !is_uploaded_file($file['tmp_name'])) {
                    throw new DomainException('Upload a valid auth.json file smaller than 64 KB.');
                }
                $auth = file_get_contents($file['tmp_name']);
            }
            Mage::getModel('mmd_rolemanager/aiProvider')->selectProvider((string) $this->getRequest()->getPost('provider'), $auth);
            $result = array('success' => true, 'message' => 'AI provider saved. All AI features now use the selected provider.');
        } catch (DomainException $e) {
            $result['message'] = $e->getMessage();
        } catch (Exception $e) {
            $result['message'] = 'Unable to save the AI connection. The provider was not changed.';
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true)
            ->setHeader('Cache-Control', 'no-store', true)->setBody(json_encode($result));
    }

    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array('admin', 'training_provider'));
    }
}
