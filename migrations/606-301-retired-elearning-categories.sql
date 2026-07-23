-- 301 the retired eLearning category URLs to Instructional Design.
--
--   elearning-courses.html                     -> instructional-design-courses.html
--   elearning-content-creation-courses.html    -> instructional-design-courses.html
--   learning-management-system-lms-courses.html-> instructional-design-courses.html
--
-- Migration 605 drained and disabled these categories, so their own URLs would
-- 404. They are real indexed landing pages, so send them to the category that
-- absorbed their courses rather than leaving dead ends.
--
-- ORDER OF OPERATIONS (learned the hard way on prod 2026-07-18, migration 588):
-- a `catalog_url` reindex REGENERATES the rewrite row for a disabled category
-- as `catalog/category/view/id/<id>`, which then 301s into a 404. So this
-- migration must be (re-)applied AFTER any catalog_url reindex, not before.
-- The UPDATE below therefore matches the regenerated id-path target as well as
-- an already-correct row, so re-running always restores the right target.
--
-- Nested product rewrites under elearning-courses/... are deliberately LEFT
-- ALONE: they resolve to catalog/product/view/... and keep working regardless
-- of the category's status. Rewriting them would be churn with no benefit.
--
-- Category ids/url_keys resolved BY NAME so this is a no-op on partner sites.
-- Guarded so it never overwrites an existing intentional redirect and never
-- creates a self-referencing loop. Store 1 (SG). Idempotent.

SET @s := 1;
SET @a_cname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_cuk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');

SET @md := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_cname AND v.store_id=0
  WHERE TRIM(v.value)='Media & Design' AND e.level=3 LIMIT 1) r);

SET @id13 := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_cname AND v.store_id=0
  WHERE TRIM(v.value)='Instructional Design' AND e.parent_id=@md LIMIT 1) r);

SET @el := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_cname AND v.store_id=0
  WHERE TRIM(v.value)='eLearning' AND e.parent_id=@md LIMIT 1) r);

SET @elcc := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_cname AND v.store_id=0
  WHERE TRIM(v.value)='eLearning Content Creation' AND e.parent_id=@el LIMIT 1) r);

SET @lms := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_cname AND v.store_id=0
  WHERE TRIM(v.value)='Learning Management System (LMS)' AND e.parent_id=@el LIMIT 1) r);

SET @dst := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@id13 AND attribute_id=@a_cuk AND store_id=0 LIMIT 1);

SET @src_el   := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@el AND attribute_id=@a_cuk AND store_id=0 LIMIT 1);
SET @src_elcc := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@elcc AND attribute_id=@a_cuk AND store_id=0 LIMIT 1);
SET @src_lms  := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@lms AND attribute_id=@a_cuk AND store_id=0 LIMIT 1);

SET @ok := (@id13 IS NOT NULL AND @dst IS NOT NULL);

-- Re-point an existing rewrite (incl. the id-path target a reindex regenerates).
UPDATE core_url_rewrite
SET target_path = @dst, options = 'RP', is_system = 0
WHERE @ok AND store_id = @s
  AND request_path IN (@src_el, @src_elcc, @src_lms)
  AND request_path <> @dst
  AND (target_path = CONCAT('catalog/category/view/id/', @el)
    OR target_path = CONCAT('catalog/category/view/id/', @elcc)
    OR target_path = CONCAT('catalog/category/view/id/', @lms)
    OR target_path = @dst);

-- Create the redirect when no row exists at all.
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT @s, CONCAT('rp_cat_', c.id, '_retired'), c.src, @dst, 0, 'RP'
FROM (
  SELECT @el AS id, @src_el AS src UNION ALL
  SELECT @elcc, @src_elcc UNION ALL
  SELECT @lms, @src_lms
) c
WHERE @ok AND c.id IS NOT NULL AND c.src IS NOT NULL AND c.src <> @dst
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.store_id=@s AND x.request_path=c.src);
