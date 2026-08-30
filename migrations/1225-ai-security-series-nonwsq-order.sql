-- 1225: Pin the requested non-WSQ order in the AI Security Series:
--   1. C434  AI for Cyber Security
--   2. C1440 AI Security and Governance   (renamed by 1224)
--   3. C28   AI Agent Security            (converted by 1223)
--   4. C1750 CompTIA SecAI+ Training
--
-- All four are already members; this is a pure reorder. Positions 101..104
-- keep them after every WSQ/CASL/IBF course, and the category is already in
-- mmd/category_ordering/curated_url_keys (added by 1193), so the nightly
-- sweep preserves this order.
--
-- The CASE covers EVERY non-WSQ member of the category, so no row is left
-- unpinned to drift above the block — see
-- feedback_curated_leftovers_must_be_pinned_not_parked.
--
-- Business-key lookups; SG-only SKUs/url_key (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @security := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-security-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C434'  THEN 101
  WHEN 'C1440' THEN 102
  WHEN 'C28'   THEN 103
  WHEN 'C1750' THEN 104
END
WHERE cp.category_id = @security
  AND p.sku IN ('C434', 'C1440', 'C28', 'C1750');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C434'  THEN 101
  WHEN 'C1440' THEN 102
  WHEN 'C28'   THEN 103
  WHEN 'C1750' THEN 104
END
WHERE i.category_id = @security
  AND p.sku IN ('C434', 'C1440', 'C28', 'C1750');
