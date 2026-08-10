-- 912: Footer "Training Grant and Subsidy" menu — relabel "UTAP Claim
--      Application" -> "Submit UTAP Claim" and point it at the direct
--      online-claim portal.
--
-- The footer item still carried the pre-908 legacy skillsupgrade.ntuc.org.sg
-- portal URL (908 swept the eserviceslanding URL only). New target
-- https://utap.ntuc.org.sg/onlineClaim matches the funding card (908).
-- Exact-match REPLACE on the one footer block — idempotent, no-op on partner
-- instances (UTAP is SG-only; the anchor is absent off-SG).

UPDATE cms_block
SET content = REPLACE(
    content,
    '<a href="http://skillsupgrade.ntuc.org.sg/wps/portal/skillsupgrade/home/skillsupgradeavailable/featuredindustries/featuredindustriesdetails?WCM_GLOBAL_CONTEXT=/content_library/skillsupgrade/home/skills+upgrade+available/featured+industries/da9571804f32741a9d86fdbda6c1e78c" title="How to submit UTAP Claim" target="_blank">UTAP Claim Application</a>',
    '<a href="https://utap.ntuc.org.sg/onlineClaim" title="Submit UTAP Claim" target="_blank">Submit UTAP Claim</a>')
WHERE identifier = 'block_footer_row2_column5'
  AND content LIKE '%title="How to submit UTAP Claim"%';
