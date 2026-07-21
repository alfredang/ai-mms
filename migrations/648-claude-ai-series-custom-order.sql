-- Claude AI Series category (url_key claude-ai-series): pin an explicit,
-- curated order for the non-WSQ courses, AFTER the WSQ block (which stays
-- first):
--   1. C1417 - Claude Code Masterclass
--   2. C1382 - Claude Cowork Masterclass
--   3. C201  - Claude Design Masterclass
--   4. C197  - Claude Microsoft 365 Masterclass
--   5. C744  - Claude Certified Associate - Foundations Certification
--   6. C437  - Claude Certified Architect - Foundations Certification
--   7. C364  - Claude Certified Architect - Professional Certification
--   8. C439  - Claude Certified Developer - Foundations Certification
--   9. C154  - Claude AI for Digital Marketing (not in the requested list;
--              placed after it)
--
-- NOTE: this deliberately overrides the canonical alphabetical non-WSQ order
-- for THIS category only (requested 2026-07-21). Positions 101+ keep the block
-- safely after any WSQ rows (canonical renumbering keeps WSQ within 1..N).
-- A future re-run of the global reorder (545/613/638 pattern) will flatten
-- this back to alphabetical — re-apply this file after any such reorder.
-- Category resolved by url_key, products by SKU: no-ops where absent. Idempotent.

SET @claude_cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1);

UPDATE catalog_category_product cp
JOIN catalog_product_entity e ON e.entity_id = cp.product_id
SET cp.position = CASE e.sku
  WHEN 'C1417' THEN 101
  WHEN 'C1382' THEN 102
  WHEN 'C201'  THEN 103
  WHEN 'C197'  THEN 104
  WHEN 'C744'  THEN 105
  WHEN 'C437'  THEN 106
  WHEN 'C364'  THEN 107
  WHEN 'C439'  THEN 108
  WHEN 'C154'  THEN 109
END
WHERE cp.category_id = @claude_cat
  AND e.sku IN ('C1417', 'C1382', 'C201', 'C197', 'C744', 'C437', 'C364', 'C439', 'C154');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity e ON e.entity_id = i.product_id
SET i.position = CASE e.sku
  WHEN 'C1417' THEN 101
  WHEN 'C1382' THEN 102
  WHEN 'C201'  THEN 103
  WHEN 'C197'  THEN 104
  WHEN 'C744'  THEN 105
  WHEN 'C437'  THEN 106
  WHEN 'C364'  THEN 107
  WHEN 'C439'  THEN 108
  WHEN 'C154'  THEN 109
END
WHERE i.category_id = @claude_cat
  AND e.sku IN ('C1417', 'C1382', 'C201', 'C197', 'C744', 'C437', 'C364', 'C439', 'C154');
