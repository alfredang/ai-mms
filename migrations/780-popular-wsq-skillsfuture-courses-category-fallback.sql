-- 780: Apply the curated Popular Courses pool using the category's canonical
-- EAV name, without depending on the Singapore store code/root relationship.
--
-- Migration 779 intentionally guarded the replacement and remained a no-op on
-- production because its store-root category lookup did not resolve there.
-- The admin readback confirms that the homepage category is "Popular Courses"
-- (ID 16). Resolve that exact EAV name across scopes, preferring the confirmed
-- entity when present, and retain the all-eight-products safety guard.
-- Idempotent.

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
  WHERE v.value = 'Popular Courses'
  GROUP BY c.entity_id
  ORDER BY (c.entity_id = 16) DESC, c.entity_id ASC
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

-- Refresh the SG storefront index rows immediately. The SG storefront is
-- store_id 1 throughout this installation; visibility follows its scoped EAV
-- value with the default scope as fallback.
INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT
  cp.category_id,
  cp.product_id,
  cp.position,
  1,
  1,
  COALESCE(store_visibility.value, default_visibility.value)
FROM catalog_category_product cp
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
 AND store_visibility.store_id = 1
 AND store_visibility.attribute_id = default_visibility.attribute_id
WHERE cp.category_id = @popular_category
  AND @popular_target_count = 8;
