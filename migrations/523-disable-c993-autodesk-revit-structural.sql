-- Disable retired course (set status = 2 / Disabled):
--   C993 - Autodesk Revit Structural Training
--
-- Sets the default-scope (store_id 0) status to Disabled and flips any
-- per-store override rows to Disabled too, so the product drops off the
-- storefront on every store. Idempotent. A catalog reindex + cache flush
-- after deploy makes the change visible on the storefront.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

-- Default scope: ensure a store_id 0 row exists and is Disabled.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE e.sku = 'C993'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flip any per-store override rows to Disabled as well (an override left at
-- Enabled keeps the course live on that store even when store_id 0 is Disabled).
UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku = 'C993';
