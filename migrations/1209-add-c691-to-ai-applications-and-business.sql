-- 1209: Add "Business Transformation with OpenClaw Digital Employees" (C691)
-- to the AI Applications Series and its AI for Business subcategory.
--
-- This is an ADD, not a move: C691 keeps its AI Agents Series membership.
--
-- Placement: immediately after "Business Transformation with AI Agents"
-- (C997) in both listings — same business-transformation theme — which means
-- shifting the rows below it down by one. Both categories carry a curated
-- non-WSQ order (mmd/category_ordering/curated_url_keys), so these positions
-- survive the nightly sweep.
--
-- Positions stay in the 101+ non-WSQ band, after every WSQ/CASL/IBF course.
-- Business-key lookups; SG-only SKU/url_keys (clean partner no-op).
-- Idempotent: the pin block below is absolute, so re-running is a no-op.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @apps := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-applications-series' LIMIT 1
);
SET @business := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-for-business' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- 1) Assign to both categories (base + index mirror).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.id, p.entity_id, 9999
FROM catalog_product_entity p
JOIN (SELECT @apps AS id UNION ALL SELECT @business) c ON c.id IS NOT NULL
WHERE p.sku = 'C691';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT c.id, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN (SELECT @apps AS id UNION ALL SELECT @business) c ON c.id IS NOT NULL
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'C691'
GROUP BY c.id, p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 2) AI for Business — re-pin the curated non-WSQ order with C691 inserted
--    after C997.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C798'  THEN 101
  WHEN 'C997'  THEN 102
  WHEN 'C691'  THEN 103
  WHEN 'C840'  THEN 104
  WHEN 'C831'  THEN 105
  WHEN 'C165'  THEN 106
  WHEN 'C398'  THEN 107
  WHEN 'C155'  THEN 108
  WHEN 'C817'  THEN 109
  WHEN 'C864'  THEN 110
  WHEN 'C711'  THEN 111
  WHEN 'C1756' THEN 112
END
WHERE cp.category_id = @business
  AND p.sku IN ('C798','C997','C691','C840','C831','C165','C398','C155','C817','C864','C711','C1756');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C798'  THEN 101
  WHEN 'C997'  THEN 102
  WHEN 'C691'  THEN 103
  WHEN 'C840'  THEN 104
  WHEN 'C831'  THEN 105
  WHEN 'C165'  THEN 106
  WHEN 'C398'  THEN 107
  WHEN 'C155'  THEN 108
  WHEN 'C817'  THEN 109
  WHEN 'C864'  THEN 110
  WHEN 'C711'  THEN 111
  WHEN 'C1756' THEN 112
END
WHERE i.category_id = @business
  AND p.sku IN ('C798','C997','C691','C840','C831','C165','C398','C155','C817','C864','C711','C1756');

-- ---------------------------------------------------------------------------
-- 3) AI Applications Series parent — same insert inside the Business group,
--    shifting the later groups (Finance, Healthcare, Robotics, ML) down one.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C798'  THEN 101
  WHEN 'C997'  THEN 102
  WHEN 'C691'  THEN 103
  WHEN 'C840'  THEN 104
  WHEN 'C831'  THEN 105
  WHEN 'C165'  THEN 106
  WHEN 'C398'  THEN 107
  WHEN 'C155'  THEN 108
  WHEN 'C817'  THEN 109
  WHEN 'C864'  THEN 110
  WHEN 'C711'  THEN 111
  WHEN 'C1756' THEN 112
  WHEN 'C104'  THEN 113
  WHEN 'C207'  THEN 114
  WHEN 'C057'  THEN 115
  WHEN 'C177'  THEN 116
  WHEN 'C1164' THEN 117
  WHEN 'C1018' THEN 118
  WHEN 'C852'  THEN 119
  WHEN 'C430'  THEN 120
  WHEN 'C592'  THEN 121
  WHEN 'C188'  THEN 122
  WHEN 'C539'  THEN 123
  WHEN 'C1071' THEN 124
  WHEN 'C926'  THEN 125
  WHEN 'C1759' THEN 126
  WHEN 'C19'   THEN 127
  WHEN 'C1330' THEN 128
  WHEN 'C279'  THEN 129
  WHEN 'C476'  THEN 130
  WHEN 'C1750' THEN 131
  WHEN 'C820'  THEN 132
END
WHERE cp.category_id = @apps
  AND p.sku IN ('C798','C997','C691','C840','C831','C165','C398','C155','C817','C864','C711','C1756',
                'C104','C207','C057','C177','C1164','C1018','C852',
                'C430','C592','C188','C539','C1071','C926','C1759','C19','C1330','C279','C476','C1750','C820');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C798'  THEN 101
  WHEN 'C997'  THEN 102
  WHEN 'C691'  THEN 103
  WHEN 'C840'  THEN 104
  WHEN 'C831'  THEN 105
  WHEN 'C165'  THEN 106
  WHEN 'C398'  THEN 107
  WHEN 'C155'  THEN 108
  WHEN 'C817'  THEN 109
  WHEN 'C864'  THEN 110
  WHEN 'C711'  THEN 111
  WHEN 'C1756' THEN 112
  WHEN 'C104'  THEN 113
  WHEN 'C207'  THEN 114
  WHEN 'C057'  THEN 115
  WHEN 'C177'  THEN 116
  WHEN 'C1164' THEN 117
  WHEN 'C1018' THEN 118
  WHEN 'C852'  THEN 119
  WHEN 'C430'  THEN 120
  WHEN 'C592'  THEN 121
  WHEN 'C188'  THEN 122
  WHEN 'C539'  THEN 123
  WHEN 'C1071' THEN 124
  WHEN 'C926'  THEN 125
  WHEN 'C1759' THEN 126
  WHEN 'C19'   THEN 127
  WHEN 'C1330' THEN 128
  WHEN 'C279'  THEN 129
  WHEN 'C476'  THEN 130
  WHEN 'C1750' THEN 131
  WHEN 'C820'  THEN 132
END
WHERE i.category_id = @apps
  AND p.sku IN ('C798','C997','C691','C840','C831','C165','C398','C155','C817','C864','C711','C1756',
                'C104','C207','C057','C177','C1164','C1018','C852',
                'C430','C592','C188','C539','C1071','C926','C1759','C19','C1330','C279','C476','C1750','C820');
