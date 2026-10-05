-- List "CASL - AI for Shopify eCommerce Store" (TGS-2026064175) under the
-- AI for Retail category (url_key ai-for-retail-courses). Applied live on SG
-- prod 2026-09-28; this keeps a rebuilt DB in sync.
-- Order (funded TGS- first, alphabetical, then C-): CASL - AI for eCommerce,
-- CASL - AI for Shopify eCommerce Store, AI for Retail (C398).
-- Resolved by url_key / SKU, so it no-ops where either is absent (partners).

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
             JOIN eav_attribute a ON a.attribute_id = v.attribute_id
                  AND a.attribute_code = 'url_key' AND a.entity_type_id = 3
             WHERE v.store_id = 0 AND v.value = 'ai-for-retail-courses' LIMIT 1);
SET @p_new  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064175' LIMIT 1);
SET @p_ecom := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064474' LIMIT 1);
SET @p_c398 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C398' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @p_new, 2 FROM DUAL WHERE @cat IS NOT NULL AND @p_new IS NOT NULL;

UPDATE catalog_category_product SET position = 1 WHERE category_id = @cat AND product_id = @p_ecom;
UPDATE catalog_category_product SET position = 2 WHERE category_id = @cat AND product_id = @p_new;
UPDATE catalog_category_product SET position = 3 WHERE category_id = @cat AND product_id = @p_c398;

INSERT IGNORE INTO catalog_category_product_index
    (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @p_new, 2, 1, 1, 4 FROM DUAL
WHERE @cat IS NOT NULL AND @p_new IS NOT NULL
  AND EXISTS (SELECT 1 FROM core_store WHERE store_id = 1)
  AND EXISTS (SELECT 1 FROM catalog_product_website WHERE product_id = @p_new AND website_id = 1);

UPDATE catalog_category_product_index SET position = 1, is_parent = 1 WHERE category_id = @cat AND product_id = @p_ecom;
UPDATE catalog_category_product_index SET position = 2, is_parent = 1 WHERE category_id = @cat AND product_id = @p_new;
UPDATE catalog_category_product_index SET position = 3, is_parent = 1 WHERE category_id = @cat AND product_id = @p_c398;
