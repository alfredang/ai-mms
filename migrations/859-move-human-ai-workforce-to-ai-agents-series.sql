-- 859: Move TGS-2024043854 — "WSQ - Build a Human-AI Workforce with Autonomous
-- AI Agents" out of the Agentic AI Series category and into the AI Agents
-- Series category.
--
--   remove from: url_key 'agentic-ai-series'
--   add to:      url_key 'ai-agents-series'
--
-- This also retires the 4th slot pinned by migration 858; the remaining three
-- pins from that block (Business Process Automation, n8n Automation, Claude
-- Code) are left untouched and simply close up to 1-2-3.
--
-- The course is added to the WSQ block of AI Agents Series at the end of the
-- existing TGS- run (position 8, after TGS-2023018987 at 7). The daily
-- category-ordering sweep renumbers the category to the canonical rule (WSQ
-- first preserving relative order, then C- alphabetical), so this lands the
-- course in the WSQ block without pinning it ahead of the existing courses.
--
-- Categories/products resolved by business key. Idempotent.

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

SET @agents_category := (
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

SET @workforce_product := (
  SELECT entity_id FROM catalog_product_entity
  WHERE sku = 'TGS-2024043854' LIMIT 1
);

-- 1. Add to AI Agents Series (no-op if already assigned).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @agents_category, @workforce_product, 8
WHERE @agents_category IS NOT NULL
  AND @workforce_product IS NOT NULL;

-- 1b. Mirror into the storefront index (what the listing actually reads), for
-- every store present on this instance. visibility is copied from the product's
-- existing index rows so it matches however this product is already indexed.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT DISTINCT @agents_category, @workforce_product, 8, 1, i.store_id, i.visibility
FROM catalog_category_product_index i
WHERE i.product_id = @workforce_product
  AND @agents_category IS NOT NULL
  AND @workforce_product IS NOT NULL;

-- 2. Remove from Agentic AI Series.
DELETE FROM catalog_category_product
WHERE category_id = @agentic_category
  AND product_id = @workforce_product
  AND @agentic_category IS NOT NULL
  AND @workforce_product IS NOT NULL;

DELETE FROM catalog_category_product_index
WHERE category_id = @agentic_category
  AND product_id = @workforce_product
  AND @agentic_category IS NOT NULL
  AND @workforce_product IS NOT NULL;
