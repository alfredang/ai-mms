-- 1266: WSQ Data Analytics & Data Visualization (url_key
-- 'wsq-data-analytics-wsq-courses') — move three courses out, add one course to
-- WSQ Agentic AI Courses, and pin the requested listing order.
--
-- Moves OUT of Data Analytics:
--   TGS-2023018659  WSQ - Claude Cowork for Digital Marketing   -> WSQ Digital Marketing
--   TGS-2022017520  WSQ - Agentic AI for Market Research        -> WSQ Digital Marketing
--   TGS-2021010367  WSQ - Harness and Loop Engineering for AI Agents -> WSQ Agentic AI
-- The two Digital Marketing courses are ALREADY members of that category, so
-- for them this is only the removal from Data Analytics.
--
-- Also ADDS to WSQ Agentic AI Courses (staying in Data Analytics as well):
--   TGS-2023041022  WSQ - Data Analytics and AI for Healthcare
--
-- Then pins the requested Data Analytics order. TGS-2020503264 (Data Mining and
-- Machine Learning Fundamentals, added in 1264) was not named in the requested
-- sequence, so it is placed last rather than dropped.
--
-- Negative positions keep the pinned block ahead of anything unpinned; the daily
-- ordering sweep preserves TGS relative order. Business-key lookups only.
-- Idempotent.

SET @da  := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @dm  := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-digital-marketing-courses' LIMIT 1);
SET @ag  := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-agentic-ai-courses' LIMIT 1);

-- 1. Ensure the movers exist in their destination categories -----------------

SET @dm_pos := (SELECT COALESCE(MAX(position),0) FROM catalog_category_product WHERE category_id=@dm);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @dm, p.entity_id, @dm_pos + 1
FROM catalog_product_entity p
WHERE p.sku IN ('TGS-2023018659','TGS-2022017520') AND @dm IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @dm, p.entity_id, @dm_pos + 1, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id=p.entity_id AND i.store_id=s.store_id
WHERE p.sku IN ('TGS-2023018659','TGS-2022017520') AND @dm IS NOT NULL
GROUP BY p.entity_id, s.store_id;

SET @ag_pos := (SELECT COALESCE(MAX(position),0) FROM catalog_category_product WHERE category_id=@ag);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @ag, p.entity_id, @ag_pos + 1
FROM catalog_product_entity p
WHERE p.sku IN ('TGS-2021010367','TGS-2023041022') AND @ag IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @ag, p.entity_id, @ag_pos + 1, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id=p.entity_id AND i.store_id=s.store_id
WHERE p.sku IN ('TGS-2021010367','TGS-2023041022') AND @ag IS NOT NULL
GROUP BY p.entity_id, s.store_id;

-- 2. Remove the three moved courses from Data Analytics ----------------------
-- (Healthcare is NOT removed — it was an "also add", not a move.)

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @da AND @da IS NOT NULL
  AND p.sku IN ('TGS-2023018659','TGS-2022017520','TGS-2021010367');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @da AND @da IS NOT NULL
  AND p.sku IN ('TGS-2023018659','TGS-2022017520','TGS-2021010367');

-- 3. Pin the requested Data Analytics order ----------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026064861' THEN -16  -- CASL - Data Analytics with Excel
  WHEN 'TGS-2020505317' THEN -15  -- WSQ - Statistical Data Analysis with Excel for Beginners
  WHEN 'TGS-2021010195' THEN -14  -- WSQ - Create Interactive Dashboard Using Excel
  WHEN 'TGS-2020505444' THEN -13  -- WSQ - Data Analytics and Visualization with Power BI
  WHEN 'TGS-2026064177' THEN -12  -- CASL - Excel Power Query and Power Pivot
  WHEN 'TGS-2020503177' THEN -11  -- WSQ - Data Visualisation with Tableau
  WHEN 'TGS-2020505550' THEN -10  -- WSQ - Data Storytelling with Tableau
  WHEN 'TGS-2025053175' THEN  -9  -- WSQ - Tableau Certified Desktop Specialist Training
  WHEN 'TGS-2025053206' THEN  -8  -- WSQ - Tableau Certified Data Analyst Training
  WHEN 'TGS-2020504082' THEN  -7  -- WSQ - Data Analytics and Visualization with Python
  WHEN 'TGS-2026064715' THEN  -6  -- CASL - Python Text Mining and Analytics
  WHEN 'TGS-2026064475' THEN  -5  -- CASL - Data Analytics and Visualization with R
  WHEN 'TGS-2023041022' THEN  -4  -- WSQ - Data Analytics and AI for Healthcare
  WHEN 'TGS-2025053209' THEN  -3  -- WSQ - AWS Certified Data Engineer Associate Training
  WHEN 'TGS-2025052344' THEN  -2  -- WSQ - Mastering Elasticsearch and Kibana
  WHEN 'TGS-2020503264' THEN  -1  -- WSQ - Data Mining and ML Fundamentals (not in requested list)
END
WHERE cp.category_id = @da AND @da IS NOT NULL
  AND p.sku IN ('TGS-2026064861','TGS-2020505317','TGS-2021010195','TGS-2020505444',
                'TGS-2026064177','TGS-2020503177','TGS-2020505550','TGS-2025053175',
                'TGS-2025053206','TGS-2020504082','TGS-2026064715','TGS-2026064475',
                'TGS-2023041022','TGS-2025053209','TGS-2025052344','TGS-2020503264');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026064861' THEN -16
  WHEN 'TGS-2020505317' THEN -15
  WHEN 'TGS-2021010195' THEN -14
  WHEN 'TGS-2020505444' THEN -13
  WHEN 'TGS-2026064177' THEN -12
  WHEN 'TGS-2020503177' THEN -11
  WHEN 'TGS-2020505550' THEN -10
  WHEN 'TGS-2025053175' THEN  -9
  WHEN 'TGS-2025053206' THEN  -8
  WHEN 'TGS-2020504082' THEN  -7
  WHEN 'TGS-2026064715' THEN  -6
  WHEN 'TGS-2026064475' THEN  -5
  WHEN 'TGS-2023041022' THEN  -4
  WHEN 'TGS-2025053209' THEN  -3
  WHEN 'TGS-2025052344' THEN  -2
  WHEN 'TGS-2020503264' THEN  -1
END
WHERE i.category_id = @da AND @da IS NOT NULL
  AND p.sku IN ('TGS-2026064861','TGS-2020505317','TGS-2021010195','TGS-2020505444',
                'TGS-2026064177','TGS-2020503177','TGS-2020505550','TGS-2025053175',
                'TGS-2025053206','TGS-2020504082','TGS-2026064715','TGS-2026064475',
                'TGS-2023041022','TGS-2025053209','TGS-2025052344','TGS-2020503264');
