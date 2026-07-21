-- Ensure every WSQ course (SKU LIKE 'TGS-%') carries the PSEA funding badge
-- on the Singapore storefront.
--
-- Why: the storefront funding chips read Magento tag relations
-- (MMD_CourseImage_Helper_Data::getProductBadges). Migration 174 mirrored
-- PSEA onto every WSQ-tagged course at the time it ran, but any TGS- course
-- added since — or any that lacked the WSQ tag — never got PSEA, so its
-- product page shows the other funding badges but not PSEA.
--
-- Fix: key off the SKU prefix (the canonical "this is a WSQ course" signal in
-- this repo) rather than the WSQ tag, so the backfill is complete regardless
-- of tag-relation drift. Idempotent via a NOT EXISTS guard; re-runs are no-ops.
--
-- Country safety: PSEA is a Singapore-only scheme (store_id = 1). TGS- SKUs
-- only exist on the SG catalog, so on a partner server (MY/GH) the INSERT
-- selects zero rows — nothing to guard beyond the SKU filter. The tag seed
-- guard below makes the file portable to any DB where PSEA was never seeded.

-- ── Ensure the PSEA tag exists (approved) ───────────────────────────────
INSERT INTO tag (name, status, first_store_id)
SELECT 'PSEA', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'PSEA');

-- ── Attach PSEA to every TGS- course on the SG store, if missing ────────
INSERT INTO tag_relation (tag_id, customer_id, product_id, store_id, active, created_at)
SELECT (SELECT tag_id FROM tag WHERE name = 'PSEA' LIMIT 1),
       NULL, cpe.entity_id, 1, 1, NOW()
FROM catalog_product_entity cpe
WHERE cpe.sku LIKE 'TGS-%'
  AND NOT EXISTS (
      SELECT 1 FROM tag_relation tr
      WHERE tr.tag_id = (SELECT tag_id FROM tag WHERE name = 'PSEA' LIMIT 1)
        AND tr.product_id = cpe.entity_id
        AND tr.store_id = 1
        AND tr.customer_id IS NULL
  );

-- ── Rebuild tag_summary for PSEA so the admin Funding Tags grid counts ──
-- stay accurate. Per-store rows plus the store_id = 0 admin roll-up, matching
-- the decomposition Magento's stock aggregator (and migration 174) produce.
DELETE FROM tag_summary
WHERE tag_id = (SELECT tag_id FROM tag WHERE name = 'PSEA' LIMIT 1);

INSERT INTO tag_summary (tag_id, store_id, customers, products, uses, historical_uses, popularity, base_popularity)
SELECT tr.tag_id, tr.store_id, 0,
       COUNT(DISTINCT tr.product_id), 0, 0, 0, 0
FROM tag_relation tr
JOIN tag t ON t.tag_id = tr.tag_id
WHERE t.name = 'PSEA'
GROUP BY tr.tag_id, tr.store_id;

INSERT INTO tag_summary (tag_id, store_id, customers, products, uses, historical_uses, popularity, base_popularity)
SELECT tr.tag_id, 0, 0,
       COUNT(DISTINCT tr.product_id), 0, 0, 0, 0
FROM tag_relation tr
JOIN tag t ON t.tag_id = tr.tag_id
WHERE t.name = 'PSEA'
GROUP BY tr.tag_id;
