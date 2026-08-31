-- 1298: Set the catalog banner image on the "WSQ AI Agents Courses" category
-- (url_key wsq-ai-agents-courses, created by 1293).
--
-- The image value is the bare filename (stock category image attribute); on SG
-- the MMD_CourseImage getImageUrl() rewrite serves it from R2
-- (catalog/category/wsq-ai-agents-courses.jpg, uploaded + verified 200), and
-- the media/.htaccess 302 fallback covers instances without R2_PUBLIC_URL.
-- Category resolved by url_key so this no-ops if the category is absent.
-- Idempotent (INSERT ... ON DUPLICATE KEY UPDATE at store 0).

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'wsq-ai-agents-courses' LIMIT 1);

SET @cat_image := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'image');

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @cat_image, 0, @cat, 'wsq-ai-agents-courses.jpg'
FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
