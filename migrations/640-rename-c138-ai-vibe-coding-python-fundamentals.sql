-- Rename C138 "AI Vibe Coding with Python" -> "AI Vibe Coding with Python
-- Fundamentals". Updates name, meta_title, the overview sentence that echoes
-- the course name, and the cover image (re-rendered from the new name on R2).
-- url_key is intentionally unchanged. All statements key off the SKU / echo
-- the exact old phrase, so they no-op where absent. Idempotent.
-- apply.php note: no content line ends in a semicolon.

SET @attr_name             := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @attr_meta_title       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @attr_course_image_url := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_name, 0, e.entity_id, 'AI Vibe Coding with Python Fundamentals'
FROM catalog_product_entity e WHERE e.sku = 'C138'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_meta_title, 0, e.entity_id, 'AI Vibe Coding with Python Fundamentals | Tertiary Courses Singapore'
FROM catalog_product_entity e WHERE e.sku = 'C138'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Overview opening sentence echoes the old name — update it to match.
UPDATE catalog_product_entity_text t
JOIN catalog_product_entity e ON e.entity_id = t.entity_id
SET t.value = REPLACE(t.value, 'AI Vibe Coding with Python.', 'AI Vibe Coding with Python Fundamentals.')
WHERE t.attribute_id = @attr_short_description AND e.sku = 'C138'
  AND t.value NOT LIKE '%AI Vibe Coding with Python Fundamentals.%';

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_course_image_url, 0, e.entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C138-20260721-115818.png'
FROM catalog_product_entity e WHERE e.sku = 'C138'
ON DUPLICATE KEY UPDATE value = VALUES(value);
