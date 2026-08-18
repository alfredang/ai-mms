-- 1057: Pin the requested WSQ/CASL order in the Autodesk Software Courses
-- category (url_key autodesk-software-courses): AutoCAD courses first, then
-- Revit, then the other Autodesk courses. No CASL-named Autodesk course is
-- assigned to this category today, so the pin lists the 15 WSQ TGS- SKUs.
--
--   AutoCAD:
--    1. TGS-2021005538 — WSQ Technical Drawing with AutoCAD
--    2. TGS-2021005539 — WSQ AutoCAD Civil 3D for Infrastructure Design
--    3. TGS-2023037469 — WSQ Technical Drawing with AutoCAD Mechanical
--    4. TGS-2023037466 — WSQ Technical Drawing with AutoCAD Electrical
--    5. TGS-2023036004 — WSQ Autodesk Certified Professional (ACP) - AutoCAD Design and Drafting
--   Revit (same relative order as migration 1055's Revit-category pin):
--    6. TGS-2021004287 — WSQ Architecture Drawing with Revit
--    7. TGS-2022015370 — WSQ Application of BIM using Revit
--    8. TGS-2023037587 — WSQ ACP for Revit Architectural Design
--    9. TGS-2023036661 — WSQ ACP for Revit Mechanical Design
--   10. TGS-2023039179 — WSQ ACP for Revit Structural Design
--   Other Autodesk (existing relative order preserved):
--   11. TGS-2021005540 — WSQ Product Design with Fusion 360
--   12. TGS-2021006715 — WSQ Product Design with Autodesk Inventor
--   13. TGS-2021009334 — WSQ Architectural Visualization with 3ds Max
--   14. TGS-2023039180 — WSQ Generative AI Design for Civil 3D
--   15. TGS-2023037544 — WSQ Generative AI for 3D Modeling
-- Non-WSQ courses (C-prefix Masterclasses) follow alphabetically as usual.
--
-- Negative positions keep these rows ahead of every unpinned course.
-- The daily category-ordering sweep preserves TGS relative order and
-- renumbers them to normal positive positions. Category/products use
-- business-key lookups. Idempotent.

SET @autodesk_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'autodesk-software-courses'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2021005538' THEN -15
  WHEN 'TGS-2021005539' THEN -14
  WHEN 'TGS-2023037469' THEN -13
  WHEN 'TGS-2023037466' THEN -12
  WHEN 'TGS-2023036004' THEN -11
  WHEN 'TGS-2021004287' THEN -10
  WHEN 'TGS-2022015370' THEN -9
  WHEN 'TGS-2023037587' THEN -8
  WHEN 'TGS-2023036661' THEN -7
  WHEN 'TGS-2023039179' THEN -6
  WHEN 'TGS-2021005540' THEN -5
  WHEN 'TGS-2021006715' THEN -4
  WHEN 'TGS-2021009334' THEN -3
  WHEN 'TGS-2023039180' THEN -2
  WHEN 'TGS-2023037544' THEN -1
END
WHERE cp.category_id = @autodesk_category
  AND p.sku IN (
    'TGS-2021005538',
    'TGS-2021005539',
    'TGS-2023037469',
    'TGS-2023037466',
    'TGS-2023036004',
    'TGS-2021004287',
    'TGS-2022015370',
    'TGS-2023037587',
    'TGS-2023036661',
    'TGS-2023039179',
    'TGS-2021005540',
    'TGS-2021006715',
    'TGS-2021009334',
    'TGS-2023039180',
    'TGS-2023037544'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2021005538' THEN -15
  WHEN 'TGS-2021005539' THEN -14
  WHEN 'TGS-2023037469' THEN -13
  WHEN 'TGS-2023037466' THEN -12
  WHEN 'TGS-2023036004' THEN -11
  WHEN 'TGS-2021004287' THEN -10
  WHEN 'TGS-2022015370' THEN -9
  WHEN 'TGS-2023037587' THEN -8
  WHEN 'TGS-2023036661' THEN -7
  WHEN 'TGS-2023039179' THEN -6
  WHEN 'TGS-2021005540' THEN -5
  WHEN 'TGS-2021006715' THEN -4
  WHEN 'TGS-2021009334' THEN -3
  WHEN 'TGS-2023039180' THEN -2
  WHEN 'TGS-2023037544' THEN -1
END
WHERE i.category_id = @autodesk_category
  AND p.sku IN (
    'TGS-2021005538',
    'TGS-2021005539',
    'TGS-2023037469',
    'TGS-2023037466',
    'TGS-2023036004',
    'TGS-2021004287',
    'TGS-2022015370',
    'TGS-2023037587',
    'TGS-2023036661',
    'TGS-2023039179',
    'TGS-2021005540',
    'TGS-2021006715',
    'TGS-2021009334',
    'TGS-2023039180',
    'TGS-2023037544'
  );
