-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C511  - Google Cloud Certified Professional Data Engineer Training
--   C992  - Autodesk Revit Training for MEP
--   C1163 - ISO 22301 Business Continuity Management System
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.
SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C511','C992','C1163')
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_int i JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2 WHERE i.attribute_id = @status_attr AND e.sku IN ('C511','C992','C1163');
