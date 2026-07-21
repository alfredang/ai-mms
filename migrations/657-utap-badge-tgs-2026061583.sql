-- Seed the UTAP funding badge for TGS-2026061583 (WSQ - Information Security
-- Management & Compliance Frameworks).
--
-- Requested 2026-07-22: the course cover shows the UTAP pill but the Magento
-- tag was never written, so the storefront UTAP chip and the UTAP funding
-- card (badge-driven fallback in view.phtml) were missing.
--
-- Partner-safe: every statement is keyed on the TGS- SKU existing, which is
-- true only on SG — MY/GH match zero rows and create nothing. Idempotent.
-- The tag_summary indexer must run after apply for the chip to show.

-- Canonical UTAP tag row (only created where the course exists).
INSERT INTO tag (name, status, first_store_id)
SELECT 'UTAP', 1, 1
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2026061583'
  AND NOT EXISTS (SELECT 1 FROM tag t WHERE t.name = 'UTAP');

-- Relation: UTAP → the course.
INSERT INTO tag_relation (tag_id, customer_id, product_id, store_id, active, created_at)
SELECT t.tag_id, NULL, p.entity_id, 1, 1, NOW()
FROM tag t
JOIN catalog_product_entity p ON p.sku = 'TGS-2026061583'
WHERE t.name = 'UTAP'
  AND NOT EXISTS (
    SELECT 1 FROM tag_relation r
    WHERE r.tag_id = t.tag_id AND r.product_id = p.entity_id AND r.store_id = 1
  );
