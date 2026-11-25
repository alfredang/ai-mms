<?php
/**
 * Sample LMS data for the App Review account (mmd_mobileapi/general/demo_emails).
 *
 * Apple and Google need a working sign-in that shows every feature. Real
 * rosters cannot be used (they would expose learners and pollute attendance,
 * reviews and franchise billing), so this account sees a clearly labelled
 * sample: one class running today (check-in open), one upcoming, two past —
 * one with a certificate and feedback done, one with feedback still to give.
 * Writes are accepted and answered but never stored. Dates move with today.
 */
class MMD_MobileApi_Helper_Demo extends Mage_Core_Helper_Abstract
{
    const RUN_CURRENT  = 900001;
    const RUN_UPCOMING = 900002;
    const RUN_PAST     = 900003;
    const RUN_PAST_CERT = 900004;

    const RUN_TEACHING = 900005;

    public function profile($email)
    {
        return array(
            'email' => $email, 'first_name' => 'Sample', 'last_name' => 'Learner', 'full_name' => 'Sample Learner',
            'phone' => '', 'linkedin_url' => '', 'theme' => 'system', 'avatar_version' => Mage::helper('mmd_mobileapi')->avatarVersion($email), 'roles' => array('learner', 'trainer'),
        );
    }

    /** Echo the reviewer's change back so the screens update; nothing is stored. */
    public function saveProfile($email, array $in)
    {
        $p = $this->profile($email);
        foreach (array('first_name', 'last_name', 'phone') as $k) {
            if (isset($in[$k]) && trim((string) $in[$k]) !== '') $p[$k] = mb_substr(trim(strip_tags((string) $in[$k])), 0, 32);
        }
        if (isset($in['theme']) && in_array($in['theme'], array('system', 'light', 'dark'), true)) {
            $p['theme'] = $in['theme'];
        }
        $p['full_name'] = trim($p['first_name'] . ' ' . $p['last_name']);
        return $p;
    }

    // ── Sample class the reviewer teaches ────────────────────────────────────

    public function trainerClasses()
    {
        $run = $this->_teachingRun();
        unset($run['course_url'], $run['price']);
        return array('current' => array($run), 'upcoming' => array(), 'past' => array());
    }

    public function trainerClassDetail($runId)
    {
        if ((int) $runId !== self::RUN_TEACHING) {
            return null;
        }
        $run   = $this->_teachingRun();
        $today = $this->_today();
        $days  = $this->_days($run['start_date'], $run['end_date']);
        $sessions = array();
        foreach ($days as $i => $d) {
            foreach (array('am' => 'AM', 'pm' => 'PM') as $k => $lbl) {
                $sessions[] = array(
                    'key' => 'd' . ($i + 1) . $k, 'day' => $i + 1, 'part' => $lbl, 'date' => $d,
                    'label' => 'Day ' . ($i + 1) . ' · ' . date('D j M', strtotime($d)) . ' · ' . $lbl,
                );
            }
        }
        $dayIdx  = array_search($today, $days, true);
        $current = 'd' . (($dayIdx === false ? 0 : $dayIdx) + 1) . ($this->_hour() < 13 ? 'am' : 'pm');
        $label   = '';
        foreach ($sessions as $s) {
            if ($s['key'] === $current) $label = $s['label'];
        }
        $roster = array();
        foreach (array('Aisha Rahman', 'Daniel Lim', 'Mei Ling Tan', 'Priya Nair', 'Wei Jie Ong') as $i => $name) {
            $roster[] = array(
                'name' => $name, 'email' => 'learner' . ($i + 1) . '@example.com', 'phone' => '', 'walkin' => false,
                'present' => $i < 3 ? array($current) : array(),
                'signed'  => $i < 2 ? array($current) : array(),
            );
        }
        $courseUrl = $run['course_url'];
        unset($run['course_url'], $run['price'], $run['days'], $run['status'], $run['order_no'], $run['certificate'],
            $run['survey_submitted'], $run['role'], $run['product_id'], $run['learner_count']);
        return $run + array(
            'sessions'              => $sessions,
            'current_session'       => $current,
            'current_session_label' => $label,
            'attendance_open'       => true,
            'checkin_url'           => $courseUrl,
            'roster'                => $roster,
            'trainer_signed'        => array(),
            'materials'             => array(array('key' => 'course_page', 'title' => 'Course Outline', 'url' => $courseUrl)),
            'documents'             => array(),
            'survey_responses'      => 3,
            'announcements'         => $this->announcements(),
            'lesson'                => $this->_lesson(true),
            'practice_exam'         => null,
            'feedback_summary'      => array(
                'count' => 3, 'overall' => 4.6,
                'questions' => array(
                    array('label' => 'The trainer explained the topics clearly', 'average' => 4.7),
                    array('label' => 'The course content met my needs', 'average' => 4.3),
                    array('label' => 'I would recommend this course', 'average' => 4.7),
                ),
                'comments' => array('Very practical, thank you!', 'Great hands-on labs.'),
            ),
        );
    }

    public function saveTrainerAttendance($runId)
    {
        if ((int) $runId !== self::RUN_TEACHING) {
            return array('success' => false, 'message' => 'This class is not on your account.');
        }
        return array('success' => true, 'message' => 'Attendance saved. (Sample account: nothing was recorded.)');
    }

    public function signAttendance($runId)
    {
        if ((int) $runId !== self::RUN_TEACHING) {
            return array('success' => false, 'message' => 'This class is not on your account.');
        }
        return array('success' => true, 'message' => 'Signature received. (Sample account: nothing was recorded.)');
    }

    protected function _teachingRun()
    {
        $runs = $this->_runs();
        $run  = $runs[self::RUN_PAST];   // a different course from the class the reviewer attends today
        $t    = $this->_today();
        $run['run_id']     = self::RUN_TEACHING;
        $run['class_id']   = 'SAMPLE05';
        $run['start_date'] = $t;
        $run['end_date']   = date('Y-m-d', strtotime($t . ' +1 day'));
        $run['days']       = $this->_days($run['start_date'], $run['end_date']);
        $run['bucket']     = 'current';
        $run['trainer']    = 'Sample Learner';
        $run['order_no']   = null;
        $run['certificate'] = null;
        $run['survey_submitted'] = null;
        $run['role']       = 'trainer';
        $run['learner_count'] = 5;
        return $run;
    }

    public function classes()
    {
        $out = array('current' => array(), 'upcoming' => array(), 'past' => array());
        foreach ($this->_runs() as $run) {
            $out[$run['bucket']][] = $run;
        }
        return $out;
    }

    public function classDetail($runId)
    {
        $runs = $this->_runs();
        if (!isset($runs[$runId])) {
            return null;
        }
        $run   = $runs[$runId];
        $today = $this->_today();
        $days  = $this->_days($run['start_date'], $run['end_date']);
        $sessions = array();
        foreach ($days as $i => $d) {
            foreach (array('am' => 'AM', 'pm' => 'PM') as $k => $lbl) {
                $past = $d < $today || ($d === $today && $k === 'am' && $this->_hour() >= 13);
                $sessions[] = array(
                    'key' => 'd' . ($i + 1) . $k, 'day' => $i + 1, 'part' => $lbl, 'date' => $d,
                    'label' => 'Day ' . ($i + 1) . ' · ' . date('D j M', strtotime($d)) . ' · ' . $lbl,
                    'present' => $run['bucket'] === 'upcoming' ? null : ($past || $run['bucket'] === 'past' ? true : null),
                );
            }
        }
        $current = '';
        if ($run['bucket'] === 'current') {
            $dayIdx  = array_search($today, $days, true);
            $current = 'd' . (($dayIdx === false ? 0 : $dayIdx) + 1) . ($this->_hour() < 13 ? 'am' : 'pm');
        }
        $currentLabel = '';
        foreach ($sessions as $s) {
            if ($s['key'] === $current) $currentLabel = $s['label'];
        }
        $present = count(array_filter(array_column($sessions, 'present')));

        $run['sessions']   = $sessions;
        $run['attendance'] = array(
            'open'                  => $run['bucket'] === 'current',
            'current_session'       => $current,
            'current_session_label' => $currentLabel,
            'marked_present'        => false,
            'sessions_present'      => $present,
            'sessions_total'        => count($sessions),
        );
        $run['materials'] = array(
            array('key' => 'course_page', 'title' => 'Course Outline', 'url' => $run['course_url']),
        );
        $run['documents'] = array();
        $run['survey'] = $this->_surveyState($run);
        $run['certificate_rule'] = Mage::helper('mmd_certificate')->attendanceRuleLabel();
        $sample = $this->quiz(self::SAMPLE_QUIZ_ID);
        $run['quizzes'] = array(array(
            'quiz_id'   => self::SAMPLE_QUIZ_ID,
            'title'     => $sample['title'],
            'questions' => count($sample['questions']),
            'url'       => '',
            'previous'  => null,
        ));
        $run['announcements'] = $this->announcements();
        $run['lesson']        = $this->_lesson(false);
        return $run;
    }

    const SAMPLE_QUIZ_ID = 900101;

    /** The sample class's announcement (nothing is stored for the sample account). */
    public function announcements()
    {
        return array(array(
            'id' => 1, 'message' => "Welcome to the class! Please bring your laptop. Slides: https://www.tertiarycourses.com.sg",
            'file_name' => '', 'file_url' => '', 'posted_by' => 'Sample Trainer',
            'posted_at' => date('D, j M Y', strtotime($this->_today())) . ', 09:00',
        ));
    }

    protected function _lesson($trainer)
    {
        $sample = $this->quiz(self::SAMPLE_QUIZ_ID);
        return array(
            array('title' => 'Topic 1: Getting started', 'subtopics' => array(
                array('title' => 'Overview of the course', 'links' => array(
                    array('type' => 'web', 'title' => 'Course page', 'url' => 'https://www.tertiarycourses.com.sg'),
                )),
                array('title' => 'Check your understanding', 'links' => array(
                    array('type' => 'quiz', 'title' => $sample['title'], 'url' => '', 'quiz_id' => self::SAMPLE_QUIZ_ID,
                          'questions' => count($sample['questions']), 'previous' => null),
                )),
            )),
            array('title' => 'Topic 2: Hands-on practice', 'subtopics' => array(
                array('title' => 'Guided lab', 'links' => array()),
            )),
        );
    }

    /** The sample lesson quiz of the sample classes (same shape as MMD_LessonQuiz_Helper_Data::getQuiz). */
    public function quiz($quizId)
    {
        if ((int) $quizId !== self::SAMPLE_QUIZ_ID) {
            return null;
        }
        return array(
            'quiz_id'    => self::SAMPLE_QUIZ_ID,
            'product_id' => 0,
            'title'      => 'Sample quiz: getting started',
            'questions'  => array(
                array('id' => 's1', 'question' => 'Where do you check in to a class session?', 'correct' => 1,
                    'options' => array('On the Billing tab', 'On the class page, under Digital attendance', 'In the course catalog')),
                array('id' => 's2', 'question' => 'When can you give course feedback?', 'correct' => 0,
                    'options' => array('From the class page, once the class has started', 'Only by email', 'Before you register')),
                array('id' => 's3', 'question' => 'Where do you find your certificate after a class?', 'correct' => 2,
                    'options' => array('In the Calendar tab', 'In the Courses tab', 'In the Certificates tab')),
            ),
        );
    }

    public function markAttendance($runId)
    {
        $runs = $this->_runs();
        if (!isset($runs[$runId]) || $runs[$runId]['bucket'] !== 'current') {
            return array('success' => false, 'message' => 'Check-in is not open for this class right now.');
        }
        return array('success' => true, 'message' => 'You have been marked present. Thank you! (Sample account — nothing was recorded.)');
    }

    public function survey($runId)
    {
        $runs = $this->_runs();
        if (!isset($runs[$runId])) {
            return null;
        }
        $run      = $runs[$runId];
        $template = Mage::helper('mmd_feedbackform')->getOrCreateTemplate();
        $context  = array(
            'course_title' => $run['title'], 'course_code' => $run['sku'], 'class_id' => $run['class_id'],
            'trainer_name' => $run['trainer'], 'start_date' => $run['start_date'], 'end_date' => $run['end_date'],
        );
        $sections = array();
        foreach ($template['sections'] as $section) {
            $fields = array();
            foreach ($section['fields'] as $f) {
                $value = '';
                if (!empty($f['autofill']) && isset($context[$f['autofill']])) {
                    $value = $context[$f['autofill']];
                } elseif ($f['type'] === 'text' && !empty($f['required']) && stripos((string) $f['label'], 'name') !== false) {
                    $value = 'Sample Learner';
                }
                $fields[] = array(
                    'id' => (string) $f['id'], 'label' => (string) $f['label'], 'type' => (string) $f['type'],
                    'required' => !empty($f['required']) && empty($f['readonly']), 'readonly' => !empty($f['readonly']),
                    'options' => array_values(array_filter(array_map('trim', explode(',', (string) (isset($f['options']) ? $f['options'] : ''))))),
                    'value' => (string) $value,
                );
            }
            $sections[] = array('id' => (string) $section['id'], 'title' => (string) $section['title'], 'fields' => $fields);
        }
        return array('title' => (string) $template['title'], 'state' => $this->_surveyState($run), 'sections' => $sections);
    }

    public function submitSurvey($runId)
    {
        $runs = $this->_runs();
        if (!isset($runs[$runId])) {
            return array('success' => false, 'message' => 'This class is not on your account.');
        }
        $state = $this->_surveyState($runs[$runId]);
        if (!$state['available']) {
            return array('success' => false, 'message' => $state['message']);
        }
        return array('success' => true, 'message' => 'Thank you! Your feedback has been recorded. (Sample account — nothing was stored.)');
    }

    public function certificates()
    {
        $runs = $this->_runs();
        return array($runs[self::RUN_PAST_CERT]['certificate']);
    }

    public function billing()
    {
        $site  = Mage::helper('mmd_mobileapi');
        $cur   = $site->currencyCode();
        $out   = array();
        $n     = 0;
        foreach ($this->_runs() as $run) {
            $n++;
            $paid = $run['bucket'] !== 'upcoming';
            $out[] = array(
                'order_no'       => 'SAMPLE-' . (100000 + $n),
                'date'           => date('Y-m-d', strtotime($run['start_date'] . ' -14 days')),
                'status'         => $paid ? 'paid' : 'pending',
                'status_label'   => $paid ? 'Paid' : 'Pending payment',
                'total'          => $run['price'],
                'paid'           => $paid ? $run['price'] : 0,
                'refunded'       => 0,
                'currency'       => $cur,
                'payment_method' => $paid ? 'Credit / Debit Card' : 'Bank Transfer',
                'invoices'       => $paid ? array('SAMPLE-INV-' . (100000 + $n)) : array(),
                'items'          => array(array(
                    'title' => $run['title'], 'sku' => $run['sku'], 'qty' => 1, 'amount' => $run['price'],
                    'class_date' => date('j M Y', strtotime($run['start_date'])), 'class_time' => '9:30am - 5:30pm',
                )),
            );
        }
        usort($out, function ($a, $b) { return strcmp($b['date'], $a['date']); });
        return $out;
    }

    /** PDF of the sample certificate (public; carries no personal data). */
    public function sampleCertificatePdf()
    {
        $runs = $this->_runs();
        $run  = $runs[self::RUN_PAST_CERT];
        $h    = Mage::helper('mmd_certificate');
        return $h->renderPdf($h->buildCertHtml('Sample Learner', $run['title'], $h->formatDates($run['start_date'], $run['end_date'])));
    }

    // ── Internals ────────────────────────────────────────────────────────────

    /** Four sample classes built from real catalog courses, dated around today. */
    protected function _runs()
    {
        static $runs = null;
        if ($runs !== null) {
            return $runs;
        }
        $courses = array();
        try {
            $courses = array_values(Mage::helper('mmd_mobileapi/catalog')->courses()['courses']);
        } catch (Exception $e) {
            $courses = array();
        }
        $pick = function ($i) use ($courses) {
            if ($courses) {
                // Spread the picks through the catalog so the sample looks varied.
                return $courses[(int) floor($i * count($courses) / 4) % count($courses)];
            }
            $fallback = array('Generative AI Essentials', 'Python Programming Fundamentals', 'Data Analytics with Excel', 'Digital Marketing Fundamentals');
            return array('id' => 0, 'sku' => 'C' . (1000 + $i), 'title' => $fallback[$i], 'url' => Mage::getBaseUrl(), 'image_url' => '', 'price' => 350.0);
        };
        $t = $this->_today();
        $d = function ($offset) use ($t) { return date('Y-m-d', strtotime($t . ' ' . ($offset >= 0 ? '+' : '') . $offset . ' days')); };
        $defs = array(
            self::RUN_CURRENT   => array(0, $d(0),   $d(1),   'current'),
            self::RUN_UPCOMING  => array(1, $d(12),  $d(13),  'upcoming'),
            self::RUN_PAST      => array(2, $d(-3),  $d(-2),  'past'),
            self::RUN_PAST_CERT => array(3, $d(-30), $d(-29), 'past'),
        );
        $runs = array();
        foreach ($defs as $runId => $def) {
            list($i, $start, $end, $bucket) = $def;
            $c = $pick($i);
            $runs[$runId] = array(
                'run_id'       => $runId,
                'class_id'     => 'SAMPLE' . substr((string) $runId, -2),
                'product_id'   => (int) $c['id'],
                'sku'          => (string) $c['sku'],
                'title'        => (string) $c['title'],
                'start_date'   => $start,
                'end_date'     => $end,
                'start_time'   => '09:30',
                'end_time'     => '17:30',
                'mode'         => $runId === self::RUN_UPCOMING ? 'Live Online' : 'Classroom',
                'venue'        => $runId === self::RUN_UPCOMING ? '' : 'Sample training venue',
                'room'         => $runId === self::RUN_UPCOMING ? '' : 'Room 1',
                'virtual_link' => $runId === self::RUN_UPCOMING ? 'https://meet.google.com/' : '',
                'trainer'      => 'Sample Trainer',
                'status'       => 'confirmed',
                'bucket'       => $bucket,
                'days'         => $this->_days($start, $end),
                'image_url'    => (string) $c['image_url'],
                'course_url'   => (string) $c['url'],
                'price'        => (float) $c['price'],
                'survey_submitted' => $runId === self::RUN_PAST_CERT,
                'role'         => 'learner',
                'certificate'  => null,
            );
        }
        $cert = $runs[self::RUN_PAST_CERT];
        $runs[self::RUN_PAST_CERT]['certificate'] = array(
            'run_id' => self::RUN_PAST_CERT, 'class_id' => $cert['class_id'], 'sku' => $cert['sku'], 'title' => $cert['title'],
            'start_date' => $cert['start_date'], 'end_date' => $cert['end_date'], 'cert_no' => $cert['class_id'] . '-0001',
            'issued_on' => $cert['end_date'], 'name' => Mage::helper('mmd_certificate')->certificateName(),
            'url' => Mage::getUrl('mobileapi/site/samplecertificate', array('_nosid' => true)),
        );
        return $runs;
    }

    protected function _surveyState(array $run)
    {
        $submitted = !empty($run['survey_submitted']);
        $available = !$submitted && $run['bucket'] !== 'upcoming';
        return array(
            'available'    => $available,
            'submitted'    => $submitted,
            'external_url' => '',
            'message'      => $submitted ? 'Thank you — your feedback has been recorded.'
                : ($available ? 'Tell us how the class went.' : 'The feedback survey opens on the first day of class.'),
        );
    }

    protected function _days($start, $end)
    {
        $out = array();
        for ($ts = strtotime($start); $ts <= strtotime($end); $ts += 86400) {
            $out[] = date('Y-m-d', $ts);
        }
        return $out;
    }

    protected function _today()
    {
        return Mage::helper('mmd_mobileapi')->today();
    }

    protected function _hour()
    {
        return (int) Mage::getModel('core/date')->date('H');
    }

    /** Sample payouts for the App Review account; nothing real. */
    public function payouts()
    {
        $m = gmdate('Y-m', strtotime('-1 month'));
        $rows = array(
            array('id' => 'demo-1', 'title' => 'Sample Course: Introduction to AI', 'course_code' => 'SAMPLE-01', 'learners' => 12,
                  'amount' => 800.00, 'payment_date' => $m . '-28', 'start_date' => $m . '-10', 'end_date' => $m . '-11'),
            array('id' => 'demo-2', 'title' => 'Sample Course: Data Analytics Basics', 'course_code' => 'SAMPLE-02', 'learners' => 9,
                  'amount' => 400.00, 'payment_date' => $m . '-14', 'start_date' => $m . '-03', 'end_date' => $m . '-03'),
        );
        return array('available' => true, 'payouts' => $rows, 'total' => 1200.00, 'currency' => 'SGD');
    }

    /** Sample training hours for the App Review account. */
    public function trainingHours()
    {
        $m = gmdate('Y-m', strtotime('-1 month'));
        return array(
            'total_hours' => 24.0,
            'months'  => array(array('month' => $m, 'hours' => 24.0)),
            'classes' => array(
                array('run_id' => self::RUN_TEACHING, 'title' => 'Sample Course: Introduction to AI', 'sku' => 'SAMPLE-01',
                      'start_date' => $m . '-10', 'end_date' => $m . '-11', 'days' => 2, 'hours' => 16.0),
                array('run_id' => self::RUN_TEACHING + 1, 'title' => 'Sample Course: Data Analytics Basics', 'sku' => 'SAMPLE-02',
                      'start_date' => $m . '-03', 'end_date' => $m . '-03', 'days' => 1, 'hours' => 8.0),
            ),
        );
    }
}
