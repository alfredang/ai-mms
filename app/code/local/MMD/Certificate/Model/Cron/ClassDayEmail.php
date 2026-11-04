<?php
/**
 * Malaysia only — daily 09:00 (store time): email each learner of a class that STARTS today its class details
 * (Mr Saeid, 4 Nov 2026: "on the class day 9 am", every learner, course/date/time + Zoom link or venue only,
 * from sales@ with the team in BCC; his team still sends the calendar invite). No courseware, no login link.
 *
 * One email per learner, To = the learner, Bcc = the booking-email copies (sales_email/order/copy_to). A class is
 * emailed once, ever — the run ids already done are kept in core_config_data (SENT_PATH). Sample approved by
 * Mr Saeid (4 Nov); off switch: mmd/class_day_email/enabled = 0. A physical class shows its venue (set by the agent
 * from the JD14 sheet's Training Venue), else KL Gateway.
 */
class MMD_Certificate_Model_Cron_ClassDayEmail
{
    const ENABLED_PATH = 'mmd/class_day_email/enabled';
    const SENT_PATH    = 'mmd/class_day_email/sent_run_ids';
    const LOG_FILE     = 'certificates.log';
    const VENUE_KL     = 'G-3A-02, Corporate Office Suite, KL Gateway, No. 2, Jalan Kerinchi, Gerbang Kerinchi Lestari, 59200 Kuala Lumpur, Malaysia';

    /** Cron entry point (Magento passes the schedule object — unused). */
    public function run($schedule = null)
    {
        if (!$this->_isMalaysia() || !Mage::getStoreConfigFlag(self::ENABLED_PATH)) {
            return;
        }
        $sent = 0;
        foreach ($this->collect() as $class) {
            // Marked first, so a failure half-way never re-sends to the learners already emailed.
            $this->markSent($class['run_id']);
            foreach ($class['emails'] as $r) {
                try {
                    $this->send($r);
                    $sent++;
                } catch (Exception $e) {
                    Mage::log('Class-day email error run=' . $class['run_id'] . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
                }
            }
        }
        Mage::log('Class-day email sweep complete — sent:' . $sent, Zend_Log::INFO, self::LOG_FILE);
    }

    /** The classes starting today, not yet emailed: array of { run_id, emails: [{ to, bcc, subject, body }] }. Sends nothing. */
    public function collect($today = null)
    {
        if (!$this->_isMalaysia()) {
            return array();
        }
        $h     = Mage::helper('mmd_certificate');
        $res   = Mage::getSingleton('core/resource');
        $read  = $res->getConnection('core_read');
        $today = $today ?: Mage::getModel('core/date')->date('Y-m-d');

        $runIds = $read->fetchCol(
            "SELECT cr.run_id FROM `" . $res->getTableName('course_runs') . "` cr
              WHERE cr.course_start_date = ? AND cr.class_id IS NOT NULL
                AND EXISTS (SELECT 1 FROM `" . $res->getTableName('course_run_enrolments') . "` e WHERE e.run_id = cr.run_id)
              ORDER BY cr.run_id",
            array($today)
        );
        $already = $this->_sentIds();
        $bcc = array_values(array_filter(array_map('trim', explode(',', (string) Mage::getStoreConfig('sales_email/order/copy_to')))));

        $out = array();
        foreach ($runIds as $runId) {
            $runId = (int) $runId;
            if (in_array($runId, $already, true)) {
                continue;
            }
            $run = $h->loadRun($runId);
            if (!$run) {
                continue;
            }
            $raw = $read->fetchRow('SELECT course_start_time, course_end_time, mode_of_training, virtual_link, venue_building FROM '
                . $res->getTableName('course_runs') . ' WHERE run_id = ?', array($runId));
            $learners = $read->fetchAll('SELECT TRIM(COALESCE(learner_name, \'\')) name, LOWER(TRIM(learner_email)) email FROM '
                . $res->getTableName('course_run_enrolments') . ' WHERE run_id = ? ORDER BY learner_email', array($runId));
            $emails = array();
            foreach ($learners as $l) {
                if (!filter_var($l['email'], FILTER_VALIDATE_EMAIL)) {
                    continue;
                }
                $msg = $this->_message($run, $raw, $l['name']);
                $emails[] = array('to' => $l['email'], 'bcc' => array_values(array_diff($bcc, array($l['email'])))) + $msg;
            }
            $out[] = array('run_id' => $runId, 'emails' => $emails);
        }
        return $out;
    }

    public function send(array $r)
    {
        $info  = Mage::helper('mmd_certificate')->companyInfo();
        $gmail = Mage::helper('mmd_email/gmail');
        if ($gmail->isConfigured()) {
            $gmail->send($r['to'], $r['subject'], $r['body'], 'Tertiary Courses Malaysia', array(), '', $r['bcc']);
            return;
        }
        $mail = new Zend_Mail('UTF-8');
        foreach ($r['bcc'] as $b) {
            $mail->addBcc($b);
        }
        $mail->addTo($r['to'])
             ->setFrom($info['from_email'], 'Tertiary Courses Malaysia')
             ->setSubject($r['subject'])
             ->setBodyHtml($r['body'])
             ->send();
    }

    public function markSent($runId)
    {
        $ids = $this->_sentIds();
        $ids[] = (int) $runId;
        $ids = array_slice(array_values(array_unique($ids)), -500);
        Mage::getConfig()->saveConfig(self::SENT_PATH, implode(',', $ids), 'default', 0);
        Mage::getConfig()->reinit();
    }

    protected function _sentIds()
    {
        $raw = (string) Mage::getSingleton('core/resource')->getConnection('core_read')->fetchOne(
            "SELECT value FROM core_config_data WHERE path = ? AND scope = 'default' AND scope_id = 0", array(self::SENT_PATH));
        return array_map('intval', array_filter(explode(',', $raw), 'strlen'));
    }

    protected function _message(array $run, array $raw, $learnerName)
    {
        $h     = Mage::helper('mmd_certificate');
        $info  = $h->companyInfo();
        $esc   = function ($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); };
        $title = $run['course_title'] . ' (' . trim($run['course_sku']) . ')';
        $dates = $h->formatDates($run['course_start_date'], $run['course_end_date']);

        $start   = (string) $raw['course_start_time'];
        $end     = (string) $raw['course_end_time'];
        $evening = $start !== '' && $start >= '17:00';
        $time = '';
        if ($start !== '' && $end !== '') {
            $time = $this->_ampm($start) . ' – ' . $this->_ampm($end) . ($evening ? '' : ' (lunch 12:30 – 1:30 pm)');
        }

        $virtual = (int) $raw['mode_of_training'] === 2;
        if ($virtual) {
            $link  = trim((string) $raw['virtual_link']);
            $where = '<b>Online via Zoom</b>: ' . ($link !== ''
                ? '<a href="' . $esc($link) . '">' . $esc($link) . '</a>'
                : 'the Zoom link will be sent to you separately');
        } else {
            $venue = trim((string) $raw['venue_building']);
            $where = '<b>Physical class</b>: ' . $esc($venue !== '' ? $venue : self::VENUE_KL);
        }

        $body = '<p>Dear ' . $esc($learnerName !== '' ? $learnerName : 'participant') . ',</p>'
            . '<p>This is a reminder that your class starts today.</p>'
            . '<table cellpadding="4" style="border-collapse:collapse">'
            . '<tr><td><b>Course</b></td><td>' . $esc($title) . '</td></tr>'
            . '<tr><td><b>Dates</b></td><td>' . $esc($dates) . '</td></tr>'
            . ($time !== '' ? '<tr><td><b>Time</b></td><td>' . $esc($time) . '</td></tr>' : '')
            . '<tr><td><b>Where</b></td><td>' . $where . '</td></tr>'
            . '</table>'
            . ($virtual ? '<p>Please join Zoom with this email address and your full name, so your attendance is recorded.</p>' : '')
            . '<p>If you have any questions, reply to this email or contact ' . $esc($info['support_email']) . '.</p>'
            . '<p>Regards,<br>Tertiary Courses Malaysia<br>' . $esc($info['name']) . ' (1187680-U)<br>HRD Corp Registered Training Provider</p>';
        return array('subject' => 'Your class today: ' . $title . ', ' . $dates, 'body' => $body);
    }

    /** "09:30:00" -> "9:30 am". */
    protected function _ampm($hms)
    {
        $t = strtotime('2000-01-01 ' . $hms);
        return $t ? strtolower(date('g:i a', $t)) : $hms;
    }

    protected function _isMalaysia()
    {
        $store = Mage::app()->getDefaultStoreView();
        return $store && $store->getCode() === 'malaysia';
    }
}
