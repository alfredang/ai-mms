-- 1196: AI Applications Series restructure.
--
-- A) Repurpose four empty deactivated categories as subcategories of the
--    AI Applications Series (SG-guarded; appended after the existing
--    Computer Vision / Reinforcement Learning children):
--      pos 3  AI for General Applications  (was Game Development, 128)
--      pos 4  AI for Finance               (was Animation, 230)
--      pos 5  AI for Healthcare            (was Google Tag Manager, 235)
--      pos 6  AI for Machine Learning      (was Google Looker Studio, 245)
--
-- B) Move out of the AI Applications Series:
--      -> AI Agents Series      : TGS-2025054471 (Autonomous AI Agents), TGS-2021010367 (Harness and Loop Engineering)
--      -> Generative AI Series  : TGS-2020505925 (Generative AI for Image and Video Creation)
--      -> Multi AI Agents Series: TGS-2024045806 (AutoGen), TGS-2025054471 (Autonomous AI Agents)
--      -> AI Vibe Coding Series : TGS-2024045802, TGS-2019504744, TGS-2019504643
--
-- C) Assign the remaining 21 WSQ/CASL/IBF courses to their subcategory with
--    the requested order, and pin the SAME grouped order (1..21, positive
--    positions per the 1195 rule) on the parent listing.
--
-- Positive pins only (negative pins die within a day - see 1195). Idempotent;
-- clean no-op on partner instances (SG base_url guard + TGS-only SKUs).

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @apps := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1
);
SET @appspath := (SELECT path FROM catalog_category_entity WHERE entity_id = @apps);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_menu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');
SET @a_anchor := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_anchor');
SET @a_metatitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_layout := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'page_layout');

SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

-- ===== A: AI for General Applications (ai-for-general-applications) =====

SET @c_gen_apps := IF(@is_sg > 0 AND @apps IS NOT NULL, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'ai-for-general-applications' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'game-devleopment-courses-in' LIMIT 1)
), NULL);

SET @oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @c_gen_apps);
SET @needs_move := IF(@c_gen_apps IS NOT NULL AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c_gen_apps) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','))
  AND entity_id <> @c_gen_apps
  AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1,
    position = 3
WHERE entity_id = @c_gen_apps
  AND @c_gen_apps IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_name, 0, @c_gen_apps, 'AI for General Applications'
FROM dual WHERE @c_gen_apps IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_urlkey, 0, @c_gen_apps, 'ai-for-general-applications'
FROM dual WHERE @c_gen_apps IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-general-applications.html'
WHERE entity_id = @c_gen_apps
  AND attribute_id = @a_urlpath
  AND @c_gen_apps IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metatitle, 0, @c_gen_apps, 'AI for General Applications'
FROM dual WHERE @c_gen_apps IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_int
WHERE entity_id = @c_gen_apps
  AND attribute_id IN (@a_active, @a_menu)
  AND store_id <> 0
  AND @c_gen_apps IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_active, 0, @c_gen_apps, 1
FROM dual WHERE @c_gen_apps IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, @c_gen_apps, 0
FROM dual WHERE @c_gen_apps IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_anchor, 0, @c_gen_apps, 1
FROM dual WHERE @c_gen_apps IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_gen_apps
  AND attribute_id = @a_layout
  AND @c_gen_apps IS NOT NULL;

SET @sql := IF(@has_flat > 0 AND @c_gen_apps IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1, position = 3, is_active = 1, include_in_menu = 0, name = ''AI for General Applications'', url_key = ''ai-for-general-applications'', url_path = ''ai-for-general-applications.html'' WHERE entity_id = @c_gen_apps',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

-- ===== A: AI for Finance (ai-for-finance) =====

SET @c_finance := IF(@is_sg > 0 AND @apps IS NOT NULL, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'ai-for-finance' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'animation-courses' LIMIT 1)
), NULL);

SET @oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @c_finance);
SET @needs_move := IF(@c_finance IS NOT NULL AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c_finance) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','))
  AND entity_id <> @c_finance
  AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1,
    position = 4
WHERE entity_id = @c_finance
  AND @c_finance IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_name, 0, @c_finance, 'AI for Finance'
FROM dual WHERE @c_finance IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_urlkey, 0, @c_finance, 'ai-for-finance'
FROM dual WHERE @c_finance IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-finance.html'
WHERE entity_id = @c_finance
  AND attribute_id = @a_urlpath
  AND @c_finance IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metatitle, 0, @c_finance, 'AI for Finance'
FROM dual WHERE @c_finance IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_int
WHERE entity_id = @c_finance
  AND attribute_id IN (@a_active, @a_menu)
  AND store_id <> 0
  AND @c_finance IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_active, 0, @c_finance, 1
FROM dual WHERE @c_finance IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, @c_finance, 0
FROM dual WHERE @c_finance IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_anchor, 0, @c_finance, 1
FROM dual WHERE @c_finance IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_finance
  AND attribute_id = @a_layout
  AND @c_finance IS NOT NULL;

SET @sql := IF(@has_flat > 0 AND @c_finance IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1, position = 4, is_active = 1, include_in_menu = 0, name = ''AI for Finance'', url_key = ''ai-for-finance'', url_path = ''ai-for-finance.html'' WHERE entity_id = @c_finance',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

-- ===== A: AI for Healthcare (ai-for-healthcare) =====

SET @c_healthcare := IF(@is_sg > 0 AND @apps IS NOT NULL, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'ai-for-healthcare' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'google-tag-manager-courses' LIMIT 1)
), NULL);

SET @oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @c_healthcare);
SET @needs_move := IF(@c_healthcare IS NOT NULL AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c_healthcare) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','))
  AND entity_id <> @c_healthcare
  AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1,
    position = 5
WHERE entity_id = @c_healthcare
  AND @c_healthcare IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_name, 0, @c_healthcare, 'AI for Healthcare'
FROM dual WHERE @c_healthcare IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_urlkey, 0, @c_healthcare, 'ai-for-healthcare'
FROM dual WHERE @c_healthcare IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-healthcare.html'
WHERE entity_id = @c_healthcare
  AND attribute_id = @a_urlpath
  AND @c_healthcare IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metatitle, 0, @c_healthcare, 'AI for Healthcare'
FROM dual WHERE @c_healthcare IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_int
WHERE entity_id = @c_healthcare
  AND attribute_id IN (@a_active, @a_menu)
  AND store_id <> 0
  AND @c_healthcare IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_active, 0, @c_healthcare, 1
FROM dual WHERE @c_healthcare IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, @c_healthcare, 0
FROM dual WHERE @c_healthcare IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_anchor, 0, @c_healthcare, 1
FROM dual WHERE @c_healthcare IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_healthcare
  AND attribute_id = @a_layout
  AND @c_healthcare IS NOT NULL;

SET @sql := IF(@has_flat > 0 AND @c_healthcare IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1, position = 5, is_active = 1, include_in_menu = 0, name = ''AI for Healthcare'', url_key = ''ai-for-healthcare'', url_path = ''ai-for-healthcare.html'' WHERE entity_id = @c_healthcare',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

-- ===== A: AI for Machine Learning (ai-for-machine-learning) =====

SET @c_ml := IF(@is_sg > 0 AND @apps IS NOT NULL, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'google-looker-studio-courses' LIMIT 1)
), NULL);

SET @oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @c_ml);
SET @needs_move := IF(@c_ml IS NOT NULL AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c_ml) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','))
  AND entity_id <> @c_ml
  AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1,
    position = 6
WHERE entity_id = @c_ml
  AND @c_ml IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_name, 0, @c_ml, 'AI for Machine Learning'
FROM dual WHERE @c_ml IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_urlkey, 0, @c_ml, 'ai-for-machine-learning'
FROM dual WHERE @c_ml IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-machine-learning.html'
WHERE entity_id = @c_ml
  AND attribute_id = @a_urlpath
  AND @c_ml IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metatitle, 0, @c_ml, 'AI for Machine Learning'
FROM dual WHERE @c_ml IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_int
WHERE entity_id = @c_ml
  AND attribute_id IN (@a_active, @a_menu)
  AND store_id <> 0
  AND @c_ml IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_active, 0, @c_ml, 1
FROM dual WHERE @c_ml IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, @c_ml, 0
FROM dual WHERE @c_ml IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_anchor, 0, @c_ml, 1
FROM dual WHERE @c_ml IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_ml
  AND attribute_id = @a_layout
  AND @c_ml IS NOT NULL;

SET @sql := IF(@has_flat > 0 AND @c_ml IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1, position = 6, is_active = 1, include_in_menu = 0, name = ''AI for Machine Learning'', url_key = ''ai-for-machine-learning'', url_path = ''ai-for-machine-learning.html'' WHERE entity_id = @c_ml',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

-- ===== B: moves out of the AI Applications Series =====

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @apps
  AND p.sku IN (
    'TGS-2025054471',
    'TGS-2021010367',
    'TGS-2020505925',
    'TGS-2024045806',
    'TGS-2024045802',
    'TGS-2019504744',
    'TGS-2019504643'
  );

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @apps
  AND p.sku IN (
    'TGS-2025054471',
    'TGS-2021010367',
    'TGS-2020505925',
    'TGS-2024045806',
    'TGS-2024045802',
    'TGS-2019504744',
    'TGS-2019504643'
  );

SET @t_ai_agents_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_ai_agents_series, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @t_ai_agents_series IS NOT NULL
  AND p.sku IN (
    'TGS-2025054471',
    'TGS-2021010367'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_ai_agents_series, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_ai_agents_series IS NOT NULL
  AND p.sku IN (
    'TGS-2025054471',
    'TGS-2021010367'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_generative_ai_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'generative-ai-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_generative_ai_series, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @t_generative_ai_series IS NOT NULL
  AND p.sku IN (
    'TGS-2020505925'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_generative_ai_series, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_generative_ai_series IS NOT NULL
  AND p.sku IN (
    'TGS-2020505925'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_multi_agents_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'multi-agents-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_multi_agents_series, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @t_multi_agents_series IS NOT NULL
  AND p.sku IN (
    'TGS-2024045806',
    'TGS-2025054471'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_multi_agents_series, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_multi_agents_series IS NOT NULL
  AND p.sku IN (
    'TGS-2024045806',
    'TGS-2025054471'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_ai_vibe_coding_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_ai_vibe_coding_series, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @t_ai_vibe_coding_series IS NOT NULL
  AND p.sku IN (
    'TGS-2024045802',
    'TGS-2019504744',
    'TGS-2019504643'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_ai_vibe_coding_series, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_ai_vibe_coding_series IS NOT NULL
  AND p.sku IN (
    'TGS-2024045802',
    'TGS-2019504744',
    'TGS-2019504643'
  )
GROUP BY p.entity_id, s.store_id;

-- ===== C: assign + pin AI for General Applications =====

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c_gen_apps, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @c_gen_apps IS NOT NULL
  AND p.sku IN (
    'TGS-2026064716',
    'TGS-2023018987',
    'TGS-2024045799'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_gen_apps, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @c_gen_apps IS NOT NULL
  AND p.sku IN (
    'TGS-2026064716',
    'TGS-2023018987',
    'TGS-2024045799'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026064716' THEN 1
  WHEN 'TGS-2023018987' THEN 2
  WHEN 'TGS-2024045799' THEN 3
END
WHERE cp.category_id = @c_gen_apps
  AND p.sku IN (
    'TGS-2026064716',
    'TGS-2023018987',
    'TGS-2024045799'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026064716' THEN 1
  WHEN 'TGS-2023018987' THEN 2
  WHEN 'TGS-2024045799' THEN 3
END
WHERE i.category_id = @c_gen_apps
  AND p.sku IN (
    'TGS-2026064716',
    'TGS-2023018987',
    'TGS-2024045799'
  );

-- ===== C: assign + pin AI for Finance =====

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c_finance, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @c_finance IS NOT NULL
  AND p.sku IN (
    'TGS-2026065050',
    'TGS-2023018794',
    'TGS-2025052659',
    'TGS-2023017892',
    'TGS-2022601648'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_finance, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @c_finance IS NOT NULL
  AND p.sku IN (
    'TGS-2026065050',
    'TGS-2023018794',
    'TGS-2025052659',
    'TGS-2023017892',
    'TGS-2022601648'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026065050' THEN 1
  WHEN 'TGS-2023018794' THEN 2
  WHEN 'TGS-2025052659' THEN 3
  WHEN 'TGS-2023017892' THEN 4
  WHEN 'TGS-2022601648' THEN 5
END
WHERE cp.category_id = @c_finance
  AND p.sku IN (
    'TGS-2026065050',
    'TGS-2023018794',
    'TGS-2025052659',
    'TGS-2023017892',
    'TGS-2022601648'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026065050' THEN 1
  WHEN 'TGS-2023018794' THEN 2
  WHEN 'TGS-2025052659' THEN 3
  WHEN 'TGS-2023017892' THEN 4
  WHEN 'TGS-2022601648' THEN 5
END
WHERE i.category_id = @c_finance
  AND p.sku IN (
    'TGS-2026065050',
    'TGS-2023018794',
    'TGS-2025052659',
    'TGS-2023017892',
    'TGS-2022601648'
  );

-- ===== C: assign + pin AI for Healthcare =====

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c_healthcare, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @c_healthcare IS NOT NULL
  AND p.sku IN (
    'TGS-2023041022'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_healthcare, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @c_healthcare IS NOT NULL
  AND p.sku IN (
    'TGS-2023041022'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023041022' THEN 1
END
WHERE cp.category_id = @c_healthcare
  AND p.sku IN (
    'TGS-2023041022'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023041022' THEN 1
END
WHERE i.category_id = @c_healthcare
  AND p.sku IN (
    'TGS-2023041022'
  );

-- ===== C: assign + pin AI for Machine Learning =====

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c_ml, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @c_ml IS NOT NULL
  AND p.sku IN (
    'TGS-2026064713',
    'TGS-2020503264',
    'TGS-2026064715',
    'TGS-2026064608',
    'TGS-2026064714',
    'TGS-2020505815',
    'TGS-2023021100',
    'TGS-2023036651',
    'TGS-2023036642',
    'TGS-2024049338',
    'TGS-2024049340',
    'TGS-2023040476'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_ml, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @c_ml IS NOT NULL
  AND p.sku IN (
    'TGS-2026064713',
    'TGS-2020503264',
    'TGS-2026064715',
    'TGS-2026064608',
    'TGS-2026064714',
    'TGS-2020505815',
    'TGS-2023021100',
    'TGS-2023036651',
    'TGS-2023036642',
    'TGS-2024049338',
    'TGS-2024049340',
    'TGS-2023040476'
  )
GROUP BY p.entity_id, s.store_id;

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
WHERE cp.category_id = @c_ml
  AND p.sku IN (
    'TGS-2026064713',
    'TGS-2020503264',
    'TGS-2026064715',
    'TGS-2026064608',
    'TGS-2026064714',
    'TGS-2020505815',
    'TGS-2023021100',
    'TGS-2023036651',
    'TGS-2023036642',
    'TGS-2024049338',
    'TGS-2024049340',
    'TGS-2023040476'
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
WHERE i.category_id = @c_ml
  AND p.sku IN (
    'TGS-2026064713',
    'TGS-2020503264',
    'TGS-2026064715',
    'TGS-2026064608',
    'TGS-2026064714',
    'TGS-2020505815',
    'TGS-2023021100',
    'TGS-2023036651',
    'TGS-2023036642',
    'TGS-2024049338',
    'TGS-2024049340',
    'TGS-2023040476'
  );

-- ===== D: pin the grouped order (1..21) on the parent listing =====

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 21
WHERE cp.category_id = @apps
  AND p.sku LIKE 'TGS-%'
  AND cp.position <= 21
  AND p.sku NOT IN (
    'TGS-2026064716',
    'TGS-2023018987',
    'TGS-2024045799',
    'TGS-2026065050',
    'TGS-2023018794',
    'TGS-2025052659',
    'TGS-2023017892',
    'TGS-2022601648',
    'TGS-2023041022',
    'TGS-2026064713',
    'TGS-2020503264',
    'TGS-2026064715',
    'TGS-2026064608',
    'TGS-2026064714',
    'TGS-2020505815',
    'TGS-2023021100',
    'TGS-2023036651',
    'TGS-2023036642',
    'TGS-2024049338',
    'TGS-2024049340',
    'TGS-2023040476'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 21
WHERE i.category_id = @apps
  AND p.sku LIKE 'TGS-%'
  AND i.position <= 21
  AND p.sku NOT IN (
    'TGS-2026064716',
    'TGS-2023018987',
    'TGS-2024045799',
    'TGS-2026065050',
    'TGS-2023018794',
    'TGS-2025052659',
    'TGS-2023017892',
    'TGS-2022601648',
    'TGS-2023041022',
    'TGS-2026064713',
    'TGS-2020503264',
    'TGS-2026064715',
    'TGS-2026064608',
    'TGS-2026064714',
    'TGS-2020505815',
    'TGS-2023021100',
    'TGS-2023036651',
    'TGS-2023036642',
    'TGS-2024049338',
    'TGS-2024049340',
    'TGS-2023040476'
  );

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026064716' THEN 1
  WHEN 'TGS-2023018987' THEN 2
  WHEN 'TGS-2024045799' THEN 3
  WHEN 'TGS-2026065050' THEN 4
  WHEN 'TGS-2023018794' THEN 5
  WHEN 'TGS-2025052659' THEN 6
  WHEN 'TGS-2023017892' THEN 7
  WHEN 'TGS-2022601648' THEN 8
  WHEN 'TGS-2023041022' THEN 9
  WHEN 'TGS-2026064713' THEN 10
  WHEN 'TGS-2020503264' THEN 11
  WHEN 'TGS-2026064715' THEN 12
  WHEN 'TGS-2026064608' THEN 13
  WHEN 'TGS-2026064714' THEN 14
  WHEN 'TGS-2020505815' THEN 15
  WHEN 'TGS-2023021100' THEN 16
  WHEN 'TGS-2023036651' THEN 17
  WHEN 'TGS-2023036642' THEN 18
  WHEN 'TGS-2024049338' THEN 19
  WHEN 'TGS-2024049340' THEN 20
  WHEN 'TGS-2023040476' THEN 21
END
WHERE cp.category_id = @apps
  AND p.sku IN (
    'TGS-2026064716',
    'TGS-2023018987',
    'TGS-2024045799',
    'TGS-2026065050',
    'TGS-2023018794',
    'TGS-2025052659',
    'TGS-2023017892',
    'TGS-2022601648',
    'TGS-2023041022',
    'TGS-2026064713',
    'TGS-2020503264',
    'TGS-2026064715',
    'TGS-2026064608',
    'TGS-2026064714',
    'TGS-2020505815',
    'TGS-2023021100',
    'TGS-2023036651',
    'TGS-2023036642',
    'TGS-2024049338',
    'TGS-2024049340',
    'TGS-2023040476'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026064716' THEN 1
  WHEN 'TGS-2023018987' THEN 2
  WHEN 'TGS-2024045799' THEN 3
  WHEN 'TGS-2026065050' THEN 4
  WHEN 'TGS-2023018794' THEN 5
  WHEN 'TGS-2025052659' THEN 6
  WHEN 'TGS-2023017892' THEN 7
  WHEN 'TGS-2022601648' THEN 8
  WHEN 'TGS-2023041022' THEN 9
  WHEN 'TGS-2026064713' THEN 10
  WHEN 'TGS-2020503264' THEN 11
  WHEN 'TGS-2026064715' THEN 12
  WHEN 'TGS-2026064608' THEN 13
  WHEN 'TGS-2026064714' THEN 14
  WHEN 'TGS-2020505815' THEN 15
  WHEN 'TGS-2023021100' THEN 16
  WHEN 'TGS-2023036651' THEN 17
  WHEN 'TGS-2023036642' THEN 18
  WHEN 'TGS-2024049338' THEN 19
  WHEN 'TGS-2024049340' THEN 20
  WHEN 'TGS-2023040476' THEN 21
END
WHERE i.category_id = @apps
  AND p.sku IN (
    'TGS-2026064716',
    'TGS-2023018987',
    'TGS-2024045799',
    'TGS-2026065050',
    'TGS-2023018794',
    'TGS-2025052659',
    'TGS-2023017892',
    'TGS-2022601648',
    'TGS-2023041022',
    'TGS-2026064713',
    'TGS-2020503264',
    'TGS-2026064715',
    'TGS-2026064608',
    'TGS-2026064714',
    'TGS-2020505815',
    'TGS-2023021100',
    'TGS-2023036651',
    'TGS-2023036642',
    'TGS-2024049338',
    'TGS-2024049340',
    'TGS-2023040476'
  );

