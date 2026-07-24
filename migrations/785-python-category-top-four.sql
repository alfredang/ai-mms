-- 785: Pin the requested top four courses in the Python category:
--   1. TGS-2019503161 — WSQ Python Fundamental Course for Beginners
--   2. TGS-2019504591 — WSQ AI Vibe Coding with Python
--   3. TGS-2025052659 — IBF AI Assisted Python Programming for Finance
--   4. TGS-2020503487 — WSQ AI Vibe Coding with PyTorch
--
-- Negative positions keep the four rows ahead of every unpinned course.
-- The daily category-ordering sweep preserves TGS relative order and
-- renumbers them to normal positive positions. Category/products use
-- business-key lookups. Idempotent.

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
  WHEN 'TGS-2019503161' THEN -4
  WHEN 'TGS-2019504591' THEN -3
  WHEN 'TGS-2025052659' THEN -2
  WHEN 'TGS-2020503487' THEN -1
END
WHERE cp.category_id = @python_category
  AND p.sku IN (
    'TGS-2019503161',
    'TGS-2019504591',
    'TGS-2025052659',
    'TGS-2020503487'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2019503161' THEN -4
  WHEN 'TGS-2019504591' THEN -3
  WHEN 'TGS-2025052659' THEN -2
  WHEN 'TGS-2020503487' THEN -1
END
WHERE i.category_id = @python_category
  AND p.sku IN (
    'TGS-2019503161',
    'TGS-2019504591',
    'TGS-2025052659',
    'TGS-2020503487'
  );
