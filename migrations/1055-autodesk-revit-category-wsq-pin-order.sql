-- 1055: Pin the requested WSQ order in the Autodesk Revit category
-- (url_key autodesk-revit-trainings):
--   1. TGS-2021004287 — WSQ Architecture Drawing with Revit
--   2. TGS-2022015370 — WSQ Application of BIM using Revit
--   3. TGS-2023037587 — WSQ Autodesk Certified Professional (ACP) for Revit Architectural Design
--   4. TGS-2023036661 — WSQ Autodesk Certified Professional (ACP) for Revit Mechanical Design
--   5. TGS-2023039179 — WSQ Autodesk Certified Professional (ACP) for Revit Structural Design
-- Non-WSQ courses (C508 Masterclass) follow alphabetically as usual.
--
-- Negative positions keep these rows ahead of every unpinned course.
-- The daily category-ordering sweep preserves TGS relative order and
-- renumbers them to normal positive positions. Category/products use
-- business-key lookups. Idempotent.

SET @revit_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'autodesk-revit-trainings'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2021004287' THEN -5
  WHEN 'TGS-2022015370' THEN -4
  WHEN 'TGS-2023037587' THEN -3
  WHEN 'TGS-2023036661' THEN -2
  WHEN 'TGS-2023039179' THEN -1
END
WHERE cp.category_id = @revit_category
  AND p.sku IN (
    'TGS-2021004287',
    'TGS-2022015370',
    'TGS-2023037587',
    'TGS-2023036661',
    'TGS-2023039179'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2021004287' THEN -5
  WHEN 'TGS-2022015370' THEN -4
  WHEN 'TGS-2023037587' THEN -3
  WHEN 'TGS-2023036661' THEN -2
  WHEN 'TGS-2023039179' THEN -1
END
WHERE i.category_id = @revit_category
  AND p.sku IN (
    'TGS-2021004287',
    'TGS-2022015370',
    'TGS-2023037587',
    'TGS-2023036661',
    'TGS-2023039179'
  );
