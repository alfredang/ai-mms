<?php
/**
 * The class page sections the apps show beside the website's class page
 * (dashboard "View Course"): Announcements, Lesson, Practice Exam, the venue
 * address and the Course Feedback summary, plus the Support tab's contacts and
 * feedback email. Shared by the learner and trainer helpers; every caller has
 * already checked that the class is the caller's own.
 */
class MMD_MobileApi_Helper_ClassPage extends Mage_Core_Helper_Abstract
{
    /** The academy's own address, used for a classroom class whose run has no venue. */
    const SG_ADDRESS = '12 Woodlands Square #07-85/86/87, Woods Square Tower 1, Singapore 737715';

    const SUPPORT_MAX_SUBJECT = 150;
    const SUPPORT_MAX_MESSAGE = 5000;
    const SUPPORT_PER_HOUR    = 5;

    /** Run one section builder; a failure leaves that section empty instead of failing the class page. */
    public function safe($fn, $fallback)
    {
        try {
            return $fn();
        } catch (Exception $e) {
            Mage::logException($e);
            return $fallback;
        }
    }

    // ── Venue ────────────────────────────────────────────────────────────────

    public function academyAddress()
    {
        $store = Mage::app()->getDefaultStoreView();
        $addr  = trim(preg_replace('/\s*\n\s*/', ', ', (string) Mage::getStoreConfig('general/store_information/address', $store)));
        if ($addr !== '') {
            return $addr;
        }
        return Mage::helper('mmd_mobileapi')->countryCode() === 'SG' ? self::SG_ADDRESS : '';
    }

    /**
     * The address a class is held at: the run's own venue, else the academy's
     * address. Live Online classes have none.
     */
    public function venue(array $r, $mode)
    {
        if ((int) $mode === 2) {
            return '';
        }
        $parts = array_filter(array_map('trim', array(
            (string) $r['venue_block'], (string) $r['venue_street'],
            trim(($r['venue_floor'] ? '#' . $r['venue_floor'] : '') . ($r['venue_unit'] ? '-' . $r['venue_unit'] : '')),
            (string) $r['venue_building'], (string) $r['postal_code'],
        )));
        if ($parts) {
            return implode(', ', $parts);
        }
        try {
            return $this->academyAddress();
        } catch (Exception $e) {
            return '';
        }
    }

    // ── Announcements ────────────────────────────────────────────────────────

    /** Posts of a class, oldest first (the website's order). */
    public function announcements($runId)
    {
        $out = array();
        foreach (Mage::helper('mmd_attendance/announcement')->listForRun((int) $runId) as $a) {
            $out[] = array(
                'id'        => (int) $a['id'],
                'message'   => (string) $a['message'],
                'file_name' => (string) $a['file_name'],
                'file_url'  => (string) $a['file_url'],
                'posted_by' => (string) $a['posted_by'],
                'posted_at' => (string) $a['posted_at'],
            );
        }
        return $out;
    }

    /** A text post by the class's trainer (the caller has checked the class is theirs). */
    public function postAnnouncement($email, $runId, $message)
    {
        $message = trim((string) preg_replace('/[\x{10000}-\x{10FFFF}]/u', '', (string) $message));
        if (function_exists('mb_substr')) {
            $message = mb_substr($message, 0, MMD_Attendance_Helper_Announcement::MAX_MESSAGE_CHARS, 'UTF-8');
        }
        if ($message === '') {
            throw new Exception('Type a message before posting.');
        }
        $profile = Mage::helper('mmd_mobileapi')->learnerProfile($email);
        $user    = Mage::helper('mmd_mobileapi')->loadAdminUser($email);
        $name    = trim((string) $profile['full_name']);
        $res     = Mage::getSingleton('core/resource');
        $res->getConnection('core_write')->insert($res->getTableName('mmd_class_announcement'), array(
            'run_id'            => (int) $runId,
            'message'           => $message,
            'file_name'         => null,
            'file_url'          => null,
            'file_key'          => null,
            'posted_by'         => $name !== '' ? $name : 'Trainer',
            'posted_by_user_id' => $user ? (int) $user->getId() : null,
            'created_at'        => gmdate('Y-m-d H:i:s'),
        ));
        return $this->announcements($runId);
    }

    /** Delete a post of this class. */
    public function deleteAnnouncement($runId, $announcementId)
    {
        $h   = Mage::helper('mmd_attendance/announcement');
        $row = $h->load((int) $announcementId);
        if (!$row || (int) $row['run_id'] !== (int) $runId) {
            throw new Exception('That announcement is no longer on this class.');
        }
        $h->delete($row);
        return $this->announcements($runId);
    }

    // ── Lesson ───────────────────────────────────────────────────────────────

    /**
     * The course Lesson as the class page shows it: topics > sub topics >
     * links, videos and quizzes. A quiz carries its question count and, for a
     * trainer, the QR link learners scan; for a learner, their latest score.
     */
    public function lesson($productId, $runId, $email, $trainer)
    {
        $lq     = Mage::helper('mmd_lessonquiz');
        $topics = $lq->productLesson((int) $productId);
        $counts = array();
        try {
            $counts = $lq->questionCounts($lq->quizIds($topics));
        } catch (Exception $e) {
            $counts = array();
        }
        $out = array();
        foreach ($topics as $t) {
            $subs = array();
            foreach ($t['subsecs'] as $s) {
                $links = array();
                foreach ($s['links'] as $l) {
                    $type = (string) $l['type'];
                    if ($type === 'qz') {
                        $qid = (int) $l['qid'];
                        $n   = isset($counts[$qid]) ? (int) $counts[$qid] : 0;
                        if ($qid <= 0 || $n === 0) continue;
                        $links[] = array(
                            'type'      => 'quiz',
                            'title'     => (string) $l['title'] !== '' ? (string) $l['title'] : 'Quiz',
                            'url'       => $trainer ? $lq->quizUrl($qid, $runId) : '',
                            'quiz_id'   => $qid,
                            'questions' => $n,
                            'previous'  => $trainer ? null : $lq->lastAttempt($qid, $email),
                        );
                        continue;
                    }
                    $url = trim((string) $l['url']);
                    if (!preg_match('#^https?://#i', $url)) continue;
                    $links[] = array(
                        'type'  => $type === 'yt' ? 'video' : ($type === 'doc' ? 'document' : ($type === 'act' ? 'activity' : 'web')),
                        'title' => (string) $l['title'] !== '' ? (string) $l['title'] : $url,
                        'url'   => $url,
                    );
                }
                $subs[] = array('title' => (string) $s['title'], 'links' => $links);
            }
            $out[] = array('title' => (string) $t['title'], 'subtopics' => $subs);
        }
        return $out;
    }

    // ── Practice Exam (trainer) ──────────────────────────────────────────────

    /** The course's linked practice exam and the class's self-register link, or null. */
    public function practiceExam(array $run)
    {
        try {
            $pe = Mage::helper('mmd_practiceexam');
            if (!$pe->isConfigured()) return null;
            $exam = $pe->getCourseExam((int) $run['product_id']);
            if (!$exam) return null;
            $full = $pe->loadRun((int) $run['run_id']);
            return array(
                'exam_code'         => (string) $exam['exam_code'],
                'exam_url'          => $pe->baseUrl(),
                'self_register_url' => $pe->selfRegisterUrl((int) $run['run_id']),
                'open'              => $full ? (bool) $pe->selfRegisterOpen($full) : true,
            );
        } catch (Exception $e) {
            return null;
        }
    }

    // ── Course Feedback summary (trainer) ────────────────────────────────────

    /** Average per rating question, overall average and the comments of a class's feedback. */
    public function feedbackSummary($runId)
    {
        if (Mage::helper('mmd_rolemanager/handover')->isManaged((int) $runId)) {
            return null; // feedback lives on the TMS for these classes
        }
        $fb        = Mage::helper('mmd_feedbackform');
        $responses = $fb->responsesForRun((int) $runId);
        $q         = $fb->questions();
        $sums      = array();
        $comments  = array();
        foreach ($responses as $r) {
            foreach ($r['stars'] as $ratingId => $v) {
                if ($v < 1) continue;
                if (!isset($sums[$ratingId])) $sums[$ratingId] = array(0, 0);
                $sums[$ratingId][0] += $v;
                $sums[$ratingId][1]++;
            }
            if ($r['detail'] !== '') $comments[] = (string) $r['detail'];
        }
        $questions = array();
        $total = 0; $count = 0;
        foreach ($q['ratings'] as $ratingId => $label) {
            $s = isset($sums[$ratingId]) ? $sums[$ratingId] : array(0, 0);
            $questions[] = array('label' => $label, 'average' => $s[1] ? round($s[0] / $s[1], 1) : null);
            $total += $s[0]; $count += $s[1];
        }
        return array(
            'count'     => count($responses),
            'overall'   => $count ? round($total / $count, 1) : null,
            'questions' => $questions,
            'comments'  => array_reverse($comments), // newest first
        );
    }

    // ── Support ──────────────────────────────────────────────────────────────

    public function supportInfo()
    {
        $site = Mage::helper('mmd_mobileapi')->siteInfo();
        $wa   = trim((string) Mage::getStoreConfig('mmd_mobileapi/general/support_whatsapp'));
        if ($wa === '' && $site['country'] === 'SG') $wa = '+65 8866 6375';
        return array(
            'email'    => $site['email'] !== '' ? $site['email'] : null,
            'phone'    => $site['phone'] !== '' ? $site['phone'] : null,
            'whatsapp' => $wa !== '' ? $wa : null,
            'address'  => $this->academyAddress() ?: null,
            'feedback' => true,
        );
    }

    /** Email the learner's message to the academy, with their name and email for the reply. */
    public function sendSupport($email, $subject, $message, $appVersion = '')
    {
        $subject = trim((string) $subject);
        $message = trim((string) $message);
        if ($subject === '' || $message === '') {
            throw new Exception('Please enter a subject and a message.');
        }
        if (function_exists('mb_substr')) {
            $subject = mb_substr($subject, 0, self::SUPPORT_MAX_SUBJECT, 'UTF-8');
            $message = mb_substr($message, 0, self::SUPPORT_MAX_MESSAGE, 'UTF-8');
        }
        // A light limit per account so the form cannot be used to flood the inbox.
        $cache = Mage::app()->getCache();
        $key   = 'mmd_mobileapi_support_' . md5($email . date('YmdH'));
        $sent  = (int) $cache->load($key);
        if ($sent >= self::SUPPORT_PER_HOUR) {
            throw new Exception('You have sent several messages in the last hour. Please email us directly or try again later.');
        }
        $cache->save((string) ($sent + 1), $key, array(), 3600);

        $h       = Mage::helper('mmd_mobileapi');
        $site    = $h->siteInfo();
        $profile = $h->learnerProfile($email);
        $to      = $site['email'] !== '' ? $site['email'] : (string) Mage::getStoreConfig('trans_email/ident_general/email');
        $name    = trim((string) $profile['full_name']);
        $roles   = isset($profile['roles']) ? implode(', ', (array) $profile['roles']) : '';
        $html =
            '<p><strong>App support message</strong> from ' . htmlspecialchars($name !== '' ? $name : $email) . '</p>' .
            '<p>Email: ' . htmlspecialchars($email) . '<br>' .
            ($profile['phone'] !== '' ? 'Phone: ' . htmlspecialchars($profile['phone']) . '<br>' : '') .
            ($roles !== '' ? 'Role: ' . htmlspecialchars($roles) . '<br>' : '') .
            'App: ' . htmlspecialchars($site['name'] . ($appVersion !== '' ? ' ' . $appVersion : '')) . '</p>' .
            '<p><strong>' . htmlspecialchars($subject) . '</strong></p>' .
            '<p>' . nl2br(htmlspecialchars($message)) . '</p>';
        $fullSubject = '[App support] ' . $subject;
        $gmail = Mage::helper('mmd_email/gmail');
        if ($gmail && $gmail->isConfigured()) {
            $gmail->send($to, $fullSubject, $html, $name !== '' ? $name . ' (app)' : (string) Mage::getStoreConfig('trans_email/ident_general/name'));
        } else {
            Mage::getModel('core/email')
                ->setToEmail($to)->setToName($site['name'])
                ->setSubject($fullSubject)
                ->setBody(strip_tags(str_replace(array('<br>', '</p>'), "\n", $html)))
                ->setFromEmail((string) Mage::getStoreConfig('trans_email/ident_general/email'))
                ->setFromName((string) Mage::getStoreConfig('trans_email/ident_general/name'))
                ->setType('text')
                ->send();
        }
    }
}
