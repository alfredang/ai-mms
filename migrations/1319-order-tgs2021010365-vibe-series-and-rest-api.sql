-- 1319 : Ordering fix for TGS-2021010365 "WSQ - Create REST APIs with AI Vibe Coding"
--
-- Migration 1318 added the course to categories 252 / 414 / 425 using
-- MAX(position)+1. That is only safe in an all-TGS category. Category 414
-- (AI Vibe Coding Series) also holds 23 C-prefix courses, so the course landed
-- at position 52 - BELOW the entire non-WSQ block, breaking the funded-first
-- rule. This is the exact failure the category-ordering skill documents
-- (precedent: migration 1269 -> fixed by 1273).
--
-- 414 "AI Vibe Coding Series" is a CURATED category (listed in
-- mmd/category_ordering/curated_url_keys), so a global 545/1201-style renumber
-- is NOT used here - it would flatten the hand-curated non-WSQ order. Instead
-- the single offending TGS- row is lifted above the C-block, which is the
-- targeted treatment the skill prescribes for curated categories.
--
-- 425 "WSQ AI Vibe Coding Courses" is already correct (all-TGS, position 22).
--
-- 388 "REST API": course is pinned to FIRST position per the owner's request;
-- the other TGS- rows shift down, and the C-prefix course stays last.
--
-- Both catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the storefront actually sorts by) are
-- written, for every store_id present on this instance.
--
-- Categories are resolved by url_key, not hardcoded id, so the file is
-- partner-safe; the @is_sg guard makes it a no-op on MY/GH, which never held
-- this SKU.

SET @is_sg := (SELECT COUNT(*) FROM core_config_data
               WHERE path = 'web/unsecure/base_url' AND value LIKE '%tertiarycourses.com.sg%');

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021010365');

SET @a_catkey := (SELECT attribute_id FROM eav_attribute
                  WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @cat_series := (SELECT v.entity_id FROM catalog_category_entity_varchar v
                    WHERE v.attribute_id = @a_catkey AND v.store_id = 0
                      AND v.value = 'ai-vibe-coding-series' LIMIT 1);

SET @cat_restapi := (SELECT v.entity_id FROM catalog_category_entity_varchar v
                     WHERE v.attribute_id = @a_catkey AND v.store_id = 0
                       AND v.value = 'rest-api-courses' LIMIT 1);

-- =====================================================================
-- 414 AI Vibe Coding Series : lift the course above the whole C-block.
-- =====================================================================
-- Target = one slot below the LAST TGS- row, i.e. the bottom of the funded
-- block but still above every non-WSQ course. Computed from the index, which
-- is what the storefront reads and which also carries anchor-inherited rows.

SET @series_last_tgs := (
  SELECT MAX(i.position) FROM catalog_category_product_index i
  JOIN catalog_product_entity p ON p.entity_id = i.product_id
  WHERE i.category_id = @cat_series AND i.store_id = 1
    AND p.sku LIKE 'TGS-%' AND p.entity_id <> @e);

SET @series_first_c := (
  SELECT MIN(i.position) FROM catalog_category_product_index i
  JOIN catalog_product_entity p ON p.entity_id = i.product_id
  WHERE i.category_id = @cat_series AND i.store_id = 1
    AND p.sku NOT LIKE 'TGS-%');

-- Only act when the course really is stranded below a non-WSQ course.
SET @series_needs_fix := (
  SELECT CASE WHEN @series_first_c IS NOT NULL
               AND (SELECT MIN(i.position) FROM catalog_category_product_index i
                    WHERE i.category_id = @cat_series AND i.store_id = 1
                      AND i.product_id = @e) > @series_first_c
              THEN 1 ELSE 0 END);

-- Open a gap: push the C-block (and anything below it) down by one.
UPDATE catalog_category_product_index
   SET position = position + 1
 WHERE category_id = @cat_series
   AND position >= @series_first_c
   AND product_id <> @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_series IS NOT NULL
   AND @series_needs_fix = 1;

UPDATE catalog_category_product
   SET position = position + 1
 WHERE category_id = @cat_series
   AND position >= @series_first_c
   AND product_id <> @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_series IS NOT NULL
   AND @series_needs_fix = 1;

-- Drop the course into the gap: last of the funded block, above every C course.
UPDATE catalog_category_product_index
   SET position = @series_last_tgs + 1
 WHERE category_id = @cat_series AND product_id = @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_series IS NOT NULL
   AND @series_needs_fix = 1;

UPDATE catalog_category_product
   SET position = @series_last_tgs + 1
 WHERE category_id = @cat_series AND product_id = @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_series IS NOT NULL
   AND @series_needs_fix = 1;

-- =====================================================================
-- 388 REST API : pin the course FIRST.
-- =====================================================================
-- Shift every other product down by one, then seat the course at position 1.
-- Guarded so a re-run (course already first) is a clean no-op.

SET @restapi_needs_fix := (
  SELECT CASE WHEN (SELECT MIN(i.position) FROM catalog_category_product_index i
                    WHERE i.category_id = @cat_restapi AND i.store_id = 1
                      AND i.product_id = @e) > 1
              THEN 1 ELSE 0 END);

UPDATE catalog_category_product_index
   SET position = position + 1
 WHERE category_id = @cat_restapi AND product_id <> @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_restapi IS NOT NULL
   AND @restapi_needs_fix = 1;

UPDATE catalog_category_product
   SET position = position + 1
 WHERE category_id = @cat_restapi AND product_id <> @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_restapi IS NOT NULL
   AND @restapi_needs_fix = 1;

UPDATE catalog_category_product_index
   SET position = 1
 WHERE category_id = @cat_restapi AND product_id = @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_restapi IS NOT NULL
   AND @restapi_needs_fix = 1;

UPDATE catalog_category_product
   SET position = 1
 WHERE category_id = @cat_restapi AND product_id = @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_restapi IS NOT NULL
   AND @restapi_needs_fix = 1;
