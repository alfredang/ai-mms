<?php
/**
 * Franchise Control Center — Franchise Admin role (SG control site only).
 *
 * Sections (?section=, mirrored in the Franchise Admin sidebar), all rendered
 * by rolemanager/franchise-report.phtml:
 *  - ''           Control Center: KPIs, per-franchise weekly stats, aggregate
 *                 charts (filter by franchise / week / month), class ledger
 *  - completed    Completed classes pulled from MY/GH (legacy weekly report)
 *  - fees         Fees & Payments ledger (GH: USD per billable learner per
 *                 delivered class; MY: no fee) + fee settings
 *  - courses | categories | schedules   one-way SG -> franchisee syncs
 *  - settings     Partner connection settings (URL + API key)
 *
 * JSON actions: pull (completed classes), pullStats (control center data),
 * sync, saveConfig, markFee. Traffic is strictly one-way SG -> partner:
 * partners are only ever GET-read or told to run their own pull-from-SG.
 */
class MMD_RoleManager_Adminhtml_FranchisereportController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array('franchise_admin'));
    }

    public static function sectionTitles()
    {
        return array(
            ''           => 'Franchise Control Center',
            'completed'  => 'Completed Classes',
            'fees'       => 'Fees & Payments',
            'courses'    => 'Course Sync',
            'categories' => 'Category Sync',
            'schedules'  => 'Schedule Sync',
            'settings'   => 'Partner Settings',
        );
    }

    public function indexAction()
    {
        $titles  = self::sectionTitles();
        $section = strtolower(trim((string) $this->getRequest()->getParam('section')));
        if (!isset($titles[$section])) $section = '';

        $this->loadLayout();
        $this->_title($titles[$section]);
        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/franchise-report.phtml')
            ->setData('section', $section);
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    /** Pull completed classes (legacy weekly report) from the partners. */
    public function pullAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            /** @var MMD_RoleManager_Model_FranchiseReportService $svc */
            $svc = Mage::getModel('mmd_rolemanager/franchiseReportService');
            if (!$svc->isConfigured()) {
                return $this->_json(array(
                    'success' => false,
                    'needs_config' => true,
                    'message' => 'Not connected yet — add a partner URL and API key in Partner Settings, then Pull Now.',
                ));
            }
            $res = $svc->pullAll($this->_who());
            $this->_json(array_merge(array('success' => $res['success']), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /** Collect control-center stats: SG locally + every configured partner. */
    public function pullStatsAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            @set_time_limit(0);
            $res = Mage::getModel('mmd_rolemanager/franchiseStatsService')->pullAll($this->_who());
            $this->_json(array_merge(array('success' => $res['success']), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /**
     * Trigger a sync on ONE partner: partner=my|gh, op=courses|categories|schedules.
     * SG-only; the partner-side endpoint independently refuses to run outside
     * country mode, so traffic can only ever flow SG -> franchisee.
     */
    public function syncAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            if (strtolower((string) getenv('MMS_MODE')) === 'country') {
                throw new Exception('Franchise sync is only available on the SG instance.');
            }
            $partner = strtolower(trim((string) $this->getRequest()->getParam('partner')));
            if (!in_array($partner, array('my', 'gh'), true)) {
                throw new Exception('Unknown partner — use my or gh.');
            }
            $op = strtolower(trim((string) $this->getRequest()->getParam('op')));
            @set_time_limit(0); // partner course sync can take minutes

            /** @var MMD_RoleManager_Model_FranchiseSyncService $svc */
            $svc = Mage::getModel('mmd_rolemanager/franchiseSyncService');
            $res = $svc->trigger($partner, $op, $this->_who());
            $this->_json(array_merge(array('success' => !empty($res['success']), 'partner' => strtoupper($partner)), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /** Partner connection (URL + key) and fee settings. */
    public function saveConfigAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            $cfg = Mage::getConfig();
            foreach (array('my', 'gh') as $cc) {
                if ($this->getRequest()->has($cc . '_url')) {
                    $cfg->saveConfig('mmd/franchise_report/' . $cc . '_url', trim((string) $this->getRequest()->getParam($cc . '_url')), 'default', 0);
                }
                $key = trim((string) $this->getRequest()->getParam($cc . '_key'));
                if ($key !== '') { // blank = keep the stored key
                    $cfg->saveConfig('mmd/franchise_report/' . $cc . '_key', $key, 'default', 0);
                }
                if ($this->getRequest()->has($cc . '_per_learner')) {
                    $fee = round(max(0, (float) $this->getRequest()->getParam($cc . '_per_learner')), 2);
                    $cur = strtoupper(preg_replace('/[^A-Za-z]/', '', (string) $this->getRequest()->getParam($cc . '_currency')));
                    $cfg->saveConfig('mmd/franchise_fee/' . $cc . '_per_learner', (string) $fee, 'default', 0);
                    $cfg->saveConfig('mmd/franchise_fee/' . $cc . '_currency', $cur !== '' ? substr($cur, 0, 3) : 'USD', 'default', 0);
                }
            }
            $cfg->reinit();
            $pushed = array();
            foreach (array('my', 'gh') as $cc) {
                if ($this->getRequest()->has($cc . '_cert_mode')) {
                    $mode = strtolower(trim((string) $this->getRequest()->getParam($cc . '_cert_mode')));
                    try {
                        Mage::getModel('mmd_rolemanager/franchiseControlService')->setMode($cc, $mode);
                        $pushed[] = strtoupper($cc) . ': certificate mode "' . ($mode === 'auto' ? 'auto-send 18:30' : 'after payment') . '" applied on the franchisee site.';
                    } catch (Exception $e) {
                        // Mode is stored on SG regardless; the push is retried on the next save.
                        $pushed[] = strtoupper($cc) . ': saved on SG, but the franchisee did not accept it — ' . $e->getMessage();
                    }
                }
            }
            $fees = 0;
            if ($this->getRequest()->has('my_per_learner') || $this->getRequest()->has('gh_per_learner')) {
                $fees = Mage::getModel('mmd_rolemanager/franchiseStatsService')->refreshFees();
            }
            $this->_json(array('success' => true, 'message' => trim('Settings saved.' . ($fees ? " Fee ledger refreshed ($fees classes)." : '') . ($pushed ? "\n" . implode("\n", $pushed) : '')), 'fees' => $fees));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /** Set one class fee row to pending / completed. Params: id, status, note. */
    public function markFeeAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            $id     = (int) $this->getRequest()->getParam('id');
            $status = strtolower(trim((string) $this->getRequest()->getParam('status')));
            $note   = substr(trim((string) $this->getRequest()->getParam('note')), 0, 255);
            if ($id <= 0 || !in_array($status, array('pending', 'completed'), true)) {
                throw new Exception('Invalid fee row or status.');
            }
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');
            $n = $write->update('mmd_franchise_class_fee', array(
                'status'  => $status,
                'paid_at' => $status === 'completed' ? Mage::getModel('core/date')->gmtDate() : null,
                'paid_by' => $status === 'completed' ? $this->_who() : null,
                'note'    => $note !== '' ? $note : null,
            ), array('id = ?' => $id));
            if (!$n) throw new Exception('Fee row not found.');
            $row = $write->fetchRow('SELECT * FROM mmd_franchise_class_fee WHERE id = ?', array($id));
            $msg = $status === 'completed' ? 'Marked as paid.' : 'Reverted to pending.';
            // Pay-to-release: a franchisee on "after payment" mode gets this
            // class's certificates generated + emailed the moment it is paid.
            if ($status === 'completed' && Mage::getModel('mmd_rolemanager/franchiseControlService')->mode($row['source_country']) === 'on_payment') {
                $msg .= ' ' . $this->_releaseCerts($row);
                $row = $write->fetchRow('SELECT * FROM mmd_franchise_class_fee WHERE id = ?', array($id));
            }
            $this->_json(array('success' => true, 'row' => $row, 'message' => $msg));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /** Retry the certificate release for one paid class (fees page button). */
    public function releaseCertsAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            $id  = (int) $this->getRequest()->getParam('id');
            $row = Mage::getSingleton('core/resource')->getConnection('core_read')->fetchRow('SELECT * FROM mmd_franchise_class_fee WHERE id = ?', array($id));
            if (!$row) throw new Exception('Fee row not found.');
            if ($row['status'] !== 'completed') throw new Exception('Mark the class fee as paid first.');
            $this->_json(array('success' => true, 'message' => $this->_releaseCerts($row)));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /** Tell the franchisee to release the class certificates; record the outcome on the fee row. */
    protected function _releaseCerts(array $feeRow)
    {
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        try {
            $r = Mage::getModel('mmd_rolemanager/franchiseControlService')->releaseCerts($feeRow['source_country'], $feeRow['class_code']);
            $note = sprintf('Certificates released: %d sent, %d already issued, %d errors (%d eligible).',
                (int) ($r['sent'] ?? 0), (int) ($r['skipped'] ?? 0), (int) ($r['errors'] ?? 0), (int) ($r['eligible'] ?? 0));
            if (!empty($r['messages'])) $note .= ' ' . implode(' | ', (array) $r['messages']);
            $write->update('mmd_franchise_class_fee', array('certs_released_at' => Mage::getModel('core/date')->gmtDate(), 'certs_note' => substr($note, 0, 255)), array('id = ?' => (int) $feeRow['id']));
            return $note;
        } catch (Exception $e) {
            $note = 'Certificate release FAILED: ' . $e->getMessage();
            $write->update('mmd_franchise_class_fee', array('certs_note' => substr($note, 0, 255)), array('id = ?' => (int) $feeRow['id']));
            return $note;
        }
    }

    protected function _who()
    {
        $user = Mage::getSingleton('admin/session')->getUser();
        $name = $user ? trim($user->getFirstname() . ' ' . $user->getLastname()) : '';
        return $name !== '' ? $name : 'admin';
    }

    protected function _json(array $data)
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true)->setBody(json_encode($data));
    }
}
