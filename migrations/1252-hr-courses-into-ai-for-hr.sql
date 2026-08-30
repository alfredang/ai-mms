-- 1252: Add two non-WSQ courses to the AI for HR subcategory:
--   C1065 AI for Performance Management
--   C1178 AI for Talent Management
--
-- Both are enabled and were in no AI series at all; they keep every existing
-- category membership (this is an add, not a move).
--
-- They are appended after the existing non-WSQ block, which keeps the 1241
-- order plus the two conversions added since:
--   101 C820 AI for HR
--   102 C169 Generative AI for Interviewing
--   103 C811 Job Assessment and Redesign for AI Adoption
--   104 C903 Workplace Evaluation and Innovation for AI Adoption
--   105 C178 Job Redesign for Managing AI Agents
--   106 C1065 AI for Performance Management      (new)
--   107 C1178 AI for Talent Management           (new)
--
-- The two WSQ courses stay pinned at 1..2. Every non-WSQ member is covered by
-- the CASE so none drifts above the block (see
-- feedback_curated_leftovers_must_be_pinned_not_parked).
--
-- Business-key lookups; SG-only SKUs/url_key (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @hr := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-for-hr-courses' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- 1) Assign both courses (base + index mirror).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @hr, p.entity_id,
       CASE p.sku WHEN 'C1065' THEN 106 WHEN 'C1178' THEN 107 END
FROM catalog_product_entity p
WHERE @hr IS NOT NULL
  AND p.sku IN ('C1065', 'C1178');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @hr, p.entity_id,
       CASE p.sku WHEN 'C1065' THEN 106 WHEN 'C1178' THEN 107 END,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @hr IS NOT NULL
  AND p.sku IN ('C1065', 'C1178')
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 2) Re-pin the full non-WSQ block with the two additions at the end.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C820'  THEN 101
  WHEN 'C169'  THEN 102
  WHEN 'C811'  THEN 103
  WHEN 'C903'  THEN 104
  WHEN 'C178'  THEN 105
  WHEN 'C1065' THEN 106
  WHEN 'C1178' THEN 107
END
WHERE cp.category_id = @hr
  AND p.sku IN ('C820', 'C169', 'C811', 'C903', 'C178', 'C1065', 'C1178');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C820'  THEN 101
  WHEN 'C169'  THEN 102
  WHEN 'C811'  THEN 103
  WHEN 'C903'  THEN 104
  WHEN 'C178'  THEN 105
  WHEN 'C1065' THEN 106
  WHEN 'C1178' THEN 107
END
WHERE i.category_id = @hr
  AND p.sku IN ('C820', 'C169', 'C811', 'C903', 'C178', 'C1065', 'C1178');
