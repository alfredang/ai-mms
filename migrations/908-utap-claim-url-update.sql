-- 908: Point all legacy UTAP links at the direct online-claim portal.
--
-- The funding card's UTAP section (helper + view.phtml canonical copy) now
-- links to https://utap.ntuc.org.sg/onlineClaim (verified 200 → NTUC sign-in,
-- 2026-08-10). This sweeps the legacy DB copies — per-course funding_and_grant
-- cms blocks and authored short descriptions — which still carry the old
-- generic NTUC eServices landing URL. Old URL still resolves, so this is a
-- consistency fix, not a dead-link fix. Server-side REPLACE only —
-- idempotent, partner-safe (no-op where the old URL is absent).

UPDATE cms_block
SET content = REPLACE(
    content,
    'https://www.ntuc.org.sg/wps/portal/up2/home/eserviceslanding?id=6bc1ca2c-ce81-4acb-a28f-c0be586e185f',
    'https://utap.ntuc.org.sg/onlineClaim')
WHERE content LIKE '%eserviceslanding?id=6bc1ca2c-ce81-4acb-a28f-c0be586e185f%';

UPDATE cms_page
SET content = REPLACE(
    content,
    'https://www.ntuc.org.sg/wps/portal/up2/home/eserviceslanding?id=6bc1ca2c-ce81-4acb-a28f-c0be586e185f',
    'https://utap.ntuc.org.sg/onlineClaim')
WHERE content LIKE '%eserviceslanding?id=6bc1ca2c-ce81-4acb-a28f-c0be586e185f%';

UPDATE catalog_product_entity_text
SET value = REPLACE(
    value,
    'https://www.ntuc.org.sg/wps/portal/up2/home/eserviceslanding?id=6bc1ca2c-ce81-4acb-a28f-c0be586e185f',
    'https://utap.ntuc.org.sg/onlineClaim')
WHERE value LIKE '%eserviceslanding?id=6bc1ca2c-ce81-4acb-a28f-c0be586e185f%';
