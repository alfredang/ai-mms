-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C749 - ISO 45001:2018 Occupational Health & Safety Management System
--   C750 - ISO 27001 Information Security Management System
--   C751 - ISO 50001:2018 Energy Management System
--   C774 - Autodesk Certified Professional (ACP) for Inventor Mechanical Design Training
--   C775 - UX/UI Design with Figma
--   C778 - PL-7004 Implement AI models with Microsoft Power Platform AI Builder
--   C785 - Fundamentals of ISO 50001:2018 Energy Management System
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.
SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C749','C750','C751','C774','C775','C778','C785')
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_int i JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2 WHERE i.attribute_id = @status_attr AND e.sku IN ('C749','C750','C751','C774','C775','C778','C785');
