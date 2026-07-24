-- 782: Normalise the hidden trailing tab in the GenAI video course SKU and
-- complete the eight-course Popular Courses homepage pool.
--
-- Live admin readback showed product 1180 as "TGS-2024043855<TAB>". The
-- storefront visually rendered the expected code, but exact SKU matching in
-- migration 781 correctly returned only seven products. Resolve the product by
-- its whitespace-normalised SKU, store the canonical code, and add it to the
-- confirmed Popular Courses category (ID 16). Idempotent.

UPDATE catalog_product_entity
SET sku = 'TGS-2024043855'
WHERE TRIM(REPLACE(sku, CHAR(9), '')) = 'TGS-2024043855'
  AND sku <> 'TGS-2024043855';

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT 16, p.entity_id, 4
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2024043855'
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
  4,
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
WHERE p.sku = 'TGS-2024043855'
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_category_product_index i
    WHERE i.category_id = 16
      AND i.product_id = p.entity_id
      AND i.store_id = 1
  );
