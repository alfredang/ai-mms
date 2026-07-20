-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C405  - PL-200 Microsoft Power Platform Functional Consultant Training
--   C1245 - 5 Days Digital Marketing Specialization
--   C1246 - 5 Days Web Development Specialization
--   C1256 - Professional Networking and Lead Generation on LinkedIn
--   C1288 - 5 Days Excel Specialization
--   C1294 - Microsoft OneDrive Training
--   C1304 - Basic Excel Training
--   C1306 - Building Information Modeling (BIM) with Revit
--   C1388 - MS-600 Microsoft 365 Certified Teams Application Developer Associate Training
--   C1389 - DP-300 Azure Database Administrator Associate
--   C1402 - AZ-400 Designing and Implementing Microsoft DevOps Solutions Training
--   C1404 - AZ-700 Azure Network Engineer Associate Training
--   C1406 - AZ-305 Azure Solutions Architect Expert Training
--   C1745 - AZ-120 Microsoft Certified Azure for SAP Workloads Specialty
--   C1747 - AZ-140 Microsoft Certified Azure Virtual Desktop Specialty
--   C1235 - Building Mobile UI with Flutter (stored SKU has a leading space -> matched via TRIM)
-- (M1411 / TGS-2024042588 share the PL-200 name but are partner/WSQ SKUs — untouched.)
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.
SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE TRIM(e.sku) IN ('C405','C1235','C1245','C1246','C1256','C1288','C1294','C1304','C1306','C1388','C1389','C1402','C1404','C1406','C1745','C1747')
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_int i JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2 WHERE i.attribute_id = @status_attr AND TRIM(e.sku) IN ('C405','C1235','C1245','C1246','C1256','C1288','C1294','C1304','C1306','C1388','C1389','C1402','C1404','C1406','C1745','C1747');
