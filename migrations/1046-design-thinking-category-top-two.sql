-- 1046: Pin the requested top two courses in the Design Thinking category:
--   1. TGS-2026064719 — CASL - Generative AI for Design Thinking
--   2. TGS-2024049781 — WSQ - Fast-Track Innovations with Agile Design Thinking
--                        and Generative AI (GenAI)
--
-- Both are TGS- (WSQ block) courses, so this is a relative-order swap inside
-- the WSQ group — the daily category-ordering sweep preserves TGS relative
-- order and renumbers them to normal positive positions. Negative positions
-- keep the pair ahead of every unpinned course until then.
-- Category/products use business-key lookups. Idempotent.

SET @design_thinking_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'design-thinking-courses'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026064719' THEN -2
  WHEN 'TGS-2024049781' THEN -1
END
WHERE cp.category_id = @design_thinking_category
  AND p.sku IN (
    'TGS-2026064719',
    'TGS-2024049781'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026064719' THEN -2
  WHEN 'TGS-2024049781' THEN -1
END
WHERE i.category_id = @design_thinking_category
  AND p.sku IN (
    'TGS-2026064719',
    'TGS-2024049781'
  );
