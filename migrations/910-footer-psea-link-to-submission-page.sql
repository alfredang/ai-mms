-- 910: Footer "Training Grant and Subsidy" menu — point the PSEA item at the
--      new on-site submission page instead of the raw MOE PDF.
--
-- The /psea-submission/ page (MMD_Psea, same release train) lets the learner
-- download the MOE template, fill it, attach it and submit — the form is
-- emailed to enquiry@tertiaryinfotech.com cc sales@tertiarycourses.com.sg.
-- Relabel "PSEA Withdrawal Form" -> "Submit PSEA Form" per ops request
-- 2026-08-10. Exact-match REPLACE on the one footer block — idempotent,
-- no-op on partner instances (PSEA is SG-only; page 404s off-SG by design).

UPDATE cms_block
SET content = REPLACE(
    content,
    '<a href="https://www.moe.gov.sg/api/media/94b3eeb8-ceed-47e3-9f58-921b33970c9a/psea-ad-hoc-withdrawal-form.pdf" title="PSEA Withdraw Form" target="_blank">PSEA Withdrawal Form</a>',
    '<a href="/psea-submission/" title="Submit PSEA Form">Submit PSEA Form</a>')
WHERE identifier = 'block_footer_row2_column5'
  AND content LIKE '%title="PSEA Withdraw Form"%';
