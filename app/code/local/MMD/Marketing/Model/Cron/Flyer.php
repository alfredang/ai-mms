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

    protected function _log($msg)
    {
        try {
            $dir = Mage::getBaseDir('log');
            if (!is_dir($dir)) @mkdir($dir, 0777, true);
            @file_put_contents($dir . '/marketing-cron.log',
                '[' . date('Y-m-d H:i:s') . '] ' . $msg . "\n", FILE_APPEND);
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
        $productId = $this->pickPopularUpcomingClass();
        if (!$productId) {
            $this->_log('propose: skipped — no popular upcoming class found in the next 2-3 weeks');
            return;
        }
        $newsletterId = $this->createProposal($productId);
        if ($newsletterId) {
            $this->sendForReview($newsletterId);
            $this->_log('propose: proposal #' . $newsletterId . ' for product ' . $productId . ' sent for review');
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
        // 1. Unsent pending proposals -> email both managers the approve/changes links.
        $ids = $this->_read()->fetchCol('SELECT newsletter_id FROM ' . $this->_tbl()
            . " WHERE review_status = 'pending' AND (review_token IS NULL OR review_token = '')");
        foreach ($ids as $nid) {
            $this->sendForReview((int) $nid);
            $this->_log('followUp: emailed managers for unsent pending proposal #' . (int) $nid);
        }
        // 2. Change requests -> regenerate (same course, fresh render) + re-send.
        $rows = $this->_read()->fetchAll('SELECT * FROM ' . $this->_tbl() . " WHERE review_status = 'changes_requested'");
        foreach ($rows as $row) {
            $old = (int) $row['newsletter_id'];
            $this->_write()->update($this->_tbl(), array('review_status' => 'superseded'),
                array('newsletter_id = ?' => $old));
            if ($this->_guard()->remainingDesignsThisWeek() < 1) {
                $this->_log('followUp: change request on #' . $old . ' deferred — weekly design cap reached');
                continue;
            }
            $pid = (int) trim(strtok((string) $row['course_pids'], ','));
            $nid = $pid ? $this->createProposal($pid) : null;
            if ($nid) {
                // carry the manager's feedback onto the new proposal for context
                $this->_write()->update($this->_tbl(),
                    array('review_feedback' => (string) $row['review_feedback']),
                    array('newsletter_id = ?' => $nid));
                $this->sendForReview($nid);
                $this->_log('followUp: regenerated #' . $old . ' -> #' . $nid . ' after change request');
            } else {
                $this->_log('followUp: could not regenerate #' . $old . ' (no renderable course)');
            }
        }
        // 3. Expire stale pendings.
        $this->_write()->update($this->_tbl(),
            array('review_status' => 'expired'),
            array("review_status = 'pending'", 'created_at < ?' => date('Y-m-d H:i:s', strtotime('-5 days')))
        );
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
        $from = date('Y-m-d', strtotime('+7 days'));
        $to   = date('Y-m-d', strtotime('+21 days'));

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
            array(date('Y-m-d H:i:s', strtotime('-30 days')))
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
            'created_at'    => date('Y-m-d H:i:s'),
        ));
        return (int) $conn->lastInsertId();
    }

    /** Email the two managers the flyer + signed Approve / Request-changes links. */
    public function sendForReview($newsletterId)
    {
        $row = $this->_read()->fetchRow('SELECT * FROM ' . $this->_tbl() . ' WHERE newsletter_id = ?', array($newsletterId));
        if (!$row) { return false; }
        $g = $this->_guard();
        $base = rtrim(Mage::getStoreConfig('web/unsecure/base_url'), '/');
        $slot = $g->nextSendSlot();
        $slotTxt = $slot ? $slot->format('l, j M Y \a\t g:ia') : 'the next available slot';

        foreach ($g->reviewers() as $email) {
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

            try {
                $mail = new Zend_Mail('utf-8');
                $mail->setBodyHtml($html)
                     ->setFrom(Mage::getStoreConfig('trans_email/ident_general/email'), 'Tertiary Marketing')
                     ->addTo($email)
                     ->setSubject('[Approval needed] ' . $row['subject']);
                $mail->send();   // uses the site's configured transport (SMTPPro on prod)
                $this->_log('sendForReview: emailed ' . $email . ' for #' . $newsletterId);
            } catch (Exception $e) {
                $this->_log('sendForReview mail to ' . $email . ' failed: ' . $e->getMessage());
            }
        }
        $this->_write()->update($this->_tbl(),
            array('review_token' => $g->signToken($newsletterId, 'batch')),
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
        if ((string) $row['status'] === 'scheduled') {
            return array(true, 'Already scheduled.');   // idempotent: don't double-book
        }

        // Create + schedule the MailerLite campaign for the chosen Mon/Thu 08:00 slot.
        try {
            $mlId = Mage::helper('mmd_marketing/mailerlite')
                ->createAndSchedule((string) $row['subject'], (string) $row['body_html'], $slot);
        } catch (Exception $e) {
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
        return array(true, 'Scheduled for ' . $slot->format('l, j M Y \a\t g:ia'));
    }
}
