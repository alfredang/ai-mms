-- 643: Rename category "React JS" -> "React" (SG /react-js-courses.html).
-- Display name only: url_key and meta_title are intentionally untouched
-- (meta_title already reads "React ..."), so no URL change and no 301s.
-- Idempotent: matched on url_key + old name, so a re-run is a no-op.
-- Partner-safe: resolved by url_key, not entity_id; updates 0 rows where
-- the category is absent or already renamed.

UPDATE catalog_category_entity_varchar v
JOIN eav_attribute a
  ON a.attribute_id = v.attribute_id
 AND a.attribute_code = 'name'
JOIN eav_entity_type t
  ON t.entity_type_id = a.entity_type_id
 AND t.entity_type_code = 'catalog_category'
JOIN catalog_category_entity_varchar uk
  ON uk.entity_id = v.entity_id
JOIN eav_attribute ua
  ON ua.attribute_id = uk.attribute_id
 AND ua.attribute_code = 'url_key'
 AND ua.entity_type_id = a.entity_type_id
SET v.value = 'React'
WHERE uk.value = 'react-js-courses'
  AND v.value = 'React JS';

-- Flat tables deliberately untouched (per-store *_store_N names differ per
-- site; see 590). Post-deploy: Category Flat Data reindex + cache flush.
