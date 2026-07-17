-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C1174 - ISO 37001 Anti-Bribery Management System
--   C1202 - 4 Days Container Specialization
--   C1218 - BIM for Construction Management and Planning with Revit and Navisworks
--   C1223 - Applying 5S Techniques
--   C1252 - 3 Days Wordpress CMS Specialization
-- (M1179 shares the ISO 37001 name but is a partner-prefix SKU — intentionally untouched.)
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.
SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C1174','C1202','C1218','C1223','C1252')
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_int i JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2 WHERE i.attribute_id = @status_attr AND e.sku IN ('C1174','C1202','C1218','C1223','C1252');
