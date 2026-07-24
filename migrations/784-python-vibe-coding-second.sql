-- 784: Place WSQ - AI Vibe Coding with Python (TGS-2019504591)
-- second in the Python category, immediately after
-- WSQ - Python Fundamental Course for Beginners (TGS-2019503161).
--
-- The daily category-ordering sweep preserves the relative order of TGS-
-- products, so positions 0 and 1 remain first and second after renumbering.
-- Category and products are resolved by business keys. Idempotent.

SET @python_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'python-programming'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2019503161' THEN 0
  WHEN 'TGS-2019504591' THEN 1
END
WHERE cp.category_id = @python_category
  AND p.sku IN ('TGS-2019503161', 'TGS-2019504591');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2019503161' THEN 0
  WHEN 'TGS-2019504591' THEN 1
END
WHERE i.category_id = @python_category
  AND p.sku IN ('TGS-2019503161', 'TGS-2019504591');
