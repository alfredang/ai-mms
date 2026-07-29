<?php
/**
 * Manual attendance — per-class, MMS-DB-native.
 *
 * Roster comes from course_run_enrolments (+ walk-ins added on the fly).
 * Attendance is stored one row per (run_id, learner_email) in
 * mmd_course_run_attendance. No SSG / NRIC — learner identity is email.
 */
class MMD_Attendance_Adminhtml_AttendanceController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_attendance')->isAllowed();
    }

    /**
     * Skip Magento's form-key check for the AJAX actions. They POST a JSON
     * body, so `form_key` lives inside the JSON and is NOT visible to the
     * default _validateFormKey() (which reads $_GET/$_POST) — that mismatch
     * triggered a 302 redirect to HTML, surfacing as a "network error" when
     * the JS tried response.json(). CSRF is still covered by the admin URL's
     * secret /key/<hash>/ segment (same approach as MMD TrainerController /
     * CoursesaveController).
     */
    protected function _validateFormKey()
    {
        return true;
    }

    public function indexAction()
    {
        $this->loadLayout()
             ->_title($this->__('Attendance'))->_title($this->__('E-Attendance'));
        $this->renderLayout();
    }

    /**
     * GET JSON — roster + saved attendance for a run.
     * params: run_id
     */
    public function loadAction()
    {
        try {
            $runId = (int) $this->getRequest()->getParam('run_id');
            if (!$runId) {
                throw new Exception('run_id is required');
            }

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $runsTbl  = $resource->getTableName('course_runs');
            $enrolTbl = $resource->getTableName('course_run_enrolments');
            $attTbl   = $resource->getTableName('mmd_course_run_attendance');

            $run = $read->fetchRow(
                "SELECT run_id, class_id, course_sku, product_id,
                        course_start_date, course_end_date
                   FROM `$runsTbl` WHERE run_id = ?",
                array($runId)
            );
            if (!$run) {
                throw new Exception('Class not found.');
            }

            $helper   = Mage::helper('mmd_attendance');
            $sessions = $helper->sessionsForRun($run);

            // Roster = enrolments UNION walk-in attendance rows not in enrolments.
            // WSQ (TGS-) classes have no materialised enrolments (the class-
            // formation cron skips TGS SKUs) — fall back to the order history,
            // which IS the registration record.
            $enrol = $read->fetchAll(
                "SELECT learner_name, learner_email FROM `$enrolTbl`
                  WHERE run_id = ? ORDER BY learner_name",
                array($runId)
            );
            if (empty($enrol)) {
                $enrol = $helper->orderRosterForRun($run);
            }
            $att = $read->fetchAll(
                "SELECT learner_email, session_key, learner_name, is_present, reason_of_absence, is_walkin
                   FROM `$attTbl` WHERE run_id = ?",
                array($runId)
            );
            // attByEmail[email] = ['name'=>…, 'is_walkin'=>…, 'att'=>[session_key=>['p'=>…,'r'=>…]]]
            $attByEmail = array();
            foreach ($att as $a) {
                $key = strtolower((string)$a['learner_email']);
                if ($key === '') continue;
                if (!isset($attByEmail[$key])) {
                    $attByEmail[$key] = array(
                        'name'      => (string)$a['learner_name'],
                        'is_walkin' => 0,
                        'att'       => array(),
                    );
                }
                if ((int)$a['is_walkin'] === 1) $attByEmail[$key]['is_walkin'] = 1;
                $attByEmail[$key]['att'][(string)$a['session_key']] = array(
                    'p' => (int)$a['is_present'],
                    'r' => (string)$a['reason_of_absence'],
                );
            }

            $roster = array();
            $seen   = array();
            foreach ($enrol as $e) {
                $key = strtolower((string)$e['learner_email']);
                if ($key === '' || isset($seen[$key])) continue;
                $seen[$key] = true;
                $a = isset($attByEmail[$key]) ? $attByEmail[$key] : null;
                $roster[] = array(
                    'learner_name'  => $e['learner_name'],
                    'learner_email' => $e['learner_email'],
                    'is_walkin'     => 0,
                    'att'           => $a ? $a['att'] : new stdClass(),
                );
            }
            // Walk-ins recorded in attendance but absent from enrolments.
            foreach ($attByEmail as $key => $a) {
                if (isset($seen[$key])) continue;
                $seen[$key] = true;
                $roster[] = array(
                    'learner_name'  => $a['name'],
                    'learner_email' => $key,
                    'is_walkin'     => (int)$a['is_walkin'],
                    'att'           => $a['att'],
                );
            }

            $this->_json(array('success' => true, 'run' => $run, 'sessions' => $sessions, 'roster' => $roster));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /**
     * POST JSON — bulk upsert attendance for a run, one record per learner
     * per session (session_key = 'd<day><am|pm>', e.g. d1am / d2pm).
     * body: { run_id, records: [{ learner_email, learner_name, session_key,
     *                             is_present, reason_of_absence }] }
     */
    public function saveAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            $body    = json_decode($this->getRequest()->getRawBody(), true);
            $runId   = (int) ($body['run_id'] ?? 0);
            $records = isset($body['records']) && is_array($body['records']) ? $body['records'] : array();
            if (!$runId) throw new Exception('run_id is required');

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $write    = $resource->getConnection('core_write');
            $attTbl   = $resource->getTableName('mmd_course_run_attendance');

            $classId = (string) $read->fetchOne(
                "SELECT class_id FROM " . $resource->getTableName('course_runs') . " WHERE run_id = ?",
                array($runId)
            );
            $adminId = Mage::helper('mmd_attendance')->getCurrentAdminId();
            $saved   = 0;

            foreach ($records as $r) {
                $email   = trim((string)($r['learner_email'] ?? ''));
                $session = strtolower(trim((string)($r['session_key'] ?? '')));
                if ($email === '' || !preg_match('/^d\d{1,2}(am|pm)$/', $session)) continue;
                $present = !empty($r['is_present']) ? 1 : 0;
                $reason  = $present ? '' : trim((string)($r['reason_of_absence'] ?? ''));
                $name    = trim((string)($r['learner_name'] ?? ''));

                $write->insertOnDuplicate(
                    $attTbl,
                    array(
                        'run_id'             => $runId,
                        'class_id'           => $classId ?: null,
                        'learner_email'      => $email,
                        'session_key'        => $session,
                        'learner_name'       => $name,
                        'is_present'         => $present,
                        'reason_of_absence'  => $reason !== '' ? $reason : null,
                        'marked_by_admin_id' => $adminId,
                    ),
                    array('learner_name', 'is_present', 'reason_of_absence', 'marked_by_admin_id', 'class_id')
                );
                $saved++;
            }

            $this->_json(array('success' => true, 'message' => 'Attendance saved.', 'saved' => $saved));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /**
     * POST JSON — add a walk-in learner: ensure a customer account, add an
     * enrolment row, and seed an absent attendance row.
     * body: { run_id, full_name, email }
     */
    public function addLearnerAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            $body  = json_decode($this->getRequest()->getRawBody(), true);
            $runId = (int) ($body['run_id'] ?? 0);
            $name  = trim((string)($body['full_name'] ?? ''));
            $email = trim((string)($body['email'] ?? ''));
            if (!$runId) throw new Exception('run_id is required');
            if ($name === '' || $email === '') throw new Exception('Name and email are required.');
            if (strpos($email, '@') === false) throw new Exception('Please enter a valid email address.');

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $write    = $resource->getConnection('core_write');
            $runsTbl  = $resource->getTableName('course_runs');
            $enrolTbl = $resource->getTableName('course_run_enrolments');
            $attTbl   = $resource->getTableName('mmd_course_run_attendance');

            $run = $read->fetchRow("SELECT * FROM `$runsTbl` WHERE run_id = ?", array($runId));
            if (!$run) throw new Exception('Class not found.');

            // Already on this run's attendance?
            $exists = $read->fetchOne(
                "SELECT attendance_id FROM `$attTbl` WHERE run_id = ? AND LOWER(learner_email) = ?",
                array($runId, strtolower($email))
            );
            if ($exists) throw new Exception('This learner is already on the roster.');

            // Resolve or create the account. For an EXISTING learner the
            // account's own name is authoritative — if the admin picked a
            // learner from the dropdown and then edited the name field, the
            // edit is ignored so the roster never mismatches the account.
            $cust       = $this->_ensureCustomer($name, $email, (int)$run['product_id']);
            $customerId = $cust['id'];
            $name       = $cust['name'];

            // Add an enrolment row so they appear in the roster like everyone else
            // (idempotent — only if not already enrolled for this run+email).
            $alreadyEnrolled = $read->fetchOne(
                "SELECT enrolment_id FROM `$enrolTbl` WHERE run_id = ? AND LOWER(learner_email) = ?",
                array($runId, strtolower($email))
            );
            if (!$alreadyEnrolled) {
                $enrolData = array(
                    'run_id'        => $runId,
                    'product_id'    => (int)$run['product_id'],
                    'learner_name'  => $name,
                    'learner_email' => $email,
                );
                // course_run_enrolments has UNIQUE (product_id, run_id, learner_email)
                $write->insertOnDuplicate($enrolTbl, $enrolData, array('learner_name'));
            }

            // Seed an absent attendance row, flagged walk-in.
            $write->insertOnDuplicate(
                $attTbl,
                array(
                    'run_id'        => $runId,
                    'class_id'      => $run['class_id'] ?: null,
                    'learner_email' => $email,
                    'learner_name'  => $name,
                    'customer_id'   => $customerId ?: null,
                    'is_present'    => 0,
                    'is_walkin'     => 1,
                    'marked_by_admin_id' => Mage::helper('mmd_attendance')->getCurrentAdminId(),
                ),
                array('learner_name', 'customer_id', 'is_walkin')
            );

            $this->_json(array('success' => true, 'message' => 'Learner added.', 'customer_id' => $customerId));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /**
     * POST JSON — remove a walk-in learner from this run (attendance + enrolment).
     * body: { run_id, learner_email }
     */
    public function removeLearnerAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            $body  = json_decode($this->getRequest()->getRawBody(), true);
            $runId = (int) ($body['run_id'] ?? 0);
            $email = trim((string)($body['learner_email'] ?? ''));
            if (!$runId || $email === '') throw new Exception('run_id and learner_email are required');

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');

            // Only remove walk-ins — never delete a genuinely-enrolled learner's row here.
            $write->delete(
                $resource->getTableName('mmd_course_run_attendance'),
                array('run_id = ?' => $runId, 'LOWER(learner_email) = ?' => strtolower($email), 'is_walkin = ?' => 1)
            );
            $write->delete(
                $resource->getTableName('course_run_enrolments'),
                array('run_id = ?' => $runId, 'LOWER(learner_email) = ?' => strtolower($email))
            );

            $this->_json(array('success' => true, 'message' => 'Learner removed.'));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    // ------------------------------------------------------------------ //

    /**
     * Find a customer_entity by email (within the run's website) or create one.
     * Returns the customer entity_id, or null on failure (non-fatal).
     */
    /**
     * Resolve (find-by-email) or create a customer account. Returns
     * array('id' => int|null, 'name' => string) where `name` is the
     * AUTHORITATIVE name to use for the roster/attendance rows:
     *  - existing account -> the account's own name (so an admin who picks an
     *    existing learner and then edits the name field can't create a
     *    roster/account mismatch — the edit is ignored for existing learners);
     *  - new account      -> the typed name (used to create the account).
     */
    protected function _ensureCustomer($name, $email, $productId)
    {
        try {
            $websiteId = (int) Mage::helper('mmd_rolemanager')->getActiveWebsiteId();
            if (!$websiteId) $websiteId = 1;

            $customer = Mage::getModel('customer/customer')->setWebsiteId($websiteId);
            $customer->loadByEmail($email);
            if ($customer->getId()) {
                $existingName = trim($customer->getFirstname() . ' ' . $customer->getLastname());
                return array('id' => (int) $customer->getId(), 'name' => ($existingName !== '' ? $existingName : $name));
            }

            // Split name into first/last.
            $parts = preg_split('/\s+/', trim($name), 2);
            $first = $parts[0] !== '' ? $parts[0] : 'Learner';
            $last  = isset($parts[1]) && $parts[1] !== '' ? $parts[1] : '-';

            $store = Mage::app()->getWebsite($websiteId)->getDefaultStore();
            $customer = Mage::getModel('customer/customer');
            $customer->setWebsiteId($websiteId)
                     ->setStoreId($store ? $store->getId() : 0)
                     ->setFirstname($first)
                     ->setLastname($last)
                     ->setEmail($email)
                     ->setForceConfirmed(true);
            $customer->setPassword($customer->generatePassword(10));
            $customer->save();
            return array('id' => (int) $customer->getId(), 'name' => trim($first . ' ' . $last));
        } catch (Exception $e) {
            Mage::log('Attendance walk-in customer create failed: ' . $e->getMessage(), Zend_Log::WARN, 'attendance.log');
            return array('id' => null, 'name' => $name);
        }
    }

    protected function _json(array $data)
    {
        $this->getResponse()
             ->setHeader('Content-Type', 'application/json', true)
             ->setBody(json_encode($data));
    }
}
