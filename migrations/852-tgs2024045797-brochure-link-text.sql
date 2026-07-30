-- 852: Follow-up to 851 — the brochure anchor text inside TGS-2024045797's
-- short_description tail still carried the old long course name.
--
-- 851 spliced the tail byte-identically (by design, to protect the WSQ Funding
-- table and the SkillsFuture deep links), which also preserved the stale anchor
-- label "WSQ - Project Management Professional (PMP) 35 PDU Training Brochure".
-- The Google Drive URL is unchanged — the PDF file itself is the same asset.
--
-- Shipped as a NEW file rather than an edit to 851: 851 is already in the
-- schema_migrations ledger, and an edited migration never re-runs on prod.
--
-- Partner-safe: guarded on @e (TGS- SKUs are SG-only) and idempotent (REPLACE
-- on an already-updated string is a no-op).

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045797' LIMIT 1);
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'WSQ - Project Management Professional (PMP) 35 PDU Training Brochure',
      'WSQ - Project Management Professional Brochure')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_sd;
