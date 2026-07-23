-- React category (url_key react-js-courses): pin an explicit, curated order
-- for the 2 non-WSQ courses, AFTER the WSQ block (which stays first):
--   1. C1143 - AI Vibe Coding for React Development
--   2. C1800 - AI Vibe Coding for Full Stack Web Development
--
-- NOTE: this deliberately overrides the canonical alphabetical non-WSQ order
-- for THIS category only (requested 2026-07-21). Positions 101+ keep the block
-- safely after any WSQ rows (canonical renumbering keeps WSQ within 1..N).
-- A future re-run of the global reorder (545/613/638 pattern) will flatten
-- this back to alphabetical — re-apply this file after any such reorder.
-- Category resolved by url_key, products by SKU: no-ops where absent. Idempotent.

SET @react_cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'react-js-courses' LIMIT 1);

UPDATE catalog_category_product cp
JOIN catalog_product_entity e ON e.entity_id = cp.product_id
SET cp.position = CASE e.sku
  WHEN 'C1143' THEN 101
  WHEN 'C1800' THEN 102
END
WHERE cp.category_id = @react_cat
  AND e.sku IN ('C1143', 'C1800');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity e ON e.entity_id = i.product_id
SET i.position = CASE e.sku
  WHEN 'C1143' THEN 101
  WHEN 'C1800' THEN 102
END
WHERE i.category_id = @react_cat
  AND e.sku IN ('C1143', 'C1800');
