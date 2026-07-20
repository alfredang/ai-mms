-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C591 - SC-300 Microsoft Certified Identity and Access Administrator Associate Training
--   C605 - Basic Semiconductor Devices Course
--   C622 - Data Visualisation with Google Looker Studio
--   C629 - Enterprise Local Area Network (LAN) Essentials Training
--   C630 - Building a Scalable Virtual Private Network (VPN)
--   C631 - Neo4j Certified Professional Training
--   C636 - PL-7003 Create and manage model-driven apps with Power Apps and Dataverse
--   C665 - MB-910 Microsoft Dynamics 365 Fundamentals (CRM) Training
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.
SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C591','C605','C622','C629','C630','C631','C636','C665')
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_int i JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2 WHERE i.attribute_id = @status_attr AND e.sku IN ('C591','C605','C622','C629','C630','C631','C636','C665');
