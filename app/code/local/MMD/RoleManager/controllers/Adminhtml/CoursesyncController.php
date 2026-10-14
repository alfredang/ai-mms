<?php
/**
 * Admin actions for syncing courses from SG (country instances only).
 * Sync is MANUAL ONLY — triggered by a human from these actions; the daily
 * auto-sync cron was removed 2026-07-06 by owner decision.
 *  - pull      : manual bulk sync now (JSON summary)
 *  - pullOne   : sync a single C-prefix course by SKU (JSON summary)
 *  - saveConfig: store SG URL + API key
 * On the Malaysia site pull / pullOne only create a dry run (MMD_RoleManager_Model_Sync_MalaysiaSync);
 * planCategories / report / apply / rollback complete the review -> apply -> rollback flow.
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

            $who  = $this->_who();
            $res  = MMD_RoleManager_Model_Sync_MalaysiaSync::isActive()
                ? Mage::getModel('mmd_rolemanager/sync_malaysiaSync')->planCourses($who)   // dry run only
                : $svc->pull($who);
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

            $who  = $this->_who();
            $res  = MMD_RoleManager_Model_Sync_MalaysiaSync::isActive()
                ? Mage::getModel('mmd_rolemanager/sync_malaysiaSync')->planCourses($who, $sku)   // dry run only
                : $svc->pullOne($sku, $who);
            $this->_json(array_merge(array('success' => $res['success']), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    // ---- Malaysia-aware sync: dry run -> review -> apply -> (rollback) ----

    /** Dry run of the SG category tree (Malaysia only). */
    public function planCategoriesAction()
    {
        $this->_malaysiaAction(function ($svc, $who) {
            return $svc->planCategories($who);
        });
    }

    public function applyAction()
    {
        $this->_malaysiaAction(function ($svc, $who, $runId) {
            return array('success' => true, 'run_id' => $runId) + $svc->apply($runId, $who);
        });
    }

    public function rollbackAction()
    {
        $this->_malaysiaAction(function ($svc, $who, $runId) {
            return array('success' => true, 'run_id' => $runId) + $svc->rollback($runId, $who);
        });
    }

    /** Dry-run / audit report of one run (HTML, opens in a new tab). */
    public function reportAction()
    {
        if (!MMD_RoleManager_Model_Sync_MalaysiaSync::isActive()) {
            $this->norouteAction();
            return;
        }
        $block = $this->getLayout()->createBlock('adminhtml/template')
            ->setTemplate('rolemanager/my-sync-report.phtml')
            ->setRunId((int) $this->getRequest()->getParam('run_id'));
        $this->getResponse()->setBody($block->toHtml());
    }

    protected function _malaysiaAction($fn)
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            if (!MMD_RoleManager_Model_Sync_MalaysiaSync::isActive()) {
                throw new Exception('The Malaysia-aware sync is only available on the Malaysia site.');
            }
            @set_time_limit(0);
            $svc = Mage::getModel('mmd_rolemanager/sync_malaysiaSync');
            $this->_json($fn($svc, $this->_who(), (int) $this->getRequest()->getParam('run_id')));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    protected function _who()
    {
        $user = Mage::getSingleton('admin/session')->getUser();
        $name = $user ? trim($user->getFirstname() . ' ' . $user->getLastname()) : '';
        return $name !== '' ? $name : ($user ? (string) $user->getEmail() : 'admin');
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
