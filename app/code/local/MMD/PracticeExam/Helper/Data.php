<?php
/**
 * Practice Exams on Tertiary Exams (exams.tertiaryinfotech.com) for certification courses.
 *
 * A course is linked to one practice exam in mmd_course_practice_exam (migration 1933),
 * switched on from Edit Course -> Lesson Details -> Course Settings. The class page then
 * shows a Practice Exam section where the trainer registers the class's learners (and the
 * trainer) on the exams site, or shows a Self-Register QR for learners to do it themselves.
 *
 * Exams API (bearer token, scope assign:practice-exams):
 *   GET  /api/v1/practice-exams
 *   GET  /api/v1/registrations?courseRunId=&exam=
 *   POST /api/v1/registrations { name, email, exam, courseRunId, remark }
 * The course run id sent is the class id (C######).
 *
 * Config (core_config_data, default scope) - the feature is OFF without a token:
 *   mmd_practiceexam/general/api_token
 *   mmd_practiceexam/general/api_url     (default https://exams.tertiaryinfotech.com)
 */
class MMD_PracticeExam_Helper_Data extends Mage_Core_Helper_Abstract
{
    const CONFIG_PATH_TOKEN = 'mmd_practiceexam/general/api_token';
    const CONFIG_PATH_URL   = 'mmd_practiceexam/general/api_url';
    const DEFAULT_URL       = 'https://exams.tertiaryinfotech.com';
    const TABLE             = 'mmd_course_practice_exam';
    const CATALOG_CACHE_KEY = 'mmd_practiceexam_catalog';

    /** Roles that may see the class section and register people. */
    public function classRoles()
    {
        return array('trainer', 'developer', 'admin', 'training_provider', 'franchise_admin');
    }

    /** Roles that may link a course to an exam. */
    public function staffRoles()
    {
        return array('developer', 'admin', 'training_provider', 'franchise_admin');
    }

    public function baseUrl()
    {
        $u = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_URL, 0));
        return rtrim($u !== '' ? $u : self::DEFAULT_URL, '/');
    }

    protected function _token()
    {
        return trim((string) Mage::getStoreConfig(self::CONFIG_PATH_TOKEN, 0));
    }

    public function isConfigured()
    {
        return $this->_token() !== '';
    }

    // ── Exams API ────────────────────────────────────────────────────────────

    /** @return array [ok(bool), status(int), data(array)] */
    protected function _call($method, $path, $body = null)
    {
        $ch = curl_init($this->baseUrl() . '/api/v1' . $path);
        $headers = array('Authorization: Bearer ' . $this->_token(), 'Accept: application/json');
        if ($body !== null) {
            $headers[] = 'Content-Type: application/json';
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
        }
        curl_setopt_array($ch, array(
            CURLOPT_CUSTOMREQUEST  => $method,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => $headers,
            CURLOPT_CONNECTTIMEOUT => 8,
            CURLOPT_TIMEOUT        => 20,
            CURLOPT_USERAGENT      => 'Tertiary-MMS/1.0',
        ));
        $raw    = curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err    = curl_error($ch);
        curl_close($ch);
        $data = is_string($raw) ? json_decode($raw, true) : null;
        if (!is_array($data)) {
            $data = array('error' => $err !== '' ? $err : 'HTTP ' . $status);
        }
        return array($status >= 200 && $status < 300, $status, $data);
    }

    protected function _error($res)
    {
        return isset($res[2]['error']) && is_string($res[2]['error']) ? $res[2]['error'] : 'Exams API error ' . $res[1];
    }

    /** Assignable practice exams (cached 10 min). @return array rows: slug, code, title, vendor */
    public function listExams()
    {
        $cached = Mage::app()->loadCache(self::CATALOG_CACHE_KEY);
        if ($cached) {
            $rows = json_decode($cached, true);
            if (is_array($rows)) return $rows;
        }
        $res = $this->_call('GET', '/practice-exams');
        if (!$res[0]) throw new Exception($this->_error($res));
        $rows = array();
        foreach ((array) (isset($res[2]['practiceExams']) ? $res[2]['practiceExams'] : array()) as $p) {
            $rows[] = array(
                'slug'   => (string) $p['slug'],
                'code'   => (string) $p['code'],
                'title'  => (string) $p['title'],
                'vendor' => isset($p['vendor']) ? (string) $p['vendor'] : '',
            );
        }
        Mage::app()->saveCache(json_encode($rows), self::CATALOG_CACHE_KEY, array(), 600);
        return $rows;
    }

    /** @return array email => [registeredAt, signedIn] */
    public function listRegistrations($classId, $examSlug)
    {
        $res = $this->_call('GET', '/registrations?' . http_build_query(array('courseRunId' => $classId, 'exam' => $examSlug)));
        if (!$res[0]) throw new Exception($this->_error($res));
        $out = array();
        foreach ((array) (isset($res[2]['registrations']) ? $res[2]['registrations'] : array()) as $r) {
            $out[strtolower((string) $r['email'])] = array(
                'registeredAt' => isset($r['registeredAt']) ? $r['registeredAt'] : null,
                'signedIn'     => !empty($r['signedIn']),
            );
        }
        return $out;
    }

    /** Create the exams account if needed and grant the practice exam. @return array [ok, error, emailSent] */
    public function registerPerson($name, $email, $examSlug, $classId, $remark = 'Registered from MMS')
    {
        $res = $this->_call('POST', '/registrations', array(
            'name' => (string) $name, 'email' => (string) $email, 'exam' => (string) $examSlug,
            'courseRunId' => (string) $classId, 'remark' => $remark,
        ));
        if (!$res[0]) return array('ok' => false, 'error' => $this->_error($res), 'emailSent' => false);
        return array('ok' => true, 'error' => '', 'emailSent' => !empty($res[2]['registrationEmailSent']));
    }

    // ── Course <-> exam link ─────────────────────────────────────────────────

    /** @return array|null [exam_code, exam_slug] */
    public function getCourseExam($productId)
    {
        try {
            $res = Mage::getSingleton('core/resource');
            $row = $res->getConnection('core_read')->fetchRow(
                'SELECT exam_code, exam_slug FROM `' . $res->getTableName(self::TABLE) . '` WHERE product_id = ?',
                array((int) $productId)
            );
            return $row && $row['exam_slug'] !== '' ? $row : null;
        } catch (Exception $e) {
            return null; // table not migrated yet
        }
    }

    /** Link the course to an exam (slug from the live catalogue); '' turns it off. @return array|null the saved link */
    public function setCourseExam($productId, $slug)
    {
        $res   = Mage::getSingleton('core/resource');
        $write = $res->getConnection('core_write');
        $tbl   = $res->getTableName(self::TABLE);
        $slug  = trim((string) $slug);
        if ($slug === '') {
            $write->delete($tbl, array('product_id = ?' => (int) $productId));
            return null;
        }
        foreach ($this->listExams() as $x) {
            if ($x['slug'] === $slug) {
                $write->insertOnDuplicate($tbl, array(
                    'product_id' => (int) $productId, 'exam_code' => $x['code'], 'exam_slug' => $x['slug'],
                ), array('exam_code', 'exam_slug'));
                return array('exam_code' => $x['code'], 'exam_slug' => $x['slug']);
            }
        }
        throw new Exception('No practice exam matches "' . $slug . '".');
    }

    // ── Class context ────────────────────────────────────────────────────────

    public function loadRun($runId)
    {
        $res = Mage::getSingleton('core/resource');
        $run = $res->getConnection('core_read')->fetchRow(
            'SELECT run_id, class_id, product_id, course_sku, course_start_date, course_end_date,
                    trainer_user_id, trainer_option_id
               FROM `' . $res->getTableName('course_runs') . '` WHERE run_id = ?',
            array((int) $runId)
        );
        return $run ?: null;
    }

    /** A trainer only reaches classes assigned to them; staff reach every class. */
    public function canAccessRun(array $run)
    {
        $rm = Mage::helper('mmd_rolemanager');
        if ($rm->isRoleAllowed($this->staffRoles())) return true;
        if (!$rm->isRoleAllowed(array('trainer'))) return false;
        $user = Mage::getSingleton('admin/session')->getUser();
        if (!$user) return false;
        if ((int) $run['trainer_user_id'] === (int) $user->getId()) return true;
        foreach ($this->_trainers($run) as $t) {
            if ($t['email'] === strtolower(trim((string) $user->getEmail()))) return true;
        }
        return false;
    }

    protected function _trainers(array $run)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $out  = array();
        if ((int) $run['trainer_user_id'] > 0) {
            $u = $read->fetchRow(
                'SELECT firstname, lastname, email FROM `' . $res->getTableName('admin_user') . '` WHERE user_id = ?',
                array((int) $run['trainer_user_id'])
            );
            if ($u) $out[] = array('name' => trim($u['firstname'] . ' ' . $u['lastname']), 'email' => strtolower(trim((string) $u['email'])));
        } elseif ((int) $run['trainer_option_id'] > 0) {
            try {
                $t = $read->fetchRow(
                    'SELECT title AS name, email FROM `' . $res->getTableName('courses_trainers') . '` WHERE relation_id = ? LIMIT 1',
                    array((int) $run['trainer_option_id'])
                );
                if ($t) $out[] = array('name' => trim((string) $t['name']), 'email' => strtolower(trim((string) $t['email'])));
            } catch (Exception $e) { /* legacy table shape differs - trainer simply not listed */ }
        }
        return array_values(array_filter($out, function ($p) { return (bool) filter_var($p['email'], FILTER_VALIDATE_EMAIL); }));
    }

    /**
     * The class's trainer + learners, one row per email (trainer first). Learners come from the
     * roster, falling back to order history exactly like E-Attendance does.
     * @return array rows: name, email, isTrainer
     */
    public function getPeople(array $run)
    {
        $res   = Mage::getSingleton('core/resource');
        $enrol = $res->getConnection('core_read')->fetchAll(
            'SELECT learner_name, learner_email FROM `' . $res->getTableName('course_run_enrolments') . '`
              WHERE run_id = ? ORDER BY learner_name',
            array((int) $run['run_id'])
        );
        if (empty($enrol)) {
            $enrol = Mage::helper('mmd_attendance')->orderRosterForRun($run);
        }
        $out = array();
        foreach ($this->_trainers($run) as $t) {
            $out[$t['email']] = $t + array('isTrainer' => true);
        }
        $learners = array();
        foreach ($enrol as $e) {
            $email = strtolower(trim((string) $e['learner_email']));
            if (isset($out[$email]) || isset($learners[$email]) || !filter_var($email, FILTER_VALIDATE_EMAIL)) continue;
            $learners[$email] = array('name' => trim((string) $e['learner_name']), 'email' => $email, 'isTrainer' => false);
        }
        uasort($learners, function ($a, $b) { return strcasecmp($a['name'], $b['name']); });
        return array_values($out + $learners);
    }

    // ── Self-register link (QR) ──────────────────────────────────────────────

    public function selfRegisterSig($runId)
    {
        $key = (string) Mage::getConfig()->getNode('global/crypt/key');
        return substr(hash_hmac('sha256', 'practice-exam-self-register:' . (int) $runId, $key), 0, 24);
    }

    public function selfRegisterUrl($runId)
    {
        $base = Mage::app()->getDefaultStoreView()->getBaseUrl(Mage_Core_Model_Store::URL_TYPE_LINK, true);
        return $base . 'practiceexam/register/index/run/' . (int) $runId . '/k/' . $this->selfRegisterSig($runId) . '/';
    }

    /** The link works from the day before the class until 7 days after it ends. */
    public function selfRegisterOpen(array $run)
    {
        $start = (string) $run['course_start_date'];
        if ($start === '' || $start === '0000-00-00') return true;
        $end   = (string) $run['course_end_date'];
        $end   = ($end !== '' && $end !== '0000-00-00') ? $end : $start;
        $today = Mage::getModel('core/date')->date('Y-m-d');
        return $today >= date('Y-m-d', strtotime($start . ' -1 day')) && $today <= date('Y-m-d', strtotime($end . ' +7 days'));
    }
}
