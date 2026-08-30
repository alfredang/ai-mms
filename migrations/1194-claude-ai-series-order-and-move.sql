-- 1194: Claude AI Series curation.
--
-- 1) Move WSQ - Agentic AI for Market Research (TGS-2022017520) out of the
--    Claude AI Series; it is already in the Agentic AI Series (pinned by
--    1188), so the INSERT below is a defensive no-op.
--
-- 2) Pin the requested WSQ order:
--    1. TGS-2025052468  WSQ - Agentic AI Applications with Claude Code
--    2. TGS-2026061312  WSQ - Claude Certified Architect Foundation
--    3. TGS-2023018659  WSQ - Claude Cowork for Digital Marketing
--
-- All TGS-; sweep preserves relative order; partner no-op. Idempotent.

SET @claude := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1
);
SET @agentic := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'agentic-ai-series' LIMIT 1
);

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @claude
  AND p.sku = 'TGS-2022017520';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @claude
  AND p.sku = 'TGS-2022017520';

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @agentic, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @agentic IS NOT NULL
  AND p.sku = 'TGS-2022017520';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @agentic, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @agentic IS NOT NULL
  AND p.sku = 'TGS-2022017520'
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025052468' THEN -3
  WHEN 'TGS-2026061312' THEN -2
  WHEN 'TGS-2023018659' THEN -1
END
WHERE cp.category_id = @claude
  AND p.sku IN ('TGS-2025052468', 'TGS-2026061312', 'TGS-2023018659');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025052468' THEN -3
  WHEN 'TGS-2026061312' THEN -2
  WHEN 'TGS-2023018659' THEN -1
END
WHERE i.category_id = @claude
  AND p.sku IN ('TGS-2025052468', 'TGS-2026061312', 'TGS-2023018659');
