-- 1211: AI Applications Series — add AI for Manufacturing and AI for Retail
-- subcategories, and set the requested dropdown order.
--
-- Target order:
--   1 AI for Business        6 AI for Manufacturing
--   2 AI for HR              7 AI for Retail
--   3 AI for Finance         8 AI for Educators
--   4 AI for Healthcare      9 AI for STEM
--   5 AI for Robotics       10 AI for Machine Learning
--
-- A) Repurpose the last two empty deactivated categories:
--      'eLearning'      -> AI for Manufacturing (ai-for-manufacturing)
--      'Free Workshops' -> AI for Retail        (ai-for-retail-courses)
--    The Retail slug carries the '-courses' suffix because 'ai-for-retail.html'
--    is the PRODUCT url of C398 "AI for Retail", which keeps its own page.
--    Same collision class as ai-for-finance/healthcare/hr — see
--    feedback_flat_url_collision_suffix_explosion.
--
-- B) Move C165 "AI for Logistics" into AI for Manufacturing and C398
--    "AI for Retail" into AI for Retail, out of AI for Business (they stay
--    on the AI Applications Series parent listing).
--
-- C) AI for HR returns to the dropdown (it now holds two courses).
--    Computer Vision and Reinforcement Learning stay hidden and active.
--
-- SG-guarded; these url_keys are SG-only (clean partner no-op). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_cname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_curlpath:= (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_cactive := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_cmenu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');
SET @a_canchor := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_anchor');
SET @a_clayout := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'page_layout');

SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);
SET @appspath := (SELECT path FROM catalog_category_entity WHERE entity_id = @apps);
SET @business := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-business' LIMIT 1);

SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1'
);

-- ===== A1: eLearning -> AI for Manufacturing =====

SET @mfg := IF(@is_sg > 0 AND @apps IS NOT NULL, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-manufacturing' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'elearning-courses' LIMIT 1)
), NULL);

SET @mfg_oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @mfg);
SET @mfg_move := IF(@mfg IS NOT NULL
  AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @mfg) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @mfg_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@mfg_oldpath, '/', ','))
  AND entity_id <> @mfg AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @mfg_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@mfg_oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1
WHERE @mfg_move = 1 AND entity_id = @mfg;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cname, 0, @mfg, 'AI for Manufacturing' FROM dual WHERE @mfg IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_curlkey, 0, @mfg, 'ai-for-manufacturing' FROM dual WHERE @mfg IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-manufacturing.html'
WHERE entity_id = @mfg AND attribute_id = @a_curlpath AND @mfg IS NOT NULL;

DELETE FROM catalog_category_entity_int
WHERE entity_id = @mfg AND attribute_id IN (@a_cactive, @a_cmenu) AND store_id <> 0 AND @mfg IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, @mfg, 1 FROM dual WHERE @mfg IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @mfg, 1 FROM dual WHERE @mfg IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_canchor, 0, @mfg, 1 FROM dual WHERE @mfg IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @mfg AND attribute_id = @a_clayout AND @mfg IS NOT NULL;

SET @sql := IF(@has_flat > 0 AND @mfg IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1, is_active = 1, include_in_menu = 1, name = ''AI for Manufacturing'', url_key = ''ai-for-manufacturing'', url_path = ''ai-for-manufacturing.html'' WHERE entity_id = @mfg',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ===== A2: Free Workshops -> AI for Retail =====

SET @retail := IF(@is_sg > 0 AND @apps IS NOT NULL, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-retail-courses' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'free-workshops' LIMIT 1)
), NULL);

SET @ret_oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @retail);
SET @ret_move := IF(@retail IS NOT NULL
  AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @retail) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @ret_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@ret_oldpath, '/', ','))
  AND entity_id <> @retail AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @ret_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@ret_oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1
WHERE @ret_move = 1 AND entity_id = @retail;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cname, 0, @retail, 'AI for Retail' FROM dual WHERE @retail IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_curlkey, 0, @retail, 'ai-for-retail-courses' FROM dual WHERE @retail IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-retail-courses.html'
WHERE entity_id = @retail AND attribute_id = @a_curlpath AND @retail IS NOT NULL;

DELETE FROM catalog_category_entity_int
WHERE entity_id = @retail AND attribute_id IN (@a_cactive, @a_cmenu) AND store_id <> 0 AND @retail IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, @retail, 1 FROM dual WHERE @retail IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @retail, 1 FROM dual WHERE @retail IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_canchor, 0, @retail, 1 FROM dual WHERE @retail IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @retail AND attribute_id = @a_clayout AND @retail IS NOT NULL;

SET @sql := IF(@has_flat > 0 AND @retail IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1, is_active = 1, include_in_menu = 1, name = ''AI for Retail'', url_key = ''ai-for-retail-courses'', url_path = ''ai-for-retail-courses.html'' WHERE entity_id = @retail',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ===== B: move the two courses into their new subcategories =====

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @mfg, p.entity_id, 101 FROM catalog_product_entity p
WHERE @mfg IS NOT NULL AND @is_sg > 0 AND p.sku = 'C165';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @mfg, p.entity_id, 101, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @mfg IS NOT NULL AND @is_sg > 0 AND p.sku = 'C165'
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @retail, p.entity_id, 101 FROM catalog_product_entity p
WHERE @retail IS NOT NULL AND @is_sg > 0 AND p.sku = 'C398';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @retail, p.entity_id, 101, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @retail IS NOT NULL AND @is_sg > 0 AND p.sku = 'C398'
GROUP BY p.entity_id, s.store_id;

-- out of AI for Business (they keep their AI Applications Series listing)
DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @business AND p.sku IN ('C165', 'C398') AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @business AND p.sku IN ('C165', 'C398') AND @is_sg > 0;

-- ===== C: AI for HR returns to the dropdown =====

SET @hr := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);

DELETE FROM catalog_category_entity_int
WHERE entity_id = @hr AND attribute_id = @a_cmenu AND store_id <> 0 AND @hr IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @hr, 1 FROM dual WHERE @hr IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @sql := IF(@has_flat > 0 AND @hr IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET include_in_menu = 1 WHERE entity_id = @hr',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ===== D: dropdown order =====

UPDATE catalog_category_entity e
JOIN catalog_category_entity_varchar v
  ON v.entity_id = e.entity_id AND v.attribute_id = @a_curlkey AND v.store_id = 0
SET e.position = CASE v.value
  WHEN 'ai-for-business'           THEN 1
  WHEN 'ai-for-hr-courses'         THEN 2
  WHEN 'ai-for-finance-courses'    THEN 3
  WHEN 'ai-for-healthcare-courses' THEN 4
  WHEN 'ai-for-robotics'           THEN 5
  WHEN 'ai-for-manufacturing'      THEN 6
  WHEN 'ai-for-retail-courses'     THEN 7
  WHEN 'ai-for-educators'          THEN 8
  WHEN 'ai-for-stem'               THEN 9
  WHEN 'ai-for-machine-learning'   THEN 10
  ELSE e.position
END
WHERE e.parent_id = @apps
  AND v.value IN ('ai-for-business', 'ai-for-hr-courses', 'ai-for-finance-courses',
                  'ai-for-healthcare-courses', 'ai-for-robotics', 'ai-for-manufacturing',
                  'ai-for-retail-courses', 'ai-for-educators', 'ai-for-stem',
                  'ai-for-machine-learning');

SET @sql := IF(@has_flat > 0 AND @apps IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 f JOIN catalog_category_entity e ON e.entity_id = f.entity_id SET f.position = e.position WHERE e.parent_id = @apps',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- curated-order exemption for the two new subcategories
UPDATE core_config_data
SET value = CONCAT(value, ',ai-for-manufacturing,ai-for-retail-courses')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-for-manufacturing%';
