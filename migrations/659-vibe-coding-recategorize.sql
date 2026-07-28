-- 659-vibe-coding-recategorize.sql
-- Recategorize AI-assisted-programming / vibe-coding courses so they live in the
-- Vibe Coding series ONLY, not in other AI series (Generative AI 433, Agentic 189,
-- Claude 281, Codex 283).
--
-- Rule (confirmed with product owner): a course whose name says "Vibe Coding" or
-- "AI-Assisted programming" belongs solely in the Vibe Coding series:
--   * AI-series tree:  414 "AI Vibe Coding Series" (under 252 AI Courses)
--   * WSQ tree:        425 "WSQ Programming & Vibe Coding" (WSQ courses only)
-- and must be REMOVED from Generative AI / Agentic / Claude / Codex series.
--
-- Excluded deliberately: TGS-2024051421 (GenAI interview course, matched on
-- "Assisted" but is not vibe coding / AI-assisted programming) — stays in 433.
--
-- Scope: 7 courses. Removals from 4 AI-series categories; 2 courses added to 414.
-- SG only. Partner-safe via the SG store-code guard below: partner installs
-- (MY/GH) carry the C-prefix SKUs too under catalog parity, and their category
-- ids DIFFER (on MY, id 189 is "Adobe After Effects", not Agentic AI Series) —
-- so every product var goes NULL there and every statement no-ops. Idempotent.

-- ---------------------------------------------------------------------------
-- Resolve product ids by SKU (NULL-safe: a missing SKU makes its DELETEs no-op).
-- @sg guard: only the SG install has store_id 1 = 'singapore'; elsewhere all
-- vars resolve NULL, turning the DELETEs/INSERTs below into no-ops.
-- ---------------------------------------------------------------------------
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @p_tgs277  := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2025052277' AND @sg=1);
SET @p_tgs659  := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2025052659' AND @sg=1);
SET @p_c818    := (SELECT entity_id FROM catalog_product_entity WHERE sku='C818' AND @sg=1);
SET @p_tgs2504 := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2021002504' AND @sg=1);
SET @p_c1231   := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1231' AND @sg=1);
SET @p_tgs9924 := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2023039924' AND @sg=1);
SET @p_tgs6088 := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2023036088' AND @sg=1);

-- ---------------------------------------------------------------------------
-- REMOVE from other AI series (both the assignment table and its flat index)
--   433 Generative AI Series : TGS-2025052277, TGS-2025052659, TGS-2023039924
--   189 Agentic AI Series    : TGS-2021002504, C1231, TGS-2023036088
--   283 Codex AI Series      : C818
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product
  WHERE (category_id=433 AND product_id IN (@p_tgs277,@p_tgs659,@p_tgs9924))
     OR (category_id=189 AND product_id IN (@p_tgs2504,@p_c1231,@p_tgs6088))
     OR (category_id=283 AND product_id = @p_c818);

DELETE FROM catalog_category_product_index
  WHERE (category_id=433 AND product_id IN (@p_tgs277,@p_tgs659,@p_tgs9924))
     OR (category_id=189 AND product_id IN (@p_tgs2504,@p_c1231,@p_tgs6088))
     OR (category_id=283 AND product_id = @p_c818);

-- ---------------------------------------------------------------------------
-- ADD the two courses that are not yet in the AI-series vibe category (414)
-- (the other five are already in 414). Append after current max position;
-- final ordering is fixed by the category-ordering reindex post-deploy.
-- ---------------------------------------------------------------------------
SET @pos414 := (SELECT COALESCE(MAX(position),0) FROM catalog_category_product WHERE category_id=414);

INSERT INTO catalog_category_product (category_id, product_id, position)
  SELECT 414, @p_tgs277, @pos414+1
  WHERE @p_tgs277 IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM catalog_category_product WHERE category_id=414 AND product_id=@p_tgs277);

INSERT INTO catalog_category_product (category_id, product_id, position)
  SELECT 414, @p_tgs659, @pos414+2
  WHERE @p_tgs659 IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM catalog_category_product WHERE category_id=414 AND product_id=@p_tgs659);

-- Mirror the two inserts into the flat index so they surface before the next
-- full reindex. store_id 1 = SG storefront; visibility/position copied.
INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
  SELECT cp.category_id, cp.product_id, cp.position, 1, 1, 4
  FROM catalog_category_product cp
  WHERE cp.category_id=414 AND cp.product_id IN (@p_tgs277,@p_tgs659)
    AND NOT EXISTS (
      SELECT 1 FROM catalog_category_product_index i
      WHERE i.category_id=cp.category_id AND i.product_id=cp.product_id AND i.store_id=1);
