<?php
/**
 * Malaysia only — daily 09:00 (store time): remind the class's trainer (To) and sales@ (Cc) when a finished
 * class's final attendance is not confirmed yet (Mr Saeid, 23 + 30 Oct 2026: "final attendance not confirmed:
 * 1 day after the class"; 3 Nov: "must be sent to sales and trainer both"). No trainer assigned: sales@ only.
 *
 * A class qualifies when it ended before today (within LOOKBACK_DAYS), has learners, has no certificate yet, and
 * its latest confirmation is not 'confirmed' or 'excluded'. One reminder per class, ever — the run ids already
 * reminded are kept in core_config_data (SENT_PATH). Off switch: mmd/attendance_reminder/enabled = 0.
 * The email links straight to the class's E-Attendance page (Saeid, 4 Nov: "with proper link").
 */
class MMD_Certificate_Model_Cron_AttendanceReminder
{
    const ENABLED_PATH  = 'mmd/attendance_reminder/enabled';
    // v2 (4 Nov): the reminder now carries a direct E-Attendance link (Saeid). A new key lets each class still
    // waiting get the linked version once; the old list (mmd/attendance_reminder/sent_run_ids) is left as it was.
    const SENT_PATH     = 'mmd/attendance_reminder/sent_run_ids_v2';
    const LOOKBACK_DAYS = 14;
    const LOG_FILE      = 'certificates.log';

    /** Cron entry point (Magento passes the schedule object — unused). */
    public function run($schedule = null)
    {
        if (!$this->_isMalaysia() || !Mage::getStoreConfigFlag(self::ENABLED_PATH)) {
            return;
        }
        $sent = 0;
        foreach ($this->collect() as $r) {
            try {
                $this->send($r);
                $this->markSent($r['run_id']);
                $sent++;
            } catch (Exception $e) {
                Mage::log('Attendance reminder error run=' . $r['run_id'] . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            }
        }
        Mage::log('Attendance reminder sweep complete — sent:' . $sent, Zend_Log::INFO, self::LOG_FILE);
    }

    /** The reminders due now: array of { run_id, to, cc, subject, body }. Sends nothing. */
    public function collect()
    {
        if (!$this->_isMalaysia()) {
            return array();
        }
        $h    = Mage::helper('mmd_certificate');
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $today = Mage::getModel('core/date')->date('Y-m-d');
        $since = date('Y-m-d', strtotime($today . ' -' . self::LOOKBACK_DAYS . ' days'));

        $runIds = $read->fetchCol(
            "SELECT cr.run_id FROM `" . $res->getTableName('course_runs') . "` cr
              WHERE cr.course_end_date < ? AND cr.course_end_date >= ?
                AND EXISTS (SELECT 1 FROM `" . $res->getTableName('course_run_enrolments') . "` e WHERE e.run_id = cr.run_id)
                AND NOT EXISTS (SELECT 1 FROM `" . $res->getTableName('mmd_course_run_certificate') . "` c WHERE c.run_id = cr.run_id)
              ORDER BY cr.course_end_date, cr.run_id",
            array($today, $since)
        );
        $already = $this->_sentIds();
        $to = Mage::getStoreConfig('trans_email/ident_sales/email') ?: 'sales@tertiarycourses.com.my';

        $out = array();
        foreach ($runIds as $runId) {
            $runId = (int) $runId;
            if (in_array($runId, $already, true)) {
                continue;
            }
            $conf = $h->confirmationForRun($runId);
            if ($conf && in_array($conf['status'], array('confirmed', 'excluded'), true)) {
                continue;
            }
            $run = $h->loadRun($runId);
            if (!$run) {
                continue;
            }
            $learners = (int) $read->fetchOne('SELECT COUNT(*) FROM ' . $res->getTableName('course_run_enrolments')
                . ' WHERE run_id = ?', array($runId));
            // The trainer is the one who confirms, so they get it directly; sales@ is copied.
            $trainer = Mage::helper('mmd_rolemanager/trainer')->resolveRunTrainer($run);
            $trainerEmail = $trainer && filter_var((string) $trainer['email'], FILTER_VALIDATE_EMAIL)
                ? strtolower(trim((string) $trainer['email'])) : '';
            $recipients = ($trainerEmail !== '' && $trainerEmail !== strtolower($to))
                ? array('to' => $trainerEmail, 'cc' => array($to))
                : array('to' => $to, 'cc' => array());
            $out[] = array('run_id' => $runId) + $recipients + $this->_message($run, $learners, $conf);
        }
        return $out;
    }

    public function send(array $r)
    {
        $info  = Mage::helper('mmd_certificate')->companyInfo();
        $gmail = Mage::helper('mmd_email/gmail');
        if ($gmail->isConfigured()) {
            $gmail->send($r['to'], $r['subject'], $r['body'], $info['short_name'], isset($r['cc']) ? $r['cc'] : array());
            return;
        }
        $mail = new Zend_Mail('UTF-8');
        foreach (isset($r['cc']) ? $r['cc'] : array() as $cc) {
            $mail->addCc($cc);
        }
        $mail->addTo($r['to'])
             ->setFrom($info['from_email'], $info['short_name'])
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

    protected function _message(array $run, $learners, $conf)
    {
        $h      = Mage::helper('mmd_certificate');
        $dates  = $h->formatDates($run['course_start_date'], $run['course_end_date']);
        $title  = $run['course_title'] . ' (' . trim($run['course_sku']) . ')';
        $esc    = function ($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); };
        // The trainer's E-Attendance page for this class (shows the login form first when logged out). Must be the
        // admin frontName: the /lmslogin router only reaches MMD_RoleManager's own controllers, so attendance 404s there.
        $link   = rtrim($h->companyInfo()['website'], '/') . '/adminlogin/attendance/index/run_id/' . (int) $run['run_id'] . '/bucket/completed';
        $state  = ($conf && $conf['status'] === 'reopened')
            ? 'Attendance was changed after it was confirmed, so it needs to be confirmed again.'
            : 'The final attendance has not been confirmed yet.';
        $body = '<p>Hello,</p>'
            . '<p>' . $esc($state) . ' Certificates of Attendance for this class are on hold until the trainer confirms it.</p>'
            . '<table cellpadding="4" style="border-collapse:collapse">'
            . '<tr><td><b>Class</b></td><td>' . $esc($run['class_id']) . '</td></tr>'
            . '<tr><td><b>Course</b></td><td>' . $esc($title) . '</td></tr>'
            . '<tr><td><b>Dates</b></td><td>' . $esc($dates) . '</td></tr>'
            . '<tr><td><b>Trainer</b></td><td>' . $esc($run['trainer_name'] !== '' ? $run['trainer_name'] : 'not assigned') . '</td></tr>'
            . '<tr><td><b>Learners</b></td><td>' . (int) $learners . '</td></tr>'
            . '</table>'
            . '<p>To release the certificates, the trainer opens the class on the E-Attendance page, checks the '
            . 'attendance, ticks "I confirm this attendance is final" and clicks "Confirm Final Attendance". '
            . 'Certificates are then sent automatically to learners with at least 75% of the training hours.</p>'
            . '<p><a href="' . $esc($link) . '" style="display:inline-block;padding:8px 18px;background:#2563eb;color:#ffffff;'
            . 'font-weight:600;border-radius:6px;text-decoration:none">Open E-Attendance for ' . $esc($run['class_id']) . '</a></p>'
            . '<p style="font-size:12px;color:#555">Link: <a href="' . $esc($link) . '">' . $esc($link) . '</a><br>'
            . 'Log in with your email if asked. If you land on the dashboard after logging in, open the link again.</p>'
            . '<p>This is an automatic reminder, sent once per class.</p>';
        return array('subject' => 'Reminder: final attendance not confirmed - ' . $run['class_id'] . ' ' . $title . ', ' . $dates,
                     'body' => $body);
    }

    protected function _isMalaysia()
    {
        $store = Mage::app()->getDefaultStoreView();
        return $store && $store->getCode() === 'malaysia';
    }
}
