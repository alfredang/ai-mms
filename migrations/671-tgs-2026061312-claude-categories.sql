-- 671: TGS-2026061312 (WSQ - Claude Certified Architect Foundation)
-- Re-home category assignments: list ONLY in "Claude AI Series" and
-- "Claude Certification Exam Prep"; remove from all other categories.
-- Categories resolved BY NAME (ids differ per site); partner-safe:
-- TGS- SKUs absent on MY/GH => @e NULL => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026061312');

DELETE cp FROM catalog_category_product cp
  WHERE cp.product_id = @e
    AND cp.category_id NOT IN (
      SELECT v.entity_id FROM catalog_category_entity_varchar v
      JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
      WHERE v.store_id = 0 AND v.value IN ('Claude AI Series', 'Claude Certification Exam Prep'));

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @e, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND v.value IN ('Claude AI Series', 'Claude Certification Exam Prep')
    AND @e IS NOT NULL;
