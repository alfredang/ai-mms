-- 301 the retired "Game Development" category URL to "Gaming & Animation".
--
--   game-devleopment-courses-in.html -> gaming-animation-and-video-courses-in.html
--
-- Migration 607 drained and disabled the category, so its own URL would 404.
-- (The 'devleopment' typo is in the LIVE url_key and therefore in the indexed
-- URL — the source path is resolved from the DB, not hardcoded, so the typo is
-- carried correctly.)
--
-- ORDER OF OPERATIONS (learned the hard way on prod 2026-07-18, migration 588):
-- a `catalog_url` reindex REGENERATES the rewrite row for a disabled category
-- as `catalog/category/view/id/<id>`, which then 301s into a 404. So this
-- migration must be (re-)applied AFTER any catalog_url reindex, not before.
-- The UPDATE matches the regenerated id-path target as well as an
-- already-correct row, so re-running always restores the right target.
--
-- Nested product rewrites under the old category path are deliberately LEFT
-- ALONE: they resolve to catalog/product/view/... and keep working.
--
-- Resolved BY NAME so this is a no-op on partner sites. Guarded against a
-- self-referencing loop. Store 1 (SG). Idempotent.

SET @s := 1;
SET @a_cname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_cuk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');

SET @md := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_cname AND v.store_id=0
  WHERE TRIM(v.value)='Media & Design' AND e.level=3 LIMIT 1) r);

SET @ga := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_cname AND v.store_id=0
  WHERE TRIM(v.value)='Gaming & Animation' AND e.parent_id=@md LIMIT 1) r);

SET @gd := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_cname AND v.store_id=0
  WHERE TRIM(v.value)='Game Development' AND e.parent_id=@ga LIMIT 1) r);

SET @dst := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@ga AND attribute_id=@a_cuk AND store_id=0 LIMIT 1);
SET @src := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@gd AND attribute_id=@a_cuk AND store_id=0 LIMIT 1);

SET @ok := (@ga IS NOT NULL AND @gd IS NOT NULL AND @dst IS NOT NULL AND @src IS NOT NULL AND @src <> @dst);

-- Re-point an existing rewrite (incl. the id-path target a reindex regenerates).
UPDATE core_url_rewrite
SET target_path = @dst, options = 'RP', is_system = 0
WHERE @ok AND store_id = @s AND request_path = @src
  AND (target_path = CONCAT('catalog/category/view/id/', @gd) OR target_path = @dst);

-- Create the redirect when no row exists at all.
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT @s, CONCAT('rp_cat_', @gd, '_retired'), @src, @dst, 0, 'RP'
FROM DUAL
WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                          WHERE x.store_id=@s AND x.request_path=@src);
