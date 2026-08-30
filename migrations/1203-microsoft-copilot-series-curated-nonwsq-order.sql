-- 1203: Microsoft Copilot Series — curated non-WSQ order.
--
-- A) Add 'microsoft-copilot-series' to mmd/category_ordering/curated_url_keys
--    so the nightly sweep (and the post-reindex repair) keep this order
--    instead of re-alphabetising it. WSQ-first is still enforced.
--
-- B) Pin the requested 10-course non-WSQ order at positions 101..110 — after
--    every TGS- course (the 3 WSQ courses are pinned 1..3 by 1190):
--     1. C34    Microsoft 365 Copilot for Excel
--     2. C027   Microsoft 365 Copilot Masterclass
--     3. C734   Copilot for Power BI
--     4. C590   Copilot Studio and Power Automate
--     5. C803   Copilot for Power Apps
--     6. C814   Creating AI Agents and Chatbots with Microsoft Copilot Studio
--     7. C811   PL-7001 Create and manage canvas apps with Power Apps
--     8. C903   PL-7002 Create and Manage Automated Processes by using Power Automate
--     9. C1768  AB-900 Microsoft 365 Copilot and Agent Administration Fundamentals
--    10. C1760  AB-620 Microsoft Certified AI Agent Builder Associate
--
--    These are exactly the category's current non-WSQ members — this is a
--    pure reorder, no membership change. (C814 and C1760 were tied at the
--    same position before this pin.)
--
-- Positive positions only (negative pins die — see 1195). Business-key
-- lookups; SG-only SKUs/url_key (clean partner no-op). Idempotent.

SET @copilot := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1
);

-- ===== A: extend the curated-order exemption =====

UPDATE core_config_data
SET value = CONCAT(value, ',microsoft-copilot-series')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%microsoft-copilot-series%';

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'microsoft-copilot-series'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT * FROM core_config_data) c
  WHERE c.path = 'mmd/category_ordering/curated_url_keys'
    AND c.scope = 'default' AND c.scope_id = 0
);

-- ===== B: pin the curated non-WSQ order (101..110) =====

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C34'    THEN 101
  WHEN 'C027'   THEN 102
  WHEN 'C734'   THEN 103
  WHEN 'C590'   THEN 104
  WHEN 'C803'   THEN 105
  WHEN 'C814'   THEN 106
  WHEN 'C811'   THEN 107
  WHEN 'C903'   THEN 108
  WHEN 'C1768'  THEN 109
  WHEN 'C1760'  THEN 110
END
WHERE cp.category_id = @copilot
  AND p.sku IN (
    'C34', 'C027', 'C734', 'C590', 'C803',
    'C814', 'C811', 'C903', 'C1768', 'C1760'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C34'    THEN 101
  WHEN 'C027'   THEN 102
  WHEN 'C734'   THEN 103
  WHEN 'C590'   THEN 104
  WHEN 'C803'   THEN 105
  WHEN 'C814'   THEN 106
  WHEN 'C811'   THEN 107
  WHEN 'C903'   THEN 108
  WHEN 'C1768'  THEN 109
  WHEN 'C1760'  THEN 110
END
WHERE i.category_id = @copilot
  AND p.sku IN (
    'C34', 'C027', 'C734', 'C590', 'C803',
    'C814', 'C811', 'C903', 'C1768', 'C1760'
  );
