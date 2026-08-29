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
        $newsletterId = $this->createProposal($productId, $this->_poppedBrief['instructions'], $this->_poppedBrief['run_date']);
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
        $this->_poppedBrief = array('instructions' => '', 'run_date' => null);
        try {
            $row = $this->_read()->fetchRow(
                'SELECT queue_id, product_id, instructions, run_date FROM mmd_marketing_flyer_queue ORDER BY position ASC, queue_id ASC LIMIT 1');
            if (!$row) { return null; }
            $this->_write()->delete('mmd_marketing_flyer_queue', array('queue_id = ?' => (int) $row['queue_id']));
            // The row's design brief (special instructions + pinned intake) travels
            // with the pop — per-ROW by design: consumed once, never inherited by a
            // later flyer for the same course.
            $this->_poppedBrief = array(
                'instructions' => trim((string) (isset($row['instructions']) ? $row['instructions'] : '')),
                'run_date'     => (isset($row['run_date']) && $row['run_date']) ? (string) $row['run_date'] : null,
            );
            $this->_log('propose: consumed flyer-queue head — product ' . (int) $row['product_id']
                . ($this->_poppedBrief['instructions'] !== '' ? ' (with special instructions)' : '')
                . ($this->_poppedBrief['run_date'] ? ' (intake ' . $this->_poppedBrief['run_date'] . ')' : ''));
            return (int) $row['product_id'];
        } catch (Exception $e) {
            // Table missing (migration not applied) — retry without the new columns
            // so a code deploy that outruns its migration still consumes the queue.
            try {
                $row = $this->_read()->fetchRow(
                    'SELECT queue_id, product_id FROM mmd_marketing_flyer_queue ORDER BY position ASC, queue_id ASC LIMIT 1');
                if (!$row) { return null; }
                $this->_write()->delete('mmd_marketing_flyer_queue', array('queue_id = ?' => (int) $row['queue_id']));
                return (int) $row['product_id'];
            } catch (Exception $e2) { return null; }
        }
    }

    /** Design brief carried by the most recent popFlyerQueue() call. */
    protected $_poppedBrief = array('instructions' => '', 'run_date' => null);

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
        // 1c. Partial transport failure: one manager got the email, the other's
        //     send threw (so the row IS stamped and step 1 skips it). Resend to
        //     JUST the missed manager(s), at most once — _resend_done is stamped
        //     before the attempt so this can never loop. The 24h reminder in 1b
        //     remains the final safety net if this resend also fails.
        $rows = $this->_read()->fetchAll('SELECT * FROM ' . $this->_tbl()
            . " WHERE review_status = 'pending' AND review_token IS NOT NULL AND review_token <> ''");
        foreach ($rows as $row) {
            $dec = json_decode((string) $row['review_decisions'], true);
            if (!is_array($dec) || empty($dec['_send_failed']) || !empty($dec['_resend_done'])) { continue; }
            $missed = array_map('strtolower', (array) $dec['_send_failed']);
            $dec['_resend_done'] = $this->_nowStr();
            $this->_write()->update($this->_tbl(), array('review_decisions' => json_encode($dec)),
                array('newsletter_id = ?' => (int) $row['newsletter_id']));
            $this->sendForReview((int) $row['newsletter_id'], $missed, false);
            $this->_log('followUp: resent #' . (int) $row['newsletter_id'] . ' to missed reviewer(s) ' . implode(',', $missed));
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
        if ((string) $row['review_status'] !== 'changes_requested') {
            // Duplicate call (double-submitted form, cron overlap) — a prior run
            // already superseded this row and built its successor.
            $this->_log('regenerate: #' . $old . ' is ' . $row['review_status'] . ', not changes_requested — skipping');
            return null;
        }
        $pid = (int) trim(strtok((string) $row['course_pids'], ','));
        if (!$pid) { $this->_log('regenerate: #' . $old . ' has no product'); return null; }
        $fb       = trim((string) $row['review_feedback']);
        $prevBody = (string) $row['body_html'];

        // ============================================================
        // HARD RULE (admin 2026-07-12): the manager's feedback MUST be
        // incorporated into a genuinely DIFFERENT design BEFORE any new
        // approval email is sent. Never re-send the rejected design.
        //   1. Regenerate the copy FROM the feedback (retry on transient
        //      Claude failure — an empty result must NOT silently reuse
        //      the old copy and re-send it).
        //   2. If generation cannot produce copy, DO NOT send anything:
        //      leave the flow as changes_requested and let followUp retry.
        //   3. The rendered body MUST differ from the rejected body; if it
        //      is byte-identical, regenerate once more before sending.
        // ============================================================
        $copy = null;
        for ($attempt = 1; $attempt <= 3 && !$copy; $attempt++) {
            try { $copy = $this->_flyer()->regenerateCopy($pid, $fb); }
            catch (Exception $e) { $this->_log('regenerate: regenerateCopy error (try ' . $attempt . ') — ' . $e->getMessage()); }
            if (!$copy && $attempt < 3) { sleep(3); }   // brief backoff (429/timeout)
        }
        if (!$copy) {
            // Generation failed — HOLD. Do not supersede, do not email the same
            // design. followUp() will retry on the next cron tick. Guarded so a
            // concurrent run that already superseded this row isn't resurrected.
            $this->_write()->update($this->_tbl(), array('review_status' => 'changes_requested'),
                array('newsletter_id = ?' => $old, "review_status = 'changes_requested'"));
            $this->_log('regenerate: HELD #' . $old . ' — copy generation failed after retries; NOT re-sending the rejected design');
            return null;
        }
        $this->_log('regenerate: AI copy rebuilt for #' . $old . ' from feedback: ' . mb_substr($fb, 0, 100));

        // New copy is in hand — free the course and build the new proposal.
        // Atomic claim: the admin button, the email link (double-submit) and the
        // hourly followUp safety net can race on the same row. Only the run that
        // flips changes_requested -> superseded may proceed — a loser that carried
        // on would "restore" the row below even though its successor exists,
        // stranding a stale active flow that blocks every future regenerate for
        // this product (incident 2026-07-27, #30/#31 deadlock).
        $claimed = $this->_write()->update($this->_tbl(), array('review_status' => 'superseded'),
            array('newsletter_id = ?' => $old, "review_status = 'changes_requested'"));
        if (!$claimed) {
            $this->_log('regenerate: #' . $old . ' already claimed by a concurrent regenerate — skipping');
            return null;
        }
        $nid = $this->createProposal($pid);
        if (!$nid) {
            $this->_write()->update($this->_tbl(), array('review_status' => 'changes_requested'),
                array('newsletter_id = ?' => $old));
            $this->_log('regenerate: could not rebuild #' . $old . ' (pid ' . $pid . ') — restored');
            return null;
        }

        // Diff-guard: the new design MUST differ from the rejected one.
        $newBody = (string) $this->_read()->fetchOne(
            'SELECT body_html FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array($nid));
        if ($prevBody !== '' && md5($newBody) === md5($prevBody)) {
            $this->_log('regenerate: new #' . $nid . ' body identical to rejected #' . $old . ' — forcing a second regeneration');
            try {
                if ($this->_flyer()->regenerateCopy($pid, $fb . "\n\n(The previous rewrite was too similar — change the wording and angle more.)")) {
                    $rebuilt = $this->_flyer()->render($pid);
                    if ($rebuilt !== '') {
                        $this->_write()->update($this->_tbl(), array('body_html' => $rebuilt),
                            array('newsletter_id = ?' => $nid));
                    }
                }
            } catch (Exception $e) { $this->_log('regenerate: second-pass error — ' . $e->getMessage()); }
        }

        $this->_write()->update($this->_tbl(),
            array('review_feedback' => (string) $row['review_feedback']),
            array('newsletter_id = ?' => $nid));
        $sent = $this->sendForReview($nid, null, false, true);
        $this->_log('regenerate: #' . $old . ' -> #' . $nid . ' after change request (feedback applied'
            . ($sent ? '' : '; review email NOT sent — followUp will retry') . ')');
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
            // WSQ only: SG blasts TGS- courses; skip non-WSQ (C-prefix) courses.
            if ($p && $p->getId() && $p->getStatus() == 1 && stripos((string) $p->getSku(), 'TGS-') === 0) {
                return $pid;
            }
        }
        return null;
    }

    /** Render the flyer and store a 'pending' review row; returns newsletter_id. */
    /**
     * @param string      $instructions  admin's special instructions from the queue
     *   row ("teal colour scheme", "lead with HRDC") — steers the AI copy exactly
     *   like manager change-request feedback, and any colour ask repaints the
     *   design (Helper_Flyer::detectColorRequest).
     * @param string|null $runDate  optional 'Y-m-d' — pin WHICH published intake
     *   the flyer leads with; ignored unless the course really sells that date.
     */
    public function createProposal($productId, $instructions = '', $runDate = null)
    {
        // HARD GATE (admin 2026-07-14): SG blasts WSQ courses ONLY. A WSQ course's
        // SKU starts with 'TGS-' (the SkillsFuture course reference). Non-WSQ
        // C-prefix courses (e.g. C427) must never be proposed or scheduled — this
        // is the single chokepoint every path (auto cron, Run Now, regenerate)
        // funnels through, so gating here covers them all.
        $sku = (string) $this->_read()->fetchOne(
            'SELECT sku FROM ' . Mage::getSingleton('core/resource')->getTableName('catalog/product')
          . ' WHERE entity_id = ?', array((int) $productId));
        if (stripos($sku, 'TGS-') !== 0) {
            $this->_log('createProposal: skipped — ' . ($sku ?: 'product ' . (int) $productId)
                . ' is not a WSQ (TGS-) course; SG blasts WSQ only');
            return null;
        }
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
        // PRE-DESIGN HOOK: check the curated pitch + accumulated blast learnings for
        // this course before building, so every design is informed by what works.
        $this->preDesignHook($productId);
        // AI-GENERATE the course-specific copy (hook/outcomes/journey) before rendering.
        // With no feedback this reuses any prior AI copy for the SKU (no API burn);
        // regenerateOnChanges passes the manager's feedback so a rework always differs.
        // Special instructions act exactly like feedback: non-empty forces a fresh
        // AI generation (and colour detection); empty reuses prior copy (no API burn).
        try { $this->_flyer()->regenerateCopy($productId, (string) $instructions); }
        catch (Exception $e) { $this->_log('createProposal: regenerateCopy failed — ' . $e->getMessage()); }
        $flyerHtml = $this->_flyer()->render($productId, $runDate);
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
    public function sendForReview($newsletterId, $onlyEmails = null, $isReminder = false, $isRevision = false)
    {
        $row = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array($newsletterId));
        if (!$row) { return false; }
        $g = $this->_guard();
        $base = rtrim(Mage::getStoreConfig('web/unsecure/base_url'), '/');

        // HARD SAFETY: never email the real managers from a non-production env.
        // Gmail OAuth sends identically from localhost, so a dev/test run would
        // otherwise deliver a live-looking approval email to angch@/tansc@ with
        // useless localhost links (real confusion 2026-07-09). Only a genuine
        // production host (…tertiarycourses.com.*) may send; anything else logs
        // and no-ops unless mmd_marketing/newsletter/allow_local_review_email=1.
        $host = strtolower((string) parse_url($base, PHP_URL_HOST));
        $isProd = (bool) preg_match('/(^|\.)tertiarycourses\.com(\.[a-z]{2,3})?$/', $host);
        if (!$isProd && !(bool) Mage::getStoreConfig('mmd_marketing/newsletter/allow_local_review_email')) {
            $this->_log('sendForReview: SKIPPED for #' . $newsletterId . ' — non-production base_url (' . ($host ?: 'empty')
                . '). Set mmd_marketing/newsletter/allow_local_review_email=1 to send from a test env.');
            return false;
        }

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
        $failed  = array();
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
            // Revised flyers get a UNIQUE subject: Gmail threads same-subject
            // messages into the rejected flyer's conversation, where the fresh
            // approval email is collapsed and easily missed (real incident
            // 2026-07-16 — manager never saw the revised copy). The #id suffix
            // guarantees every revision starts its own thread.
            $subject = ($isReminder ? '[Reminder] ' : '') . '[Approval needed] ' . $row['subject']
                . ($isRevision ? ' — revised (#' . (int) $newsletterId . ')' : '');

            // Two attempts per recipient: a transient Gmail/SMTP hiccup for ONE
            // manager must not silently drop them from the approval loop while
            // the other manager's success stamps the proposal as "emailed".
            $delivered = false;
            for ($try = 1; $try <= 2 && !$delivered; $try++) {
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
                    $delivered = true;
                    $sentAny   = true;
                    $this->_log('sendForReview: emailed ' . $email . ' for #' . $newsletterId . ' via ' . ($gmail ? 'gmail-oauth' : 'smtp'));
                } catch (Exception $e) {
                    $this->_log('sendForReview mail to ' . $email . ' failed (try ' . $try . '): ' . $e->getMessage());
                    if ($try < 2) { sleep(2); }
                }
            }
            if (!$delivered) { $failed[] = strtolower($email); }
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
        // Partial failure: remember who never got the email so followUp() can
        // resend to JUST them (once). A successful (re)send clears the marker.
        if (!empty($failed)) { $dec['_send_failed'] = array_values($failed); }
        elseif (isset($dec['_send_failed']) && is_array($onlyEmails)) { unset($dec['_send_failed']); }
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

        // LinkedIn company-page auto-post — same non-fatal, once-only contract.
        try { $this->_postLinkedinOrgOnce($newsletterId, 'scheduleApproved'); }
        catch (Exception $e) { $this->_log('scheduleApproved: LinkedIn org error: ' . $e->getMessage()); }

        // Facebook page auto-post — same non-fatal, once-only contract as LinkedIn.
        try { $this->_postFacebookOnce($newsletterId, 'scheduleApproved'); }
        catch (Exception $e) { $this->_log('scheduleApproved: Facebook error: ' . $e->getMessage()); }

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
        $nid = $this->createProposal($pid, $this->_poppedBrief['instructions'], $this->_poppedBrief['run_date']);
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
            // POST-BLAST HOOK: analyse how this blast did vs. the running average
            // and record the learning so the next design leans on what works.
            try { $this->analyseBlast((int) $row['newsletter_id'], $stats, $row); }
            catch (Exception $e) { $this->_log('analyseBlast error: ' . $e->getMessage()); }
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

        // LinkedIn company-page auto-post — covers campaigns approved before the
        // org credential existed AND acts as the blast-time trigger. Once only.
        try { $this->_postLinkedinOrgOnce((int) $row['newsletter_id'], 'markBlasted'); }
        catch (Exception $e) { $this->_log('markBlasted: LinkedIn org error: ' . $e->getMessage()); }

        // Facebook page auto-post — covers campaigns approved before Facebook was
        // configured AND acts as the blast-time trigger. Once only.
        try { $this->_postFacebookOnce((int) $row['newsletter_id'], 'markBlasted'); }
        catch (Exception $e) { $this->_log('markBlasted: Facebook error: ' . $e->getMessage()); }
        return true;
    }

    /**
     * Post the campaign's flyer card to the LinkedIn COMPANY PAGE once (deduped
     * by the _linkedin_org_url marker in review_decisions — the org twin of
     * _linkedin_url). Fires only when mmd_marketing/linkedin/org_urn is set AND
     * the token carries w_organization_social; otherwise a silent skip, so this
     * ships dormant until the LinkedIn app's Community Management API access is
     * approved. Non-fatal by the same contract as the member post.
     */
    protected function _postLinkedinOrgOnce($newsletterId, $context)
    {
        $li = Mage::helper('mmd_marketing/linkedin');
        $org = $li->orgUrn();
        if ($org === '' || !$li->isConfigured()) { return; }
        // Re-read the row: the caller may have just written _linkedin_url /
        // _facebook_url and a stale copy here would clobber them.
        $row = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array((int) $newsletterId));
        if (!$row) { return; }
        $dec = json_decode((string) $row['review_decisions'], true);
        if (!is_array($dec)) { $dec = array(); }
        if (!empty($dec['_linkedin_org_url'])) { return; }

        $pid = (int) trim(strtok((string) $row['course_pids'], ','));
        if (!$pid) { return; }
        $res = $li->postFlyer($pid, '', $org);
        $this->_log($context . ': LinkedIn org ' . (!empty($res['ok']) ? 'posted ' . $res['url'] : 'skipped/failed: ' . $res['msg']));
        if (!empty($res['ok'])) {
            $dec['_linkedin_org_url'] = $res['url'];
            $this->_write()->update($this->_tbl(), array('review_decisions' => json_encode($dec)),
                array('newsletter_id = ?' => (int) $newsletterId));
        }
    }

    /**
     * Post the campaign's course to the Facebook page ONCE (deduped by the
     * _facebook_url marker in review_decisions, the Facebook twin of
     * _linkedin_url). A link post — Facebook renders the card from the course
     * page's OpenGraph tags. Non-fatal: called from both scheduleApproved()
     * and markBlastedByCampaign(), whichever runs first with credentials wins.
     */
    protected function _postFacebookOnce($newsletterId, $context)
    {
        $fb = Mage::helper('mmd_marketing/facebook');
        if (!$fb->isConfigured()) { return; }
        // Re-read the row: the caller may have just written _linkedin_url and a
        // stale copy here would clobber it.
        $row = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array((int) $newsletterId));
        if (!$row) { return; }
        $dec = json_decode((string) $row['review_decisions'], true);
        if (!is_array($dec)) { $dec = array(); }
        if (!empty($dec['_facebook_url'])) { return; }

        $pid = (int) trim(strtok((string) $row['course_pids'], ','));
        if (!$pid) { return; }
        $product = Mage::getModel('catalog/product')->load($pid);
        if (!$product->getId() || !$product->getUrlPath()) { return; }
        $courseUrl = rtrim((string) Mage::getStoreConfig('web/unsecure/base_url'), '/')
            . '/' . ltrim((string) $product->getUrlPath(), '/');

        $message = (string) ($row['subject'] ?: $product->getName())
            . "\n\nWSQ funding + SkillsFuture Credit claimable — seats fill fast. Course details and sign-up:";
        $res = $fb->postLink($message, $courseUrl);
        $this->_log($context . ': Facebook ' . (!empty($res['ok']) ? 'posted ' . $res['url'] : 'skipped/failed: ' . $res['msg']));
        if (!empty($res['ok'])) {
            $dec['_facebook_url'] = $res['url'];
            $this->_write()->update($this->_tbl(), array('review_decisions' => json_encode($dec)),
                array('newsletter_id = ?' => (int) $newsletterId));
        }
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

    /**
     * POST-BLAST LEARNING LOOP. When a blast is captured, compare its open/click
     * rates against the average of all PRIOR blasts and append a structured
     * "learning" to core_config (mmd_marketing/newsletter/design_learnings, JSON,
     * last 24). Each entry records the design levers we can actually change —
     * subject, course, WSQ funding hook, accent, whether the pitch was curated —
     * alongside the outcome and a verdict vs. the running average. The
     * newsletter-design skill reads this log each cycle: patterns from
     * above-average blasts become the default for the next design; below-average
     * ones are avoided. Goal: climb open + click rate over time.
     */
    public function analyseBlast($newsletterId, $stats, $row = null)
    {
        if (!is_array($stats) || empty($stats)) { return; }
        if (!$row) { $row = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array($newsletterId)); }
        if (!$row) { return; }

        // Baseline = average open/click over prior captured blasts (exclude self).
        $prior = $this->_read()->fetchCol('SELECT blast_stats FROM ' . $this->_tbl()
            . " WHERE status = 'sent' AND blast_stats IS NOT NULL AND newsletter_id <> ?", array((int) $newsletterId));
        $oSum = $cSum = $n = 0.0;
        foreach ($prior as $bs) {
            $p = json_decode((string) $bs, true);
            if (!is_array($p)) { continue; }
            $oSum += isset($p['open_rate']) ? (float) $p['open_rate'] : 0;
            $cSum += isset($p['click_rate']) ? (float) $p['click_rate'] : 0;
            $n++;
        }
        $avgO = $n > 0 ? $oSum / $n : null;
        $avgC = $n > 0 ? $cSum / $n : null;

        $o = isset($stats['open_rate']) ? (float) $stats['open_rate'] : 0;
        $c = isset($stats['click_rate']) ? (float) $stats['click_rate'] : 0;
        // Verdict: WIN if it beats BOTH averages, LOSS if below both, else MIXED.
        $verdict = 'baseline';
        if ($avgO !== null) {
            if ($o >= $avgO && $c >= $avgC)      { $verdict = 'win'; }
            elseif ($o < $avgO && $c < $avgC)    { $verdict = 'loss'; }
            else                                 { $verdict = 'mixed'; }
        }

        $pid    = (int) trim(strtok((string) $row['course_pids'], ','));
        $cd     = $pid ? $this->_flyer()->courseData($pid) : null;
        $curated = false;
        if ($cd) {
            $pitch   = $this->_flyer(); // curated map lives on the flyer helper
            $curated = false;
            try {
                $ref = new ReflectionMethod('MMD_Marketing_Helper_Flyer', '_curatedPitch');
                $ref->setAccessible(true);
                $map = $ref->invoke(Mage::helper('mmd_marketing/flyer'));
                $curated = isset($map[trim((string) $cd['sku'])]);
            } catch (Exception $e) { /* best-effort */ }
        }

        $entry = array(
            'at'         => $this->_nowStr(),
            'newsletter' => (int) $newsletterId,
            'sku'        => $cd ? (string) $cd['sku'] : '',
            'course'     => $cd ? (string) $cd['name'] : (string) $row['title'],
            'subject'    => (string) $row['subject'],
            'is_wsq'     => $cd ? (bool) $cd['is_wsq'] : null,
            'accent'     => $cd ? (string) $cd['accent'] : '',
            'curated'    => $curated,
            'open_rate'  => round($o, 4),
            'click_rate' => round($c, 4),
            'ctor'       => isset($stats['ctor']) ? round((float) $stats['ctor'], 4) : null,
            'avg_open'   => $avgO !== null ? round($avgO, 4) : null,
            'avg_click'  => $avgC !== null ? round($avgC, 4) : null,
            'verdict'    => $verdict,
        );

        $log = $this->designLearnings();
        $log[] = $entry;
        if (count($log) > 24) { $log = array_slice($log, -24); }
        Mage::getModel('core/config')->saveConfig('mmd_marketing/newsletter/design_learnings', json_encode($log));
        Mage::app()->getCacheInstance()->cleanType('config');
        $this->_log('analyseBlast: #' . (int) $newsletterId . ' open=' . round($o * 100, 1) . '% click='
            . round($c * 100, 1) . '% verdict=' . strtoupper($verdict)
            . ($avgO !== null ? ' (avg ' . round($avgO * 100, 1) . '%/' . round($avgC * 100, 1) . '%)' : ' (first blast)'));
    }

    /**
     * The persisted post-blast learnings log (JSON array; newest last). Reads the
     * value straight from core_config_data — NOT Mage::getStoreConfig(), which
     * returns the in-memory config snapshot loaded at bootstrap and so does NOT
     * reflect a saveConfig() made earlier in the same request. That stale read
     * meant two analyseBlast() calls in one process each started from an empty
     * log and overwrote each other; a direct DB read makes appends accumulate.
     */
    public function designLearnings()
    {
        $raw = $this->_read()->fetchOne(
            'SELECT value FROM ' . Mage::getSingleton('core/resource')->getTableName('core/config_data')
          . " WHERE path = 'mmd_marketing/newsletter/design_learnings'"
          . ' AND scope = ? AND scope_id = 0 LIMIT 1',
            array('default')
        );
        $log = json_decode((string) $raw, true);
        return is_array($log) ? $log : array();
    }

    /**
     * PRE-DESIGN HOOK. Before a flyer is built, surface (and log) what should guide
     * it for this course: does it have a curated pitch, and what have past blasts
     * taught us? Returns a structured recommendation the render already honours
     * (curated pitch + accent) and that a human/agent can act on — e.g. copy the
     * subject formula of the highest open-rate WSQ blast. Non-fatal, read-only.
     */
    public function preDesignHook($productId)
    {
        $rec = array('curated' => false, 'best_subject' => null, 'best_open' => null, 'avg_open' => null, 'avg_click' => null, 'notes' => array());
        try {
            $cd = $this->_flyer()->courseData((int) $productId);
            if (!$cd) { return $rec; }
            $sku = trim((string) $cd['sku']);

            $ref = new ReflectionMethod('MMD_Marketing_Helper_Flyer', '_curatedPitch');
            $ref->setAccessible(true);
            $map = $ref->invoke(Mage::helper('mmd_marketing/flyer'));
            $rec['curated'] = isset($map[$sku]);
            $rec['notes'][] = $rec['curated']
                ? 'Using curated pitch + accent for ' . $sku . '.'
                : 'No curated pitch for ' . $sku . ' — outcomes reframed from its own topics; consider adding one to the newsletter-design skill.';

            // Learn from history: the best-performing past blast (prefer same funding
            // type) sets the subject formula + confidence target for this design.
            $log  = $this->designLearnings();
            $isW  = (bool) $cd['is_wsq'];
            $pool = array_filter($log, function ($e) use ($isW) { return isset($e['is_wsq']) && (bool) $e['is_wsq'] === $isW; });
            if (empty($pool)) { $pool = $log; }
            if (!empty($pool)) {
                usort($pool, function ($a, $b) { return ($b['open_rate'] ?? 0) <=> ($a['open_rate'] ?? 0); });
                $best = $pool[0];
                $rec['best_subject'] = isset($best['subject']) ? (string) $best['subject'] : null;
                $rec['best_open']    = isset($best['open_rate']) ? (float) $best['open_rate'] : null;
                $o = $c = $n = 0.0;
                foreach ($log as $e) { $o += $e['open_rate'] ?? 0; $c += $e['click_rate'] ?? 0; $n++; }
                $rec['avg_open']  = $n ? $o / $n : null;
                $rec['avg_click'] = $n ? $c / $n : null;
                $rec['notes'][] = 'Best past open-rate: ' . round(($rec['best_open'] ?: 0) * 100, 1) . '% — subject "' . $rec['best_subject'] . '". Aim to beat it.';
            } else {
                $rec['notes'][] = 'No blast history yet — this becomes the baseline.';
            }
        } catch (Exception $e) {
            $rec['notes'][] = 'preDesignHook partial: ' . $e->getMessage();
        }
        $this->_log('preDesignHook: pid ' . (int) $productId . ' — ' . implode(' ', $rec['notes']));
        return $rec;
    }
}
