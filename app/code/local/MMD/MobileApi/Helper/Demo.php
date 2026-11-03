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

    public function profile($email)
    {
        return array('email' => $email, 'first_name' => 'Sample', 'last_name' => 'Learner', 'full_name' => 'Sample Learner');
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
        return $run;
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
}
