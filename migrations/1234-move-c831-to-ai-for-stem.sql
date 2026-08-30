-- 1234: Move "AI for Early Childhood" (C831) from the AI for Business
-- subcategory to AI for STEM.
--
-- AI for STEM has been empty since 1206 created it — this is its first
-- course. C831 keeps its AI Applications Series parent listing (and All
-- Courses / Infocomm Technology / AI Courses); only the subcategory changes.
--
-- The AI for Business curated non-WSQ block is re-pinned without C831 so the
-- remaining courses stay contiguous, and every non-WSQ member is covered by
-- the CASE so none drifts above the block (see
-- feedback_curated_leftovers_must_be_pinned_not_parked).
--
-- Positions stay in the 101+ band, after every WSQ/CASL/IBF course; both
-- categories carry a curated non-WSQ order so the nightly sweep preserves it.
--
-- Business-key lookups; SG-only SKU/url_keys (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @business := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-business' LIMIT 1);
SET @stem := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-stem' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Leave AI for Business.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @business
  AND p.sku = 'C831';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @business
  AND p.sku = 'C831';

-- ---------------------------------------------------------------------------
-- 2) Join AI for STEM (first course in the category).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @stem, p.entity_id, 101
FROM catalog_product_entity p
WHERE @stem IS NOT NULL
  AND p.sku = 'C831';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @stem, p.entity_id, 101, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @stem IS NOT NULL
  AND p.sku = 'C831'
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = 101
WHERE cp.category_id = @stem AND p.sku = 'C831';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = 101
WHERE i.category_id = @stem AND p.sku = 'C831';

-- ---------------------------------------------------------------------------
-- 3) Re-pin the AI for Business non-WSQ block without C831.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C798'  THEN 101
  WHEN 'C997'  THEN 102
  WHEN 'C691'  THEN 103
  WHEN 'C840'  THEN 104
  WHEN 'C155'  THEN 105
  WHEN 'C817'  THEN 106
  WHEN 'C864'  THEN 107
  WHEN 'C711'  THEN 108
  WHEN 'C1756' THEN 109
END
WHERE cp.category_id = @business
  AND p.sku IN ('C798','C997','C691','C840','C155','C817','C864','C711','C1756');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C798'  THEN 101
  WHEN 'C997'  THEN 102
  WHEN 'C691'  THEN 103
  WHEN 'C840'  THEN 104
  WHEN 'C155'  THEN 105
  WHEN 'C817'  THEN 106
  WHEN 'C864'  THEN 107
  WHEN 'C711'  THEN 108
  WHEN 'C1756' THEN 109
END
WHERE i.category_id = @business
  AND p.sku IN ('C798','C997','C691','C840','C155','C817','C864','C711','C1756');
