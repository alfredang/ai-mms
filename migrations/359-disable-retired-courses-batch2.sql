-- Disable a second batch of retired courses (status = 2 / Disabled):
--   C1354 - C# Programming Fundamentals for Beginners
--   C1170 - Laravel Essential Training
--   C024  - MySQL Essential Training
--   C475  - Natural Language Processing with Python NLTK Training
--   C179  - Python Django Web Development Essential Training
--   C917  - NoSQL Essential Training
--   C918  - MongoDB Essential Training
--   C808  - Text Mining with Orange
--   C545  - Predictive Analytics with Orange
--   C1809 - Pearson Vue Certified IT Specialist Java
--   C1812 - Pearson Vue Certified IT Specialist Python
--   C1200 - 5 Days Python Programming Specialization
--   C213  - Build Web Apps with ASP.NET Core and C#
--
-- Sets store_id 0 to Disabled AND flips every per-store override to Disabled
-- (a per-store status left Enabled keeps the course live on that store). Applies
-- on all sites. Idempotent. Reindex + cache flush after deploy to drop them
-- from the storefront.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE e.sku IN ('C1354', 'C1170', 'C024', 'C475', 'C179', 'C917', 'C918', 'C808', 'C545', 'C1809', 'C1812', 'C1200', 'C213')
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku IN ('C1354', 'C1170', 'C024', 'C475', 'C179', 'C917', 'C918', 'C808', 'C545', 'C1809', 'C1812', 'C1200', 'C213');
