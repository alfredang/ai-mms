-- 1213: Cross-list AI Vibe Coding courses into the AI Applications Series
-- subcategories (they stay in the AI Vibe Coding Series).
--
-- AI for Finance   <- C188 Python Financial Analysis, C544 Blockchain,
--                     C976 Smart Contract, C728 Algorithmic Trading,
--                     C1319 Crypto Tokens
-- AI for ML        <- C193 Python Data Analysis, C430 Machine Learning,
--                     C539 PyTorch Deep Learning, C592 Computer Vision
--                     (C430/C539/C592 are already members — only C193 is new;
--                      the pin below re-seats all four together.)
--
-- Both subcategories carry a curated non-WSQ order, so each new course is
-- pinned explicitly rather than left to drift. Positions stay in the 101+
-- band, after every WSQ/CASL/IBF course.
--
-- The courses are added to the AI Applications Series parent listing too, so
-- they appear on that page in their subcategory group.
--
-- SG-guarded; C-prefix SKUs and these url_keys are SG-only (partner no-op).
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);
SET @finance := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-finance-courses' LIMIT 1);
SET @ml := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Assign to the subcategories and to the parent listing.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @finance, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @finance IS NOT NULL AND @is_sg > 0
  AND p.sku IN ('C188', 'C544', 'C976', 'C728', 'C1319');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @finance, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @finance IS NOT NULL AND @is_sg > 0
  AND p.sku IN ('C188', 'C544', 'C976', 'C728', 'C1319')
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @ml, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @ml IS NOT NULL AND @is_sg > 0
  AND p.sku IN ('C193', 'C430', 'C539', 'C592');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @ml, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @ml IS NOT NULL AND @is_sg > 0
  AND p.sku IN ('C193', 'C430', 'C539', 'C592')
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @apps, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @apps IS NOT NULL AND @is_sg > 0
  AND p.sku IN ('C188', 'C544', 'C976', 'C728', 'C1319', 'C193', 'C430', 'C539', 'C592');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @apps, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @apps IS NOT NULL AND @is_sg > 0
  AND p.sku IN ('C188', 'C544', 'C976', 'C728', 'C1319', 'C193', 'C430', 'C539', 'C592')
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 2) AI for Finance — existing five, then the five Vibe Coding additions.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C104'  THEN 101
  WHEN 'C207'  THEN 102
  WHEN 'C057'  THEN 103
  WHEN 'C177'  THEN 104
  WHEN 'C1164' THEN 105
  WHEN 'C188'  THEN 106
  WHEN 'C544'  THEN 107
  WHEN 'C976'  THEN 108
  WHEN 'C728'  THEN 109
  WHEN 'C1319' THEN 110
END
WHERE cp.category_id = @finance
  AND p.sku IN ('C104','C207','C057','C177','C1164','C188','C544','C976','C728','C1319');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C104'  THEN 101
  WHEN 'C207'  THEN 102
  WHEN 'C057'  THEN 103
  WHEN 'C177'  THEN 104
  WHEN 'C1164' THEN 105
  WHEN 'C188'  THEN 106
  WHEN 'C544'  THEN 107
  WHEN 'C976'  THEN 108
  WHEN 'C728'  THEN 109
  WHEN 'C1319' THEN 110
END
WHERE i.category_id = @finance
  AND p.sku IN ('C104','C207','C057','C177','C1164','C188','C544','C976','C728','C1319');

-- ---------------------------------------------------------------------------
-- 3) AI for Machine Learning — the four Vibe Coding courses lead the non-WSQ
--    block (C193 joins them), then the rest of the requested 1206 order.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C430'  THEN 101
  WHEN 'C592'  THEN 102
  WHEN 'C193'  THEN 103
  WHEN 'C188'  THEN 104
  WHEN 'C539'  THEN 105
  WHEN 'C1071' THEN 106
  WHEN 'C926'  THEN 107
  WHEN 'C1759' THEN 108
  WHEN 'C19'   THEN 109
  WHEN 'C1330' THEN 110
  WHEN 'C279'  THEN 111
END
WHERE cp.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C19','C1330','C279');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C430'  THEN 101
  WHEN 'C592'  THEN 102
  WHEN 'C193'  THEN 103
  WHEN 'C188'  THEN 104
  WHEN 'C539'  THEN 105
  WHEN 'C1071' THEN 106
  WHEN 'C926'  THEN 107
  WHEN 'C1759' THEN 108
  WHEN 'C19'   THEN 109
  WHEN 'C1330' THEN 110
  WHEN 'C279'  THEN 111
END
WHERE i.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C19','C1330','C279');

-- ---------------------------------------------------------------------------
-- 4) Parent listing — slot the additions into their subcategory groups:
--    Finance group ends at 117, Machine Learning group runs from 122.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C544'  THEN 118
  WHEN 'C976'  THEN 119
  WHEN 'C728'  THEN 120
  WHEN 'C1319' THEN 121
  WHEN 'C193'  THEN 134
END
WHERE cp.category_id = @apps
  AND p.sku IN ('C544','C976','C728','C1319','C193');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C544'  THEN 118
  WHEN 'C976'  THEN 119
  WHEN 'C728'  THEN 120
  WHEN 'C1319' THEN 121
  WHEN 'C193'  THEN 134
END
WHERE i.category_id = @apps
  AND p.sku IN ('C544','C976','C728','C1319','C193');

-- ---------------------------------------------------------------------------
-- 5) Push the ML members not in the requested order (CompTIA DataAI / SecAI+,
--    AI for HR) below the pinned block so the requested order leads.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = 200 + cp.product_id
WHERE cp.category_id = @ml
  AND p.sku NOT LIKE 'TGS-%'
  AND p.sku NOT IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C19','C1330','C279');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = 200 + i.product_id
WHERE i.category_id = @ml
  AND p.sku NOT LIKE 'TGS-%'
  AND p.sku NOT IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C19','C1330','C279');
