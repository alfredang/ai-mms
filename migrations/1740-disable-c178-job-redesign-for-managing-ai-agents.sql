-- Disable retired course (status = 2 / Disabled), SG only:
--   C178 - Job Redesign for Managing AI Agents
--
-- Already applied live via /agent/api_ops op=disable (audit_id 57); this keeps a
-- rebuilt DB in the same state. Same pattern as 842. Idempotent; no-op off SG.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id=1 AND code='singapore');
SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE @sg=1 AND TRIM(e.sku)='C178'
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE @sg=1 AND i.attribute_id = @status_attr AND TRIM(e.sku)='C178';
