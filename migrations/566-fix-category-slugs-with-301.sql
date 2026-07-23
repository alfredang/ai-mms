-- 566: Correct category url_keys that name a different subject than the
--      category title, ALWAYS leaving a 301 behind so no existing link breaks.
--
-- Companion to 565 (which fixed the descriptions). Split deliberately: a URL
-- change carries SEO risk that a text change does not, so it ships and rolls
-- back independently.
--
-- Scope is the non-WSQ categories only (WSQ/IBF categories are out of scope by
-- instruction). Slugs that are merely longer SEO variants of the title
-- ('Docker' -> docker-courses, 'AWS' -> aws-cloud-computing-courses) are LEFT
-- ALONE — only genuine subject divergence is corrected:
--
--   81  Healthcare & WSH        life-science-courses-training        -> healthcare-and-wsh-courses
--   126 Marketing Analytics     business-analytics-training-courses  -> marketing-analytics-courses
--   139 AI Applications Series  machine-learning-courses             -> ai-applications-series-courses
--   250 AI Devops Series        voice-agents-and-video-agents-coures -> ai-devops-series-courses
--   314 Ethereum                ethereum-skillsfuture-courses-in     -> ethereum-blockchain-courses
--
-- 314's '-in' suffix is a fossil of the retired India store.
-- 250's old slug is also misspelled ('coures') and already carries a chain of
-- prior RP rewrites; this adds to that chain rather than disturbing it.
--
-- FlatCategoryUrl means every category resolves at /<url_key>.html, so both the
-- old and new request paths are single-segment. For each category we:
--   1. capture the current url_key,
--   2. write an is_system=0, options='RP' (301) rewrite old.html -> new.html
--      for EVERY store that has a rewrite row for that category,
--   3. then set the new url_key on store 0 and any per-store override,
--   4. and mirror the new value into each catalog_category_flat_store_N present.
--
-- Guarded so it is a no-op once applied (matches on the OLD slug only) and safe
-- on partner instances where a category or flat table may not exist.
-- After deploy: reindex Catalog URL Rewrites + Category Flat Data, flush cache.

SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

-- ===========================================================================
-- Helper pattern, repeated per category. @old / @new drive everything.
-- ===========================================================================

-- ---------------------------------------------------------------- 81 --------
SET @old := 'life-science-courses-training';
SET @new := 'healthcare-and-wsh-courses';
SET @cid := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
             WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @old LIMIT 1);

INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT DISTINCT r.store_id, @cid, NULL,
       CONCAT('cat301_', @cid, '_', r.store_id),
       CONCAT(@old, '.html'), CONCAT(@new, '.html'), 0, 'RP', 'slug fix 566'
FROM core_url_rewrite r
WHERE @cid IS NOT NULL AND r.category_id = @cid AND r.product_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.store_id = r.store_id AND x.request_path = CONCAT(@old, '.html'));

UPDATE catalog_category_entity_varchar SET value = @new
WHERE attribute_id = @a_uk AND value = @old;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT("UPDATE catalog_category_flat_store_1 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT("UPDATE catalog_category_flat_store_2 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT("UPDATE catalog_category_flat_store_3 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------- 126 -------
SET @old := 'business-analytics-training-courses';
SET @new := 'marketing-analytics-courses';
SET @cid := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
             WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @old LIMIT 1);

INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT DISTINCT r.store_id, @cid, NULL,
       CONCAT('cat301_', @cid, '_', r.store_id),
       CONCAT(@old, '.html'), CONCAT(@new, '.html'), 0, 'RP', 'slug fix 566'
FROM core_url_rewrite r
WHERE @cid IS NOT NULL AND r.category_id = @cid AND r.product_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.store_id = r.store_id AND x.request_path = CONCAT(@old, '.html'));

UPDATE catalog_category_entity_varchar SET value = @new
WHERE attribute_id = @a_uk AND value = @old;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT("UPDATE catalog_category_flat_store_1 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT("UPDATE catalog_category_flat_store_2 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT("UPDATE catalog_category_flat_store_3 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------- 139 -------
SET @old := 'machine-learning-courses';
SET @new := 'ai-applications-series-courses';
SET @cid := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
             WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @old LIMIT 1);

INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT DISTINCT r.store_id, @cid, NULL,
       CONCAT('cat301_', @cid, '_', r.store_id),
       CONCAT(@old, '.html'), CONCAT(@new, '.html'), 0, 'RP', 'slug fix 566'
FROM core_url_rewrite r
WHERE @cid IS NOT NULL AND r.category_id = @cid AND r.product_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.store_id = r.store_id AND x.request_path = CONCAT(@old, '.html'));

UPDATE catalog_category_entity_varchar SET value = @new
WHERE attribute_id = @a_uk AND value = @old;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT("UPDATE catalog_category_flat_store_1 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT("UPDATE catalog_category_flat_store_2 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT("UPDATE catalog_category_flat_store_3 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------- 250 -------
SET @old := 'voice-agents-and-video-agents-coures';
SET @new := 'ai-devops-series-courses';
SET @cid := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
             WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @old LIMIT 1);

INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT DISTINCT r.store_id, @cid, NULL,
       CONCAT('cat301_', @cid, '_', r.store_id),
       CONCAT(@old, '.html'), CONCAT(@new, '.html'), 0, 'RP', 'slug fix 566'
FROM core_url_rewrite r
WHERE @cid IS NOT NULL AND r.category_id = @cid AND r.product_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.store_id = r.store_id AND x.request_path = CONCAT(@old, '.html'));

-- Re-point the EXISTING inbound 301 chain (old slugs that already redirect to
-- this category) at the new slug, so nothing becomes a 301->301 hop.
UPDATE core_url_rewrite SET target_path = CONCAT(@new, '.html')
WHERE @cid IS NOT NULL AND category_id = @cid AND product_id IS NULL
  AND options = 'RP' AND target_path = CONCAT(@old, '.html')
  AND request_path <> CONCAT(@old, '.html');

UPDATE catalog_category_entity_varchar SET value = @new
WHERE attribute_id = @a_uk AND value = @old;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT("UPDATE catalog_category_flat_store_1 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT("UPDATE catalog_category_flat_store_2 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT("UPDATE catalog_category_flat_store_3 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------- 314 -------
SET @old := 'ethereum-skillsfuture-courses-in';
SET @new := 'ethereum-blockchain-courses';
SET @cid := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
             WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @old LIMIT 1);

INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT DISTINCT r.store_id, @cid, NULL,
       CONCAT('cat301_', @cid, '_', r.store_id),
       CONCAT(@old, '.html'), CONCAT(@new, '.html'), 0, 'RP', 'slug fix 566'
FROM core_url_rewrite r
WHERE @cid IS NOT NULL AND r.category_id = @cid AND r.product_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.store_id = r.store_id AND x.request_path = CONCAT(@old, '.html'));

UPDATE catalog_category_entity_varchar SET value = @new
WHERE attribute_id = @a_uk AND value = @old;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT("UPDATE catalog_category_flat_store_1 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT("UPDATE catalog_category_flat_store_2 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT("UPDATE catalog_category_flat_store_3 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
