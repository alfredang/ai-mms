<?php
/**
 * AJAX endpoints for the multi-step class-reschedule form.
 *
 * Flow:
 *   1. POST /reschedule/ajax/sendotp    { email }           → sends OTP
 *   2. POST /reschedule/ajax/verifyotp  { email, code }     → sets session
 *   3. POST /reschedule/ajax/getenrollments                 → upcoming courses (MMS DB + LMS)
 *   4. POST /reschedule/ajax/getsiblingruns { run_id }      → future runs from LMS (graceful empty)
 *   5. POST /reschedule/ajax/submit     { all fields }      → save lead, push to LMS if WSQ
 *
 * After verifyotp succeeds, core/session carries 'reschedule_verified_email' which
 * gates getEnrollments, getSiblingRuns, and submit.
 *
 * LMS calls use env vars LMS_API_URL + LMS_API_KEY (set in Coolify).
 * All LMS calls are non-fatal: if unavailable, MMS saves the lead as lms_status=pending_push.
 */
class MMD_Reschedule_AjaxController extends Mage_Core_Controller_Front_Action
{
    const OTP_TTL_SECONDS  = 900;  // 15 min
    const OTP_RATE_LIMIT   = 3;    // max sends per email per rate window
    const OTP_RATE_WINDOW  = 600;  // 10 min
    const LMS_TIMEOUT      = 8;    // seconds per LMS call
    const EXTRA_TO         = 'angss@tertiaryinfotech.com';

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private function _json($code, array $data)
    {
        $this->getResponse()
            ->setHttpResponseCode($code)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setBody(json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    }

    private function _post($key, $default = '')
    {
        return trim((string) $this->getRequest()->getPost($key, $default));
    }

    private function _session()
    {
        return Mage::getSingleton('core/session');
    }

    private function _verifiedEmail()
    {
        return (string) $this->_session()->getData('reschedule_verified_email');
    }

    private function _resource()
    {
        return Mage::getSingleton('core/resource');
    }

    private function _write()
    {
        return $this->_resource()->getConnection('core_write');
    }

    private function _read()
    {
        return $this->_resource()->getConnection('core_read');
    }

    /** GET request to LMS external API. Returns decoded array or null on any failure. */
    private function _lmsGet($path, array $query = array())
    {
        $baseUrl = rtrim((string) getenv('LMS_API_URL'), '/');
        $apiKey  = (string) getenv('LMS_API_KEY');
        if (!$baseUrl || !$apiKey) {
            return null;
        }
        $url = $baseUrl . $path . ($query ? ('?' . http_build_query($query)) : '');
        $ch = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => self::LMS_TIMEOUT,
            CURLOPT_HTTPHEADER     => array('X-API-Key: ' . $apiKey, 'Accept: application/json'),
            CURLOPT_SSL_VERIFYPEER => true,
        ));
        $body = curl_exec($ch);
        $http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($http !== 200 || $body === false) {
            return null;
        }
        $decoded = json_decode((string) $body, true);
        return is_array($decoded) ? $decoded : null;
    }

    /** POST request to LMS external API. Returns decoded array (with _http key) or null on curl failure. */
    private function _lmsPost($path, array $payload)
    {
        $baseUrl = rtrim((string) getenv('LMS_API_URL'), '/');
        $apiKey  = (string) getenv('LMS_API_KEY');
        if (!$baseUrl || !$apiKey) {
            return null;
        }
        $bodyStr = json_encode($payload);
        $ch = curl_init($baseUrl . $path);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => self::LMS_TIMEOUT,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $bodyStr,
            CURLOPT_HTTPHEADER     => array(
                'X-API-Key: ' . $apiKey,
                'Content-Type: application/json',
                'Accept: application/json',
            ),
            CURLOPT_SSL_VERIFYPEER => true,
        ));
        $resp = curl_exec($ch);
        $http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($resp === false) {
            return null;
        }
        $decoded = json_decode((string) $resp, true);
        $base = array('_http' => $http);
        return is_array($decoded) ? array_merge($decoded, $base) : $base;
    }

    // ------------------------------------------------------------------
    // Step 1 — send OTP
    // ------------------------------------------------------------------

    public function sendotpAction()
    {
        $email = $this->_post('email');
        if (!Zend_Validate::is($email, 'EmailAddress')) {
            return $this->_json(400, array('ok' => false, 'message' => 'Invalid email address.'));
        }

        $tbl  = $this->_resource()->getTableName('mmd_reschedule_otp');
        $read = $this->_read();

        // Rate limit: max OTP_RATE_LIMIT sends per email per OTP_RATE_WINDOW seconds
        $recent = (int) $read->fetchOne(
            "SELECT COUNT(*) FROM `{$tbl}` WHERE email = ? AND created_at >= DATE_SUB(NOW(), INTERVAL " . self::OTP_RATE_WINDOW . " SECOND)",
            array($email)
        );
        if ($recent >= self::OTP_RATE_LIMIT) {
            return $this->_json(429, array('ok' => false, 'message' => 'Too many attempts. Please wait 10 minutes before requesting another code.'));
        }

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $this->_write()->insert($tbl, array(
            'email'      => $email,
            'code'       => $code,
            'expires_at' => date('Y-m-d H:i:s', time() + self::OTP_TTL_SECONDS),
            'used'       => 0,
            'created_at' => date('Y-m-d H:i:s'),
        ));

        try {
            $tplId = Mage::getModel('core/email_template')->loadByCode('MMD Reschedule OTP')->getId();
            if (!$tplId) {
                Mage::throwException('OTP email template not found.');
            }
            $tpl = Mage::getModel('core/email_template');
            $tpl->setDesignConfig(array('area' => 'frontend', 'store' => Mage::app()->getStore()->getId()));
            $tpl->sendTransactional($tplId, 'general', $email, $email, array('code' => $code));
            if (!$tpl->getSentSuccess()) {
                Mage::throwException('Mail transport returned failure.');
            }
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, array('ok' => false, 'message' => 'Could not send email. Please try again or call +65 6100 0613.'));
        }

        return $this->_json(200, array('ok' => true));
    }

    // ------------------------------------------------------------------
    // Step 2 — verify OTP
    // ------------------------------------------------------------------

    public function verifyotpAction()
    {
        $email = $this->_post('email');
        $code  = preg_replace('/\D/', '', $this->_post('code'));

        if (!Zend_Validate::is($email, 'EmailAddress') || strlen($code) !== 6) {
            return $this->_json(400, array('ok' => false, 'message' => 'Invalid input.'));
        }

        $tbl = $this->_resource()->getTableName('mmd_reschedule_otp');
        $row = $this->_read()->fetchRow(
            "SELECT otp_id FROM `{$tbl}` WHERE email = ? AND code = ? AND used = 0 AND expires_at > NOW() ORDER BY otp_id DESC LIMIT 1",
            array($email, $code)
        );

        if (!$row) {
            return $this->_json(400, array('ok' => false, 'message' => 'Invalid or expired code. Please try again.'));
        }

        $this->_write()->update($tbl, array('used' => 1), array('otp_id = ?' => (int) $row['otp_id']));
        $this->_session()->setData('reschedule_verified_email', $email);

        return $this->_json(200, array('ok' => true));
    }

    // ------------------------------------------------------------------
    // Step 3 — fetch enrolled upcoming courses
    // ------------------------------------------------------------------

    public function getenrollmentsAction()
    {
        $email = $this->_verifiedEmail();
        if (!$email) {
            return $this->_json(401, array('ok' => false, 'message' => 'Session expired. Please refresh and start again.'));
        }

        $courses = array();

        // --- MMS DB: non-WSQ upcoming enrolments ---
        try {
            $read      = $this->_read();
            $creTbl    = $this->_resource()->getTableName('course_run_enrolments');
            $crTbl     = $this->_resource()->getTableName('course_runs');
            $varTbl    = $this->_resource()->getTableName('catalog_product_entity_varchar');
            $nameAttrId = (int) Mage::getSingleton('eav/config')->getAttribute('catalog_product', 'name')->getId();

            $rows = $read->fetchAll(
                "SELECT cr.run_id, cr.course_sku, cr.course_start_date, cr.course_end_date,
                        COALESCE(cpev.value, cr.course_sku) AS course_title
                 FROM `{$creTbl}` cre
                 JOIN `{$crTbl}` cr ON cr.run_id = cre.run_id
                 LEFT JOIN `{$varTbl}` cpev
                   ON cpev.entity_id = cr.product_id
                   AND cpev.attribute_id = {$nameAttrId}
                   AND cpev.store_id = 0
                 WHERE cre.learner_email = ?
                   AND cr.course_sku NOT LIKE 'TGS-%'
                   AND (cr.course_start_date IS NULL OR cr.course_start_date >= CURDATE())
                 ORDER BY cr.course_start_date ASC
                 LIMIT 20",
                array($email)
            );

            foreach ($rows as $r) {
                $courses[] = array(
                    'source'            => 'mms',
                    'run_id'            => (string) $r['run_id'],
                    'course_sku'        => (string) $r['course_sku'],
                    'course_title'      => (string) $r['course_title'],
                    'course_start_date' => (string) $r['course_start_date'],
                    'course_end_date'   => (string) $r['course_end_date'],
                    'is_wsq'            => false,
                );
            }
        } catch (Exception $e) {
            Mage::logException($e);
            // Non-fatal: continue to LMS lookup
        }

        // --- LMS: WSQ enrolments (external/enrollments already exists) ---
        $lmsData = $this->_lmsGet('/api/external/enrollments', array('learner_email' => $email));
        if (is_array($lmsData) && !empty($lmsData['enrollments'])) {
            foreach ((array) $lmsData['enrollments'] as $enr) {
                if (empty($enr['courseRunId'])) {
                    continue;
                }
                // Only show future runs
                $startDate = isset($enr['startDate']) ? $enr['startDate'] : null;
                if ($startDate && $startDate < date('Y-m-d')) {
                    continue;
                }
                $courses[] = array(
                    'source'            => 'lms',
                    'run_id'            => (string) $enr['courseRunId'],
                    'course_sku'        => isset($enr['courseSku'])   ? (string) $enr['courseSku']   : '',
                    'course_title'      => isset($enr['courseTitle'])  ? (string) $enr['courseTitle']  :
                                          (isset($enr['courseSku']) ? (string) $enr['courseSku'] : 'Unknown'),
                    'course_start_date' => $startDate,
                    'course_end_date'   => isset($enr['endDate']) ? (string) $enr['endDate'] : null,
                    'is_wsq'            => true,
                );
            }
        }

        return $this->_json(200, array('ok' => true, 'courses' => $courses));
    }

    // ------------------------------------------------------------------
    // Step 3b — sibling runs for selected WSQ course (LMS proxy)
    // ------------------------------------------------------------------

    public function getsiblingrunsAction()
    {
        if (!$this->_verifiedEmail()) {
            return $this->_json(401, array('ok' => false, 'message' => 'Session expired. Please refresh and start again.'));
        }

        $runId = $this->_post('run_id');
        if (!$runId) {
            return $this->_json(400, array('ok' => false, 'message' => 'Missing run_id.'));
        }

        // Gracefully empty if LMS endpoint not yet available
        $data = $this->_lmsGet('/api/external/sibling-course-runs', array('run_id' => $runId));
        $runs = (is_array($data) && !empty($data['runs'])) ? $data['runs'] : array();

        return $this->_json(200, array('ok' => true, 'runs' => $runs));
    }

    // ------------------------------------------------------------------
    // Step 4 — submit reschedule request
    // ------------------------------------------------------------------

    public function submitAction()
    {
        $verifiedEmail = $this->_verifiedEmail();
        $email         = $this->_post('email');

        if (!$verifiedEmail || strtolower($verifiedEmail) !== strtolower($email)) {
            return $this->_json(403, array('ok' => false, 'message' => 'Email verification required. Please refresh and try again.'));
        }

        // Honeypot
        if ($this->_post('hideit') !== '') {
            return $this->_json(400, array('ok' => false, 'message' => 'Submission rejected.'));
        }

        $name        = $this->_post('name');
        $nric        = $this->_post('nric');
        $telephone   = $this->_post('telephone');
        $course      = $this->_post('course');
        $courseCode  = $this->_post('course_code');
        $startDate   = $this->_post('course_start_date');
        $nextDate    = $this->_post('next_course_start_date');
        $runId       = $this->_post('run_id');
        $targetRunId = $this->_post('target_run_id');
        $isWsq       = $this->_post('is_wsq') === '1';
        $comment     = $this->_post('comment');

        if (!$name || !$nric || !Zend_Validate::is($email, 'EmailAddress')
            || !$telephone || !$course || !$courseCode || !$startDate
        ) {
            return $this->_json(400, array('ok' => false, 'message' => 'Please complete all required fields.'));
        }

        // Turnstile (if configured)
        $turnstile = Mage::helper('magentocaptcha/turnstile');
        if ($turnstile->isConfigured()) {
            $r = $turnstile->verify(
                (string) $this->getRequest()->getPost(MMD_MagentoCaptcha_Helper_Turnstile::TOKEN_FIELD, ''),
                $turnstile->getRemoteIp()
            );
            if (empty($r['ok'])) {
                return $this->_json(400, array('ok' => false, 'message' => 'Spam check failed. Please refresh and try again.'));
            }
        }

        // Attempt LMS push for WSQ leads when LMS env vars are set
        $lmsStatus   = null;
        $lmsResponse = null;

        if ($isWsq) {
            if (getenv('LMS_API_URL') && getenv('LMS_API_KEY')) {
                $lmsResult = $this->_lmsPost('/api/external/reschedule-request', array(
                    'learner_email'  => $email,
                    'current_run_id' => $runId,
                    'target_run_id'  => $targetRunId,
                    'course_sku'     => $courseCode,
                    'course_title'   => $course,
                    'preferred_date' => $nextDate,
                    'name'           => $name,
                    'nric'           => $nric,
                ));
                if ($lmsResult !== null) {
                    $lmsStatus   = ((int) ($lmsResult['_http'] ?? 0) === 200) ? 'pushed' : 'failed';
                    $lmsResponse = json_encode($lmsResult);
                } else {
                    $lmsStatus = 'pending_push'; // curl failure, retry later
                }
            } else {
                $lmsStatus = 'pending_push'; // LMS not configured yet
            }
        }

        // Save lead
        $lead = Mage::getModel('mmd_reschedule/lead')
            ->setStoreId(Mage::app()->getStore()->getId())
            ->setStoreCode(Mage::app()->getStore()->getCode())
            ->setName($name)->setNric($nric)->setEmail($email)->setTelephone($telephone)
            ->setCourse($course)->setCourseCode($courseCode)
            ->setCourseStartDate($startDate)->setNextCourseStartDate($nextDate)
            ->setRunId($runId ?: null)->setTargetRunId($targetRunId ?: null)
            ->setIsWsq($isWsq ? 1 : 0)->setLmsStatus($lmsStatus)->setLmsResponse($lmsResponse)
            ->setMessage($comment)->setSource('class-reschedule')
            ->setIp($turnstile->getRemoteIp())
            ->setUserAgent(substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255))
            ->setStatus('new')
            ->save();

        // Staff notification email
        Mage::helper('mmd_leadmail')->notify(
            'Class Reschedule Request',
            $name, $email, $telephone,
            array(
                array('NRIC',             $nric),
                array('Course Title',     $course),
                array('Course Code',      $courseCode),
                array('Course Start Date',$startDate),
                array('Next Start Date',  $nextDate),
                array('WSQ',              $isWsq ? 'Yes' : 'No'),
                array('Run ID',           $runId ?: '-'),
                array('Target Run ID',    $targetRunId ?: '-'),
                array('LMS Status',       $lmsStatus ?: '-'),
            ),
            $comment,
            array(self::EXTRA_TO)
        );

        // Auto-mode for non-WSQ: mark confirmed immediately
        if (!$isWsq && Mage::getStoreConfig('mmd_reschedule/automation/non_wsq_mode') === 'auto') {
            $lead->setStatus('confirmed')->save();
        }

        // Clear verified session so the same OTP can't be reused for another submission
        $this->_session()->unsetData('reschedule_verified_email');

        return $this->_json(200, array(
            'ok'      => true,
            'message' => 'Thank you for your submission. We will respond within 7 working days. If you do not hear from us, please call our office hotline +65 6100 0613.',
        ));
    }
}
