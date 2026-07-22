-- 739: TGS-2024048313 (WSQ - Native Android Apps Development with Java and
-- Vibe Coding):
--   1. List in Mobile Apps + Android (already in AI Vibe Coding Series).
--   2. Pin to the TOP of Android (position 0; 740's reorder renumbers dense).
--   3. Remove from WSQ Media & Marketing Courses (user rule: only marketing
--      courses there).
-- Name-resolved; partner-safe (TGS- absent on MY/GH).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024048313');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @e, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND TRIM(v.value) IN ('Mobile Apps', 'Android', 'AI Vibe Coding Series')
    AND @e IS NOT NULL;

SET @android := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND TRIM(v.value) = 'Android' LIMIT 1);

UPDATE catalog_category_product SET position = 0
  WHERE category_id = @android AND product_id = @e;
UPDATE catalog_category_product_index SET position = 0
  WHERE category_id = @android AND product_id = @e;

DELETE cp FROM catalog_category_product cp
  JOIN catalog_category_entity_varchar c ON c.entity_id = cp.category_id AND c.store_id = 0 AND TRIM(c.value) = 'WSQ Media & Marketing Courses'
  JOIN eav_attribute a ON a.attribute_id = c.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE cp.product_id = @e;
