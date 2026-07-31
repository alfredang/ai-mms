-- 856: Pin TGS-2024045801 — "WSQ - Agentic AI for Business Process Automation"
-- as the FIRST course listed in the Agentic AI Series category
-- (url_key 'agentic-ai-series').
--
-- A negative position keeps the row ahead of every other course. The daily
-- category-ordering sweep preserves TGS relative order and renumbers the WSQ
-- block to normal positive positions, so this pin survives (the 784/785/786
-- pattern). Category/product resolved by business key. Idempotent.

SET @agentic_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'agentic-ai-series'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = -1
WHERE cp.category_id = @agentic_category
  AND p.sku = 'TGS-2024045801';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = -1
WHERE i.category_id = @agentic_category
  AND p.sku = 'TGS-2024045801';
