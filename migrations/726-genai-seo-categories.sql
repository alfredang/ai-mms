-- 726: TGS-2020503501 (WSQ - Generative AI for SEO)
-- List under Generative AI Series + SEO and their parents (AI Courses,
-- Digital Marketing). Name-resolved; partner-safe (TGS- absent on MY/GH).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503501');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @e, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND TRIM(v.value) IN ('Generative AI Series', 'AI Courses', 'SEO', 'Digital Marketing')
    AND @e IS NOT NULL;
