-- Disable a fifth batch of retired courses (status = 2 / Disabled, all scopes):
--   C782  - Automate Business Workflows with Flowise Agentic AI
--   C1242 - 3 Days Arduino Specialization
--   C1312 - DP-602T00 Implement a Data Warehouse with Microsoft Fabric
--   C234  - DP-603T00 Implement a Real-Time Intelligence solution with Microsoft Fabric
--   C577  - Text Mining with R
--   C925  - Full Machine Learning with R
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C782', 'C1242', 'C1312', 'C234', 'C577', 'C925')
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku IN ('C782', 'C1242', 'C1312', 'C234', 'C577', 'C925');
