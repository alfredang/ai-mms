-- 1032: Pin the requested first two courses in the Tableau category
--   (/tableau-software-courses.html):
--   1. TGS-2020503177 — WSQ Data Visualisation with Tableau
--   2. TGS-2020505550 — WSQ Data Storytelling with Tableau
--
-- Negative positions keep these rows ahead of every unpinned course.
-- The daily category-ordering sweep preserves TGS relative order and
-- renumbers them to normal positive positions. Category/products use
-- business-key lookups. Idempotent.

SET @tableau_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'tableau-software-courses'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2020503177' THEN -2
  WHEN 'TGS-2020505550' THEN -1
END
WHERE cp.category_id = @tableau_category
  AND p.sku IN (
    'TGS-2020503177',
    'TGS-2020505550'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2020503177' THEN -2
  WHEN 'TGS-2020505550' THEN -1
END
WHERE i.category_id = @tableau_category
  AND p.sku IN (
    'TGS-2020503177',
    'TGS-2020505550'
  );
