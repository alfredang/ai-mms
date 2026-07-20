-- Ensure EVERY AI Vibe Coding course is listed in the "AI Vibe Coding Series"
-- category. Data-driven: assigns any product carrying the badge
-- course_series_badge = 'AI Vibe Coding Series' to that category. Self-
-- maintaining (picks up C143, C1154 and any future badged course). Category
-- resolved by NAME so it is partner-safe (id differs per site). Store scope 0.
-- Idempotent (INSERT IGNORE). No content line ends in a semicolon.

SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT cat.entity_id, ev.entity_id, 0
FROM catalog_product_entity_varchar ev
JOIN catalog_category_entity_varchar cat
  ON cat.store_id = 0
JOIN eav_attribute ca
  ON ca.attribute_id = cat.attribute_id AND ca.entity_type_id = 3 AND ca.attribute_code = 'name'
WHERE ev.store_id = 0
  AND ev.attribute_id = @a_badge
  AND ev.value = 'AI Vibe Coding Series'
  AND cat.value = 'AI Vibe Coding Series';
