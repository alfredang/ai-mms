<?php
/**
 * Franchisee-side control endpoint — lets the SG Franchise Control Center
 * manage certificate release on a franchisee instance without a partner admin
 * logging in.
 *
 * POST /courses/api_franchise_control
 *   Header: X-API-Key: <mmd/course_sync/api_key>  (same key as course sync)
 *   Body:   op=cert_mode&mode=auto|on_payment
 *             auto        — the daily 18:30 certificate sweep runs
 *                           (mmd/certificate/auto_enabled = 1)
 *             on_payment  — sweep OFF; certificates are only released per class
 *                           when SG confirms the franchise fee was paid
 *           op=release_certs&class_code=C000017
 *             generate + email certificates to every eligible learner of that
 *             class now (same attendance rules as the sweep; idempotent).
 *           op=status — current mode (GET-like, still POST).
 *
 * One-way guarantee: 403 unless MMS_MODE=country, so SG can never be
 * controlled by anyone; only the local (partner) config / certificates change.
 */
class MMD_Courses_Api_Franchise_ControlController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_API_KEY = 'mmd/course_sync/api_key';
    const CERT_ENABLED   = 'mmd/certificate/auto_enabled';
    const LOG_FILE       = 'certificates.log';

    public function indexAction()
    {
        if (strtolower((string) getenv('MMS_MODE')) !== 'country') {
            return $this->_json(403, array('success' => false, 'error' => 'Franchise control is only available on franchisee (country) instances.'));
        }
        if (!$this->getRequest()->isPost()) {
            return $this->_json(405, array('success' => false, 'error' => 'POST required.'));
        }
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('success' => false, 'error' => 'API key not configured (mmd/course_sync/api_key).'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('success' => false, 'error' => 'Invalid or missing X-API-Key.'));
        }

        $op = strtolower(trim((string) $this->getRequest()->getParam('op')));
        try {
            switch ($op) {
                case 'status':
                    return $this->_json(200, array('success' => true, 'mode' => $this->_mode()));

                case 'cert_mode':
                    $mode = strtolower(trim((string) $this->getRequest()->getParam('mode')));
                    if (!in_array($mode, array('auto', 'on_payment'), true)) {
                        return $this->_json(400, array('success' => false, 'error' => 'mode must be auto or on_payment.'));
                    }
                    Mage::getConfig()->saveConfig(self::CERT_ENABLED, $mode === 'auto' ? 1 : 0, 'default', 0);
                    Mage::getConfig()->reinit();
                    Mage::app()->cleanCache(array(Mage_Core_Model_Config::CACHE_TAG));
                    Mage::log('Franchise control: certificate mode set to ' . $mode . ' by SG control center.', Zend_Log::INFO, self::LOG_FILE, true);
                    return $this->_json(200, array('success' => true, 'mode' => $mode));

                case 'release_certs':
                    $classCode = strtoupper(trim((string) $this->getRequest()->getParam('class_code')));
                    if ($classCode === '') {
                        return $this->_json(400, array('success' => false, 'error' => 'class_code required.'));
                    }
                    return $this->_json(200, array_merge(array('success' => true, 'class_code' => $classCode), $this->_release($classCode)));

                default:
                    return $this->_json(400, array('success' => false, 'error' => 'Unknown op — use status, cert_mode or release_certs.'));
            }
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, array('success' => false, 'error' => $e->getMessage()));
        }
    }

    protected function _mode()
    {
        return Mage::getStoreConfigFlag(self::CERT_ENABLED) ? 'auto' : 'on_payment';
    }

    /** Issue + email a certificate to every eligible learner of the class. */
    protected function _release($classCode)
    {
        @set_time_limit(0);
        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $runId = (int) $read->fetchOne('SELECT run_id FROM course_runs WHERE class_id = ? LIMIT 1', array($classCode));
        if (!$runId) throw new Exception('Class ' . $classCode . ' not found on this site.');

        /** @var MMD_Certificate_Helper_Data $h */
        $h   = Mage::helper('mmd_certificate');
        $run = $h->loadRun($runId);
        if (!$run) throw new Exception('Class ' . $classCode . ' could not be loaded.');

        $sent = 0; $skipped = 0; $errors = 0; $msgs = array();
        $learners = $h->getEligibleLearners($runId, $run);
        foreach ($learners as $learner) {
            try {
                $r = $h->issueAndSend($run, $learner, null);
                if ($r['status'] === 'sent') $sent++;
                elseif ($r['status'] === 'skipped') $skipped++;
                else { $errors++; if (!empty($r['message'])) $msgs[] = $r['message']; }
            } catch (Exception $e) {
                $errors++; $msgs[] = $e->getMessage();
            }
        }
        $already = (int) $read->fetchOne(
            "SELECT COUNT(*) FROM mmd_course_run_certificate WHERE run_id = ? AND status IN ('issued','sent')", array($runId)
        );
        Mage::log("Franchise control: released certificates for $classCode — sent:$sent skipped:$skipped errors:$errors", Zend_Log::INFO, self::LOG_FILE, true);
        return array('eligible' => count($learners), 'sent' => $sent, 'skipped' => $skipped, 'errors' => $errors,
                     'issued_total' => $already, 'messages' => array_slice($msgs, 0, 5));
    }

    private function _json($code, array $data)
    {
        $this->getResponse()->setHttpResponseCode($code)->setHeader('Content-Type', 'application/json', true)->setBody(json_encode($data));
    }
}
