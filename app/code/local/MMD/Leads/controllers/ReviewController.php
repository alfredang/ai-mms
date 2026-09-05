<?php
/**
 * Public no-login admin review endpoint for AI-drafted lead replies —
 * /leadreview/review/decide/id/<lead>/d/<approve|changes>/e/<email>/t/<token>[/k/<kind>]
 *
 * <kind> selects the lead table (corporate / franchise / customised — see
 * MMD_Leads_Helper_Data::getLeadKinds()); omitted = general enquiry lead.
 *
 * Authorisation is the HMAC token bound to lead + reviewer email (same
 * contract as the blog pipeline's /blog/index/decide). Links only ever go
 * to the configured reviewers.
 *
 *   approve — atomically claims the pending draft and emails the reply to
 *             the lead through the branded course-reply template, CCing
 *             the training team (mmd_leads/auto_reply/cc).
 *   changes — GET shows a feedback form; POST records the feedback,
 *             regenerates the draft with Claude honouring it, and re-sends
 *             the approval email.
 */
class MMD_Leads_ReviewController extends Mage_Core_Controller_Front_Action
{
    public function decideAction()
    {
        $req      = $this->getRequest();
        $id       = (int) $req->getParam('id');
        $decision = (string) $req->getParam('d');
        $email    = strtolower(trim((string) $req->getParam('e')));
        $token    = (string) $req->getParam('t');
        $kind     = (string) $req->getParam('k', 'general');
        $helper   = Mage::helper('mmd_leads');

        $lead = $helper->getLeadModel($kind);
        if (!$lead
            || !$helper->verifyDraftReviewToken($id, $email, $token, $kind)
            || !in_array($email, $helper->getDraftReviewers(), true)
        ) {
            return $this->_reviewPage('Invalid or expired link',
                '<p style="color:#475569;">This approval link is not valid. Please use the buttons in the latest review email.</p>', '#ef4444');
        }

        $lead->load($id);
        if (!$lead->getId()) {
            return $this->_reviewPage('Not found',
                '<p style="color:#475569;">This lead no longer exists.</p>', '#ef4444');
        }
        if ($lead->getStatus() === MMD_Leads_Model_Lead::STATUS_REPLIED) {
            return $this->_reviewPage('Already replied',
                '<p style="color:#475569;">A reply has already been sent to <b>' . $this->_esc($lead->getEmail()) . '</b> — nothing more to do.</p>', '#059669');
        }

        if ($decision === 'changes') {
            return $this->_handleChanges($lead, $email);
        }
        if ($decision === 'approve') {
            return $this->_handleApprove($lead, $email);
        }
        return $this->_reviewPage('Unknown action',
            '<p style="color:#475569;">Unrecognised decision.</p>', '#ef4444');
    }

    protected function _handleApprove(MMD_Leads_Model_Lead $lead, $reviewerEmail)
    {
        if (trim((string) $lead->getDraftHtml()) === '') {
            return $this->_reviewPage('No draft available',
                '<p style="color:#475569;">There is no pending draft for this lead — it may be regenerating. Try again from the latest review email.</p>', '#ef4444');
        }

        $req  = $this->getRequest();
        $vNow = substr(sha1((string) $lead->getDraftHtml()), 0, 12);

        // GET = confirmation preview. Nothing is sent until the reviewer sees
        // EXACTLY which lead and which draft this is and posts Confirm & send.
        // (Also stops mail-scanner link prefetches from ever triggering a
        // send, and makes lookalike approval emails safe — incident
        // 2026-07-28: two leads drafted near-identical approval emails and
        // one was approved by mistake.)
        if (!$req->isPost()) {
            $action = $this->_esc($req->getRequestUri());
            return $this->_reviewPage('Confirm before sending',
                '<p style="color:#475569;">You are about to send this reply to ' . $this->_esc($lead->getKindLabel()) . ' lead <b>#' . (int) $lead->getId() . '</b>:</p>'
                . '<table role="presentation" style="font-size:13px;color:#334155;border-collapse:collapse;margin:0 0 10px;">'
                . '<tr><td style="padding:2px 12px 2px 0;color:#94a3b8;">To</td><td><b>' . $this->_esc($lead->getName()) . '</b> &lt;' . $this->_esc($lead->getEmail()) . '&gt;</td></tr>'
                . '<tr><td style="padding:2px 12px 2px 0;color:#94a3b8;">Subject</td><td>Re: Your enquiry about ' . $this->_esc($lead->getDraftSubject()) . '</td></tr>'
                . '</table>'
                . '<p style="font-size:12.5px;color:#64748b;background:#f8fafc;border:1px solid #e4e9f0;border-radius:8px;padding:8px 12px;white-space:pre-wrap;margin:0 0 12px;">Their message: ' . $this->_esc(mb_substr($lead->getEnquiryMessage(), 0, 400)) . '</p>'
                . '<div style="border:1px solid #e4e9f0;border-radius:10px;padding:14px 16px;font-size:14px;line-height:1.6;color:#0f172a;max-height:340px;overflow:auto;">' . $lead->getDraftHtml() . '</div>'
                . '<form method="post" action="' . $action . '" style="margin-top:16px;display:flex;gap:10px;">'
                . '<input type="hidden" name="v" value="' . $vNow . '"/>'
                . '<button type="submit" style="background:#059669;color:#fff;border:0;border-radius:10px;padding:12px 22px;font-weight:700;font-size:14px;cursor:pointer;">&#10003; Confirm &amp; send to ' . $this->_esc($lead->getEmail()) . '</button>'
                . '</form>', '#059669');
        }

        // Version lock: the confirm page embeds the fingerprint of the draft
        // it displayed; if the draft changed in between, never send blind.
        if ((string) $req->getPost('v') !== $vNow) {
            return $this->_reviewPage('Draft has changed',
                '<p style="color:#475569;">This draft was updated after you opened the confirmation page. Please review the latest version and confirm again.</p>'
                . '<p><a href="' . $this->_esc($req->getRequestUri()) . '" style="color:#2563eb;font-weight:700;">Open the latest draft</a></p>', '#f59e0b');
        }

        // Atomic claim — only the first approval flips pending -> approved
        // and sends; a concurrent second click sees 0 rows and reports done.
        $write   = Mage::getSingleton('core/resource')->getConnection('core_write');
        $table   = $lead->getResource()->getMainTable();
        $claimed = $write->update(
            $table,
            array('draft_status' => MMD_Leads_Model_Lead::DRAFT_APPROVED_SENT),
            array(
                'lead_id = ?'        => (int) $lead->getId(),
                'draft_status IN (?)' => array(
                    MMD_Leads_Model_Lead::DRAFT_PENDING_REVIEW,
                    MMD_Leads_Model_Lead::DRAFT_CHANGES_REQUESTED,
                ),
            )
        );
        if (!$claimed) {
            return $this->_reviewPage('Already handled',
                '<p style="color:#475569;">This draft was already approved and sent — nothing more to do.</p>', '#059669');
        }

        $helper  = Mage::helper('mmd_leads');
        $subject = (string) $lead->getDraftSubject() ?: (trim($lead->getEnquiryInterest()) ?: 'your enquiry');
        $ccList  = array();
        foreach (preg_split('/[,;]+/', (string) Mage::getStoreConfig('mmd_leads/auto_reply/cc', (int) $lead->getStoreId() ?: null)) ?: array() as $cc) {
            $cc = trim($cc);
            if ($cc !== '' && Zend_Validate::is($cc, 'EmailAddress')) {
                $ccList[$cc] = $cc;
            }
        }

        try {
            $helper->sendCourseReply($lead, $lead->getEmail(), array_values($ccList), $subject, (string) $lead->getDraftHtml());
        } catch (Exception $e) {
            Mage::logException($e);
            // Roll the claim back so the next approval click can retry.
            $write->update($table,
                array('draft_status' => MMD_Leads_Model_Lead::DRAFT_PENDING_REVIEW),
                array('lead_id = ?' => (int) $lead->getId()));
            return $this->_reviewPage('Send failed',
                '<p style="color:#475569;">Approving worked but the email to the lead failed: <b>' . $this->_esc($e->getMessage()) . '</b>. Click the approve link again to retry, or send manually from the admin.</p>', '#ef4444');
        }

        $lead->setDraftStatus(MMD_Leads_Model_Lead::DRAFT_APPROVED_SENT)
             ->logDraftEvent('approved', 'Approved by ' . $reviewerEmail . ' — reply auto-sent to ' . $lead->getEmail());
        $lead->markReplied($subject . "\n\n" . $lead->getDraftHtml(), 0);

        return $this->_reviewPage('Approved & sent',
            '<p style="color:#475569;">The reply has been emailed to <b>' . $this->_esc($lead->getName()) . '</b> &lt;' . $this->_esc($lead->getEmail()) . '&gt;'
            . ($ccList ? ' (cc: ' . $this->_esc(implode(', ', $ccList)) . ')' : '') . '.</p>', '#059669');
    }

    protected function _handleChanges(MMD_Leads_Model_Lead $lead, $reviewerEmail)
    {
        $req = $this->getRequest();
        if ($req->isPost()) {
            $fb = trim((string) $req->getPost('feedback'));
            $lead->setDraftStatus(MMD_Leads_Model_Lead::DRAFT_CHANGES_REQUESTED)
                 ->setDraftFeedback($fb)
                 ->logDraftEvent('changes_requested', $reviewerEmail . ($fb !== '' ? ': ' . mb_substr($fb, 0, 200) : ''))
                 ->save();

            // Regenerate + re-send NOW so the fresh approval email arrives
            // immediately (the 5-min cron is only the retry safety net).
            $ok = false;
            try {
                $ok = Mage::getModel('mmd_leads/cron_draftreview')->_draftAndSend($lead, $fb);
            } catch (Exception $e) {
                Mage::logException($e);
            }
            return $this->_reviewPage('Changes requested',
                '<p style="color:#475569;">Thanks — your feedback was recorded.'
                . ($ok
                    ? ' The reply has been <b>regenerated</b> and a fresh approval email is on its way to you.'
                    : ' The reply will be regenerated and re-sent for approval within a few minutes.')
                . '</p>', '#f59e0b');
        }

        // GET — feedback form (same self-URL posts back with the token intact).
        $action = $this->_esc($req->getRequestUri());
        return $this->_reviewPage('Request changes',
            '<p style="color:#475569;">Describe what to change — the reply to <b>' . $this->_esc($lead->getName()) . '</b> is rewritten with your notes and re-sent for approval.</p>'
            . '<form method="post" action="' . $action . '">'
            . '<textarea name="feedback" rows="5" style="width:100%;box-sizing:border-box;border:1px solid #cbd5e1;border-radius:10px;padding:12px 14px;font:14px/1.5 -apple-system,Segoe UI,Arial,sans-serif;" placeholder="e.g. Mention the next class date explicitly, keep it under 100 words, drop the funding paragraph…"></textarea>'
            . '<button type="submit" style="margin-top:14px;background:#0a1020;color:#fff;border:0;border-radius:10px;padding:12px 22px;font-weight:700;font-size:14px;cursor:pointer;">Submit &amp; regenerate</button>'
            . '</form>', '#f59e0b');
    }

    protected function _reviewPage($title, $bodyHtml, $accent)
    {
        $html = '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            . '<meta name="robots" content="noindex,nofollow"><title>' . $this->_esc($title) . '</title></head>'
            . '<body style="margin:0;background:#eef2f7;font-family:-apple-system,Segoe UI,Arial,sans-serif;">'
            . '<div style="max-width:520px;margin:8vh auto;background:#fff;border:1px solid #e4e9f0;border-radius:16px;padding:32px 30px;box-shadow:0 20px 50px -20px rgba(15,23,42,.35);">'
            . '<div style="width:44px;height:6px;border-radius:3px;background:' . $accent . ';margin:0 0 18px;"></div>'
            . '<h1 style="font-size:20px;color:#0a1020;margin:0 0 12px;">' . $this->_esc($title) . '</h1>'
            . $bodyHtml
            . '<p style="font-size:12px;color:#94a3b8;margin:22px 0 0;">Tertiary Infotech Academy — lead reply review</p>'
            . '</div></body></html>';
        $this->getResponse()
            ->setHeader('Content-Type', 'text/html; charset=utf-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setBody($html);
        return $this;
    }

    protected function _esc($s)
    {
        return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8');
    }
}
