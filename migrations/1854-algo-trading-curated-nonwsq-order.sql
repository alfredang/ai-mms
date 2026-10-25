-- 1854: Curated non-WSQ (C-prefix) order in the Investing & Trading category
-- (url_key algorithmic-trading-quantitative-analysis-courses), per the owner's
-- requested sequence, after the two TGS- rows at positions 1-2:
--   3. C207  — AI for Finance
--   4. C728  — AI Powered Quantitative Trading Fundamentals
--   5. C177  — AI Agents for Stock Trading (to be renamed "Build a Multi AI
--              Agents Workflow for Stock Trading")
--   6. C1164 — Multi Agents System for Algorithmic Trading (disabled, 1853)
--
-- Two halves, both required (same pattern as 1841):
--   1. Register the category in mmd/category_ordering/curated_url_keys, or the
--      nightly MMD_RoleManager_Model_Cron_CategoryOrdering sweep re-alphabetises
--      the C-block within a day. WSQ-first is still enforced either way.
--   2. Write the positions.
--
-- Both the storefront-facing index and the admin-facing base table are written.
-- SG-only (partners keep the alphabetical rule). Idempotent.

-- 1. curated allow-list — append idempotently, preserving whatever is already there.
UPDATE core_config_data
   SET value = CONCAT(value, ',algorithmic-trading-quantitative-analysis-courses')
 WHERE path = 'mmd/category_ordering/curated_url_keys'
   AND FIND_IN_SET('algorithmic-trading-quantitative-analysis-courses', value) = 0
   AND @mms_instance = 'SG';

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'algorithmic-trading-quantitative-analysis-courses'
  FROM DUAL
 WHERE @mms_instance = 'SG'
   AND NOT EXISTS (SELECT 1 FROM (SELECT 1 FROM core_config_data
        WHERE path = 'mmd/category_ordering/curated_url_keys' LIMIT 1) x);

-- 2. the curated positions.
SET @algo_trading_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'algorithmic-trading-quantitative-analysis-courses'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE TRIM(p.sku)
  WHEN 'C207' THEN 3
  WHEN 'C728' THEN 4
  WHEN 'C177' THEN 5
  WHEN 'C1164' THEN 6
END
WHERE cp.category_id = @algo_trading_category
  AND TRIM(p.sku) IN ('C207', 'C728', 'C177', 'C1164')
  AND @mms_instance = 'SG';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE TRIM(p.sku)
  WHEN 'C207' THEN 3
  WHEN 'C728' THEN 4
  WHEN 'C177' THEN 5
  WHEN 'C1164' THEN 6
END
WHERE i.category_id = @algo_trading_category
  AND TRIM(p.sku) IN ('C207', 'C728', 'C177', 'C1164')
  AND @mms_instance = 'SG';
