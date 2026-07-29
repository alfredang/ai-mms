-- Disable retired AI Vibe Coding courses (set status = 2 / Disabled):
--   C205  - AI Vibe Coding for C#
--   C435  - AI Vibe Coding for Augmented Reality (AR)
--   C789  - AI Vibe Coding for Blockchain
--   C1310 - AI Vibe Coding for .NET
--
-- C435 was appended to already-applied migration 350 after it had run, so the
-- edit never executed on prod (edited migrations never re-run) — this NEW
-- migration ships the disable for real, together with the other three.
--
-- Sets the default-scope (store_id 0) status to Disabled and flips any
-- per-store override rows to Disabled too. Idempotent. A catalog reindex +
-- cache flush after deploy makes the change visible on the storefront.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

-- Default scope: ensure a store_id 0 row exists and is Disabled.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE e.sku IN ('C205', 'C435', 'C789', 'C1310')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flip any per-store override rows to Disabled as well (an Enabled override
-- keeps the course live on that store even when store_id 0 is Disabled).
UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku IN ('C205', 'C435', 'C789', 'C1310');
