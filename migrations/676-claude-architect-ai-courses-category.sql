-- 676: Category assignments per user directive:
--  - TGS-2026061312 (WSQ - Claude Certified Architect Foundation) -> add "AI Courses"
--  - TGS-2020505109 (WSQ - AI Agent with Hermes Agent) -> ensure in
--    "AI Agents Series" + "AI Courses" (already assigned on SG; INSERT IGNORE no-ops)
-- Categories resolved BY NAME; partner-safe: TGS- absent on MY/GH => @e NULL => no-op.

SET @claude := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026061312');
SET @hermes := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505109');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @claude, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND v.value = 'AI Courses' AND @claude IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @hermes, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND v.value IN ('AI Agents Series', 'AI Courses') AND @hermes IS NOT NULL;
