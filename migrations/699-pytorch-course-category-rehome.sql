-- 699: TGS-2020503487 (WSQ - AI Vibe Coding with PyTorch)
-- Re-home category assignments: list ONLY in "AI Vibe Coding Series",
-- "Python" and "AI Courses"; remove from all other categories.
-- Categories resolved BY NAME (TRIM: the Python row is stored as 'Python ');
-- partner-safe: TGS- absent on MY/GH => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503487');

DELETE cp FROM catalog_category_product cp
  WHERE cp.product_id = @e
    AND cp.category_id NOT IN (
      SELECT v.entity_id FROM catalog_category_entity_varchar v
      JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
      WHERE v.store_id = 0 AND TRIM(v.value) IN ('AI Vibe Coding Series', 'Python', 'AI Courses'));

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @e, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND TRIM(v.value) IN ('AI Vibe Coding Series', 'Python', 'AI Courses')
    AND @e IS NOT NULL;
