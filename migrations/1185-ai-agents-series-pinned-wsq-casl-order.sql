-- 1185: Pin the requested WSQ/CASL order in the AI Agents Series category:
--   1. TGS-2025054471 — WSQ - Autonomous AI Agents
--   2. TGS-2020503395 — WSQ - Business Innovation with AI Agents
--   3. TGS-2026064176 — CASL - AI Agent with Hermes Agent
--   4. TGS-2026064859 — CASL - Autonomous AI Agents with OpenClaw
--   5. TGS-2024043854 — WSQ - Build a Human-AI Workforce with Autonomous AI Agents
--   6. TGS-2024052081 — WSQ - Automate Video and Voice AI Agents with n8n
--   7. TGS-2025053228 — WSQ - AI Agent Cybersecurity
--
-- TGS-2025054471 was not a member of this category, so it is assigned first.
-- Negative positions keep these rows ahead of every unpinned course. The daily
-- category-ordering sweep preserves TGS relative order and renumbers them to
-- normal positive positions; the remaining TGS- courses keep their relative
-- order after this block, and non-WSQ (C-prefix) stay alphabetical below.
-- Category/products use business-key lookups. Idempotent.

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

-- Add the missing course to the category (no-op where already assigned, or
-- where the SKU/category does not exist on this instance).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @ai_agents_category, p.entity_id, -7
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2025054471'
  AND @ai_agents_category IS NOT NULL;

-- Mirror that assignment into the storefront index, for every store on this
-- instance, copying the visibility this product already has there.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @ai_agents_category, p.entity_id, -7, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s
  ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id
 AND i.store_id = s.store_id
WHERE p.sku = 'TGS-2025054471'
  AND @ai_agents_category IS NOT NULL
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025054471' THEN -7
  WHEN 'TGS-2020503395' THEN -6
  WHEN 'TGS-2026064176' THEN -5
  WHEN 'TGS-2026064859' THEN -4
  WHEN 'TGS-2024043854' THEN -3
  WHEN 'TGS-2024052081' THEN -2
  WHEN 'TGS-2025053228' THEN -1
END
WHERE cp.category_id = @ai_agents_category
  AND p.sku IN (
    'TGS-2025054471',
    'TGS-2020503395',
    'TGS-2026064176',
    'TGS-2026064859',
    'TGS-2024043854',
    'TGS-2024052081',
    'TGS-2025053228'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025054471' THEN -7
  WHEN 'TGS-2020503395' THEN -6
  WHEN 'TGS-2026064176' THEN -5
  WHEN 'TGS-2026064859' THEN -4
  WHEN 'TGS-2024043854' THEN -3
  WHEN 'TGS-2024052081' THEN -2
  WHEN 'TGS-2025053228' THEN -1
END
WHERE i.category_id = @ai_agents_category
  AND p.sku IN (
    'TGS-2025054471',
    'TGS-2020503395',
    'TGS-2026064176',
    'TGS-2026064859',
    'TGS-2024043854',
    'TGS-2024052081',
    'TGS-2025053228'
  );
