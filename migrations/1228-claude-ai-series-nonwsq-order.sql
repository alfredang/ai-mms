-- 1228: Pin the requested non-WSQ order in the Claude AI Series:
--   1. C1417 Claude Code Masterclass
--   2. C1382 Claude Cowork Masterclass
--   3. C201  Claude Design Masterclass
--   4. C197  Claude Microsoft 365 Masterclass
--   5. C141  Claude Code for Digital Marketing   (converted by 1212)
--   6. C744  Claude Certified Associate - Foundations Certification
--   7. C437  Claude Certified Architect - Foundations Certification
--   8. C364  Claude Certified Architect - Professional Certification
--   9. C439  Claude Certified Developer - Foundations Certification
--
-- All nine are already members; this is a pure reorder. Positions 101..109
-- keep them after every WSQ/CASL/IBF course, and the category is already in
-- mmd/category_ordering/curated_url_keys, so the nightly sweep preserves it.
--
-- The CASE covers EVERY non-WSQ member of the category, so no row is left
-- unpinned to drift above the block — see
-- feedback_curated_leftovers_must_be_pinned_not_parked.
--
-- Business-key lookups; SG-only SKUs/url_key (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @claude := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'claude-ai-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C1417' THEN 101
  WHEN 'C1382' THEN 102
  WHEN 'C201'  THEN 103
  WHEN 'C197'  THEN 104
  WHEN 'C141'  THEN 105
  WHEN 'C744'  THEN 106
  WHEN 'C437'  THEN 107
  WHEN 'C364'  THEN 108
  WHEN 'C439'  THEN 109
END
WHERE cp.category_id = @claude
  AND p.sku IN ('C1417','C1382','C201','C197','C141','C744','C437','C364','C439');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C1417' THEN 101
  WHEN 'C1382' THEN 102
  WHEN 'C201'  THEN 103
  WHEN 'C197'  THEN 104
  WHEN 'C141'  THEN 105
  WHEN 'C744'  THEN 106
  WHEN 'C437'  THEN 107
  WHEN 'C364'  THEN 108
  WHEN 'C439'  THEN 109
END
WHERE i.category_id = @claude
  AND p.sku IN ('C1417','C1382','C201','C197','C141','C744','C437','C364','C439');
