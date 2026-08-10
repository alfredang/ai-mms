-- 907: Replace the dead MOE PSEA ad-hoc withdrawal form URL with the working one.
--
-- The old form path (moe.gov.sg/-/media/files/financial-matters/...) returns
-- 404; MOE now serves the same PDF from its media API. Verified 2026-08-10:
--   old: https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf -> 404
--   new: https://www.moe.gov.sg/api/media/94b3eeb8-ceed-47e3-9f58-921b33970c9a/psea-ad-hoc-withdrawal-form.pdf -> 200 application/pdf
--
-- Code copies (CourseImage helper + product view.phtml PSEA canonical card)
-- are fixed in the same commit; this sweeps the data copies: legacy per-course
-- funding_and_grant cms blocks, the SG footer block, and one product
-- description. Server-side REPLACE only — idempotent, partner-safe (no-op
-- where the old URL is absent).

UPDATE cms_block
SET content = REPLACE(
    content,
    'https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf',
    'https://www.moe.gov.sg/api/media/94b3eeb8-ceed-47e3-9f58-921b33970c9a/psea-ad-hoc-withdrawal-form.pdf')
WHERE content LIKE '%moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form%';

UPDATE cms_page
SET content = REPLACE(
    content,
    'https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf',
    'https://www.moe.gov.sg/api/media/94b3eeb8-ceed-47e3-9f58-921b33970c9a/psea-ad-hoc-withdrawal-form.pdf')
WHERE content LIKE '%moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form%';

UPDATE catalog_product_entity_text
SET value = REPLACE(
    value,
    'https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf',
    'https://www.moe.gov.sg/api/media/94b3eeb8-ceed-47e3-9f58-921b33970c9a/psea-ad-hoc-withdrawal-form.pdf')
WHERE value LIKE '%moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form%';
