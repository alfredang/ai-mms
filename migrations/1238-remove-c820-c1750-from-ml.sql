-- 1238: Remove two non-WSQ courses from the AI for Machine Learning
-- subcategory; they belong in the categories they already sit in:
--   C820  AI for HR                -> already in AI for HR (378)
--   C1750 CompTIA SecAI+ Training  -> already in the AI Security Series (214)
--
-- Both destination memberships already exist, so the defensive INSERTs below
-- are no-ops and their positions there are left untouched. The real change is
-- the removal from AI for Machine Learning, where they were the last two
-- non-WSQ rows (113/114) — leftovers from when the ML subcategory absorbed
-- the hidden Computer Vision / RL / HR members back in 1206.
--
-- After this the ML non-WSQ block is exactly the curated list (101..112) with
-- every member covered, so nothing drifts above it (see
-- feedback_curated_leftovers_must_be_pinned_not_parked).
--
-- Business-key lookups; SG-only SKUs/url_keys (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @ml := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1);
SET @hr := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);
SET @security := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-security-series' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Leave AI for Machine Learning.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @ml
  AND p.sku IN ('C820', 'C1750');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @ml
  AND p.sku IN ('C820', 'C1750');

-- ---------------------------------------------------------------------------
-- 2) Defensive: ensure the destination memberships (both already exist).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @hr, p.entity_id, 104
FROM catalog_product_entity p
WHERE @hr IS NOT NULL AND p.sku = 'C820';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @hr, p.entity_id, 104, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @hr IS NOT NULL AND p.sku = 'C820'
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @security, p.entity_id, 105
FROM catalog_product_entity p
WHERE @security IS NOT NULL AND p.sku = 'C1750';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @security, p.entity_id, 105, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @security IS NOT NULL AND p.sku = 'C1750'
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 3) Re-pin the AI for Machine Learning non-WSQ block (now 12 courses).
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
END
WHERE cp.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C539','C1071','C926','C1759','C1762',
                'C19','C1330','C279','C476');

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
END
WHERE i.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C539','C1071','C926','C1759','C1762',
                'C19','C1330','C279','C476');
