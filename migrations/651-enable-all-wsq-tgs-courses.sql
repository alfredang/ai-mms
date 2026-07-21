-- Enable ALL WSQ courses (TGS- SKU prefix): set status = 1 / Enabled.
--
-- Requested 2026-07-22: WSQ courses must always be enabled. Currently only
-- TGS-2026061583 (WSQ - Information Security Management & Compliance
-- Frameworks) is Disabled at default scope, but this flips every TGS- course
-- so any other disabled row is corrected too.
--
-- Sets the default-scope (store_id 0) status to Enabled and flips any
-- per-store override rows to Enabled as well. Idempotent. Partner-safe:
-- TGS- SKUs exist only on SG, so this matches zero rows on MY/GH.
-- A catalog reindex (incl. stock + price) + cache flush after deploy makes
-- re-enabled courses visible in category listings again.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

-- Default scope: ensure a store_id 0 row exists and is Enabled.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 1
FROM catalog_product_entity e
WHERE e.sku LIKE 'TGS-%'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flip any per-store override rows to Enabled as well (a per-store status
-- override left at Disabled keeps the course hidden on that store even when
-- store_id 0 is Enabled).
UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 1
WHERE i.attribute_id = @status_attr AND e.sku LIKE 'TGS-%';
