-- Disable retired big-data courses (status = 2 / Disabled, all store scopes):
--   C363 - Apache Spark Essential Training
--   C457 - Elasticsearch Essential Training with Kibana
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C363', 'C457')
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku IN ('C363', 'C457');
