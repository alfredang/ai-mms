-- 1206: AI Applications Series — final subcategory set.
--
-- Target dropdown (in this order):
--   AI for Business, AI for Finance, AI for Healthcare, AI for Robotics,
--   AI for Machine Learning, AI for Educators, AI for STEM
--
-- A) Move 'AI for Machine Learning' back under the AI Applications Series
--    (1198 had parked it under the AI Infrastructure Series). Flat URLs mean
--    a reparent never touches url_key/url_path.
--
-- B) Repurpose two empty deactivated categories as new subcategories:
--      'Analog IC Design' -> AI for Educators   (ai-for-educators)
--      'Cert Verify'      -> AI for STEM        (ai-for-stem)
--    Both start empty; they are activated, anchored and shown in the menu.
--
-- C) Computer Vision, Reinforcement Learning (RL) and AI for HR leave the
--    dropdown (include_in_menu = 0) but stay ACTIVE so no page 404s and no
--    course loses a home. Their enabled non-WSQ courses are folded into
--    'AI for Machine Learning' and remain listed on the AI Applications
--    Series parent page:
--      C1071 AI-901 Microsoft Azure AI Fundamentals      (already in both)
--      C592  AI Vibe Coding for Computer Vision          (already in both)
--      C820  AI for HR                                   (added to ML here)
--    The other members of those three categories are disabled products
--    (status = 2) and are intentionally left alone.
--
-- D) Position the seven visible subcategories in the requested order.
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

SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1'
);

-- ===== A: reparent AI for Machine Learning under AI Applications Series =====

SET @ml := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1);
SET @ml_oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @ml);
SET @ml_move := IF(@ml IS NOT NULL AND @apps IS NOT NULL
  AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @ml) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @ml_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@ml_oldpath, '/', ','))
  AND entity_id <> @ml AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @ml_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@ml_oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1
WHERE @ml_move = 1 AND entity_id = @ml;

SET @sql := IF(@has_flat > 0 AND @ml IS NOT NULL AND @apps IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1 WHERE entity_id = @ml',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Show the reparented AI for Machine Learning in the dropdown. It kept
-- include_in_menu = 0 from when it lived under the AI Infrastructure Series,
-- and 1205 only flipped the children 139 had at that time.
DELETE FROM catalog_category_entity_int
WHERE entity_id = @ml AND attribute_id = @a_cmenu AND store_id <> 0 AND @ml IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @ml, 1 FROM dual WHERE @ml IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @sql := IF(@has_flat > 0 AND @ml IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET include_in_menu = 1 WHERE entity_id = @ml',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ===== B: AI for Educators =====

SET @c_educators := IF(@is_sg > 0 AND @apps IS NOT NULL, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-educators' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'analog-ic-design-courses' LIMIT 1)
), NULL);

SET @oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @c_educators);
SET @needs_move := IF(@c_educators IS NOT NULL
  AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c_educators) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @needs_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','))
  AND entity_id <> @c_educators AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @needs_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1
WHERE @needs_move = 1 AND entity_id = @c_educators;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cname, 0, @c_educators, 'AI for Educators' FROM dual WHERE @c_educators IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_curlkey, 0, @c_educators, 'ai-for-educators' FROM dual WHERE @c_educators IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-educators.html'
WHERE entity_id = @c_educators AND attribute_id = @a_curlpath AND @c_educators IS NOT NULL;

DELETE FROM catalog_category_entity_int
WHERE entity_id = @c_educators AND attribute_id IN (@a_cactive, @a_cmenu) AND store_id <> 0 AND @c_educators IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, @c_educators, 1 FROM dual WHERE @c_educators IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @c_educators, 1 FROM dual WHERE @c_educators IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_canchor, 0, @c_educators, 1 FROM dual WHERE @c_educators IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_educators AND attribute_id = @a_clayout AND @c_educators IS NOT NULL;

SET @sql := IF(@has_flat > 0 AND @c_educators IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1, is_active = 1, include_in_menu = 1, name = ''AI for Educators'', url_key = ''ai-for-educators'', url_path = ''ai-for-educators.html'' WHERE entity_id = @c_educators',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ===== B: AI for STEM =====

SET @c_stem := IF(@is_sg > 0 AND @apps IS NOT NULL, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-stem' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'cert-verify' LIMIT 1)
), NULL);

SET @oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @c_stem);
SET @needs_move := IF(@c_stem IS NOT NULL
  AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c_stem) <> @apps, 1, 0);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @needs_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','))
  AND entity_id <> @c_stem AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @needs_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1
WHERE @needs_move = 1 AND entity_id = @c_stem;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cname, 0, @c_stem, 'AI for STEM' FROM dual WHERE @c_stem IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_curlkey, 0, @c_stem, 'ai-for-stem' FROM dual WHERE @c_stem IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-stem.html'
WHERE entity_id = @c_stem AND attribute_id = @a_curlpath AND @c_stem IS NOT NULL;

DELETE FROM catalog_category_entity_int
WHERE entity_id = @c_stem AND attribute_id IN (@a_cactive, @a_cmenu) AND store_id <> 0 AND @c_stem IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, @c_stem, 1 FROM dual WHERE @c_stem IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @c_stem, 1 FROM dual WHERE @c_stem IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_canchor, 0, @c_stem, 1 FROM dual WHERE @c_stem IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_stem AND attribute_id = @a_clayout AND @c_stem IS NOT NULL;

SET @sql := IF(@has_flat > 0 AND @c_stem IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @apps, path = CONCAT(@appspath, ''/'', entity_id), level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, ''/'', ''''))) + 1, is_active = 1, include_in_menu = 1, name = ''AI for STEM'', url_key = ''ai-for-stem'', url_path = ''ai-for-stem.html'' WHERE entity_id = @c_stem',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ===== C: fold the hidden categories' enabled non-WSQ course into ML =====
-- (C1071 and C592 are already in both; C820 needs adding.)

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @ml, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @ml), 0) + 1
FROM catalog_product_entity p
WHERE @ml IS NOT NULL AND @is_sg > 0 AND p.sku IN ('C820', 'C1071', 'C592');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @ml, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @ml AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @ml IS NOT NULL AND @is_sg > 0 AND p.sku IN ('C820', 'C1071', 'C592')
GROUP BY p.entity_id, s.store_id;

-- keep them listed on the AI Applications Series parent page too
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @apps, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @apps), 0) + 1
FROM catalog_product_entity p
WHERE @apps IS NOT NULL AND @is_sg > 0 AND p.sku IN ('C820', 'C1071', 'C592');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @apps, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @apps AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @apps IS NOT NULL AND @is_sg > 0 AND p.sku IN ('C820', 'C1071', 'C592')
GROUP BY p.entity_id, s.store_id;

-- hide the three from the dropdown (categories stay ACTIVE — pages keep working)
SET @cv := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'deep-learning-computer-vision-courses' LIMIT 1);
SET @rl := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'deep-reinforcement-learning-courses' LIMIT 1);
SET @hr := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);

DELETE FROM catalog_category_entity_int
WHERE attribute_id = @a_cmenu AND store_id <> 0
  AND entity_id IN (@cv, @rl, @hr) AND @cv IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, x.id, 0 FROM (SELECT @cv AS id UNION ALL SELECT @rl UNION ALL SELECT @hr) x
WHERE x.id IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @sql := IF(@has_flat > 0 AND @cv IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET include_in_menu = 0 WHERE entity_id IN (@cv, @rl, @hr)',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ===== D: order the seven visible subcategories =====

UPDATE catalog_category_entity e
JOIN catalog_category_entity_varchar v
  ON v.entity_id = e.entity_id AND v.attribute_id = @a_curlkey AND v.store_id = 0
SET e.position = CASE v.value
  WHEN 'ai-for-business'           THEN 1
  WHEN 'ai-for-finance-courses'    THEN 2
  WHEN 'ai-for-healthcare-courses' THEN 3
  WHEN 'ai-for-robotics'           THEN 4
  WHEN 'ai-for-machine-learning'   THEN 5
  WHEN 'ai-for-educators'          THEN 6
  WHEN 'ai-for-stem'               THEN 7
  ELSE e.position
END
WHERE e.parent_id = @apps
  AND v.value IN ('ai-for-business', 'ai-for-finance-courses', 'ai-for-healthcare-courses',
                  'ai-for-robotics', 'ai-for-machine-learning', 'ai-for-educators', 'ai-for-stem');

SET @sql := IF(@has_flat > 0 AND @apps IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 f JOIN catalog_category_entity e ON e.entity_id = f.entity_id SET f.position = e.position WHERE e.parent_id = @apps',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- curated-order exemption for the two new subcategories (harmless while empty)
UPDATE core_config_data
SET value = CONCAT(value, ',ai-for-educators,ai-for-stem')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-for-educators%';


-- ===== E: AI Applications Series parent page — non-WSQ grouped by
-- subcategory (Business, Finance, Healthcare, Robotics, Machine Learning),
-- each group keeping its own curated order, all at 101+ so they sit after
-- every WSQ/CASL/IBF course. AI for Educators and AI for STEM are empty.

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C798' THEN 101
  WHEN 'C997' THEN 102
  WHEN 'C840' THEN 103
  WHEN 'C831' THEN 104
  WHEN 'C165' THEN 105
  WHEN 'C398' THEN 106
  WHEN 'C155' THEN 107
  WHEN 'C817' THEN 108
  WHEN 'C864' THEN 109
  WHEN 'C711' THEN 110
  WHEN 'C1756' THEN 111
  WHEN 'C104' THEN 112
  WHEN 'C207' THEN 113
  WHEN 'C057' THEN 114
  WHEN 'C177' THEN 115
  WHEN 'C1164' THEN 116
  WHEN 'C1018' THEN 117
  WHEN 'C852' THEN 118
  WHEN 'C430' THEN 119
  WHEN 'C592' THEN 120
  WHEN 'C188' THEN 121
  WHEN 'C539' THEN 122
  WHEN 'C1071' THEN 123
  WHEN 'C926' THEN 124
  WHEN 'C1759' THEN 125
  WHEN 'C19' THEN 126
  WHEN 'C1330' THEN 127
  WHEN 'C279' THEN 128
  WHEN 'C476' THEN 129
  WHEN 'C1750' THEN 130
  WHEN 'C820' THEN 131
END
WHERE cp.category_id = @apps
  AND p.sku IN (
    'C798',
    'C997',
    'C840',
    'C831',
    'C165',
    'C398',
    'C155',
    'C817',
    'C864',
    'C711',
    'C1756',
    'C104',
    'C207',
    'C057',
    'C177',
    'C1164',
    'C1018',
    'C852',
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C19',
    'C1330',
    'C279',
    'C476',
    'C1750',
    'C820'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C798' THEN 101
  WHEN 'C997' THEN 102
  WHEN 'C840' THEN 103
  WHEN 'C831' THEN 104
  WHEN 'C165' THEN 105
  WHEN 'C398' THEN 106
  WHEN 'C155' THEN 107
  WHEN 'C817' THEN 108
  WHEN 'C864' THEN 109
  WHEN 'C711' THEN 110
  WHEN 'C1756' THEN 111
  WHEN 'C104' THEN 112
  WHEN 'C207' THEN 113
  WHEN 'C057' THEN 114
  WHEN 'C177' THEN 115
  WHEN 'C1164' THEN 116
  WHEN 'C1018' THEN 117
  WHEN 'C852' THEN 118
  WHEN 'C430' THEN 119
  WHEN 'C592' THEN 120
  WHEN 'C188' THEN 121
  WHEN 'C539' THEN 122
  WHEN 'C1071' THEN 123
  WHEN 'C926' THEN 124
  WHEN 'C1759' THEN 125
  WHEN 'C19' THEN 126
  WHEN 'C1330' THEN 127
  WHEN 'C279' THEN 128
  WHEN 'C476' THEN 129
  WHEN 'C1750' THEN 130
  WHEN 'C820' THEN 131
END
WHERE i.category_id = @apps
  AND p.sku IN (
    'C798',
    'C997',
    'C840',
    'C831',
    'C165',
    'C398',
    'C155',
    'C817',
    'C864',
    'C711',
    'C1756',
    'C104',
    'C207',
    'C057',
    'C177',
    'C1164',
    'C1018',
    'C852',
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C19',
    'C1330',
    'C279',
    'C476',
    'C1750',
    'C820'
  );

UPDATE core_config_data
SET value = CONCAT(value, ',ai-applications-series')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-applications-series%';


-- ===== F: AI for Machine Learning subcategory — requested non-WSQ order =====
-- (The requested "DP-100 Azure Data Scientist Associate Training" no longer
-- exists as a non-WSQ course: C840 was converted to "AI for Product
-- Development" by 1204. The WSQ DP-100 course stays in this category's
-- WSQ block. CompTIA DataAI / SecAI+ and AI for HR are not in the requested
-- list, so they sort after this block.)

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C430' THEN 101
  WHEN 'C592' THEN 102
  WHEN 'C188' THEN 103
  WHEN 'C539' THEN 104
  WHEN 'C1071' THEN 105
  WHEN 'C926' THEN 106
  WHEN 'C1759' THEN 107
  WHEN 'C19' THEN 108
  WHEN 'C1330' THEN 109
  WHEN 'C279' THEN 110
END
WHERE cp.category_id = @ml
  AND p.sku IN (
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C19',
    'C1330',
    'C279'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C430' THEN 101
  WHEN 'C592' THEN 102
  WHEN 'C188' THEN 103
  WHEN 'C539' THEN 104
  WHEN 'C1071' THEN 105
  WHEN 'C926' THEN 106
  WHEN 'C1759' THEN 107
  WHEN 'C19' THEN 108
  WHEN 'C1330' THEN 109
  WHEN 'C279' THEN 110
END
WHERE i.category_id = @ml
  AND p.sku IN (
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C19',
    'C1330',
    'C279'
  );

-- Push the non-requested non-WSQ members (CompTIA DataAI / SecAI+, AI for HR)
-- below the requested block so the requested order leads the non-WSQ section.
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = 200 + cp.product_id
WHERE cp.category_id = @ml
  AND p.sku NOT LIKE 'TGS-%'
  AND p.sku NOT IN ('C430','C592','C188','C539','C1071','C926','C1759','C19','C1330','C279');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = 200 + i.product_id
WHERE i.category_id = @ml
  AND p.sku NOT LIKE 'TGS-%'
  AND p.sku NOT IN ('C430','C592','C188','C539','C1071','C926','C1759','C19','C1330','C279');
