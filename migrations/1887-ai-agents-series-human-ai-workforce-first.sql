-- 1887: Pin TGS-2024043854 — WSQ - Build a Human–AI Workforce with Autonomous
-- AI Agents — as the first course in the AI Agents Series category
-- (url_key ai-agents-series).
--
-- A negative position puts it ahead of every other course. The daily
-- category-ordering sweep preserves TGS relative order and renumbers it to
-- position 1. Category/product use business-key lookups; the TGS- SKU does
-- not exist on MY/GH, so this is a no-op there. Idempotent.

SET @ai_agents_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'ai-agents-series'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = -1
WHERE cp.category_id = @ai_agents_category
  AND p.sku = 'TGS-2024043854';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = -1
WHERE i.category_id = @ai_agents_category
  AND p.sku = 'TGS-2024043854';
