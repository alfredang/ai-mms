-- 783: Add WSQ - AI Vibe Coding with Python to the SG homepage
-- "Popular WSQ and SkillsFuture Courses" pool as the ninth curated course.
-- The live admin confirms this pool is Popular Courses (category ID 16).
-- Idempotent.

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT 16, p.entity_id, 9
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2019504591'
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_category_product cp
    WHERE cp.category_id = 16
      AND cp.product_id = p.entity_id
  );

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT
  16,
  p.entity_id,
  9,
  1,
  1,
  COALESCE(store_visibility.value, default_visibility.value)
FROM catalog_product_entity p
JOIN catalog_product_entity_int default_visibility
  ON default_visibility.entity_id = p.entity_id
 AND default_visibility.store_id = 0
 AND default_visibility.attribute_id = (
   SELECT attribute_id
   FROM eav_attribute
   WHERE entity_type_id = 4
     AND attribute_code = 'visibility'
   LIMIT 1
 )
LEFT JOIN catalog_product_entity_int store_visibility
  ON store_visibility.entity_id = p.entity_id
 AND store_visibility.store_id = 1
 AND store_visibility.attribute_id = default_visibility.attribute_id
WHERE p.sku = 'TGS-2019504591'
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_category_product_index i
    WHERE i.category_id = 16
      AND i.product_id = p.entity_id
      AND i.store_id = 1
  );
