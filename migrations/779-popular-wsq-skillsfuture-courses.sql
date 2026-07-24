-- 779: Replace the SG homepage "Popular WSQ and SkillsFuture Courses" pool.
--
-- The homepage carousel reads the "Popular Courses" category. Its membership
-- must contain exactly the eight owner-curated WSQ courses below; no legacy
-- products should remain eligible for the randomised carousel.
--
-- Partner-safe: resolve the Singapore root/category by business keys instead
-- of fixed category IDs. The replacement runs only when all eight SKUs exist,
-- preventing a partial list if a catalogue is incomplete. Idempotent.

SET @sg_root := (
  SELECT g.root_category_id
  FROM core_store s
  JOIN core_store_group g ON g.group_id = s.group_id
  WHERE s.code = 'singapore'
  LIMIT 1
);

SET @category_name_attr := (
  SELECT attribute_id
  FROM eav_attribute
  WHERE entity_type_id = 3
    AND attribute_code = 'name'
  LIMIT 1
);

SET @popular_category := (
  SELECT c.entity_id
  FROM catalog_category_entity c
  JOIN catalog_category_entity_varchar v
    ON v.entity_id = c.entity_id
   AND v.attribute_id = @category_name_attr
   AND v.store_id = 0
  WHERE c.parent_id = @sg_root
    AND v.value = 'Popular Courses'
  LIMIT 1
);

SET @popular_target_count := (
  SELECT COUNT(*)
  FROM catalog_product_entity
  WHERE sku IN (
    'TGS-2023035977',
    'TGS-2025052468',
    'TGS-2019503161',
    'TGS-2024043855',
    'TGS-2020505790',
    'TGS-2022017524',
    'TGS-2022015374',
    'TGS-2020504020'
  )
);

DELETE FROM catalog_category_product
WHERE category_id = @popular_category
  AND @popular_target_count = 8;

DELETE FROM catalog_category_product_index
WHERE category_id = @popular_category
  AND @popular_target_count = 8;

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT
  @popular_category,
  p.entity_id,
  CASE p.sku
    WHEN 'TGS-2023035977' THEN 1
    WHEN 'TGS-2025052468' THEN 2
    WHEN 'TGS-2019503161' THEN 3
    WHEN 'TGS-2024043855' THEN 4
    WHEN 'TGS-2020505790' THEN 5
    WHEN 'TGS-2022017524' THEN 6
    WHEN 'TGS-2022015374' THEN 7
    WHEN 'TGS-2020504020' THEN 8
  END
FROM catalog_product_entity p
WHERE @popular_category IS NOT NULL
  AND @popular_target_count = 8
  AND p.sku IN (
    'TGS-2023035977',
    'TGS-2025052468',
    'TGS-2019503161',
    'TGS-2024043855',
    'TGS-2020505790',
    'TGS-2022017524',
    'TGS-2022015374',
    'TGS-2020504020'
  );

-- Mirror the SG storefront rows so the homepage reflects the curated list
-- immediately, without waiting for the next full category-product reindex.
INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT
  cp.category_id,
  cp.product_id,
  cp.position,
  1,
  s.store_id,
  COALESCE(store_visibility.value, default_visibility.value)
FROM catalog_category_product cp
JOIN core_store s
  ON s.code = 'singapore'
JOIN catalog_product_entity_int default_visibility
  ON default_visibility.entity_id = cp.product_id
 AND default_visibility.store_id = 0
 AND default_visibility.attribute_id = (
   SELECT attribute_id
   FROM eav_attribute
   WHERE entity_type_id = 4
     AND attribute_code = 'visibility'
   LIMIT 1
 )
LEFT JOIN catalog_product_entity_int store_visibility
  ON store_visibility.entity_id = cp.product_id
 AND store_visibility.store_id = s.store_id
 AND store_visibility.attribute_id = default_visibility.attribute_id
WHERE cp.category_id = @popular_category
  AND @popular_target_count = 8;
