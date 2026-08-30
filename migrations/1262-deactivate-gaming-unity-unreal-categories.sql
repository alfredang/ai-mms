-- 1262: Deactivate three gaming category pages (is_active = 0,
-- include_in_menu = 0 at store 0), on explicit request:
--   391 gaming-software-courses         (parent, under Software Training 53)
--   205 unreal-engine-training-courses  (child of 391)
--   206 unity-training-courses          (child of 391)
--
-- Parent and both children go down together, so no live child is left under a
-- deactivated parent. The categories still hold enabled courses (6 indexed in
-- 391, 5 in 206, 1 in 205) — those courses are NOT touched and stay live via
-- their other category memberships; only these listing pages are removed.
--
-- Search redirects pointing at the three killed URLs are cleared (632 pattern)
-- so terms like "unity", "unreal engine", "game programming" fall back to
-- normal catalog search instead of dead-ending on a 404.
--
-- Same category pattern as 1253 / 1261. A catalog reindex + cache flush after
-- apply makes the change visible. SG-guarded; partner no-op. Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_cactive := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_cmenu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');

SET @cat_gaming := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'gaming-software-courses' LIMIT 1
);
SET @cat_unreal := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'unreal-engine-training-courses' LIMIT 1
);
SET @cat_unity := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'unity-training-courses' LIMIT 1
);

-- Drop per-store overrides so the store-0 disable wins everywhere.
DELETE FROM catalog_category_entity_int
WHERE entity_id IN (@cat_gaming, @cat_unreal, @cat_unity)
  AND attribute_id IN (@a_cactive, @a_cmenu)
  AND store_id <> 0
  AND @is_sg > 0;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, c.entity_id, 0
FROM catalog_category_entity c
WHERE c.entity_id IN (@cat_gaming, @cat_unreal, @cat_unity)
  AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, c.entity_id, 0
FROM catalog_category_entity c
WHERE c.entity_id IN (@cat_gaming, @cat_unreal, @cat_unity)
  AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flat mirror (store 1), guarded; 'DO 0' no-op where the table is absent.
SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @sql := IF(@has_flat > 0 AND @is_sg > 0,
  'UPDATE catalog_category_flat_store_1 SET is_active = 0, include_in_menu = 0
   WHERE entity_id IN (@cat_gaming, @cat_unreal, @cat_unity)',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

-- Clear search redirects that point at the killed pages (632 pattern).
UPDATE catalogsearch_query
SET redirect = NULL
WHERE @is_sg > 0
  AND (
    redirect LIKE '%/gaming-software-courses.html%'
    OR redirect LIKE '%/unreal-engine-training-courses.html%'
    OR redirect LIKE '%/unity-training-courses.html%'
  );
