-- 1229: Pin the requested non-WSQ order in the Codex AI Series:
--   1. C989 Codex Masterclass
--   2. C427 Codex for Work Automation
--   3. C818 Codex for Digital Marketing   (converted by 1212)
--
-- All three are already members and are the category's ONLY non-WSQ rows, so
-- this is a pure reorder with every non-WSQ member covered by the CASE — no
-- row is left unpinned to drift above the block (see
-- feedback_curated_leftovers_must_be_pinned_not_parked).
--
-- Positions 101..103 keep them after the WSQ course, and the category is
-- already in mmd/category_ordering/curated_url_keys (added by 1201), so the
-- nightly sweep preserves this order.
--
-- Business-key lookups; SG-only SKUs/url_key (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @codex := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'codex-ai-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C989' THEN 101
  WHEN 'C427' THEN 102
  WHEN 'C818' THEN 103
END
WHERE cp.category_id = @codex
  AND p.sku IN ('C989', 'C427', 'C818');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C989' THEN 101
  WHEN 'C427' THEN 102
  WHEN 'C818' THEN 103
END
WHERE i.category_id = @codex
  AND p.sku IN ('C989', 'C427', 'C818');
