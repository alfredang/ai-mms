<?php
/**
 * Consolidated course-feedback email — daily 09:00.
 *
 * For every class whose last day was yesterday or earlier (within a 7-day
 * lookback) and which received at least one QR feedback response, emails one
 * summary — average per question plus every learner's ratings and comment —
 * to this site's recipients. Each franchise site runs its own DB, so the
 * recipients are picked from MMS_COUNTRY_CODE (unset = SG, as in apply.php).
 * At-most-once per class via mmd_feedback_digest_sent.
 */
class MMD_FeedbackForm_Model_Cron_Digest
{
    const LOG_FILE  = 'feedback_digest.log';
    const DAYS_BACK = 7;

    /** Site => array(to, cc). */
    protected $_recipients = array(
        'SG' => array(array('tansc@tertiaryinfotech.com', 'angch@tertiaryinfotech.com'), array()),
        'MY' => array(array('sales@tertiarycourses.com.my'), array('saeid@tertiarycourses.com.my')),
        'GH' => array(array('siraj@tertiarycourses.com.gh'), array()),
    );

    /** Feedback form rating_id => short label (same as the admin Course Review grid). */
    protected $_ratings = array(1 => 'Learning Outcome', 2 => 'Trainer Quality', 5 => 'Training Environment');

    public function run()
    {
        $site = strtoupper((string)(getenv('MMS_COUNTRY_CODE') ?: 'SG'));
        if (!isset($this->_recipients[$site])) {
            Mage::log('Feedback digest skipped — no recipients for site ' . $site, Zend_Log::WARN, self::LOG_FILE);
            return;
        }
        list($to, $cc) = $this->_recipients[$site];

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $linkTbl  = $resource->getTableName('mmd_feedback_review_run');
        $sentTbl  = $resource->getTableName('mmd_feedback_digest_sent');
        $runsTbl  = $resource->getTableName('course_runs');

        $today = Mage::getModel('core/date')->date('Y-m-d');
        $from  = date('Y-m-d', strtotime($today . ' -' . self::DAYS_BACK . ' days'));
        $runIds = $read->fetchCol(
            "SELECT DISTINCT cr.run_id
               FROM `$runsTbl` cr
               JOIN `$linkTbl` l ON l.run_id = cr.run_id
               LEFT JOIN `$sentTbl` s ON s.run_id = cr.run_id
              WHERE s.run_id IS NULL
                AND DATE(COALESCE(cr.course_end_date, cr.course_start_date)) >= ?
                AND DATE(COALESCE(cr.course_end_date, cr.course_start_date)) < ?",
            array($from, $today)
        );

        $sent = 0;
        foreach ($runIds as $runId) {
            try {
                $run       = $this->_loadRun((int)$runId);
                $responses = $this->_loadResponses((int)$runId);
                if (!$run || !$responses) continue;

                $subject = 'Course Feedback: ' . $run['course_title'] . ' (' . $run['class_id'] . ') — '
                         . count($responses) . ' response' . (count($responses) === 1 ? '' : 's');
                $this->_send($to, $cc, $subject, $this->_buildBody($run, $responses));

                $write->insert($sentTbl, array(
                    'run_id'         => (int)$runId,
                    'response_count' => count($responses),
                    'recipients'     => implode(', ', array_merge($to, $cc)),
                ));
                $sent++;
            } catch (Exception $e) {
                Mage::log('Feedback digest error run=' . $runId . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            }
        }

        Mage::log(sprintf('Feedback digest complete — sent:%d (classes:%d)', $sent, count($runIds)), Zend_Log::INFO, self::LOG_FILE);
    }

    protected function _loadRun($runId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $nameAttr = (int)Mage::getSingleton('eav/config')->getAttribute('catalog_product', 'name')->getId();

        return $read->fetchRow(
            "SELECT cr.run_id, cr.class_id, cr.course_sku, cr.course_start_date,
                    COALESCE(cr.course_end_date, cr.course_start_date) AS course_end_date,
                    COALESCE(pn.value, cr.course_sku) AS course_title,
                    COALESCE(
                        NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))), ''),
                        tov.value, ''
                    ) AS trainer_name
               FROM `" . $resource->getTableName('course_runs') . "` cr
               LEFT JOIN `" . $resource->getTableName('catalog_product_entity_varchar') . "` pn
                    ON pn.entity_id = cr.product_id AND pn.store_id = 0 AND pn.attribute_id = $nameAttr
               LEFT JOIN `" . $resource->getTableName('admin_user') . "` au ON au.user_id = cr.trainer_user_id
               LEFT JOIN `" . $resource->getTableName('eav_attribute_option_value') . "` tov
                    ON tov.option_id = cr.trainer_option_id AND tov.store_id = 0
              WHERE cr.run_id = ?",
            array($runId)
        ) ?: null;
    }

    /** One row per review: nickname, detail, created_at, stars (rating_id => value). */
    protected function _loadResponses($runId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');

        $rows = $read->fetchAll(
            "SELECT r.review_id, r.created_at, rd.nickname, rd.detail
               FROM `" . $resource->getTableName('mmd_feedback_review_run') . "` l
               JOIN `" . $resource->getTableName('review') . "` r ON r.review_id = l.review_id
               JOIN `" . $resource->getTableName('review_detail') . "` rd ON rd.review_id = r.review_id
              WHERE l.run_id = ?
              ORDER BY r.created_at",
            array($runId)
        );
        if (!$rows) return array();

        $byId = array();
        foreach ($rows as $row) {
            $row['stars'] = array();
            $byId[(int)$row['review_id']] = $row;
        }
        $votes = $read->fetchAll(
            "SELECT review_id, rating_id, value FROM `" . $resource->getTableName('rating_option_vote') . "`
              WHERE review_id IN (" . implode(',', array_keys($byId)) . ")"
        );
        foreach ($votes as $v) {
            $byId[(int)$v['review_id']]['stars'][(int)$v['rating_id']] = (int)$v['value'];
        }
        return array_values($byId);
    }

    protected function _buildBody(array $run, array $responses)
    {
        $e     = function ($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); };
        $th    = 'style="text-align:left;padding:6px 8px;border:1px solid #d0d7e2;background:#eef2f7;"';
        $td    = 'style="padding:6px 8px;border:1px solid #d0d7e2;vertical-align:top;"';
        $dates = date('d M Y', strtotime($run['course_start_date']));
        if (substr($run['course_end_date'], 0, 10) !== substr($run['course_start_date'], 0, 10)) {
            $dates .= ' – ' . date('d M Y', strtotime($run['course_end_date']));
        }

        // Averages per question, across the responses that rated it.
        $avgRows = '';
        $all     = array();
        foreach ($this->_ratings as $ratingId => $label) {
            $vals = array();
            foreach ($responses as $r) {
                if (isset($r['stars'][$ratingId])) $vals[] = $r['stars'][$ratingId];
            }
            $all = array_merge($all, $vals);
            $avgRows .= '<tr><td ' . $td . '>' . $e($label) . '</td><td ' . $td . '>'
                      . ($vals ? number_format(array_sum($vals) / count($vals), 1) . ' / 5' : '—') . '</td></tr>';
        }
        $avgRows .= '<tr><td ' . $td . '><strong>Overall</strong></td><td ' . $td . '><strong>'
                  . ($all ? number_format(array_sum($all) / count($all), 1) . ' / 5' : '—') . '</strong></td></tr>';

        $head = '<th ' . $th . '>Learner</th>';
        foreach ($this->_ratings as $label) $head .= '<th ' . $th . '>' . $e($label) . '</th>';
        $head .= '<th ' . $th . '>Comment</th>';
        $body = '';
        foreach ($responses as $r) {
            $body .= '<tr><td ' . $td . '>' . $e($r['nickname']) . '</td>';
            foreach ($this->_ratings as $ratingId => $label) {
                $body .= '<td ' . $td . '>' . (isset($r['stars'][$ratingId]) ? $r['stars'][$ratingId] : '—') . '</td>';
            }
            $comment = trim((string)$r['detail']);
            $body .= '<td ' . $td . '>' . ($comment === '' || $comment === 'N/A' ? '—' : nl2br($e($comment))) . '</td></tr>';
        }

        return '<div style="font-family:Arial,sans-serif;font-size:14px;color:#1f2937;">'
            . '<p>Consolidated learner feedback for the class below.</p>'
            . '<table style="border-collapse:collapse;margin-bottom:16px;">'
            . '<tr><td ' . $td . '>Course</td><td ' . $td . '><strong>' . $e($run['course_title']) . '</strong></td></tr>'
            . '<tr><td ' . $td . '>Course Code</td><td ' . $td . '>' . $e($run['course_sku']) . '</td></tr>'
            . '<tr><td ' . $td . '>Course Run ID</td><td ' . $td . '>' . $e($run['class_id']) . '</td></tr>'
            . '<tr><td ' . $td . '>Trainer</td><td ' . $td . '>' . $e($run['trainer_name'] ?: '—') . '</td></tr>'
            . '<tr><td ' . $td . '>Dates</td><td ' . $td . '>' . $e($dates) . '</td></tr>'
            . '<tr><td ' . $td . '>Responses</td><td ' . $td . '>' . count($responses) . '</td></tr>'
            . '</table>'
            . '<h3 style="font-size:15px;margin:0 0 8px;">Average ratings</h3>'
            . '<table style="border-collapse:collapse;margin-bottom:16px;">' . $avgRows . '</table>'
            . '<h3 style="font-size:15px;margin:0 0 8px;">Individual responses</h3>'
            . '<table style="border-collapse:collapse;"><tr>' . $head . '</tr>' . $body . '</table>'
            . '</div>';
    }

    protected function _send(array $to, array $cc, $subject, $body)
    {
        $fromName = 'Tertiary Courses';
        $gmail    = Mage::helper('mmd_email/gmail');
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
