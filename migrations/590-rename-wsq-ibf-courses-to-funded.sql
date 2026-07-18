-- 588: Rename menu categories "WSQ Courses" -> "WSQ Funded Courses"
--      and "IBF Courses" -> "IBF Funded Courses".
-- Display name only: url_key and meta_title are intentionally untouched,
-- so no URL change and no 301 rewrites are required.
-- Idempotent: matched on the old value, so a re-run is a no-op.

-- EAV (store 0). Category ids resolved by name, not hardcoded, so the
-- migration is safe on partner DBs where ids may differ (or the category
-- is absent, in which case this updates 0 rows).
UPDATE catalog_category_entity_varchar v
JOIN eav_attribute a
  ON a.attribute_id = v.attribute_id
 AND a.attribute_code = 'name'
JOIN eav_entity_type t
  ON t.entity_type_id = a.entity_type_id
 AND t.entity_type_code = 'catalog_category'
SET v.value = 'WSQ Funded Courses'
WHERE v.value = 'WSQ Courses';

UPDATE catalog_category_entity_varchar v
JOIN eav_attribute a
  ON a.attribute_id = v.attribute_id
 AND a.attribute_code = 'name'
JOIN eav_entity_type t
  ON t.entity_type_id = a.entity_type_id
 AND t.entity_type_code = 'catalog_category'
SET v.value = 'IBF Funded Courses'
WHERE v.value = 'IBF Courses';

-- Mirror into the flat category tables so the storefront menu reflects the
-- rename without waiting on a reindex.
UPDATE catalog_category_flat SET name = 'WSQ Funded Courses' WHERE name = 'WSQ Courses';
UPDATE catalog_category_flat SET name = 'IBF Funded Courses' WHERE name = 'IBF Courses';
UPDATE catalog_category_flat_store_1 SET name = 'WSQ Funded Courses' WHERE name = 'WSQ Courses';
UPDATE catalog_category_flat_store_1 SET name = 'IBF Funded Courses' WHERE name = 'IBF Courses';
