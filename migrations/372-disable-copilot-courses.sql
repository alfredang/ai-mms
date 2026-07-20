-- Disable retired courses (status = 2 / Disabled, all store scopes):
--   C897  - Creative Design with Generative AI (GenAI) in Photoshop and Firefly
--   C1194 - MS-4004 Empower Your Workforce with Microsoft 365 Copilot Use Cases
--   C856  - MS-4005 Craft Effective Prompts for Microsoft 365 Copilot
--   C998  - MS-4007 Microsoft 365 Copilot User Enablement Specialist
--   C429  - (was converted in 370; user then asked to disable it — disable wins)
-- Applies on all sites. Idempotent. Reindex + cache flush after deploy.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku IN ('C897', 'C1194', 'C856', 'C998', 'C429', 'C714', 'C694')
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku IN ('C897', 'C1194', 'C856', 'C998', 'C429', 'C714', 'C694');
