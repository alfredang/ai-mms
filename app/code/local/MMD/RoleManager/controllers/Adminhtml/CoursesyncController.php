<?php
/**
 * Admin actions for syncing courses from SG (country instances only).
 * Sync is MANUAL ONLY — triggered by a human from these actions; the daily
 * auto-sync cron was removed 2026-07-06 by owner decision.
 *  - pull      : manual bulk sync now (JSON summary)
 *  - pullOne   : sync a single C-prefix course by SKU (JSON summary)
 *  - saveConfig: store SG URL + API key
 */
class MMD_RoleManager_Adminhtml_CoursesyncController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array('admin', 'developer'));
    }

    public function pullAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            if (strtolower((string) getenv('MMS_MODE')) !== 'country') {
                throw new Exception('Course sync is only available in country mode.');
            }

            /** @var MMD_RoleManager_Model_CourseSyncService $svc */
            $svc = Mage::getModel('mmd_rolemanager/courseSyncService');
            if (!$svc->isConfigured()) throw new Exception('Set the SG Sync URL and API key first.');

            $user = Mage::getSingleton('admin/session')->getUser();
            $name = $user ? trim($user->getFirstname() . ' ' . $user->getLastname()) : '';
            $who  = $name !== '' ? $name : ($user ? (string)$user->getEmail() : 'admin');
            $res  = $svc->pull($who);
            $this->_json(array_merge(array('success' => $res['success']), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    public function pullOneAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            if (strtolower((string) getenv('MMS_MODE')) !== 'country') {
                throw new Exception('Course sync is only available in country mode.');
            }

            /** @var MMD_RoleManager_Model_CourseSyncService $svc */
            $svc = Mage::getModel('mmd_rolemanager/courseSyncService');
            if (!$svc->isConfigured()) throw new Exception('Set the SG Sync URL and API key first.');

            $sku = trim((string) $this->getRequest()->getParam('sku'));

            $user = Mage::getSingleton('admin/session')->getUser();
            $name = $user ? trim($user->getFirstname() . ' ' . $user->getLastname()) : '';
            $who  = $name !== '' ? $name : ($user ? (string)$user->getEmail() : 'admin');
            $res  = $svc->pullOne($sku, $who);
            $this->_json(array_merge(array('success' => $res['success']), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    public function pullCoursewareOneAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            if (strtolower((string) getenv('MMS_MODE')) !== 'country') {
                throw new Exception('Course sync is only available in country mode.');
            }

            /** @var MMD_RoleManager_Model_CourseSyncService $svc */
            $svc = Mage::getModel('mmd_rolemanager/courseSyncService');
            if (!$svc->isConfigured()) throw new Exception('Set the SG Sync URL and API key first.');

            $sku = trim((string) $this->getRequest()->getParam('sku'));

            $user = Mage::getSingleton('admin/session')->getUser();
            $name = $user ? trim($user->getFirstname() . ' ' . $user->getLastname()) : '';
            $who  = $name !== '' ? $name : ($user ? (string)$user->getEmail() : 'admin');
            $res  = $svc->pullCoursewareOne($sku, $who);
            $this->_json(array_merge(array('success' => $res['success']), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    public function saveConfigAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            $url = trim((string) $this->getRequest()->getParam('sg_url'));
            $key = trim((string) $this->getRequest()->getParam('api_key'));
            Mage::getConfig()->saveConfig('mmd/course_sync/sg_url', $url, 'default', 0);
            if ($key !== '') {
                Mage::getConfig()->saveConfig('mmd/course_sync/api_key', $key, 'default', 0);
            }
            Mage::getConfig()->reinit();
            $this->_json(array('success' => true, 'message' => 'Course sync settings saved.'));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    protected function _json(array $data)
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true)->setBody(json_encode($data));
    }
}
