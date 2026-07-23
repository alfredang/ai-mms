-- 736: TGS-2023037545 (WSQ - Native iOS Apps Development with C++ and Vibe
-- Coding) — list in the iOS category (child of Mobile Apps) and pin to its
-- TOP (position 0; 737's reorder renumbers dense; WSQ relative order keeps
-- the pin durable). Name-resolved; partner-safe (TGS- absent on MY/GH).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037545');
SET @ios := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND TRIM(v.value) = 'iOS' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT @ios, @e, 0 FROM dual WHERE @ios IS NOT NULL AND @e IS NOT NULL;

UPDATE catalog_category_product SET position = 0
  WHERE category_id = @ios AND product_id = @e;
UPDATE catalog_category_product_index SET position = 0
  WHERE category_id = @ios AND product_id = @e;
