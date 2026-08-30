-- 1237: Remove "AI Vibe Coding for Python Financial Analysis" (C188) from
-- the AI for Machine Learning subcategory; it belongs under AI for Finance.
--
-- C188 is ALREADY a member of AI for Finance (added by 1213 and pinned there
-- after the WSQ/CASL/IBF block), so the INSERT below is a defensive no-op and
-- its Finance position is left untouched. The real change is the removal from
-- AI for Machine Learning.
--
-- The AI for Machine Learning curated non-WSQ block is re-pinned without
-- C188 so the remaining courses stay contiguous, with every non-WSQ member
-- covered by the CASE so none drifts above the block (see
-- feedback_curated_leftovers_must_be_pinned_not_parked).
--
-- Positions stay in the 101+ band, after every WSQ/CASL/IBF course; both
-- categories carry a curated non-WSQ order so the nightly sweep preserves it.
-- C188 keeps its AI Vibe Coding Series and AI Applications Series listings.
--
-- Business-key lookups; SG-only SKUs/url_keys (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @ml := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1);
SET @finance := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-finance-courses' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Leave AI for Machine Learning.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @ml
  AND p.sku = 'C188';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @ml
  AND p.sku = 'C188';

-- ---------------------------------------------------------------------------
-- 2) Defensive: ensure AI for Finance membership (it already holds it).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @finance, p.entity_id, 106
FROM catalog_product_entity p
WHERE @finance IS NOT NULL
  AND p.sku = 'C188';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @finance, p.entity_id, 106, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @finance IS NOT NULL
  AND p.sku = 'C188'
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 3) Re-pin the AI for Machine Learning non-WSQ block without C188.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C430'  THEN 101
  WHEN 'C592'  THEN 102
  WHEN 'C193'  THEN 103
  WHEN 'C539'  THEN 104
  WHEN 'C1071' THEN 105
  WHEN 'C926'  THEN 106
  WHEN 'C1759' THEN 107
  WHEN 'C1762' THEN 108
  WHEN 'C19'   THEN 109
  WHEN 'C1330' THEN 110
  WHEN 'C279'  THEN 111
  WHEN 'C476'  THEN 112
  WHEN 'C1750' THEN 113
  WHEN 'C820'  THEN 114
END
WHERE cp.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C539','C1071','C926','C1759','C1762',
                'C19','C1330','C279','C476','C1750','C820');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C430'  THEN 101
  WHEN 'C592'  THEN 102
  WHEN 'C193'  THEN 103
  WHEN 'C539'  THEN 104
  WHEN 'C1071' THEN 105
  WHEN 'C926'  THEN 106
  WHEN 'C1759' THEN 107
  WHEN 'C1762' THEN 108
  WHEN 'C19'   THEN 109
  WHEN 'C1330' THEN 110
  WHEN 'C279'  THEN 111
  WHEN 'C476'  THEN 112
  WHEN 'C1750' THEN 113
  WHEN 'C820'  THEN 114
END
WHERE i.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C539','C1071','C926','C1759','C1762',
                'C19','C1330','C279','C476','C1750','C820');
