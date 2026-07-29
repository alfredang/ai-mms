<?php
/**
 * Certificate of Achievement — generation (HTML → mPDF PDF), email delivery
 * (Gmail), attendance gating, and idempotent issuance.
 *
 * Visual replicates the LMS certificate: navy "CERTIFICATE / OF ACCOMPLISHMENT"
 * header, blue chevron geometry, left-aligned body, signature block, seal.
 *
 * Gate: a learner gets a certificate only for a COMPLETED class where their
 * OVERALL session attendance exceeds 70% — present sessions / total sessions
 * of the run (each class day has an AM + PM session; see
 * MMD_Attendance_Helper_Data::sessionsForRun). No assessment data in MMS.
 */
class MMD_Certificate_Helper_Data extends Mage_Core_Helper_Abstract
{
    const ENABLED_CONFIG_PATH = 'mmd/certificate/auto_enabled';
    /** Overall attendance required for a certificate: strictly more than 70%. */
    const ATTENDANCE_THRESHOLD = 0.70;
    const LOG_FILE            = 'certificates.log';
    const SIGNER_NAME         = 'Dr. Alfred Ang';
    const SIGNER_TITLE        = 'Managing Director';
    const SIGNER_ORG          = 'Tertiary Infotech Academy';

    public function allowedRoles()
    {
        return array('trainer', 'training_provider', 'admin', 'developer');
    }
    public function isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed($this->allowedRoles());
    }
    public function isAutoEnabled()
    {
        return Mage::getStoreConfigFlag(self::ENABLED_CONFIG_PATH);
    }

    // ------------------------------------------------------------------ //
    // Gating
    // ------------------------------------------------------------------ //

    /**
     * Completed runs (end_date <= today — the 18:30 sweep fires AFTER the last
     * session of the final day, so a class counts as completed the same
     * evening) within $daysBack that have at least one present learner who has
     * not yet been issued a certificate. The per-learner 70% attendance gate
     * is applied afterwards by getEligibleLearners().
     */
    public function getEligibleRuns($daysBack = 7)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $runs = $res->getTableName('course_runs');
        $att  = $res->getTableName('mmd_course_run_attendance');
        $cert = $res->getTableName('mmd_course_run_certificate');

        $today  = Mage::getModel('core/date')->date('Y-m-d');
        $cutoff = date('Y-m-d', strtotime('-' . (int)$daysBack . ' days'));

        return $read->fetchCol(
            "SELECT DISTINCT cr.run_id
               FROM `$runs` cr
               JOIN `$att` a ON a.run_id = cr.run_id AND a.is_present = 1
              WHERE cr.course_end_date IS NOT NULL
                AND cr.course_end_date <= ?
                AND cr.course_end_date >= ?
                AND EXISTS (
                    SELECT 1 FROM `$att` a2
                     WHERE a2.run_id = cr.run_id AND a2.is_present = 1
                       AND NOT EXISTS (
                           SELECT 1 FROM `$cert` c
                            WHERE c.run_id = a2.run_id
                              AND LOWER(c.learner_email) = LOWER(a2.learner_email)
                              AND c.status IN ('issued','sent')
                       )
                )",
            array($today, $cutoff)
        );
    }

    /**
     * Learners for a run whose OVERALL attendance exceeds the 70% threshold
     * (distinct present sessions / total sessions of the run) and who do NOT
     * already have an issued/sent cert.
     *
     * @param int        $runId
     * @param array|null $run   optional pre-loaded run row (loadRun shape) —
     *                          avoids a second lookup from the cron sweep
     */
    public function getEligibleLearners($runId, $run = null)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $att  = $res->getTableName('mmd_course_run_attendance');
        $cert = $res->getTableName('mmd_course_run_certificate');

        if ($run === null) {
            $run = $this->loadRun($runId);
        }
        if (!$run) {
            return array();
        }
        $totalSessions = max(1, count(Mage::helper('mmd_attendance')->sessionsForRun($run)));

        // Attendance is per session (one row per run+learner+session_key), so
        // collapse to one row per learner and count their present sessions.
        $rows = $read->fetchAll(
            "SELECT a.learner_email, MAX(a.learner_name) AS learner_name, MAX(a.customer_id) AS customer_id,
                    COUNT(DISTINCT CASE WHEN a.is_present = 1 THEN a.session_key END) AS present_sessions
               FROM `$att` a
              WHERE a.run_id = ?
                AND NOT EXISTS (
                    SELECT 1 FROM `$cert` c
                     WHERE c.run_id = a.run_id
                       AND LOWER(c.learner_email) = LOWER(a.learner_email)
                       AND c.status IN ('issued','sent')
                )
              GROUP BY a.learner_email
             HAVING present_sessions > 0",
            array((int)$runId)
        );

        $eligible = array();
        foreach ($rows as $row) {
            if ((int)$row['present_sessions'] / $totalSessions > self::ATTENDANCE_THRESHOLD) {
                unset($row['present_sessions']);
                $eligible[] = $row;
            }
        }
        return $eligible;
    }

    /**
     * Full class roster with per-learner attendance + certificate status —
     * drives the trainer's Certificate of Achievement panel. Roster =
     * course_run_enrolments, else the order history (WSQ classes have no
     * materialised enrolments), plus attendance-only walk-ins. No 70% filter
     * here — the trainer sees everyone and decides who to send to manually.
     *
     * @return array { total_sessions, learners: [ { learner_email,
     *                 learner_name, customer_id, present_sessions,
     *                 attendance_pct, cert_status, cert_no, sent_at } ] }
     */
    public function getClassCertRoster(array $run)
    {
        $res      = Mage::getSingleton('core/resource');
        $read     = $res->getConnection('core_read');
        $att      = $res->getTableName('mmd_course_run_attendance');
        $cert     = $res->getTableName('mmd_course_run_certificate');
        $enrolTbl = $res->getTableName('course_run_enrolments');
        $runId    = (int)$run['run_id'];

        $attHelper = Mage::helper('mmd_attendance');
        $total     = max(1, count($attHelper->sessionsForRun($run)));

        $enrol = $read->fetchAll(
            "SELECT learner_name, learner_email FROM `$enrolTbl` WHERE run_id = ? ORDER BY learner_name",
            array($runId)
        );
        if (empty($enrol)) {
            $enrol = $attHelper->orderRosterForRun($run);
        }

        $attBy = array();
        foreach ($read->fetchAll(
            "SELECT LOWER(learner_email) AS e, MAX(learner_name) AS n, MAX(customer_id) AS cid,
                    COUNT(DISTINCT CASE WHEN is_present = 1 THEN session_key END) AS p
               FROM `$att` WHERE run_id = ? GROUP BY LOWER(learner_email)",
            array($runId)
        ) as $r) {
            $attBy[$r['e']] = $r;
        }

        $certBy = array();
        foreach ($read->fetchAll(
            "SELECT LOWER(learner_email) AS e, status, cert_no, sent_at FROM `$cert` WHERE run_id = ?",
            array($runId)
        ) as $r) {
            $certBy[$r['e']] = $r;
        }

        $out = array(); $seen = array();
        foreach ($enrol as $l) {
            $email = strtolower(trim((string)$l['learner_email']));
            if ($email === '' || isset($seen[$email])) continue;
            $seen[$email] = true;
            $out[] = $this->_rosterRow($email, trim((string)$l['learner_name']), $attBy, $certBy, $total);
        }
        foreach ($attBy as $email => $a) { // attendance rows not in the roster (walk-ins)
            if (isset($seen[$email])) continue;
            $seen[$email] = true;
            $out[] = $this->_rosterRow($email, (string)$a['n'], $attBy, $certBy, $total);
        }
        return array('total_sessions' => $total, 'learners' => $out);
    }

    protected function _rosterRow($email, $name, array $attBy, array $certBy, $total)
    {
        $a = isset($attBy[$email]) ? $attBy[$email] : null;
        $c = isset($certBy[$email]) ? $certBy[$email] : null;
        $present = $a ? (int)$a['p'] : 0;
        return array(
            'learner_email'    => $email,
            'learner_name'     => $name !== '' ? $name : ($a ? (string)$a['n'] : ''),
            'customer_id'      => ($a && !empty($a['cid'])) ? (int)$a['cid'] : null,
            'present_sessions' => $present,
            'attendance_pct'   => (int)round($present * 100 / $total),
            'cert_status'      => $c ? (string)$c['status'] : '',
            'cert_no'          => $c ? (string)$c['cert_no'] : '',
            'sent_at'          => $c ? (string)$c['sent_at'] : '',
        );
    }

    public function loadRun($runId)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $runs = $res->getTableName('course_runs');
        $pV   = $res->getTableName('catalog_product_entity_varchar');
        $optV = $res->getTableName('eav_attribute_option_value');
        $eA   = $res->getTableName('eav_attribute');
        $eT   = $res->getTableName('eav_entity_type');
        $auTbl= $res->getTableName('admin_user');
        $nameAttrId = (int)$read->fetchOne(
            "SELECT a.attribute_id FROM `$eA` a JOIN `$eT` t ON t.entity_type_id=a.entity_type_id
              WHERE t.entity_type_code='catalog_product' AND a.attribute_code='name'"
        );
        return $read->fetchRow(
            "SELECT cr.run_id, cr.class_id, cr.course_sku, cr.product_id,
                    cr.course_start_date, cr.course_end_date, cr.trainer_option_id, cr.trainer_user_id,
                    COALESCE(pn.value, cr.course_sku) AS course_title,
                    -- Phase 2: account-confirmed trainer wins, EAV is the fallback.
                    COALESCE(
                        NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))), ''),
                        tov.value, ''
                    ) AS trainer_name
               FROM `$runs` cr
               LEFT JOIN `$pV` pn ON pn.entity_id=cr.product_id AND pn.store_id=0 AND pn.attribute_id=$nameAttrId
               LEFT JOIN `$auTbl` au ON au.user_id=cr.trainer_user_id
               LEFT JOIN `$optV` tov ON tov.option_id=cr.trainer_option_id AND tov.store_id=0
              WHERE cr.run_id = ?",
            array((int)$runId)
        ) ?: null;
    }

    // ------------------------------------------------------------------ //
    // Issue + send (idempotent)
    // ------------------------------------------------------------------ //

    /**
     * Issue (generate PDF + email) one certificate. Idempotent: an atomic
     * INSERT on the unique (run_id, learner_email) key claims the slot; if a
     * 'sent' cert already exists it returns 'skipped' — UNLESS $force is set,
     * in which case it re-renders and OVERWRITES the stored PDF in place at the
     * same token (LMS "Create Certificate" overwrite semantics; no versioning).
     *
     * @return array { status: 'sent'|'skipped'|'error', message }
     */
    public function issueAndSend(array $run, array $learner, $adminId = null, $force = false)
    {
        $res   = Mage::getSingleton('core/resource');
        $write = $res->getConnection('core_write');
        $read  = $res->getConnection('core_read');
        $tbl   = $res->getTableName('mmd_course_run_certificate');

        $email = trim((string)$learner['learner_email']);
        $name  = trim((string)($learner['learner_name'] ?: $email));
        if ($email === '') {
            return array('status' => 'error', 'message' => 'Learner has no email.');
        }

        // Atomic claim. If a row already exists for (run_id, email) with a
        // non-error status, INSERT IGNORE leaves it and we skip.
        $token  = bin2hex(random_bytes(24));
        $certNo = $run['class_id'] . '-' . str_pad((string)((int)$read->fetchOne(
            "SELECT COUNT(*)+1 FROM `$tbl` WHERE run_id = ?", array((int)$run['run_id'])
        )), 4, '0', STR_PAD_LEFT);

        $write->query(
            "INSERT IGNORE INTO `$tbl`
                (run_id, class_id, course_sku, course_title, trainer_name, start_date, end_date,
                 learner_email, learner_name, customer_id, cert_no, token, status, issued_by_admin_id)
             VALUES (?,?,?,?,?,?,?,?,?,?,?,?, 'issued', ?)",
            array(
                (int)$run['run_id'], $run['class_id'] ?: null, $run['course_sku'] ?: null,
                $run['course_title'] ?: null, $run['trainer_name'] ?: null,
                $run['course_start_date'] ?: null, $run['course_end_date'] ?: null,
                $email, $name, !empty($learner['customer_id']) ? (int)$learner['customer_id'] : null,
                $certNo, $token, $adminId ? (int)$adminId : null
            )
        );

        $row = $read->fetchRow(
            "SELECT * FROM `$tbl` WHERE run_id = ? AND LOWER(learner_email) = ?",
            array((int)$run['run_id'], strtolower($email))
        );
        if (!$row) {
            return array('status' => 'error', 'message' => 'Failed to claim certificate row.');
        }
        if ($row['status'] === 'sent' && !$force) {
            return array('status' => 'skipped', 'message' => 'Already sent.');
        }

        try {
            $dates = $this->formatDates($run['course_start_date'], $run['course_end_date']);
            $pdf   = $this->renderPdf($this->buildCertHtml($name, $run['course_title'], $dates));
            $this->_emailCertificate($email, $name, $run, $row['token'], $pdf);

            // Store the rendered bytes as the source of truth — downloads serve
            // this verbatim. On a forced re-issue this OVERWRITES in place
            // (same row, same token), matching LMS overwrite semantics.
            $write->update($tbl,
                array(
                    'status'        => 'sent',
                    'sent_at'       => now(),
                    'error_message' => null,
                    'pdf_blob'      => $pdf,
                    'source'        => 'mpdf',
                ),
                array('certificate_id = ?' => (int)$row['certificate_id'])
            );
            Mage::log(($force ? 'Certificate re-issued (overwrite) to ' : 'Certificate sent to ') . $email . ' for run ' . $run['run_id'], Zend_Log::INFO, self::LOG_FILE);
            return array('status' => 'sent', 'message' => ($force ? 'Certificate re-issued to ' : 'Certificate sent to ') . $email);
        } catch (Exception $e) {
            $write->update($tbl,
                array('status' => 'error', 'error_message' => substr($e->getMessage(), 0, 500)),
                array('certificate_id = ?' => (int)$row['certificate_id'])
            );
            Mage::log('Certificate error for ' . $email . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            return array('status' => 'error', 'message' => $e->getMessage());
        }
    }

    // ------------------------------------------------------------------ //
    // PDF rendering
    // ------------------------------------------------------------------ //

    public function renderPdf($html)
    {
        if (!class_exists('\\Mpdf\\Mpdf')) {
            // Composer autoloader is normally registered by Mage bootstrap; ensure it.
            $autoload = Mage::getBaseDir() . '/vendor/autoload.php';
            if (is_file($autoload)) require_once $autoload;
        }
        if (!class_exists('\\Mpdf\\Mpdf')) {
            throw new Exception('mPDF is not available.');
        }
        $tmp = Mage::getBaseDir('var') . DS . 'tmp' . DS . 'mpdf';
        if (!is_dir($tmp)) @mkdir($tmp, 0777, true);

        $mpdf = new \Mpdf\Mpdf(array(
            'mode'        => 'utf-8',
            'format'      => 'A4',
            'orientation' => 'P',
            'margin_left' => 0, 'margin_right' => 0, 'margin_top' => 0,
            'margin_bottom' => 0, 'margin_header' => 0, 'margin_footer' => 0,
            'tempDir'     => $tmp,
        ));
        $mpdf->WriteHTML($html);
        return $mpdf->Output('', \Mpdf\Output\Destination::STRING_RETURN);
    }

    public function formatDates($start, $end)
    {
        $fmt = function($d) { return $d ? date('d M Y', strtotime($d)) : ''; };
        $s = $fmt($start); $e = $fmt($end);
        if ($s === '' && $e === '') return 'N/A';
        if ($e === '' || $e === $s) return $s ?: $e;
        return $s . ' - ' . $e;
    }

    /**
     * Certificate HTML, replicating the LMS Slides design for mPDF.
     */
    public function buildCertHtml($name, $course, $dates)
    {
        $esc  = function($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); };
        $name = $esc($name); $course = $esc($course); $dates = $esc($dates);

        // Chevron decoration as inline SVG (top-right + bottom-right corners).
        // mPDF honours position:fixed on DIRECT body children placed at explicit
        // page coordinates — nested position:absolute is unreliable, so every
        // element below is a fixed-position direct child of <body>.
        $chevTop = '<svg width="230" height="300" viewBox="0 0 230 300" xmlns="http://www.w3.org/2000/svg">'
            . '<polygon points="40,0 230,0 230,300 150,150" fill="#1e3a8a"/>'
            . '<polygon points="0,0 110,0 230,235 230,300 120,300" fill="#3b82f6"/>'
            . '<polygon points="70,0 150,0 230,150 230,250" fill="#2563eb"/>'
            . '<polygon points="120,30 230,200 230,300 150,160" fill="#22d3ee" opacity="0.85"/>'
            . '<polygon points="20,0 70,0 200,250 150,250" fill="#1e40af" opacity="0.45"/>'
            . '</svg>';
        $chevBot = '<svg width="250" height="150" viewBox="0 0 250 150" xmlns="http://www.w3.org/2000/svg">'
            . '<polygon points="90,150 0,150 100,20 190,20" fill="#1e3a8a"/>'
            . '<polygon points="40,150 0,150 80,40 120,40" fill="#3b82f6"/>'
            . '<polygon points="150,150 230,40 250,80 190,150" fill="#22d3ee" opacity="0.8"/>'
            . '</svg>';

        return '<!DOCTYPE html><html><head><meta charset="utf-8"><style>
        @page { margin: 0; }
        body { font-family: sans-serif; color: #1f2937; }
        .fx { position: fixed; }
        .chev-top { position: fixed; top: 0mm; left: 145mm; }
        .chev-bot { position: fixed; top: 247mm; left: 145mm; }
        .h1 { position: fixed; top: 52mm; left: 24mm; width: 150mm; font-size: 50px; font-weight: 800; color: #1e3a8a; letter-spacing: 1px; }
        .h2 { position: fixed; top: 70mm; left: 25mm; width: 150mm; font-size: 21px; font-weight: 600; color: #475569; letter-spacing: 7px; }
        .lead { position: fixed; top: 100mm; left: 24mm; width: 150mm; font-size: 15px; color: #475569; }
        .name { position: fixed; top: 107mm; left: 24mm; width: 150mm; font-size: 30px; font-weight: 800; color: #111827; border-bottom: 2px solid #cbd5e1; padding-bottom: 5px; }
        .for  { position: fixed; top: 128mm; left: 24mm; width: 150mm; font-size: 15px; color: #475569; }
        .course { position: fixed; top: 135mm; left: 24mm; width: 150mm; font-size: 23px; font-weight: 800; color: #2563eb; }
        .held { position: fixed; top: 150mm; left: 24mm; width: 150mm; font-size: 15px; color: #475569; }
        .held b { color: #111827; }
        .sig-name { position: fixed; top: 250mm; left: 24mm; width: 60mm; font-size: 15px; color: #111827; border-top: 1px solid #94a3b8; padding-top: 6px; }
        .sig-title { position: fixed; top: 258mm; left: 24mm; width: 70mm; font-size: 13px; color: #475569; }
        .sig-org { position: fixed; top: 263mm; left: 24mm; width: 80mm; font-size: 13px; font-weight: 700; color: #1e3a8a; }
        .logo { position: fixed; top: 250mm; left: 150mm; width: 13mm; height: 13mm; background: #1e3a8a; border-radius: 8px; color: #fff; text-align: center; }
        .logo .l { font-size: 26px; font-weight: 800; }
        .seal { position: fixed; top: 246mm; left: 171mm; width: 26mm; height: 26mm; border: 2px solid #1e3a8a; border-radius: 50%; text-align: center; color: #1e3a8a; background: #ffffff; }
        .seal .t { font-size: 22px; font-weight: 800; }
        .seal .s { font-size: 7px; letter-spacing: 1px; }
        </style></head><body>
            <div class="chev-top">' . $chevTop . '</div>
            <div class="chev-bot">' . $chevBot . '</div>
            <div class="h1">CERTIFICATE</div>
            <div class="h2">OF ACCOMPLISHMENT</div>
            <div class="lead">This Certificate is proudly presented to</div>
            <div class="name">' . ($name !== '' ? $name : '&nbsp;') . '</div>
            <div class="for">For completing the course</div>
            <div class="course">' . ($course !== '' ? $course : '&nbsp;') . '</div>
            <div class="held">Held on <b>' . ($dates !== '' ? $dates : 'N/A') . '</b></div>
            <div class="sig-name">' . self::SIGNER_NAME . '</div>
            <div class="sig-title">' . self::SIGNER_TITLE . '</div>
            <div class="sig-org">' . self::SIGNER_ORG . '</div>
            <div class="logo"><div class="l">T</div></div>
            <div class="seal"><div class="t">T</div><div class="s">TERTIARY<br>INFOTECH</div></div>
        </body></html>';
    }

    // ------------------------------------------------------------------ //
    // Email
    // ------------------------------------------------------------------ //

    protected function _emailCertificate($toEmail, $toName, array $run, $token, $pdfBytes)
    {
        $info     = $this->companyInfo();
        $subject  = 'Certificate for Completing ' . $run['course_title'];
        $body     = $this->buildEmailBody($toName, $run['course_title'], $token, $info);
        $fileName = preg_replace('/[^A-Za-z0-9_\- ]/', '', $toName) . '-Certificate-of-Achievement.pdf';
        $fileName = trim($fileName) !== '' ? $fileName : 'Certificate-of-Achievement.pdf';

        // Prefer Gmail (SG/admin store). Fall back to Zend_Mail with attachment.
        $gmail = Mage::helper('mmd_email/gmail');
        if ($gmail->isConfigured()) {
            $gmail->sendWithAttachment(
                $toEmail, $subject, $body, $pdfBytes, $fileName, 'application/pdf',
                $info['short_name'], array(), $info['support_email']
            );
            return;
        }

        $mail = new Zend_Mail('UTF-8');
        $mail->addTo($toEmail, $toName)
             ->setFrom($info['from_email'], $info['short_name'])
             ->setSubject($subject)
             ->setBodyHtml($body)
             ->createAttachment(
                 $pdfBytes, 'application/pdf',
                 Zend_Mime::DISPOSITION_ATTACHMENT, Zend_Mime::ENCODING_BASE64, $fileName
             );
        if ($info['support_email']) $mail->setReplyTo($info['support_email']);
        $mail->send();
    }

    public function buildEmailBody($name, $course, $token, array $info)
    {
        $url = rtrim(Mage::getBaseUrl(), '/') . '/certificate/download/index?token=' . $token;
        $e   = function($s){ return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); };
        return '<p>Hello ' . $e($name) . ',</p>'
            . '<p>Congratulations on successfully completing the course <i>' . $e($course) . '</i>! '
            . 'We are truly proud of your perseverance, dedication, and motivation throughout the program.</p>'
            . '<p>Please find attached your Certificate of Achievement in recognition of your accomplishment.</p>'
            . '<p>You can also download your certificate here: <a href="' . $e($url) . '">' . $e($url) . '</a></p>'
            . '<p>Your commitment to learning and professional growth is commendable, and we wish you continued success '
            . 'in applying your new skills.</p>'
            . '<p>For learners who have achieved at least 75% attendance and passed their assessment for WSQ courses, '
            . 'they can view and download their WSQ SOA (Statement of Attainment) through '
            . '<a href="https://www.MySkillsFuture.gov.sg">www.MySkillsFuture.gov.sg</a>.</p>'
            . '<p>Please note that SkillsFuture Singapore uses OpenCerts to issue the WSQ Statements of Attainment (SOA). '
            . 'The OpenCerts will be ready for viewing/downloading 4-5 weeks upon completion of WSQ courses.</p>'
            . '<p>Best regards,<br/><strong>Support Team</strong><br/><strong>' . $e($info['short_name']) . '</strong><br/>'
            . 'Email: <a href="mailto:' . $e($info['support_email']) . '">' . $e($info['support_email']) . '</a></p>';
    }

    public function companyInfo()
    {
        return array(
            'name'          => 'Tertiary Infotech Academy',
            'short_name'    => 'Tertiary Infotech',
            'support_email' => Mage::getStoreConfig('trans_email/ident_support/email') ?: 'enquiry@tertiaryinfotech.com',
            'from_email'    => Mage::getStoreConfig('trans_email/ident_general/email') ?: 'noreply@tertiarycourses.com.sg',
            'website'       => 'https://www.tertiarycourses.com.sg',
        );
    }
}
