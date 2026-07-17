-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C835 - ISO 14001:2015 EMS Internal Auditor Training
--   C851 - Data Visualisation with Python Training
--   C876 - Google Cloud Certified Professional Cloud Security Engineer Training
--   C895 - ISO/IEC 20000-1:2018. Service Management System
--   C902 - Creating Dynamic eLearning Content with iSpring Suite
--   C905 - Basic Flutter Training
--   C906 - Google Classroom LMS Training
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.
SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C835','C851','C876','C895','C902','C905','C906')
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_int i JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2 WHERE i.attribute_id = @status_attr AND e.sku IN ('C835','C851','C876','C895','C902','C905','C906');
