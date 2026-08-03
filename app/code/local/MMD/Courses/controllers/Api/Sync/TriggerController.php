<?php
/**
 * Country-side sync trigger endpoint — lets the SG Franchise Management page
 * kick off a sync ON a franchisee instance without a partner admin logging in.
 *
 * POST /courses/api_sync_trigger
 *   Header: X-API-Key: <mmd/course_sync/api_key>  (same key as course sync)
 *   Body:   op=courses | categories | schedules
 *
 * One-way traffic guarantee (SG -> partner, never back):
 *   - 403 unless MMS_MODE=country, so the SG instance can never be triggered.
 *   - Every op only READS from SG's /courses/api_sync_export* endpoints and
 *     writes into the LOCAL (partner) DB. Nothing here can touch SG's data.
 *
 * Ops:
 *   courses    — MMD_RoleManager_Model_CourseSyncService::pull() (full course
 *                import; P1 partner-owned fields preserved on update)
 *   categories — MMD_RoleManager_Model_CategorySyncService::pull() (mirror the
 *                SG category tree)
 *   schedules  — MMD_RoleManager_Model_CourseSyncService::syncSchedules()
 *                (replace local Course Date/Time custom options with SG's)
 *
 * Runs synchronously — a full course sync can take minutes; the SG caller
 * uses a long curl timeout. Results are also written to mmd_course_sync_log
 * locally, so a dropped connection never loses the outcome.
 */
class MMD_Courses_Api_Sync_TriggerController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_API_KEY = 'mmd/course_sync/api_key';

    public function indexAction()
    {
        // Mode guard: only franchisee (country) instances accept triggers.
        if (strtolower((string) getenv('MMS_MODE')) !== 'country') {
            return $this->_json(403, array('success' => false, 'error' => 'Sync trigger is only available on franchisee (country) instances.'));
        }

        if (!$this->getRequest()->isPost()) {
            return $this->_json(405, array('success' => false, 'error' => 'POST required.'));
        }

        // Auth — same X-API-Key contract as /courses/api_sync_export
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('success' => false, 'error' => 'API key not configured (mmd/course_sync/api_key).'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('success' => false, 'error' => 'Invalid or missing X-API-Key.'));
        }

        $op = strtolower(trim((string) $this->getRequest()->getParam('op')));
        if (!in_array($op, array('courses', 'categories', 'schedules'), true)) {
            return $this->_json(400, array('success' => false, 'error' => 'Unknown op — use courses, categories or schedules.'));
        }

        @set_time_limit(0);
        @ignore_user_abort(true);

        try {
            switch ($op) {
                case 'courses':
                    /** @var MMD_RoleManager_Model_CourseSyncService $svc */
                    $svc = Mage::getModel('mmd_rolemanager/courseSyncService');
                    if (!$svc->isConfigured()) {
                        return $this->_json(503, array('success' => false, 'error' => 'This site has no SG sync URL / API key configured yet.'));
                    }
                    $res = $svc->pull('SG remote trigger');
                    break;
                case 'categories':
                    /** @var MMD_RoleManager_Model_CategorySyncService $svc */
                    $svc = Mage::getModel('mmd_rolemanager/categorySyncService');
                    if (!$svc->isConfigured()) {
                        return $this->_json(503, array('success' => false, 'error' => 'This site has no SG sync URL / API key configured yet.'));
                    }
                    $res = $svc->pull('SG remote trigger');
                    break;
                default: // schedules
                    /** @var MMD_RoleManager_Model_CourseSyncService $svc */
                    $svc = Mage::getModel('mmd_rolemanager/courseSyncService');
                    if (!$svc->isConfigured()) {
                        return $this->_json(503, array('success' => false, 'error' => 'This site has no SG sync URL / API key configured yet.'));
                    }
                    $res = $svc->syncSchedules('SG remote trigger');
            }
            $this->_json(200, array_merge(array('success' => !empty($res['success']), 'op' => $op), $res));
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_json(500, array('success' => false, 'op' => $op, 'error' => $e->getMessage()));
        }
    }

    private function _json($code, array $data)
    {
        $this->getResponse()
            ->setHttpResponseCode($code)
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($data));
    }
}
