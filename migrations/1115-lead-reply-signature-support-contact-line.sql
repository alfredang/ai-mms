-- 1115: Lead reply signature — "Warm regards, Support from Tertiary Infotech
-- Academy" + clickable Email / WhatsApp contact line.
--
-- The SG lead auto-reply is sent from the DB template "Lead Auto-Reply —
-- Singapore (WSQ)" (seeded by 166; store-scope pointer
-- mmd_leads/auto_reply/email_template targets its row id), so editing the repo
-- file template (auto_reply_sg.html, updated in this same commit) never
-- reaches prod on its own — this migration rewrites the DB copy's signature
-- block to match. The operator/AI course reply (mmd_leads_course_reply) is
-- file-based with no DB row, so the commit's course_reply.html edit covers it.
--
-- Two whitespace-free REPLACE anchors (verified against live SG prod
-- 2026-08-25: single-line template_text, no CR/LF, signature reads
-- "Yours Sincerely,<br/> ... <strong>{{var store_brand}}</strong>") so the
-- inner whitespace run between them can't defeat the match. Idempotent (the
-- anchors vanish after the first run) and partner-safe: scoped to the
-- Singapore template row, a no-op where the row or the anchors are absent.

UPDATE core_email_template
SET template_text = REPLACE(
        REPLACE(
            template_text,
            'Yours Sincerely,<br/>',
            'Warm regards,<br/>'),
        '<strong>{{var store_brand}}</strong>',
        'Support from <strong>Tertiary Infotech Academy</strong><br/>Email: <a href="mailto:enquiry@tertiaryinfotech.com" style="color:#2563eb;">enquiry@tertiaryinfotech.com</a> | Tel: 61000613 | Whatsapp: <a href="https://wa.me/6588666375" style="color:#2563eb;">8866 6375</a>'),
    modified_at = NOW()
WHERE template_code LIKE 'Lead Auto-Reply%Singapore%'
  AND template_text LIKE '%Yours Sincerely,<br/>%';
