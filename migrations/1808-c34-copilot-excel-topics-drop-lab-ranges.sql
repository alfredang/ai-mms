-- C34 Microsoft 365 Copilot for Excel: drop the "(Labs 1-3)" / "(Labs 4-6)" / "(Labs 7-8)" suffixes
-- from the three course-outline topics (LSN_DATA JSON + rendered <p> list in `description`).
-- Topic titles otherwise unchanged. short_description is not touched.
--
-- SG-only (store guard). Idempotent: only rewrites a description that still carries "(Labs ".
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C34' LIMIT 1);
SET @attr := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = 4);

UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<!-- LSN_DATA: [{"title":"Topic 1: Excel Fundamentals with Copilot","subsecs":[]},',
     '{"title":"Topic 2: Skills and Rules","subsecs":[]},',
     '{"title":"Topic 3: Interactive Dashboards with Copilot, Skills and Rules","subsecs":[]}] -->\n',
     '<p><strong>Topic 1: Excel Fundamentals with Copilot</strong></p>\n',
     '<p><strong>Topic 2: Skills and Rules</strong></p>\n',
     '<p><strong>Topic 3: Interactive Dashboards with Copilot, Skills and Rules</strong></p>\n')
 WHERE @sg = 1
   AND entity_id = @pid
   AND attribute_id = @attr
   AND value LIKE '%Excel Fundamentals with Copilot (Labs %';
