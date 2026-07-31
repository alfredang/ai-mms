-- 857: Pin the top three courses in the Agentic AI Series category
-- (url_key 'agentic-ai-series'):
--   1. TGS-2024045801 — WSQ - Agentic AI for Business Process Automation
--   2. TGS-2023035977 — WSQ - Agentic AI Automation with n8n
--   3. TGS-2025052468 — WSQ - Agentic AI Applications with Claude Code
--
-- Extends the single pin from 856 (which set TGS-2024045801 to -1) so the
-- requested 3rd slot is explicit rather than incidental. Negative positions
-- keep these rows ahead of every unpinned course; the daily category-ordering
-- sweep preserves TGS relative order and renumbers them to normal positive
-- positions (the 784/785/786 pattern). Category/products resolved by business
-- key. Idempotent.

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
SET cp.position = CASE p.sku
  WHEN 'TGS-2024045801' THEN -3
  WHEN 'TGS-2023035977' THEN -2
  WHEN 'TGS-2025052468' THEN -1
END
WHERE cp.category_id = @agentic_category
  AND p.sku IN (
    'TGS-2024045801',
    'TGS-2023035977',
    'TGS-2025052468'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2024045801' THEN -3
  WHEN 'TGS-2023035977' THEN -2
  WHEN 'TGS-2025052468' THEN -1
END
WHERE i.category_id = @agentic_category
  AND p.sku IN (
    'TGS-2024045801',
    'TGS-2023035977',
    'TGS-2025052468'
  );
