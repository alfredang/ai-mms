-- 706: TGS-2023036657 (WSQ - Agentic AI for TikTok Marketing)
-- Re-home category assignments: list ONLY in Agentic AI Series + Video
-- Marketing and their parents (AI Courses, Digital Marketing); remove from
-- all other categories. Name-resolved; partner-safe: TGS- absent on MY/GH.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036657');

DELETE cp FROM catalog_category_product cp
  WHERE cp.product_id = @e
    AND cp.category_id NOT IN (
      SELECT v.entity_id FROM catalog_category_entity_varchar v
      JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
      WHERE v.store_id = 0 AND TRIM(v.value) IN ('Agentic AI Series', 'AI Courses', 'Video Marketing', 'Digital Marketing'));

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @e, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND TRIM(v.value) IN ('Agentic AI Series', 'AI Courses', 'Video Marketing', 'Digital Marketing')
    AND @e IS NOT NULL;
