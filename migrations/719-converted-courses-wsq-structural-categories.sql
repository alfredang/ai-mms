-- 719: Structural category listings for the seven repurposed WSQ courses
-- (follows 716's Adult Courses add), per user directive:
--   - ALL seven -> "WSQ and IBF courses" + "WSQ Funded Courses"
--   - ONLY the marketing courses (TikTok TGS-2023036657, Social Media
--     TGS-2020505996) -> "WSQ Media & Marketing Courses"
--   - Facebook: none.
-- INSERT IGNORE; name-resolved; partner-safe (TGS- absent on MY/GH).

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT c.entity_id, e.entity_id, 1
  FROM catalog_product_entity e
  JOIN catalog_category_entity_varchar c ON c.store_id = 0 AND TRIM(c.value) IN ('WSQ and IBF courses', 'WSQ Funded Courses')
  JOIN eav_attribute a ON a.attribute_id = c.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE e.sku IN ('TGS-2026061312', 'TGS-2020505109', 'TGS-2023036646',
                  'TGS-2025052674', 'TGS-2020503487', 'TGS-2023036657', 'TGS-2020505996');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT c.entity_id, e.entity_id, 1
  FROM catalog_product_entity e
  JOIN catalog_category_entity_varchar c ON c.store_id = 0 AND TRIM(c.value) = 'WSQ Media & Marketing Courses'
  JOIN eav_attribute a ON a.attribute_id = c.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE e.sku IN ('TGS-2023036657', 'TGS-2020505996');
