-- 711: Re-apply curated non-WSQ category orders (copy of 656) — same push as 710.
-- ---------------------------------------------------------------------------
-- Claude AI Series (url_key claude-ai-series) — from 648
-- ---------------------------------------------------------------------------

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

-- ---------------------------------------------------------------------------
-- Python (url_key python-programming) — from 642
-- ---------------------------------------------------------------------------

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

-- ---------------------------------------------------------------------------
-- React (url_key react-js-courses) — from 645
-- ---------------------------------------------------------------------------

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
