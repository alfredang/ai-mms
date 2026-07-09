<?php
/**
 * Autonomous flyer pipeline (SG-only, gated by mmd_marketing/newsletter/blast_enabled).
 *
 *   propose()  — Mon & Thu 10:00: if the week still has a free blast slot, pick a
 *                popular upcoming class (next 2-3 weeks), render the flyer, store it
 *                as a 'pending' review, and email the managers Approve / Request-changes.
 *   followUp() — hourly: nothing to do here yet beyond expiring stale pending reviews;
 *                the regenerate-on-changes step is wired in Phase 2 (Claude subscription).
 *
 * Approval itself is handled by the public review endpoint (MMD_Marketing IndexController),
 * which on the SECOND manager approval calls scheduleApproved() below. All MailerLite
 * scheduling passes through MMD_Marketing_Helper_Blastguard so the "max 2 per week /
 * Monday & Thursday 08:00" hard rule can never be bypassed.
 */
class MMD_Marketing_Model_Cron_Flyer
{
    /** @return MMD_Marketing_Helper_Blastguard */
    protected function _guard() { return Mage::helper('mmd_marketing/blastguard'); }
    protected function _flyer() { return Mage::helper('mmd_marketing/flyer'); }

    /**
     * Wall-clock "now" string in Asia/Singapore (optionally shifted, e.g.
     * '-30 days'). Never use date()/time() here — Magento bootstrap forces
     * PHP to UTC while every pipeline timestamp is SGT (see Blastguard::nowLocal).
     */
    protected function _nowStr($modify = null, $format = 'Y-m-d H:i:s')
    {
        $dt = $this->_guard()->nowLocal();
        if ($modify) { $dt->modify($modify); }
        return $dt->format($format);
    }

    protected function _log($msg)
    {
        try {
            $dir = Mage::getBaseDir('log');
            if (!is_dir($dir)) @mkdir($dir, 0777, true);
            @file_put_contents($dir . '/marketing-cron.log',
                '[' . $this->_nowStr() . '] ' . $msg . "\n", FILE_APPEND);
        } catch (Exception $e) {}
    }

    protected function _tbl() { return Mage::getSingleton('core/resource')->getTableName('newsletters'); }
    protected function _read()  { return Mage::getSingleton('core/resource')->getConnection('core_read'); }
    protected function _write() { return Mage::getSingleton('core/resource')->getConnection('core_write'); }

    /** Cron entry: propose a new flyer for review (Mon & Thu 10:00). */
    public function propose()
    {
        $g = $this->_guard();
        if (!$g->isEnabled()) {
            return; // feature off (default on every instance except when SG toggles on)
        }
        // Don't stack proposals: if one is already awaiting review, skip this run.
        $pending = (int) $this->_read()->fetchOne(
            'SELECT COUNT(*) FROM ' . $this->_tbl()
          . " WHERE review_status IN ('pending','changes_requested')"
        );
        if ($pending > 0) {
            $this->_log('propose: skipped — a proposal is already awaiting review');
            return;
        }
        // HARD RULE #1 (design side): never propose more than 2 designs per week.
        if ($g->remainingDesignsThisWeek() < 1) {
            $this->_log('propose: skipped — 2 designs already proposed this week (weekly design cap)');
            return;
        }
        // Respect the weekly BLAST cap up front too — no point proposing if no slot is bookable.
        if ($g->nextSendSlot() === null) {
            $this->_log('propose: skipped — weekly cap reached, no bookable Mon/Thu slot');
            return;
        }
        // The admin-curated next-flyer queue wins: consume the TOP course.
        // Only when the queue is empty does the popular-class auto-pick run.
        $productId = $this->popFlyerQueue();
        if (!$productId) {
            $productId = $this->pickPopularUpcomingClass();
        }
        if (!$productId) {
            $this->_log('propose: skipped — flyer queue empty and no popular upcoming class found');
            return;
        }
        $newsletterId = $this->createProposal($productId);
        if ($newsletterId) {
            $this->sendForReview($newsletterId);
            $this->_log('propose: proposal #' . $newsletterId . ' for product ' . $productId . ' sent for review');
        }
    }

    /**
     * Pop the head of the admin-curated flyer queue (lowest position). The row
     * is DELETED on consumption so each queued course produces exactly one
     * proposal — no loop can re-propose it. Returns null when the queue is
     * empty or the table doesn't exist yet.
     */
    public function popFlyerQueue()
    {
        try {
            $row = $this->_read()->fetchRow(
                'SELECT queue_id, product_id FROM mmd_marketing_flyer_queue ORDER BY position ASC, queue_id ASC LIMIT 1');
            if (!$row) { return null; }
            $this->_write()->delete('mmd_marketing_flyer_queue', array('queue_id = ?' => (int) $row['queue_id']));
            $this->_log('propose: consumed flyer-queue head — product ' . (int) $row['product_id']);
            return (int) $row['product_id'];
        } catch (Exception $e) {
            return null; // table missing (migration not applied) — fall back to auto-pick
        }
    }

    /**
     * Cron entry (hourly): pipeline housekeeping.
     *  1. Email the managers any 'pending' proposal that was never sent for review
     *     (review_token empty — e.g. a proposal seeded by a migration or SQL).
     *  2. After a manager requests changes: supersede the old proposal, re-render
     *     the same course with fresh catalog data, and re-send for approval.
     *  3. Expire proposals left pending > 5 days.
     */
    public function followUp()
    {
        if (!$this->_guard()->isEnabled()) {
            return;
        }
        // HARD RULE (admin, 2026-07-04) — NO EMAIL SPAM, NO INFINITE CRON LOOPS:
        // per proposal, each manager receives AT MOST two emails, ever:
        //   (a) the original approval email, sent ONCE (sending stamps
        //       review_token, and only token-less rows are picked up here);
        //   (b) ONE reminder 24h later to managers who haven't responded
        //       (sending stamps _reminder_sent_at, checked before sending).
        // After that: silence. The 5-day expiry below retires the proposal.
        // Any future email added to this cron MUST carry a stamped-marker
        // guard like these two — never send based on state that the send
        // itself does not change.
        // 1. Unsent pending proposals -> email both managers ONCE.
        $ids = $this->_read()->fetchCol('SELECT newsletter_id FROM ' . $this->_tbl()
            . " WHERE review_status = 'pending' AND (review_token IS NULL OR review_token = '')");
        foreach ($ids as $nid) {
            $this->sendForReview((int) $nid);
            $this->_log('followUp: emailed managers for unsent pending proposal #' . (int) $nid);
        }
        // 1b. ONE reminder, 24h after the original send, only to managers who
        //     have not responded. _reminder_sent_at makes this fire at most once.
        $rows = $this->_read()->fetchAll('SELECT * FROM ' . $this->_tbl()
            . " WHERE review_status = 'pending' AND review_token IS NOT NULL AND review_token <> ''");
        foreach ($rows as $row) {
            $dec = json_decode((string) $row['review_decisions'], true);
            if (!is_array($dec)) { $dec = array(); }
            if (!empty($dec['_reminder_sent_at'])) { continue; }   // reminder already sent — never again
            // _sent_at / created_at are SGT wall-clock strings — compare against a
            // wall-clock "now" parsed the same way, never against time() (UTC).
            $sentAt = !empty($dec['_sent_at']) ? strtotime((string) $dec['_sent_at']) : strtotime((string) $row['created_at']);
            $nowTs  = strtotime($this->_nowStr());
            if (!$sentAt || ($nowTs - $sentAt) < 86400) { continue; }
            $silent = array();
            foreach ($this->_guard()->reviewers() as $r) {
                $rl = strtolower($r);
                if (empty($dec[$rl])) { $silent[] = $rl; }
            }
            if (empty($silent)) { continue; }
            $this->sendForReview((int) $row['newsletter_id'], $silent, true);
            $this->_log('followUp: 24h reminder for #' . (int) $row['newsletter_id']
                . ' to ' . implode(',', $silent) . ' — FINAL email for this proposal');
        }
        // 2. Change requests -> regenerate (same course, fresh render) + re-send.
        //    Safety net only: the admin "request changes" button and the email
        //    link both regenerate SYNCHRONOUSLY now, so this normally finds
        //    nothing. It still catches any changes_requested row that slipped
        //    through (e.g. a synchronous regenerate that errored mid-way).
        $rows = $this->_read()->fetchAll('SELECT newsletter_id FROM ' . $this->_tbl() . " WHERE review_status = 'changes_requested'");
        foreach ($rows as $row) {
            $this->regenerateOnChanges((int) $row['newsletter_id']);
        }
        // 3. Expire stale pendings.
        $this->_write()->update($this->_tbl(),
            array('review_status' => 'expired'),
            array("review_status = 'pending'", 'created_at < ?' => $this->_nowStr('-5 days'))
        );
    }

    /**
     * Rework a rejected flow: supersede it, re-render the SAME course with fresh
     * catalog data (carrying the manager's feedback), and re-send for approval.
     * Called SYNCHRONOUSLY the moment a manager requests changes (admin button +
     * email link) so a fresh approval email goes out immediately — the hourly
     * followUp() is just a safety net. Returns the new newsletter_id or null.
     *
     * No weekly-design-cap check here on purpose: reworking a rejected design
     * reuses the same weekly slot (the old row is superseded first), so it is NOT
     * a new design against the "max 2/week" rule — capping it here would strand a
     * flow with no way to be revised. It fires only on an explicit human change
     * request (one regenerate per request), so there is no runaway loop.
     */
    public function regenerateOnChanges($newsletterId)
    {
        $row = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array($newsletterId));
        if (!$row) { return null; }
        $old = (int) $row['newsletter_id'];
        if (in_array((string) $row['status'], array('scheduled', 'sent'), true)
            || trim((string) $row['mailerlite_id']) !== '') {
            return null; // already booked — nothing to rework
        }
        // Supersede first so createProposal's one-active-flow-per-course guard frees the course.
        $this->_write()->update($this->_tbl(), array('review_status' => 'superseded'),
            array('newsletter_id = ?' => $old));
        $pid = (int) trim(strtok((string) $row['course_pids'], ','));
        if (!$pid) { $this->_log('regenerate: #' . $old . ' has no product'); return null; }
        $nid = $this->createProposal($pid);
        if (!$nid) {
            // couldn't rebuild — restore the change-request state so it isn't lost
            $this->_write()->update($this->_tbl(), array('review_status' => 'changes_requested'),
                array('newsletter_id = ?' => $old));
            $this->_log('regenerate: could not rebuild #' . $old . ' (pid ' . $pid . ') — restored');
            return null;
        }
        $this->_write()->update($this->_tbl(),
            array('review_feedback' => (string) $row['review_feedback']),
            array('newsletter_id = ?' => $nid));
        $this->sendForReview($nid);
        $this->_log('regenerate: #' . $old . ' -> #' . $nid . ' after change request');
        return $nid;
    }

    /**
     * Pick a popular class that has an upcoming run 7-21 days out. "Popular" =
     * most confirmed enrolments to date. Skips TGS-external and anything blasted
     * in the last 30 days so we don't repeat courses.
     */
    public function pickPopularUpcomingClass()
    {
        $res  = Mage::getSingleton('core/resource');
        $conn = $this->_read();
        $runs = $res->getTableName('course_runs');
        $enr  = $res->getTableName('course_run_enrolments');
        $log  = $res->getTableName('mmd_marketing_blast_log');
        $from = $this->_nowStr('+7 days', 'Y-m-d');
        $to   = $this->_nowStr('+21 days', 'Y-m-d');

        $select = $conn->select()
            ->from(array('r' => $runs), array('product_id'))
            ->joinLeft(array('e' => $enr), 'e.run_id = r.run_id', array('pop' => 'COUNT(e.enrolment_id)'))
            ->where('r.course_start_date >= ?', $from)
            ->where('r.course_start_date <= ?', $to)
            ->group('r.product_id')
            ->order('pop DESC')
            ->limit(10);
        $rows = $conn->fetchAll($select);
        if (!$rows) {
            return null;
        }
        // exclude products blasted in the last 30 days. blast_log stores newsletter_id,
        // so translate through newsletters.course_pids to get the actual product ids
        // (the old code compared newsletter_id against product ids and never matched).
        $news = $res->getTableName('newsletters');
        $recent = $conn->fetchCol(
            'SELECT n.course_pids FROM ' . $log . ' b'
          . ' JOIN ' . $news . ' n ON n.newsletter_id = b.newsletter_id'
          . ' WHERE b.blasted_at > ?',
            array($this->_nowStr('-30 days'))
        );
        $recentPids = array();
        foreach ($recent as $csv) {
            foreach (explode(',', (string) $csv) as $p) {
                $p = (int) trim($p);
                if ($p) { $recentPids[$p] = true; }
            }
        }
        foreach ($rows as $row) {
            $pid = (int) $row['product_id'];
            if (isset($recentPids[$pid])) continue;
            $p = Mage::getModel('catalog/product')->load($pid);
            if ($p && $p->getId() && $p->getStatus() == 1) {
                return $pid;
            }
        }
        return null;
    }

    /** Render the flyer and store a 'pending' review row; returns newsletter_id. */
    public function createProposal($productId)
    {
        // Dedupe guard: one ACTIVE flow per course. If this product already has a
        // pending / changes-requested / scheduling / scheduled flow, don't create a
        // second one (a queue "Run Now" on an already-scheduled course would
        // otherwise duplicate it in the pipeline AND in MailerLite).
        $active = (int) $this->_read()->fetchOne(
            'SELECT newsletter_id FROM ' . $this->_tbl()
          . " WHERE course_pids = ? AND template_key = 'agentic_flyer'"
          . " AND (review_status IN ('pending','changes_requested') OR status IN ('scheduling','scheduled'))"
          . " AND status <> 'sent' LIMIT 1",
            array((string) $productId)
        );
        if ($active) {
            $this->_log('createProposal: skipped — product ' . (int) $productId . ' already has active flow #' . $active);
            return null;
        }
        $flyerHtml = $this->_flyer()->render($productId);
        if ($flyerHtml === '') {
            return null;
        }
        $c = $this->_flyer()->courseData($productId);
        // Open-rate-optimised subject + preheader: benefit/funding hook up front, the
        // course name second. The preheader is the inbox snippet that (with the subject)
        // decides whether the email gets opened.
        $subject = $c['is_wsq']
            ? $c['name'] . ' — up to 70% SkillsFuture funded'
            : $c['name'] . ' — enrol now, limited seats';
        $preview = $c['is_wsq']
            ? 'Check your SkillsFuture/WSQ funding + get the free syllabus. Seats are limited.'
            : 'Get the free course syllabus and secure your seat before it fills up.';
        $conn = $this->_write();
        $conn->insert($this->_tbl(), array(
            'country_code'  => 'SG',
            'template_key'  => 'agentic_flyer',
            'title'         => $c['name'],
            'subject'       => $subject,
            'preview_text'  => $preview,
            'course_pids'   => (string) $productId,
            'body_html'     => $flyerHtml,
            'status'        => 'draft',
            'review_status' => 'pending',
            'is_auto'       => 1,
            'created_at'    => $this->_nowStr(),
        ));
        return (int) $conn->lastInsertId();
    }

    /**
     * Email the managers the flyer + signed Approve / Request-changes links.
     * $onlyEmails limits recipients (used by the 24h reminder to skip managers
     * who already responded); $isReminder stamps _reminder_sent_at so the
     * reminder can never repeat (see the HARD RULE in followUp()).
     */
    public function sendForReview($newsletterId, $onlyEmails = null, $isReminder = false)
    {
        $row = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array($newsletterId));
        if (!$row) { return false; }
        $g = $this->_guard();
        $base = rtrim(Mage::getStoreConfig('web/unsecure/base_url'), '/');
        $slot = $g->nextSendSlot();
        $slotTxt = $slot ? $slot->format('l, j M Y \a\t g:ia') : 'the next available slot';

        // PRIMARY transport = Gmail OAuth (same path the admin OTP email uses,
        // Mage::helper('mmd_email/gmail')). It sends via the Gmail API with a
        // refresh-token, so it is IMMUNE to the SMTP app-password revocations
        // that repeatedly break Zend_Mail/SMTPPro (real incident 2026-07-04/05:
        // SMTP returned 5.7.8/5.7.9 BadCredentials; container has no sendmail).
        // Falls back to SMTPPro's transport only if Gmail OAuth isn't configured.
        $gmail = null;
        try {
            $gh = Mage::helper('mmd_email/gmail');
            if ($gh && $gh->isConfigured()) { $gmail = $gh; }
        } catch (Exception $e) { $this->_log('sendForReview: Gmail OAuth helper unavailable: ' . $e->getMessage()); }
        $transport = null;
        if (!$gmail) {
            try {
                if (Mage::helper('core')->isModuleEnabled('Aschroder_SMTPPro')) {
                    $t = Mage::helper('smtppro')->getTransport();
                    if ($t) { $transport = $t; }
                }
            } catch (Exception $e) { $this->_log('sendForReview: SMTPPro transport unavailable: ' . $e->getMessage()); }
        }

        $sentAny = false;
        foreach ($g->reviewers() as $email) {
            if (is_array($onlyEmails) && !in_array(strtolower($email), $onlyEmails, true)) { continue; }
            $tok = $g->signToken($newsletterId, $email);
            $approve = $base . '/newsletter-review/index/decide/id/' . $newsletterId . '/d/approve/e/' . rawurlencode($email) . '/t/' . $tok;
            $reject  = $base . '/newsletter-review/index/decide/id/' . $newsletterId . '/d/changes/e/'  . rawurlencode($email) . '/t/' . $tok;

            $html = '<div style="font-family:-apple-system,Segoe UI,Arial,sans-serif;max-width:660px;margin:0 auto;">'
                . '<p style="font-size:15px;color:#0a1020;">Hi — a new course flyer is ready for your approval. If approved, it will be scheduled to MailerLite for the next blast on <b>' . $slotTxt . '</b> (max 2 campaigns/week).</p>'
                . '<table role="presentation" style="margin:18px 0;"><tr>'
                . '<td style="padding-right:10px;"><a href="' . htmlspecialchars($approve) . '" style="background:#059669;color:#fff;text-decoration:none;font-weight:700;font-size:14px;padding:11px 22px;border-radius:8px;display:inline-block;">✓ Approve &amp; schedule</a></td>'
                . '<td><a href="' . htmlspecialchars($reject) . '" style="background:#e2e8f0;color:#0a1020;text-decoration:none;font-weight:700;font-size:14px;padding:11px 22px;border-radius:8px;display:inline-block;">✎ Request changes</a></td>'
                . '</tr></table>'
                . '<p style="font-size:12px;color:#7c8aa3;">"Request changes" lets you ask for a new design or a different course; the system will regenerate and re-send for approval.</p>'
                . '<hr style="border:0;border-top:1px solid #e4e9f0;margin:18px 0;">'
                . $row['body_html']
                . '</div>';
            $subject = ($isReminder ? '[Reminder] ' : '') . '[Approval needed] ' . $row['subject'];

            try {
                if ($gmail) {
                    $gmail->send($email, $subject, $html, 'Tertiary Marketing');
                } else {
                    $mail = new Zend_Mail('utf-8');
                    $mail->setBodyHtml($html)
                         ->setFrom(Mage::getStoreConfig('trans_email/ident_general/email'), 'Tertiary Marketing')
                         ->addTo($email)
                         ->setSubject($subject);
                    $transport ? $mail->send($transport) : $mail->send();
                }
                $sentAny = true;
                $this->_log('sendForReview: emailed ' . $email . ' for #' . $newsletterId . ' via ' . ($gmail ? 'gmail-oauth' : 'smtp'));
            } catch (Exception $e) {
                $this->_log('sendForReview mail to ' . $email . ' failed: ' . $e->getMessage());
            }
        }
        // Only stamp the anti-spam markers if a send actually SUCCEEDED — otherwise
        // a transport failure would mark the proposal "emailed" and it would never
        // retry. The token marks "original email sent", _sent_at anchors the 24h
        // reminder window, _reminder_sent_at (reminders only) makes the reminder final.
        if (!$sentAny) {
            $this->_log('sendForReview: no email sent for #' . $newsletterId . ' — leaving unstamped for retry');
            return false;
        }
        $dec = json_decode((string) $row['review_decisions'], true);
        if (!is_array($dec)) { $dec = array(); }
        if (empty($dec['_sent_at'])) { $dec['_sent_at'] = $this->_nowStr(); }
        if ($isReminder) { $dec['_reminder_sent_at'] = $this->_nowStr(); }
        $this->_write()->update($this->_tbl(),
            array(
                'review_token'     => $g->signToken($newsletterId, 'batch'),
                'review_decisions' => json_encode($dec),
            ),
            array('newsletter_id = ?' => $newsletterId));
        return true;
    }

    /**
     * Called by the public review endpoint once BOTH managers have approved:
     * schedule the campaign to MailerLite for the next Mon/Thu 08:00 and record
     * the blast so it counts against the weekly cap. Returns [ok,message].
     */
    public function scheduleApproved($newsletterId)
    {
        $g = $this->_guard();
        $reason = '';
        if (!$g->canScheduleNow($reason)) {
            return array(false, $reason);
        }
        $slot = $g->nextSendSlot();
        $row  = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array($newsletterId));
        if (!$row) { return array(false, 'Proposal not found.'); }
        // Idempotent: a set mailerlite_id means it's already booked. (Don't rely on
        // status='scheduled' alone — the legacy enum blanked that write; the enum is
        // fixed in migration 307, but mailerlite_id is the reliable guard.)
        if (trim((string) $row['mailerlite_id']) !== '' || (string) $row['status'] === 'scheduled') {
            return array(true, 'Already scheduled.');
        }

        // ATOMIC CLAIM (migration 334): two near-simultaneous approvals both passed
        // the read above and each created a MailerLite campaign (real double-booking
        // 2026-07-05). Claim the row with a conditional UPDATE — only the request
        // that flips status to 'scheduling' proceeds; the loser sees 0 rows updated.
        $claimed = $this->_write()->update($this->_tbl(),
            array('status' => 'scheduling'),
            array(
                'newsletter_id = ?' => $newsletterId,
                "(mailerlite_id IS NULL OR mailerlite_id = '')",
                "status NOT IN ('scheduling','scheduled','sent')",
            )
        );
        if (!$claimed) {
            return array(true, 'Already scheduled.');
        }

        // Create + schedule the MailerLite campaign for the chosen Mon/Thu 08:00 slot.
        try {
            $mlId = Mage::helper('mmd_marketing/mailerlite')
                ->createAndSchedule((string) $row['subject'], (string) $row['body_html'], $slot);
        } catch (Exception $e) {
            // release the claim so a retry is possible
            $this->_write()->update($this->_tbl(), array('status' => 'draft'),
                array('newsletter_id = ?' => $newsletterId, "status = 'scheduling'"));
            $this->_log('scheduleApproved: MailerLite FAILED for #' . $newsletterId . ': ' . $e->getMessage());
            return array(false, 'MailerLite scheduling failed: ' . $e->getMessage());
        }

        $g->recordBlast($newsletterId, (string) $row['country_code'], $mlId, $slot, null);
        $this->_write()->update($this->_tbl(), array(
            'review_status'     => 'approved',
            'status'            => 'scheduled',
            'mailerlite_id'     => $mlId,
            'scheduled_send_at' => $slot->format('Y-m-d H:i:s'),
        ), array('newsletter_id = ?' => $newsletterId));
        $this->_log('scheduleApproved: #' . $newsletterId . ' -> MailerLite ' . $mlId . ' for ' . $slot->format('Y-m-d H:i'));

        // Auto-publish the flyer design to LinkedIn (non-fatal — skips silently if
        // LinkedIn isn't configured; MailerLite scheduling must never depend on it).
        try {
            $pid = (int) trim(strtok((string) $row['course_pids'], ','));
            $li  = Mage::helper('mmd_marketing/linkedin');
            if ($pid && $li->isConfigured()) {
                $res = $li->postFlyer($pid);
                $this->_log('scheduleApproved: LinkedIn ' . ($res['ok'] ? 'posted ' . $res['url'] : 'skipped/failed: ' . $res['msg']));
                if (!empty($res['ok'])) {
                    $dec = json_decode((string) $row['review_decisions'], true);
                    if (!is_array($dec)) { $dec = array(); }
                    $dec['_linkedin_url'] = $res['url'];
                    $this->_write()->update($this->_tbl(), array('review_decisions' => json_encode($dec)), array('newsletter_id = ?' => $newsletterId));
                }
            }
        } catch (Exception $e) { $this->_log('scheduleApproved: LinkedIn error: ' . $e->getMessage()); }

        // Auto kick-start the NEXT flyer: as soon as this one is booked to MailerLite,
        // pull the next course from the admin queue and send it for approval so it's
        // ready for the next Mon/Thu slot. Bounded by the weekly design/blast caps and
        // the "one pending at a time" rule, so it can't runaway (no infinite loop).
        try {
            $this->autoStartNext();
        } catch (Exception $e) { $this->_log('scheduleApproved: autoStartNext error: ' . $e->getMessage()); }

        return array(true, 'Scheduled for ' . $slot->format('l, j M Y \a\t g:ia'));
    }

    /**
     * Create + send-for-review the NEXT queued flyer, so the pipeline always has
     * the following blast lined up the moment the current one is scheduled. Guards:
     * only when the week still has a bookable slot AND a design slot, only when no
     * proposal is already pending (no stacking), and only if the queue has a course.
     * Returns the new newsletter_id or null.
     */
    public function autoStartNext()
    {
        $g = $this->_guard();
        if (!$g->isEnabled()) { return null; }
        // Don't stack: skip if something is already awaiting review.
        $pending = (int) $this->_read()->fetchOne(
            'SELECT COUNT(*) FROM ' . $this->_tbl() . " WHERE review_status IN ('pending','changes_requested')");
        if ($pending > 0) { $this->_log('autoStartNext: skipped — a proposal is already pending'); return null; }
        if ($g->remainingDesignsThisWeek() < 1) { $this->_log('autoStartNext: skipped — weekly design cap'); return null; }
        if ($g->nextSendSlot() === null)         { $this->_log('autoStartNext: skipped — no bookable slot left this week'); return null; }
        // Prefer the admin-curated queue; fall back to a popular upcoming class so
        // there is always a next flyer lined up.
        $pid = $this->popFlyerQueue();
        if (!$pid) { $pid = $this->pickPopularUpcomingClass(); }
        if (!$pid) { $this->_log('autoStartNext: no queued or popular course — nothing to auto-start'); return null; }
        $nid = $this->createProposal($pid);
        if ($nid) {
            $this->sendForReview($nid);
            $this->_log('autoStartNext: proposal #' . $nid . ' (product ' . $pid . ') auto-started + sent for review');
        }
        return $nid;
    }

    /**
     * Cron (every 10 min) + safety net behind the MailerLite webhook: detect
     * campaigns that actually BLASTED and move their pipeline row to 'sent'
     * (stage "Blasted"), cache the campaign stats for the dashboard, and fire
     * the LinkedIn auto-post if it hasn't already gone out. Also refreshes the
     * cached stats of recently-sent campaigns so the dashboard numbers stay
     * close to live (opens/clicks keep moving for days after a blast).
     */
    public function syncBlasts()
    {
        $g = $this->_guard();
        if (!$g->isEnabled()) { return; }
        // 1. Scheduled rows whose send time has passed → ask MailerLite if they went out.
        // Compare against PHP time (Asia/Singapore, same clock that wrote
        // scheduled_send_at) — MySQL NOW() is UTC on prod and would detect the
        // blast 8 hours late (real miss 2026-07-06).
        $due = $this->_read()->fetchAll('SELECT newsletter_id, mailerlite_id FROM ' . $this->_tbl()
            . " WHERE status = 'scheduled' AND mailerlite_id IS NOT NULL AND mailerlite_id <> ''"
            . ' AND scheduled_send_at <= ?', array($this->_nowStr()));
        foreach ($due as $row) {
            $this->markBlastedByCampaign((string) $row['mailerlite_id']);
        }
        // 2. Refresh cached stats for campaigns blasted in the last 30 days (max 5/run).
        $sent = $this->_read()->fetchAll('SELECT newsletter_id, mailerlite_id FROM ' . $this->_tbl()
            . " WHERE status = 'sent' AND mailerlite_id IS NOT NULL AND mailerlite_id <> ''"
            . ' AND sent_at >= ? ORDER BY sent_at DESC LIMIT 5', array($this->_nowStr('-30 days')));
        foreach ($sent as $row) {
            try {
                $stats = $this->_campaignStats((string) $row['mailerlite_id']);
                if ($stats !== null) {
                    $this->_write()->update($this->_tbl(), array('blast_stats' => json_encode($stats)),
                        array('newsletter_id = ?' => (int) $row['newsletter_id']));
                }
            } catch (Exception $e) {
                $this->_log('syncBlasts: stats refresh failed for #' . (int) $row['newsletter_id'] . ': ' . $e->getMessage());
            }
        }
    }

    /**
     * Mark the pipeline row for a MailerLite campaign as BLASTED: status 'sent',
     * sent_at stamped, stats cached — then the LinkedIn auto-post (once, guarded
     * by the _linkedin_url marker in review_decisions). Shared by the webhook
     * endpoint (instant) and the syncBlasts cron (safety net). Idempotent.
     */
    public function markBlastedByCampaign($campaignId)
    {
        $campaignId = trim((string) $campaignId);
        if ($campaignId === '') { return false; }
        $row = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE mailerlite_id = ?', array($campaignId));
        if (!$row) { return false; }

        try {
            $c = Mage::helper('mmd_marketing/mailerlite')->getCampaign($campaignId);
        } catch (Exception $e) {
            $this->_log('markBlasted: getCampaign failed for ' . $campaignId . ': ' . $e->getMessage());
            return false;
        }
        $d = isset($c['data']) ? $c['data'] : $c;
        if (!isset($d['status']) || (string) $d['status'] !== 'sent') {
            return false; // not blasted yet — the cron will try again
        }

        if ((string) $row['status'] !== 'sent') {
            // MailerLite timestamps are UTC without a zone marker — convert to
            // local (Asia/Singapore) or the blast shows 8h early on the dashboard.
            $sentAt = $this->_nowStr();
            if (!empty($d['finished_at'])) {
                try {
                    $dt = new DateTime($d['finished_at'], new DateTimeZone('UTC'));
                    $dt->setTimezone(new DateTimeZone('Asia/Singapore'));
                    $sentAt = $dt->format('Y-m-d H:i:s');
                } catch (Exception $e) { /* keep local now */ }
            }
            $stats  = $this->_statsFromCampaign($d);
            $this->_write()->update($this->_tbl(), array(
                'status'      => 'sent',
                'sent_at'     => $sentAt,
                'blast_stats' => $stats !== null ? json_encode($stats) : null,
            ), array('newsletter_id = ?' => (int) $row['newsletter_id']));
            $this->_log('markBlasted: #' . (int) $row['newsletter_id'] . ' (campaign ' . $campaignId . ') -> BLASTED at ' . $sentAt);
        }

        // LinkedIn auto-post — covers campaigns approved before LinkedIn was
        // configured AND acts as the blast-time trigger. Once only.
        try {
            $dec = json_decode((string) $row['review_decisions'], true);
            if (!is_array($dec)) { $dec = array(); }
            if (empty($dec['_linkedin_url'])) {
                $pid = (int) trim(strtok((string) $row['course_pids'], ','));
                $li  = Mage::helper('mmd_marketing/linkedin');
                if ($pid && $li->isConfigured()) {
                    $res = $li->postFlyer($pid);
                    $this->_log('markBlasted: LinkedIn ' . (!empty($res['ok']) ? 'posted ' . $res['url'] : 'skipped/failed: ' . $res['msg']));
                    if (!empty($res['ok'])) {
                        $dec['_linkedin_url'] = $res['url'];
                        $this->_write()->update($this->_tbl(), array('review_decisions' => json_encode($dec)),
                            array('newsletter_id = ?' => (int) $row['newsletter_id']));
                    }
                }
            }
        } catch (Exception $e) { $this->_log('markBlasted: LinkedIn error: ' . $e->getMessage()); }
        return true;
    }

    /** Fetch + normalise campaign stats. Returns array or null. */
    protected function _campaignStats($campaignId)
    {
        $c = Mage::helper('mmd_marketing/mailerlite')->getCampaign($campaignId);
        $d = isset($c['data']) ? $c['data'] : $c;
        return $this->_statsFromCampaign($d);
    }

    /** Normalise MailerLite's campaign stats blob into the fields the dashboard shows. */
    protected function _statsFromCampaign($d)
    {
        if (empty($d['stats']) || !is_array($d['stats'])) { return null; }
        $s = $d['stats'];
        $num = function ($k) use ($s) { return isset($s[$k]) ? (int) $s[$k] : 0; };
        $rate = function ($k) use ($s) {
            if (!isset($s[$k])) { return 0.0; }
            $v = $s[$k];
            if (is_array($v)) { $v = isset($v['float']) ? $v['float'] : (isset($v['string']) ? rtrim($v['string'], '%') / 100 : 0); }
            return (float) $v;
        };
        $sent   = $num('sent');
        $hard   = $num('hard_bounces_count');
        $soft   = $num('soft_bounces_count');
        return array(
            'sent'          => $sent,
            'opens'         => $num('opens_count'),
            'unique_opens'  => $num('unique_opens_count'),
            'open_rate'     => $rate('open_rate'),
            'clicks'        => $num('clicks_count'),
            'unique_clicks' => $num('unique_clicks_count'),
            'click_rate'    => $rate('click_rate'),
            'ctor'          => $rate('click_to_open_rate'),
            'unsubscribes'  => $num('unsubscribes_count'),
            'hard_bounces'  => $hard,
            'soft_bounces'  => $soft,
            'delivery_rate' => $sent > 0 ? max(0, ($sent - $hard - $soft) / $sent) : 0,
            'updated_at'    => $this->_nowStr(),
        );
    }
}
