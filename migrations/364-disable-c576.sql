-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C576  - Vibe Coding for Algorithmic Trading and Value Investment
--   C1196 - Days Data Analytics with R Specialization
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C576', 'C1196')
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku IN ('C576', 'C1196');
