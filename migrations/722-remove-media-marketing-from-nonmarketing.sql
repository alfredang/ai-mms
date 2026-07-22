-- 722: Two category corrections per user directives:
--   1. Enforce "only marketing courses in WSQ Media & Marketing Courses":
--      remove the legacy assignment from the two non-marketing repurposed
--      courses that still carried it (Hermes TGS-2020505109, Game Dev
--      TGS-2025052674).
--   2. List WSQ - Agentic AI for Social Media Marketing (TGS-2020505996)
--      in the Facebook and Instagram categories.
-- Name-resolved; partner-safe (TGS- absent on MY/GH).

DELETE cp FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN catalog_category_entity_varchar c ON c.entity_id = cp.category_id AND c.store_id = 0 AND TRIM(c.value) = 'WSQ Media & Marketing Courses'
  JOIN eav_attribute a ON a.attribute_id = c.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE e.sku IN ('TGS-2020505109', 'TGS-2025052674');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT c.entity_id, e.entity_id, 1
  FROM catalog_product_entity e
  JOIN catalog_category_entity_varchar c ON c.store_id = 0 AND TRIM(c.value) IN ('Facebook', 'Instagram')
  JOIN eav_attribute a ON a.attribute_id = c.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE e.sku = 'TGS-2020505996';
