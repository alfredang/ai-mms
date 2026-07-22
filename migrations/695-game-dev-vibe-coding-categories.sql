-- 695: List TGS-2025052674 (WSQ - AI Vibe Coding for Game Development) in
-- "AI Vibe Coding Series" and "Gaming & Animation".
-- Categories resolved BY NAME; partner-safe: TGS- absent on MY/GH => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052674');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @e, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND v.value IN ('AI Vibe Coding Series', 'Gaming & Animation')
    AND @e IS NOT NULL;
