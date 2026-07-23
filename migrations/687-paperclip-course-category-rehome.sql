-- 687: TGS-2023036646 (WSQ - Manage AI Agents with Paperclip)
-- Re-home category assignments: list ONLY in "AI Agents Series",
-- "Multi Agents Series" and "AI Courses"; remove from all other categories
-- (Adult Courses, WSQ and IBF, Infocomm Technology, Agentic AI Series,
-- WSQ Funded, WSQ IT & Security, WSQ AI Courses, Generative AI Series).
-- Categories resolved BY NAME; partner-safe: TGS- absent on MY/GH => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036646');

DELETE cp FROM catalog_category_product cp
  WHERE cp.product_id = @e
    AND cp.category_id NOT IN (
      SELECT v.entity_id FROM catalog_category_entity_varchar v
      JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
      WHERE v.store_id = 0 AND v.value IN ('AI Agents Series', 'Multi Agents Series', 'AI Courses'));

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @e, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND v.value IN ('AI Agents Series', 'Multi Agents Series', 'AI Courses')
    AND @e IS NOT NULL;
