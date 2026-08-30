-- 1241: Pin the requested non-WSQ order in the AI for HR subcategory:
--   1. C820 AI for HR
--   2. C169 Generative AI for Interviewing                (converted by 1240)
--   3. C811 Job Assessment and Redesign for AI Adoption   (converted by 1210)
--   4. C903 Workplace Evaluation and Innovation for AI Adoption (converted by 1220)
--
-- Pure reorder — all four are already members and are the category's ONLY
-- non-WSQ rows, so the CASE covers every one and none can drift above the
-- block (see feedback_curated_leftovers_must_be_pinned_not_parked).
--
-- Positions 101..104 keep them after the two WSQ courses pinned at 1..2 by
-- 1235 (WSQ - Agentic AI for HR, WSQ - Generative AI for Interviewing).
--
-- Business-key lookups; SG-only SKUs/url_key (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @hr := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-for-hr-courses' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C820' THEN 101
  WHEN 'C169' THEN 102
  WHEN 'C811' THEN 103
  WHEN 'C903' THEN 104
END
WHERE cp.category_id = @hr
  AND p.sku IN ('C820', 'C169', 'C811', 'C903');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C820' THEN 101
  WHEN 'C169' THEN 102
  WHEN 'C811' THEN 103
  WHEN 'C903' THEN 104
END
WHERE i.category_id = @hr
  AND p.sku IN ('C820', 'C169', 'C811', 'C903');
