-- 781: Force the owner-curated SG homepage Popular Courses membership.
--
-- Live admin readback identifies the homepage category as:
--   Popular Courses (ID: 16)
-- and live product-page readback confirms each of the eight supplied SKUs.
-- Earlier defensive lookup/count guards left the production membership
-- untouched, so use the confirmed category identifier and SKU business keys
-- directly. The statements are idempotent.

DELETE FROM catalog_category_product
WHERE category_id = 16;

DELETE FROM catalog_category_product_index
WHERE category_id = 16;

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT
  16,
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
WHERE p.sku IN (
  'TGS-2023035977',
  'TGS-2025052468',
  'TGS-2019503161',
  'TGS-2024043855',
  'TGS-2020505790',
  'TGS-2022017524',
  'TGS-2022015374',
  'TGS-2020504020'
);

-- Mirror the direct assignments into the SG storefront index immediately.
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
WHERE cp.category_id = 16;
