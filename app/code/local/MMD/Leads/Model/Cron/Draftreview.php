<?php
/**
 * Lead AI-draft review pipeline (cron, every 5 min) — the lead-reply
 * counterpart of the blog approval flow:
 *
 *   1. Pick up recent NEW leads with no draft yet (and leads whose admin
 *      asked for changes), max a few per run.
 *   2. Generate a personalised reply with Claude (MMD_Leads_Helper_AiDraft).
 *   3. Email the admin the draft with Approve / Request-changes HMAC links
 *      (no login needed — same token contract as the blog pipeline).
 *   4. Approval (ReviewController::decideAction) auto-sends the reply to
 *      the lead; request-changes regenerates and re-sends for approval.
 *
 * Runs OUT-OF-BAND only — never in the storefront submission path (the
 * instant generic auto-reply still goes out on capture; this pipeline
 * follows up with the personalised reply once approved).
 *
 * Reviewer emails only leave a production SG host unless
 * mmd_leads/draft_review/allow_local_review_email=1 (same guard contract
 * as the blog/newsletter reviews).
 */
class MMD_Leads_Model_Cron_Draftreview
{
    const CONFIG_ENABLED     = 'mmd_leads/draft_review/enabled';
    const CONFIG_ALLOW_LOCAL = 'mmd_leads/draft_review/allow_local_review_email';
    const MAX_PER_RUN        = 3;
    const LOOKBACK_DAYS      = 2;

    public function run()
    {
        if (!Mage::getStoreConfigFlag(self::CONFIG_ENABLED)) {
            return 'draft review disabled';
        }
        if (!Mage::helper('mmd_leads')->getDraftReviewers()) {
            return 'no reviewers configured';
        }

        $done = 0;

        // Fresh leads awaiting a first draft. Bounded created_at window so
        // enabling the feature never mass-drafts the historical backlog.
        $fresh = Mage::getModel('mmd_leads/lead')->getCollection()
            ->addFieldToFilter('status', MMD_Leads_Model_Lead::STATUS_NEW)
            ->addFieldToFilter('draft_status', array('null' => true))
            ->addFieldToFilter('created_at', array('gteq' => date('Y-m-d H:i:s', time() - self::LOOKBACK_DAYS * 86400)))
            ->setOrder('lead_id', 'ASC')
            ->setPageSize(self::MAX_PER_RUN);
        foreach ($fresh as $lead) {
            $done += $this->_draftAndSend($lead) ? 1 : 0;
        }

        // Change-requested leads awaiting a regenerate (the decide endpoint
        // regenerates synchronously; this is the retry safety net).
        $redo = Mage::getModel('mmd_leads/lead')->getCollection()
            ->addFieldToFilter('status', MMD_Leads_Model_Lead::STATUS_NEW)
            ->addFieldToFilter('draft_status', MMD_Leads_Model_Lead::DRAFT_CHANGES_REQUESTED)
            ->setOrder('lead_id', 'ASC')
            ->setPageSize(self::MAX_PER_RUN);
        foreach ($redo as $lead) {
            $done += $this->_draftAndSend($lead, (string) $lead->getDraftFeedback()) ? 1 : 0;
        }

        return $done . ' draft(s) processed';
    }

    /**
     * Generate (or regenerate) the draft for one lead and email the
     * approval request. Public so the decide endpoint can regenerate
     * synchronously on request-changes.
     *
     * @return bool  true when the approval email went out
     */
    public function _draftAndSend(MMD_Leads_Model_Lead $lead, $feedback = '')
    {
        try {
            $draft = Mage::helper('mmd_leads/aiDraft')->draft($lead, $feedback);
        } catch (Exception $e) {
            // Leave draft_status untouched — the bounded window retries on
            // the next runs and naturally stops after LOOKBACK_DAYS.
            $this->_log('draft generation failed for lead #' . $lead->getId() . ': ' . $e->getMessage());
            return false;
        }

        $lead->setDraftSubject($draft['subject_course'])
             ->setDraftHtml($draft['body_html'])
             ->logDraftEvent('drafted', $feedback !== '' ? 'Redrafted per admin feedback' : 'AI draft generated');

        if (!$this->sendForReview($lead)) {
            // Draft is saved but unstamped — next cron run retries the email.
            $lead->save();
            return false;
        }

        $lead->setDraftStatus(MMD_Leads_Model_Lead::DRAFT_PENDING_REVIEW)
             ->setDraftReviewSentAt(Varien_Date::now())
             ->logDraftEvent('review_sent', 'Approval email sent to ' . implode(', ', Mage::helper('mmd_leads')->getDraftReviewers()))
             ->save();
        return true;
    }

    /**
     * Email the reviewers the pending draft with approve / request-changes
     * token links. Gmail OAuth first, SMTPPro, then bare Zend_Mail — same
     * transport ladder as the blog review email.
     *
     * @return bool  true when at least one reviewer email went out
     */
    public function sendForReview(MMD_Leads_Model_Lead $lead)
    {
        if (!$this->_mayEmailReviewers()) {
            $this->_log('sendForReview SKIPPED for lead #' . $lead->getId()
                . ' — non-SG-production base_url. Set mmd_leads/draft_review/allow_local_review_email=1 to test.');
            return false;
        }

        $helper  = Mage::helper('mmd_leads');
        $base    = rtrim((string) Mage::getStoreConfig('web/unsecure/base_url'), '/');
        $storeId = (int) $lead->getStoreId();

        $gmail = null;
        try {
            $gh = Mage::helper('mmd_email/gmail');
            if ($gh && $gh->isConfigured()) { $gmail = $gh; }
        } catch (Exception $e) {
            $this->_log('Gmail OAuth helper unavailable: ' . $e->getMessage());
        }
        $transport = null;
        if (!$gmail) {
            try {
                if (Mage::helper('core')->isModuleEnabled('Aschroder_SMTPPro')) {
                    $t = Mage::helper('smtppro')->getTransport();
                    if ($t) { $transport = $t; }
                }
            } catch (Exception $e) {
                $this->_log('SMTPPro transport unavailable: ' . $e->getMessage());
            }
        }

        $leadUrl = $base . '/index.php/adminlogin/leads/view/id/' . (int) $lead->getId() . '/';

        $sentAny = false;
        foreach ($helper->getDraftReviewers() as $email) {
            $tok     = $helper->signDraftReviewToken($lead->getId(), $email);
            $approve = $base . '/leadreview/review/decide/id/' . (int) $lead->getId() . '/d/approve/e/' . rawurlencode($email) . '/t/' . $tok;
            $changes = $base . '/leadreview/review/decide/id/' . (int) $lead->getId() . '/d/changes/e/' . rawurlencode($email) . '/t/' . $tok;

            $html = '<div style="font-family:-apple-system,Segoe UI,Arial,sans-serif;max-width:720px;margin:0 auto;">'
                . '<p style="font-size:15px;color:#0a1020;">Hi — an AI-drafted reply to a new lead is ready for your approval. '
                . 'If approved, it is emailed to the lead immediately.</p>'
                . '<table role="presentation" style="font-size:13px;color:#334155;border-collapse:collapse;margin:0 0 4px;">'
                . '<tr><td style="padding:2px 12px 2px 0;color:#64748b;">Lead</td><td><b>' . htmlspecialchars($lead->getName()) . '</b> &lt;' . htmlspecialchars($lead->getEmail()) . '&gt;' . ($lead->getCompany() ? ' · ' . htmlspecialchars($lead->getCompany()) : '') . '</td></tr>'
                . '<tr><td style="padding:2px 12px 2px 0;color:#64748b;">Interest</td><td>' . htmlspecialchars($lead->getCoursesInterested() ?: '—') . ($lead->getCourseCode() ? ' (' . htmlspecialchars($lead->getCourseCode()) . ')' : '') . '</td></tr>'
                . '<tr><td style="padding:2px 12px 2px 0;color:#64748b;">Store</td><td>' . htmlspecialchars($helper->getStoreLabel($storeId)) . '</td></tr>'
                . '</table>'
                . '<p style="font-size:13px;color:#475569;background:#f1f5f9;border-radius:8px;padding:10px 14px;white-space:pre-wrap;margin:10px 0 0;">' . htmlspecialchars($lead->getComment()) . '</p>'
                . '<table role="presentation" style="margin:18px 0;"><tr>'
                . '<td style="padding-right:10px;"><a href="' . htmlspecialchars($approve) . '" style="background:#059669;color:#fff;text-decoration:none;font-weight:700;font-size:14px;padding:11px 22px;border-radius:8px;display:inline-block;">&#10003; Approve &amp; send to lead</a></td>'
                . '<td><a href="' . htmlspecialchars($changes) . '" style="background:#e2e8f0;color:#0a1020;text-decoration:none;font-weight:700;font-size:14px;padding:11px 22px;border-radius:8px;display:inline-block;">&#9998; Request changes</a></td>'
                . '</tr></table>'
                . '<p style="font-size:12px;color:#7c8aa3;">"Request changes" lets you describe what to rewrite; the reply is regenerated and re-sent for approval. '
                . 'You can also <a href="' . htmlspecialchars($leadUrl) . '" style="color:#2563eb;">edit and send it manually</a> in the admin.</p>'
                . '<hr style="border:0;border-top:1px solid #e4e9f0;margin:18px 0;">'
                . '<p style="font-size:12px;color:#7c8aa3;margin:0 0 6px;">Draft subject: <b style="color:#334155;">Re: Your enquiry about ' . htmlspecialchars($lead->getDraftSubject()) . '</b></p>'
                . '<div style="border:1px solid #e4e9f0;border-radius:10px;padding:18px 20px;font-size:14px;line-height:1.6;color:#0f172a;">'
                . '<p style="margin:0 0 12px;">Hi ' . htmlspecialchars($helper->getFirstName($lead->getName())) . ',</p>'
                . $lead->getDraftHtml()
                . '<p style="margin:12px 0 0;color:#64748b;">— sent via the branded course-reply template with greeting/signature.</p>'
                . '</div>'
                . '</div>';
            $subject = '[Approval needed] Lead reply: ' . $lead->getName()
                . ' — ' . ($lead->getDraftSubject() ?: $lead->getCoursesInterested());

            try {
                if ($gmail) {
                    $gmail->send($email, $subject, $html, 'Tertiary Leads');
                } else {
                    $mail = new Zend_Mail('utf-8');
                    $mail->setBodyHtml($html)
                         ->setFrom(Mage::getStoreConfig('trans_email/ident_general/email'), 'Tertiary Leads')
                         ->addTo($email)
                         ->setSubject($subject);
                    $transport ? $mail->send($transport) : $mail->send();
                }
                $sentAny = true;
                $this->_log('sendForReview: emailed ' . $email . ' for lead #' . $lead->getId());
            } catch (Exception $e) {
                $this->_log('sendForReview mail to ' . $email . ' failed: ' . $e->getMessage());
            }
        }
        return $sentAny;
    }

    /** Never email the real admin from a non-production env (blog contract). */
    protected function _mayEmailReviewers()
    {
        $host = strtolower((string) parse_url(
            (string) Mage::getStoreConfig('web/unsecure/base_url'), PHP_URL_HOST
        ));
        if (preg_match('/(^|\.)tertiarycourses\.com\.sg$/', $host)) {
            return true;
        }
        return (bool) Mage::getStoreConfig(self::CONFIG_ALLOW_LOCAL);
    }

    protected function _log($msg)
    {
        Mage::log('[lead-draft-review] ' . $msg, Zend_Log::INFO, 'leads.log', true);
    }
}
