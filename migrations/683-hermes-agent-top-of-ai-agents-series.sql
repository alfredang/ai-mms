-- 683: Pin "WSQ - AI Agent with Hermes Agent" (TGS-2020505109) to the TOP of
-- AI Agents Series. WSQ rows keep their relative order through the canonical
-- global reorder, so setting the lowest position here + the 684 reorder makes
-- it #1 and keeps it #1 on future reorders.
-- Category resolved by url_key; TGS- SKU absent on partners => no-op there.

SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key')
    AND store_id = 0 AND value = 'ai-agents-series' LIMIT 1);
SET @p := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505109');

UPDATE catalog_category_product SET position = 0
  WHERE category_id = @cat AND product_id = @p;
UPDATE catalog_category_product_index SET position = 0
  WHERE category_id = @cat AND product_id = @p;
