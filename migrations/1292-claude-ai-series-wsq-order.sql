-- 1292: Pin the requested WSQ order on "Claude AI Series" (url_key
-- 'claude-ai-series', category 281):
--
--   1  TGS-2025052468  WSQ - Agentic AI Applications with Claude Code
--   2  TGS-2023018659  WSQ - Claude Cowork for Digital Marketing
--   3  TGS-2020503109  WSQ - Claude Cowork for Email Marketing
--   4  TGS-2026061312  WSQ - Claude Certified Architect Foundation
--
-- ROOT CAUSE: catalog_category_product already held exactly this order, but
-- catalog_category_product_index -- the table the storefront actually reads --
-- had drifted out of sync (Agentic AI at 3, Digital Marketing at 1, Email
-- Marketing at 2), so the live page rendered the wrong order while the
-- authoring table looked correct. Writing only catalog_category_product would
-- therefore have looked right in SQL and changed nothing on the page. Both
-- tables are set here.
--
-- Sort config is fine and deliberately untouched: default_sort_by resolves to
-- 'position' from the store default (the category sets no override), so no
-- default_sort_by / available_sort_by repair is needed here.
--
-- Positions are POSITIVE (a full reindex zeroes negative positions). The
-- category IS on mmd/category_ordering/curated_url_keys, so the nightly
-- CategoryOrdering sweep keeps the non-WSQ block in its existing order and
-- enforces WSQ-first; these four stay 1..4 ahead of the C-prefix courses,
-- which start at 5.
--
-- C154 "Claude AI for Digital Marketing" is disabled (status=2) and so has no
-- index row -- expected, not repaired here.
--
-- Business-key (url_key / SKU) lookups only. Idempotent. Safe on partner
-- sites: neither the category nor these SKUs exist there, so every statement
-- matches zero rows.

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series'
  LIMIT 1);

-- Authoring table.
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
JOIN (
  SELECT 'TGS-2025052468' AS sku, 1 AS pos UNION ALL
  SELECT 'TGS-2023018659', 2 UNION ALL
  SELECT 'TGS-2020503109', 3 UNION ALL
  SELECT 'TGS-2026061312', 4
) s ON s.sku = p.sku
SET cp.position = s.pos
WHERE cp.category_id = @cat AND @cat IS NOT NULL;

-- Index table -- this is the one the storefront reads.
UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
JOIN (
  SELECT 'TGS-2025052468' AS sku, 1 AS pos UNION ALL
  SELECT 'TGS-2023018659', 2 UNION ALL
  SELECT 'TGS-2020503109', 3 UNION ALL
  SELECT 'TGS-2026061312', 4
) s ON s.sku = p.sku
SET i.position = s.pos
WHERE i.category_id = @cat AND @cat IS NOT NULL;
