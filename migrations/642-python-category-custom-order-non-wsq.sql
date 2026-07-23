-- Python category (url_key python-programming): pin an explicit, curated order
-- for the 5 non-WSQ courses, AFTER the WSQ/IBF block (which stays first):
--   1. C138 - AI Vibe Coding with Python Fundamentals
--   2. C193 - AI Vibe Coding for Python Data Analysis
--   3. C179 - AI Vibe Coding for Python Applications
--   4. C539 - AI Vibe Coding with PyTorch Deep Learning
--   5. C188 - AI Vibe Coding for Python Financial Analysis
--
-- NOTE: this deliberately overrides the canonical alphabetical non-WSQ order
-- for THIS category only (requested 2026-07-21). Positions 101+ keep the block
-- safely after any WSQ rows (canonical renumbering keeps WSQ within 1..N).
-- A future re-run of the global reorder (545/613/638 pattern) will flatten
-- this back to alphabetical — re-apply this file after any such reorder.
-- Category resolved by url_key, products by SKU: no-ops where absent. Idempotent.

SET @python_cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'python-programming' LIMIT 1);

UPDATE catalog_category_product cp
JOIN catalog_product_entity e ON e.entity_id = cp.product_id
SET cp.position = CASE e.sku
  WHEN 'C138' THEN 101
  WHEN 'C193' THEN 102
  WHEN 'C179' THEN 103
  WHEN 'C539' THEN 104
  WHEN 'C188' THEN 105
END
WHERE cp.category_id = @python_cat
  AND e.sku IN ('C138', 'C193', 'C179', 'C539', 'C188');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity e ON e.entity_id = i.product_id
SET i.position = CASE e.sku
  WHEN 'C138' THEN 101
  WHEN 'C193' THEN 102
  WHEN 'C179' THEN 103
  WHEN 'C539' THEN 104
  WHEN 'C188' THEN 105
END
WHERE i.category_id = @python_cat
  AND e.sku IN ('C138', 'C193', 'C179', 'C539', 'C188');
