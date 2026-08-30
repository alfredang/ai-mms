-- 1198: Rename AI Devops Series -> AI Infrastructure Series (new URL + 301),
-- move the "AI for Machine Learning" subcategory under it (was under the
-- AI Applications Series), and move its 12 courses into the series listing:
--
--   /ai-devops-series.html  301->  /ai-infrastructure-series.html
--   Subcategory 'ai-for-machine-learning' reparents 139 -> 250 (flat URLs:
--   a reparent never touches url_key/url_path).
--
--   Pinned order on the AI Infrastructure Series listing (1..12, positive
--   positions per the 1195 rule):
--    1 TGS-2026064713  CASL - Computer Vision for Beginners
--    2 TGS-2020503264  WSQ - Data Mining and Machine Learning Fundamentals for Beginners
--    3 TGS-2026064715  CASL - Python Text Mining and Analytics: Transforming Text
--    4 TGS-2026064608  CASL - Pattern Recognition and Machine Learning with R
--    5 TGS-2026064714  CASL - Practical Reinforcement Learning for Beginners
--    6 TGS-2020505815  WSQ - Building Advanced Machine Learning and AI Solutions with Pytorch
--    7 TGS-2023021100  WSQ - Microsoft Azure AI Fundamentals (AI-900)
--    8 TGS-2023036651  WSQ - Microsoft Certified Azure AI Engineer Associate (AI-102) Training
--    9 TGS-2023036642  WSQ - Microsoft Azure Data Scientist Associate (DP-100)
--   10 TGS-2024049338  WSQ - AWS Certified AI Practitioner Training
--   11 TGS-2024049340  WSQ - AWS Certified Machine Learning Engineer Associate Training
--   12 TGS-2023040476  WSQ - Google Professional Machine Learning Engineer Training
--
--   The 12 are removed from the AI Applications Series direct listing (they
--   live on via the subcategory, now under the Infrastructure series).
--
-- Business-key lookups only; these url_keys exist only on SG (clean partner
-- no-op). Idempotent via COALESCE on the new slug.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_metatitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');

SET @infra := COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value = 'ai-infrastructure-series' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value = 'ai-devops-series' LIMIT 1)
);
SET @ml := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1
);
SET @apps := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1
);
SET @infrapath := (SELECT path FROM catalog_category_entity WHERE entity_id = @infra);

-- ---------------------------------------------------------------------------
-- A) Rename + re-slug the series, 301 the old URL.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_name, 0, @infra, 'AI Infrastructure Series'
FROM dual WHERE @infra IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_urlkey, 0, @infra, 'ai-infrastructure-series'
FROM dual WHERE @infra IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-infrastructure-series.html'
WHERE entity_id = @infra
  AND attribute_id = @a_urlpath
  AND @infra IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metatitle, 0, @infra, 'AI Infrastructure Series'
FROM dual WHERE @infra IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Free the old request path (system + any prior custom row), then 301 it and
-- seat the new system rewrite so the new URL works before any reindex.
DELETE FROM core_url_rewrite
WHERE request_path = 'ai-devops-series.html'
  AND @infra IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/ai-devops-series-301', 'ai-devops-series.html', 'ai-infrastructure-series.html', 0, 'RP'
FROM dual WHERE @infra IS NOT NULL;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('category/', @infra)
  AND store_id = 1
  AND request_path <> 'ai-infrastructure-series.html'
  AND @infra IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, category_id)
SELECT 1, CONCAT('category/', @infra), 'ai-infrastructure-series.html',
       CONCAT('catalog/category/view/id/', @infra), 1, @infra
FROM dual WHERE @infra IS NOT NULL;

-- ---------------------------------------------------------------------------
-- B) Reparent the AI for Machine Learning subcategory under the series.
-- ---------------------------------------------------------------------------

SET @oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @ml);
SET @needs_move := IF(@ml IS NOT NULL AND @infra IS NOT NULL
  AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @ml) <> @infra, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','))
  AND entity_id <> @ml
  AND NOT FIND_IN_SET(entity_id, REPLACE(@infrapath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@infrapath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @infra,
    path = CONCAT(@infrapath, '/', entity_id),
    level = (LENGTH(@infrapath) - LENGTH(REPLACE(@infrapath, '/', ''))) + 1,
    position = 1
WHERE @needs_move = 1
  AND entity_id = @ml;

-- ---------------------------------------------------------------------------
-- C) Course moves: out of the AI Applications Series listing, into the
--    AI Infrastructure Series listing with the pinned order.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @apps
  AND p.sku IN (
    'TGS-2026064713', 'TGS-2020503264', 'TGS-2026064715', 'TGS-2026064608',
    'TGS-2026064714', 'TGS-2020505815', 'TGS-2023021100', 'TGS-2023036651',
    'TGS-2023036642', 'TGS-2024049338', 'TGS-2024049340', 'TGS-2023040476'
  );

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @apps
  AND p.sku IN (
    'TGS-2026064713', 'TGS-2020503264', 'TGS-2026064715', 'TGS-2026064608',
    'TGS-2026064714', 'TGS-2020505815', 'TGS-2023021100', 'TGS-2023036651',
    'TGS-2023036642', 'TGS-2024049338', 'TGS-2024049340', 'TGS-2023040476'
  );

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @infra, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @infra IS NOT NULL
  AND p.sku IN (
    'TGS-2026064713', 'TGS-2020503264', 'TGS-2026064715', 'TGS-2026064608',
    'TGS-2026064714', 'TGS-2020505815', 'TGS-2023021100', 'TGS-2023036651',
    'TGS-2023036642', 'TGS-2024049338', 'TGS-2024049340', 'TGS-2023040476'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @infra, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @infra IS NOT NULL
  AND p.sku IN (
    'TGS-2026064713', 'TGS-2020503264', 'TGS-2026064715', 'TGS-2026064608',
    'TGS-2026064714', 'TGS-2020505815', 'TGS-2023021100', 'TGS-2023036651',
    'TGS-2023036642', 'TGS-2024049338', 'TGS-2024049340', 'TGS-2023040476'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 12
WHERE cp.category_id = @infra
  AND p.sku LIKE 'TGS-%'
  AND cp.position <= 12
  AND p.sku NOT IN (
    'TGS-2026064713', 'TGS-2020503264', 'TGS-2026064715', 'TGS-2026064608',
    'TGS-2026064714', 'TGS-2020505815', 'TGS-2023021100', 'TGS-2023036651',
    'TGS-2023036642', 'TGS-2024049338', 'TGS-2024049340', 'TGS-2023040476'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 12
WHERE i.category_id = @infra
  AND p.sku LIKE 'TGS-%'
  AND i.position <= 12
  AND p.sku NOT IN (
    'TGS-2026064713', 'TGS-2020503264', 'TGS-2026064715', 'TGS-2026064608',
    'TGS-2026064714', 'TGS-2020505815', 'TGS-2023021100', 'TGS-2023036651',
    'TGS-2023036642', 'TGS-2024049338', 'TGS-2024049340', 'TGS-2023040476'
  );

-- Also shift non-TGS rows clear of the pinned range so the listing is clean
-- immediately (the nightly sweep would otherwise interleave them for a day).
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 12
WHERE cp.category_id = @infra
  AND p.sku NOT LIKE 'TGS-%'
  AND cp.position <= 12;

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 12
WHERE i.category_id = @infra
  AND p.sku NOT LIKE 'TGS-%'
  AND i.position <= 12;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026064713' THEN 1
  WHEN 'TGS-2020503264' THEN 2
  WHEN 'TGS-2026064715' THEN 3
  WHEN 'TGS-2026064608' THEN 4
  WHEN 'TGS-2026064714' THEN 5
  WHEN 'TGS-2020505815' THEN 6
  WHEN 'TGS-2023021100' THEN 7
  WHEN 'TGS-2023036651' THEN 8
  WHEN 'TGS-2023036642' THEN 9
  WHEN 'TGS-2024049338' THEN 10
  WHEN 'TGS-2024049340' THEN 11
  WHEN 'TGS-2023040476' THEN 12
END
WHERE cp.category_id = @infra
  AND p.sku IN (
    'TGS-2026064713', 'TGS-2020503264', 'TGS-2026064715', 'TGS-2026064608',
    'TGS-2026064714', 'TGS-2020505815', 'TGS-2023021100', 'TGS-2023036651',
    'TGS-2023036642', 'TGS-2024049338', 'TGS-2024049340', 'TGS-2023040476'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026064713' THEN 1
  WHEN 'TGS-2020503264' THEN 2
  WHEN 'TGS-2026064715' THEN 3
  WHEN 'TGS-2026064608' THEN 4
  WHEN 'TGS-2026064714' THEN 5
  WHEN 'TGS-2020505815' THEN 6
  WHEN 'TGS-2023021100' THEN 7
  WHEN 'TGS-2023036651' THEN 8
  WHEN 'TGS-2023036642' THEN 9
  WHEN 'TGS-2024049338' THEN 10
  WHEN 'TGS-2024049340' THEN 11
  WHEN 'TGS-2023040476' THEN 12
END
WHERE i.category_id = @infra
  AND p.sku IN (
    'TGS-2026064713', 'TGS-2020503264', 'TGS-2026064715', 'TGS-2026064608',
    'TGS-2026064714', 'TGS-2020505815', 'TGS-2023021100', 'TGS-2023036651',
    'TGS-2023036642', 'TGS-2024049338', 'TGS-2024049340', 'TGS-2023040476'
  );

-- ---------------------------------------------------------------------------
-- D) Flat mirror (store 1), guarded; 'DO 0' no-op.
-- ---------------------------------------------------------------------------

SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @sql := IF(@has_flat > 0 AND @infra IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET name = ''AI Infrastructure Series'', url_key = ''ai-infrastructure-series'', url_path = ''ai-infrastructure-series.html'' WHERE entity_id = @infra',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

SET @sql := IF(@has_flat > 0 AND @ml IS NOT NULL AND @infra IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @infra, path = CONCAT(@infrapath, ''/'', entity_id), level = (LENGTH(@infrapath) - LENGTH(REPLACE(@infrapath, ''/'', ''''))) + 1, position = 1 WHERE entity_id = @ml',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;
