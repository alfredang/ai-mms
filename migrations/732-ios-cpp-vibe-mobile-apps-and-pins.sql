-- 732: TGS-2023037545 (WSQ - Native iOS Apps Development with C++ and Vibe Coding)
--   1. List in Mobile Apps (+ parents — already in Infocomm Technology,
--      Programming, C/C++/C#, AI Vibe Coding Series, AI Courses; INSERT
--      IGNORE covers the full set anyway).
--   2. Pin to the TOP of Mobile Apps and C/C++/C# (position 0; the 733
--      reorder renumbers dense and WSQ relative order makes it durable).
-- Name/url_key-resolved; partner-safe (TGS- absent on MY/GH).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037545');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT v.entity_id, @e, 1 FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND TRIM(v.value) IN ('Mobile Apps', 'Infocomm Technology', 'C/C++/C#', 'Programming', 'AI Vibe Coding Series', 'AI Courses')
    AND @e IS NOT NULL;

SET @mobile := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND TRIM(v.value) = 'Mobile Apps' LIMIT 1);
SET @cpp := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
  WHERE v.store_id = 0 AND TRIM(v.value) = 'C/C++/C#' LIMIT 1);

UPDATE catalog_category_product SET position = 0
  WHERE category_id IN (@mobile, @cpp) AND product_id = @e;
UPDATE catalog_category_product_index SET position = 0
  WHERE category_id IN (@mobile, @cpp) AND product_id = @e;
