-- 301 the retired "Soft Skills" category URL to its parent.
--
-- Migration 586 flattened the Soft Skills sub-tree into "Business & Soft
-- Skills" and disabled the now-empty container (id 300). Its own URL
-- (critical-core-soft-skills-courses.html) therefore 404s -- it was a real
-- indexed landing page, so send it to the parent instead of leaving a dead end.
--
-- The ~29 nested product rewrites under critical-core-soft-skills-courses/...
-- are deliberately LEFT ALONE: they resolve to catalog/product/view/... and
-- keep working independently of the category's status. Rewriting them would be
-- churn with no benefit.
--
-- Category ids/url_keys resolved BY NAME so this is a no-op on partner sites.
-- Guarded so it never overwrites an existing intentional redirect, and never
-- creates a self-referencing loop. Idempotent.
--
-- ORDER OF OPERATIONS (learned the hard way on prod 2026-07-18): a
-- `catalog_url` reindex REGENERATES the rewrite row for a disabled category as
-- `catalog/category/view/id/<id>`, which then 301s into a 404. So this
-- migration must be (re-)applied AFTER any catalog_url reindex, not before.
-- The UPDATE below therefore matches the regenerated id-path target as well as
-- an already-correct row, so re-running always restores the right target.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');

SET @bss := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Business & Soft Skills' AND e.level=3 LIMIT 1) r);

SET @ss := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Soft  Skills' AND e.parent_id=@bss LIMIT 1) r);

SET @src := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@ss AND attribute_id=@a_uk AND store_id=0 LIMIT 1);
SET @dst := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@bss AND attribute_id=@a_uk AND store_id=0 LIMIT 1);

SET @ok := (@bss IS NOT NULL AND @ss IS NOT NULL AND @src IS NOT NULL AND @dst IS NOT NULL AND @src <> @dst);

-- Point the retired category URL at the parent with a permanent redirect.
-- Matches BOTH the id-path target that a catalog_url reindex regenerates and
-- an already-corrected row, so this is safe to re-run after any reindex.
UPDATE core_url_rewrite
SET target_path = @dst, options = 'RP', is_system = 0, category_id = NULL
WHERE @ok AND request_path = @src
  AND (target_path = CONCAT('catalog/category/view/id/', @ss) OR target_path = @dst);

-- If no rewrite row exists for the old slug, create one per store.
INSERT INTO core_url_rewrite (store_id, category_id, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, @src, @dst, 0, 'RP'
FROM core_store s
WHERE @ok AND s.store_id > 0
  AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                  WHERE x.request_path = @src AND x.store_id = s.store_id);
