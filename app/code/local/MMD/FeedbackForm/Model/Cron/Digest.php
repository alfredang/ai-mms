<?php
/**
 * Class evaluation email — daily 18:30 (site time), on the class's last day.
 *
 * For every class that ended today or earlier (within a 7-day lookback) and
 * has at least one QR feedback response, emails every response to the class's
 * trainer, cc this site's staff. Learners are listed as "Learner 1, 2, …" —
 * the trainer never sees who gave which rating. Each franchise site runs its
 * own DB, so the cc list is picked from MMS_COUNTRY_CODE (unset = SG, as in
 * apply.php). User rule 2026-11-27: always to the trainer, cc SG angch@ + tansc@,
 * MY angch@ + saeid@, GH angch@ + siraj@. At-most-once per class via mmd_feedback_digest_sent; responses
 * that arrive after the email stay visible on the class reviews page
 * (adminhtml/feedbackresponses/class).
 */
class MMD_FeedbackForm_Model_Cron_Digest
{
    const LOG_FILE  = 'feedback_digest.log';
    const DAYS_BACK = 7;

    /** Site => cc list, subject prefix, sender name, sign-off. */
    protected $_sites = array(
        'SG' => array(
            'cc'     => array('angch@tertiaryinfotech.com', 'tansc@tertiaryinfotech.com'),
            'prefix' => '[TIA] ',
            'from'   => 'Tertiary Infotech Academy',
            'sign'   => 'Kael | Tertiary Infotech Academy',
        ),
        'MY' => array(
            'cc'     => array('angch@tertiaryinfotech.com', 'saeid@tertiarycourses.com.my'),
            'prefix' => '',
            'from'   => 'Tertiary Courses Malaysia',
            'sign'   => 'Tertiary Courses Malaysia',
        ),
        'GH' => array(
            'cc'     => array('angch@tertiaryinfotech.com', 'siraj@tertiarycourses.com.gh'),
            'prefix' => '',
            'from'   => 'Tertiary Courses Ghana',
            'sign'   => 'Tertiary Courses Ghana',
        ),
    );

    /** Email wording per rating (same layout as the lms-tms "[TIA] Class Evaluation" email). */
    protected $_ratingLabels = array(
        1 => 'The course effectively met its learning objectives',
        2 => 'The trainer demonstrated strong knowledge of the subject matter',
        5 => 'The training environment was conducive to learning',
    );

    public function run()
    {
        $code = strtoupper((string)(getenv('MMS_COUNTRY_CODE') ?: 'SG'));
        if (!isset($this->_sites[$code])) {
            Mage::log('Class evaluation email skipped — no recipients for site ' . $code, Zend_Log::WARN, self::LOG_FILE);
            return;
        }
        $site = $this->_sites[$code];

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $linkTbl  = $resource->getTableName('mmd_feedback_review_run');
        $sentTbl  = $resource->getTableName('mmd_feedback_digest_sent');
        $runsTbl  = $resource->getTableName('course_runs');

        // Site-local "today": the sweep fires after the last session of the final day.
        $today = Mage::getModel('core/date')->date('Y-m-d');
        $from  = date('Y-m-d', strtotime($today . ' -' . self::DAYS_BACK . ' days'));
        $runIds = $read->fetchCol(
            "SELECT DISTINCT cr.run_id
               FROM `$runsTbl` cr
               JOIN `$linkTbl` l ON l.run_id = cr.run_id
               LEFT JOIN `$sentTbl` s ON s.run_id = cr.run_id
              WHERE s.run_id IS NULL
                AND DATE(COALESCE(cr.course_end_date, cr.course_start_date)) >= ?
                AND DATE(COALESCE(cr.course_end_date, cr.course_start_date)) <= ?",
            array($from, $today)
        );

        /** @var MMD_FeedbackForm_Helper_Data $h */
        $h    = Mage::helper('mmd_feedbackform');
        $sent = 0;
        foreach ($runIds as $runId) {
            try {
                $run       = $h->loadRun((int)$runId);
                $responses = $h->responsesForRun((int)$runId);
                if (!$run || !$responses) continue;

                $mail = $this->buildMail($run, $responses, $site);
                $this->_send($mail['to'], $mail['cc'], $mail['subject'], $mail['body'], $site['from']);

                $write->insert($sentTbl, array(
                    'run_id'         => (int)$runId,
                    'response_count' => count($responses),
                    'recipients'     => implode(', ', array_merge($mail['to'], $mail['cc'])),
                ));
                $sent++;
            } catch (Exception $e) {
                Mage::log('Class evaluation email error run=' . $runId . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            }
        }

        Mage::log(sprintf('Class evaluation emails complete — sent:%d (classes:%d)', $sent, count($runIds)), Zend_Log::INFO, self::LOG_FILE);
    }

    /**
     * Recipients, subject and HTML body for one class. The trainer is the
     * To; with no trainer email on file the site's staff receive it directly.
     *
     * @param array $run       MMD_FeedbackForm_Helper_Data::loadRun()
     * @param array $responses MMD_FeedbackForm_Helper_Data::responsesForRun()
     * @param array $site      one entry of $_sites
     * @return array { to: string[], cc: string[], subject: string, body: string }
     */
    public function buildMail(array $run, array $responses, array $site)
    {
        $trainer = Mage::helper('mmd_rolemanager/trainer')->resolveRunTrainer($run);
        $email   = $trainer ? strtolower(trim((string)$trainer['email'])) : '';
        $name    = $trainer ? trim((string)$trainer['name']) : '';
        if ($email !== '' && Zend_Validate::is($email, 'EmailAddress')) {
            $to = array($email);
            $cc = array_values(array_diff($site['cc'], $to));
        } else {
            $to   = $site['cc'];
            $cc   = array();
            $name = $name !== '' ? $name . ' (no email on file)' : '';
        }

        $e  = function ($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); };
        $q  = Mage::helper('mmd_feedbackform')->questions();
        $p  = '<p style="margin:0 0 18px;">';
        $body = $p . 'Hello ' . $e($name !== '' ? $name : 'Team') . ',</p>'
              . $p . 'You have received evaluation feedback for the ' . $e($run['course_title'])
              . ' course (Code: ' . $e($run['course_sku']) . ').</p>';

        $n = 0;
        foreach ($q['ratings'] as $ratingId => $label) {
            if (isset($this->_ratingLabels[$ratingId])) $label = $this->_ratingLabels[$ratingId];
            $lines = '';
            foreach ($responses as $i => $r) {
                if (isset($r['stars'][$ratingId])) {
                    $lines .= '<br>&nbsp;Learner ' . ($i + 1) . ': ' . (int)$r['stars'][$ratingId] . '/5';
                }
            }
            $body .= $p . (++$n) . '. ' . $e($label) . ':' . ($lines !== '' ? $lines : '<br>&nbsp;No ratings') . '</p>';
        }

        $lines = '';
        foreach ($responses as $i => $r) {
            if ($r['detail'] !== '') {
                $lines .= '<br>&nbsp;' . ($i + 1) . '. ' . nl2br($e($r['detail']));
            }
        }
        $body .= $p . 'Feedback from learners:' . ($lines !== '' ? $lines : '<br>&nbsp;No comments') . '</p>'
               . '<p style="margin:0;">Best regards,<br>' . $e($site['sign']) . '</p>';

        return array(
            'to'      => $to,
            'cc'      => $cc,
            'subject' => $site['prefix'] . 'Class Evaluation - ' . $run['course_title'] . ' (' . $run['class_id'] . ')',
            'body'    => '<div style="font-family:Arial,sans-serif;font-size:14px;line-height:1.5;color:#1f2937;">' . $body . '</div>',
        );
    }

    protected function _send(array $to, array $cc, $subject, $body, $fromName)
    {
        $gmail = Mage::helper('mmd_email/gmail');
        if ($gmail->isConfigured()) {
            $gmail->send(implode(', ', $to), $subject, $body, $fromName, $cc);
            return;
        }

        $mail = new Zend_Mail('UTF-8');
        foreach ($to as $addr) $mail->addTo($addr);
        foreach ($cc as $addr) $mail->addCc($addr);
        $mail->setFrom(Mage::getStoreConfig('trans_email/ident_general/email') ?: 'noreply@tertiarycourses.com.sg', $fromName)
             ->setSubject($subject)
             ->setBodyHtml($body)
             ->send();
    }
}
