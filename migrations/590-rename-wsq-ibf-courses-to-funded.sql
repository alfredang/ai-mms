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

-- NOTE: the flat category tables are deliberately NOT touched here.
--
-- The original version of this migration ran
--   UPDATE catalog_category_flat SET ...
-- but there is no unsuffixed catalog_category_flat — flat data lives in
-- per-store catalog_category_flat_store_N tables, and which of those exist
-- differs per site. Naming a missing table made apply.php abort the whole
-- chain, the container exit non-zero, and every SG route 502.
--
-- The EAV writes above are the source of truth. The storefront menu picks
-- the new names up when Category Flat Data is reindexed, which is the
-- documented post-deploy step for category renames — no DDL-fragile flat
-- mirror needed here.
