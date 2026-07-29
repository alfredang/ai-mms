-- 843: Rename the master course-listing category "Adult Courses" to
-- "All Courses" (owner request 2026-07-29). Label-only change: url_key stays
-- `adult-training-courses` so no URL/301 churn; meta_* SEO copy untouched.
-- The storefront heading, breadcrumb and mega-menu item all read the category
-- name, so this one attribute drives them all.
--
-- Partner-safe: category resolved by url_key (ids differ per site; catalog
-- parity means the same category/name exists on MY/GH). Idempotent: the
-- `value='Adult Courses'` guard makes re-runs no-ops.
--
-- Flat mirror is GUARDED via information_schema per the category-ordering
-- skill (never name a bare/unguarded flat table — migration 590 outage), so
-- the rename lands without waiting for a Category Flat Data reindex.

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'adult-training-courses' LIMIT 1);
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');

-- EAV source of truth (store 0 + any store-specific override rows).
UPDATE catalog_category_entity_varchar SET value = 'All Courses'
WHERE entity_id = @cat AND attribute_id = @a_name AND value = 'Adult Courses' AND @cat IS NOT NULL;

-- Guarded flat mirror, one block per active store (SG=1, MY=2, GH=3).
SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_1') > 0,
  "UPDATE catalog_category_flat_store_1 SET name='All Courses' WHERE name='Adult Courses'", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_2') > 0,
  "UPDATE catalog_category_flat_store_2 SET name='All Courses' WHERE name='Adult Courses'", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_3') > 0,
  "UPDATE catalog_category_flat_store_3 SET name='All Courses' WHERE name='Adult Courses'", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
