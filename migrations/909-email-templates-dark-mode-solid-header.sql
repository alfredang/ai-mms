-- 909: Make the lead auto-reply email templates dark-mode-safe in Gmail.
--
-- Gmail's dark theme inverts SOLID background + text colours coherently
-- (contrast survives), but it keeps CSS gradients/background-images while
-- STILL inverting the text colour — so the auto-reply's blue gradient header
-- rendered near-black text on a mid-blue band (reported 2026-08-10 on the
-- "Thank you for your enquiry" MY email). Fix: solid #1e3a8a header, matching
-- the repo file templates (app/locale/.../mmd_leads/*.html, same commit).
-- House rule going forward: NEVER put text over a gradient/bg-image in email
-- HTML — solid colours only (the "MMD Lead Notification" template is the
-- reference pattern).
--
-- Targets DB templates 8 ("Lead Auto-Reply — Enquiry Acknowledgement") and
-- 9 ("Lead Auto-Reply — Singapore (WSQ)") by content match, so this is
-- idempotent and a no-op on partner instances without the rows.

UPDATE core_email_template
SET template_text = REPLACE(
    template_text,
    'background:linear-gradient(135deg,#1e3a8a 0%,#2563eb 100%)',
    'background:#1e3a8a'),
    modified_at = NOW()
WHERE template_text LIKE '%background:linear-gradient(135deg,#1e3a8a 0%,#2563eb 100%)%';
