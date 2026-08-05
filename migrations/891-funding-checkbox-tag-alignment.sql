-- 891: Align funding badge tags with what the WSQ Funding card actually
-- renders today, ahead of the checkbox-driven refactor (2026-08).
--
-- The Edit Course "Funding and Grant" section becomes six checkboxes
-- (WSQ/CASL, MCES/SME, SFEC, UTAP, PSEA, Absentee Payroll) that read/write
-- the funding badge TAGS, and the storefront WSQ Funding card now renders
-- canonical per-scheme copy from those same tags
-- (MMD_CourseImage_Helper_Data::getWsqFundingNarrativeHtml) instead of the
-- per-course `funding_and_grant` cms/block. So the tags must first be brought
-- in line with today's card, or the switchover would visibly change courses:
--
--   1. UTAP — the card shows UTAP when the block contains a UTAP section
--      (271 courses), but only 3 carry the UTAP tag. Seed the tag from the
--      block content so those courses keep their UTAP card.
--      (Courses without UTAP in the block correctly stay untagged — the 27
--      known non-UTAP courses keep hiding it, matching today.)
--   2. SFEC — the 7 IBF courses (block contains the IBF-STS section instead
--      of SFEC) have never rendered an SFEC section, but they DO carry the
--      SFEC tag. Remove it so the canonical builder doesn't add a section
--      those courses never showed. (Their empty-bodied "IBF-STS" pill —
--      stripped fee table — disappears with the switchover; a known fix.)
--
-- All other schemes already agree: WSQ∪CASL = 299/299, MCES = 299/299,
-- PSEA = 299/299 (migration 655), SkillsFuture Credit untouched (no
-- checkbox; the SFC section renders on every funded course).
--
-- Partner safety: keyed off TGS- SKUs and `course_TGS-%` cms blocks —
-- neither exists on MY/GH, so this is a no-op there. Idempotent via
-- NOT EXISTS / content-conditioned DELETE; summary rebuild is
-- delete-then-recompute (matches migrations 174/655).

-- ── Ensure the UTAP tag exists (approved) ───────────────────────────────
INSERT INTO tag (name, status, first_store_id)
SELECT 'UTAP', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'UTAP');

-- ── 1. Seed UTAP tag from the funding block content ─────────────────────
INSERT INTO tag_relation (tag_id, customer_id, product_id, store_id, active, created_at)
SELECT (SELECT tag_id FROM tag WHERE name = 'UTAP' LIMIT 1),
       NULL, cpe.entity_id, 1, 1, NOW()
FROM catalog_product_entity cpe
JOIN cms_block cb
  ON cb.identifier = CONCAT('course_', cpe.sku, '_funding_and_grant')
WHERE cpe.sku LIKE 'TGS-%'
  AND cb.content LIKE '%UTAP%'
  AND NOT EXISTS (
      SELECT 1 FROM tag_relation tr
      WHERE tr.tag_id = (SELECT tag_id FROM tag WHERE name = 'UTAP' LIMIT 1)
        AND tr.product_id = cpe.entity_id
        AND tr.store_id = 1
        AND tr.customer_id IS NULL
  );

-- ── 2. Remove SFEC tag from the 7 IBF-STS courses ───────────────────────
DELETE tr FROM tag_relation tr
JOIN catalog_product_entity cpe ON cpe.entity_id = tr.product_id
JOIN cms_block cb
  ON cb.identifier = CONCAT('course_', cpe.sku, '_funding_and_grant')
WHERE tr.tag_id = (SELECT tag_id FROM tag WHERE name = 'SFEC' LIMIT 1)
  AND cpe.sku LIKE 'TGS-%'
  AND cb.content LIKE '%IBF-STS%'
  AND cb.content NOT LIKE '%(SFEC)%';

-- ── Rebuild tag_summary for UTAP + SFEC ─────────────────────────────────
DELETE FROM tag_summary
WHERE tag_id IN (SELECT tag_id FROM tag WHERE name IN ('UTAP', 'SFEC'));

INSERT INTO tag_summary (tag_id, store_id, customers, products, uses, historical_uses, popularity, base_popularity)
SELECT tr.tag_id, tr.store_id, 0,
       COUNT(DISTINCT tr.product_id), 0, 0, 0, 0
FROM tag_relation tr
JOIN tag t ON t.tag_id = tr.tag_id
WHERE t.name IN ('UTAP', 'SFEC')
GROUP BY tr.tag_id, tr.store_id;

INSERT INTO tag_summary (tag_id, store_id, customers, products, uses, historical_uses, popularity, base_popularity)
SELECT tr.tag_id, 0, 0,
       COUNT(DISTINCT tr.product_id), 0, 0, 0, 0
FROM tag_relation tr
JOIN tag t ON t.tag_id = tr.tag_id
WHERE t.name IN ('UTAP', 'SFEC')
GROUP BY tr.tag_id;
