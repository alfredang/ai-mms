-- 1263: Deactivate the "Orange" category page (is_active = 0,
-- include_in_menu = 0 at store 0), on explicit request:
--   237 orange-courses (leaf under 1/2/53/140, no children)
--
-- The category still holds one enabled course — the course is NOT touched and
-- stays live via its other category memberships; only this listing page is
-- removed. The one search redirect pointing at the killed URL ("orange") is
-- cleared (632 pattern) so the term falls back to normal catalog search.
--
-- Same category pattern as 1253 / 1261 / 1262. A catalog reindex + cache
-- flush after apply makes the change visible. SG-guarded; partner no-op.
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_cactive := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_cmenu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');

SET @cat_orange := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'orange-courses' LIMIT 1
);

-- Drop per-store overrides so the store-0 disable wins everywhere.
DELETE FROM catalog_category_entity_int
WHERE entity_id = @cat_orange
  AND attribute_id IN (@a_cactive, @a_cmenu)
  AND store_id <> 0
  AND @cat_orange IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, @cat_orange, 0
FROM dual WHERE @cat_orange IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @cat_orange, 0
FROM dual WHERE @cat_orange IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flat mirror (store 1), guarded; 'DO 0' no-op where the table is absent.
SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @sql := IF(@has_flat > 0 AND @cat_orange IS NOT NULL AND @is_sg > 0,
  'UPDATE catalog_category_flat_store_1 SET is_active = 0, include_in_menu = 0 WHERE entity_id = @cat_orange',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

-- Clear the search redirect that points at the killed page (632 pattern).
UPDATE catalogsearch_query
SET redirect = NULL
WHERE @is_sg > 0
  AND redirect LIKE '%/orange-courses.html%';
