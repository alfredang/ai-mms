-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C472 - SC-900 Microsoft Security, Compliance, and Identity Fundamentals Training
--   C482 - SC-400 Microsoft Certified Information Protection and Compliance Administrator Associate Training
--   C487 - 5 Days Blockchain Specialization
--   C488 - DP-604T00 Implement a data science and machine learning solution with Microsoft Fabric
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.
SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C472','C482','C487','C488')
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_int i JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2 WHERE i.attribute_id = @status_attr AND e.sku IN ('C472','C482','C487','C488');
