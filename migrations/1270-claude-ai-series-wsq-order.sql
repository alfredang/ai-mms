-- 1270: Claude AI Series (url_key 'claude-ai-series') — pin the requested order
-- for the four WSQ courses at the top of the listing:
--   1  TGS-2025052468  WSQ - Agentic AI Applications with Claude Code
--   2  TGS-2023018659  WSQ - Claude Cowork for Digital Marketing
--   3  TGS-2020503109  WSQ - Claude Cowork for Email Marketing
--   4  TGS-2026061312  WSQ - Claude Certified Architect Foundation
--
-- Only the TGS- block is touched. The curated C-prefix order below it
-- (Masterclasses, then the certifications — migration 1256) is left exactly as
-- it is: this category IS in mmd/category_ordering/curated_url_keys, so the
-- nightly sweep keeps that curated non-WSQ order rather than re-alphabetising
-- it, and it preserves TGS relative order for the block pinned here.
--
-- Negative positions keep the WSQ block ahead of the curated C-prefix block.
-- Business-key lookups only; no-ops where the category or SKUs are absent on
-- this instance. Idempotent.

SET @cl := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='claude-ai-series' LIMIT 1);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025052468' THEN -4
  WHEN 'TGS-2023018659' THEN -3
  WHEN 'TGS-2020503109' THEN -2
  WHEN 'TGS-2026061312' THEN -1
END
WHERE cp.category_id = @cl AND @cl IS NOT NULL
  AND p.sku IN ('TGS-2025052468','TGS-2023018659','TGS-2020503109','TGS-2026061312');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025052468' THEN -4
  WHEN 'TGS-2023018659' THEN -3
  WHEN 'TGS-2020503109' THEN -2
  WHEN 'TGS-2026061312' THEN -1
END
WHERE i.category_id = @cl AND @cl IS NOT NULL
  AND p.sku IN ('TGS-2025052468','TGS-2023018659','TGS-2020503109','TGS-2026061312');
