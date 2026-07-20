-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C217 - SC-5002 Secure Azure Services and Workloads with Microsoft Defender for Cloud
--   C164 - SC-5003 Implement Information Protection and Data Loss Prevention with Microsoft Purview
--   C825 - Safeguarding Against Online and Phone Scams
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C217', 'C164', 'C825')
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku IN ('C217', 'C164', 'C825');
