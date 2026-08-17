-- 1049 — Strip funding badge tags from unfunded non-WSQ (C-prefix) courses.
--
-- BUG: the AI cover generator's badge checkboxes were seeded per-WEBSITE only
-- (SG => WSQ/MCES/UTAP pre-ticked) and ignored the SKU, so clicking
-- "AI Generate" on a non-WSQ C-prefix course rendered a cover with a
-- "FUNDING AVAILABLE / WSQ / UTAP / MCES" chip row AND wrote the matching
-- Magento tags via syncProductTags(). Those tags additionally drive:
--   * the storefront chips under the course title (catalog list + product view)
--   * getWsqFundingNarrativeHtml() — the WSQ badge GATES the whole WSQ Funding
--     card, so an unfunded course could render SkillsFuture/UTAP claim copy.
--
-- Code fix (same commit) gates every render/tag-write path on the TGS- SKU
-- prefix (MMD_CourseImage_Helper_Data::isFundableSku), covering the Edit Course
-- checkbox defaults, generateAction, bulkRunAction and the Agent API cover op.
-- This migration repairs the data already written.
--
-- Scope: only C-prefix SKUs (C + digit) — i.e. unfunded SG non-WSQ courses.
-- TGS- courses (WSQ *and* CASL, which both use TGS- SKUs) are untouched, as are
-- M-prefix partner SKUs. Audited on SG prod 2026-08-17 by crawling all 282
-- category pages: of 248 distinct C-prefix courses, only C924 carried funding
-- chips. Written as a set-based DELETE rather than a C924 literal so any other
-- product polluted the same way (on any partner server, whose data may differ)
-- is cleaned by the same file.
--
-- Partner-safe: prefix convention holds on every site; a server with no
-- matching rows is a harmless no-op. Idempotent — re-running deletes nothing.

DELETE r
FROM tag_relation r
JOIN tag t ON t.tag_id = r.tag_id
JOIN catalog_product_entity p ON p.entity_id = r.product_id
WHERE p.sku REGEXP '^C[0-9]'
  AND t.name IN (
      'WSQ', 'CASL', 'SkillsFuture Credit', 'PSEA', 'UTAP',
      'IBF', 'HRDF', 'SFEC', 'Absentee Payroll', 'MCES'
  );

-- Recompute tag_summary so the admin Tags grid shows accurate product counts
-- after the deletes above (mirrors syncProductTags()'s own recompute step).
-- Rows whose relations are now all gone must be REMOVED, not zeroed, matching
-- the helper's behaviour when products drops to 0.
DELETE s
FROM tag_summary s
WHERE NOT EXISTS (
    SELECT 1 FROM tag_relation r
    WHERE r.tag_id = s.tag_id AND r.store_id = s.store_id
);

UPDATE tag_summary s
SET s.products = (
        SELECT COUNT(DISTINCT r.product_id) FROM tag_relation r
        WHERE r.tag_id = s.tag_id AND r.store_id = s.store_id
    ),
    s.uses = (
        SELECT COUNT(*) FROM tag_relation r
        WHERE r.tag_id = s.tag_id AND r.store_id = s.store_id
    ),
    s.customers = (
        SELECT COUNT(DISTINCT r.customer_id) FROM tag_relation r
        WHERE r.tag_id = s.tag_id AND r.store_id = s.store_id
    ),
    s.popularity = (
        SELECT COUNT(DISTINCT r.product_id) FROM tag_relation r
        WHERE r.tag_id = s.tag_id AND r.store_id = s.store_id
    );
