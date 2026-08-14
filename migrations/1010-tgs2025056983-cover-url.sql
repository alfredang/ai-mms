-- 1010: Point TGS-2025056983 at the cover PNG re-rendered for its new title
-- ("WSQ - Generative AI for Script Development and Storytelling", migration 1009).
-- The old cover baked the retired "Storytelling and Storyboarding" title.
-- Partner-safe: @e is NULL on MY/GH, so the statements no-op there.

SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025056983');
SET @a  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @url := 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025056983-20260814-132531.png';

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a, 0, @e, @url FROM DUAL WHERE @e IS NOT NULL AND @a IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a AND store_id <> 0 AND @e IS NOT NULL;
