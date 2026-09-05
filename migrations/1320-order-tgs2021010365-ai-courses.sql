-- 1320 : Ordering fix for TGS-2021010365 in category 252 "AI Courses"
--
-- Same root cause as 1319: migration 1318 appended the course with
-- MAX(position)+1, landing it at 244 while the non-WSQ block starts at 114 -
-- i.e. below every C-prefix course, breaking the funded-first rule. 1319 fixed
-- AI Vibe Coding Series and REST API; the catalog-wide audit query from the
-- category-ordering skill then surfaced this third category.
--
-- "artificial-intelligence-courses" is CURATED (listed in
-- mmd/category_ordering/curated_url_keys), so only the offending TGS- row is
-- moved; the curated non-WSQ order is left byte-identical. A windowing
-- renumber was tried and rejected: this category also carries stale
-- anchor-inherited positions (60028 / 100033-style) which make MAX(position)
-- over the funded rows meaningless, and re-sorting risks the curated block.
--
-- The course is placed at (last funded row that is still ABOVE the C-block) + 1,
-- computed with an explicit "< first C position" bound so stale anchor rows
-- cannot skew it. Remaining rows are untouched: position 114 is occupied by the
-- first C course, and duplicate positions sort deterministically by product_id,
-- so no gap-opening shift is needed - but the funded row is guaranteed to sort
-- above the whole C-block.
--
-- Idempotent: the guard no-ops once the course already sits above the C-block.
-- Partner-safe (url_key lookup + @is_sg guard).

SET @is_sg := (SELECT COUNT(*) FROM core_config_data
               WHERE path = 'web/unsecure/base_url' AND value LIKE '%tertiarycourses.com.sg%');

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021010365');

SET @cat_ai := (SELECT v.entity_id FROM catalog_category_entity_varchar v
                JOIN eav_attribute a ON a.attribute_id = v.attribute_id
                 AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
                WHERE v.store_id = 0 AND v.value = 'artificial-intelligence-courses' LIMIT 1);

-- Where the non-WSQ block starts.
SET @ai_first_c := (
  SELECT MIN(i.position) FROM catalog_category_product_index i
  JOIN catalog_product_entity p ON p.entity_id = i.product_id
  WHERE i.category_id = @cat_ai AND i.store_id = 1
    AND p.sku NOT LIKE 'TGS-%');

-- Last funded row that is genuinely inside the funded block (bounded, so the
-- stale anchor-inherited rows far below cannot skew it).
SET @ai_last_tgs := (
  SELECT MAX(i.position) FROM catalog_category_product_index i
  JOIN catalog_product_entity p ON p.entity_id = i.product_id
  WHERE i.category_id = @cat_ai AND i.store_id = 1
    AND p.sku LIKE 'TGS-%' AND p.entity_id <> @e
    AND i.position < @ai_first_c);

SET @ai_needs_fix := (
  SELECT CASE WHEN @ai_first_c IS NOT NULL AND @ai_last_tgs IS NOT NULL
               AND (SELECT MIN(i.position) FROM catalog_category_product_index i
                    WHERE i.category_id = @cat_ai AND i.store_id = 1
                      AND i.product_id = @e) > @ai_first_c
              THEN 1 ELSE 0 END);

-- Open a one-slot gap at the bottom of the funded block.
UPDATE catalog_category_product_index
   SET position = position + 1
 WHERE category_id = @cat_ai
   AND position > @ai_last_tgs
   AND position < 60000                    -- leave stale anchor rows alone
   AND product_id <> @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_ai IS NOT NULL AND @ai_needs_fix = 1;

UPDATE catalog_category_product
   SET position = position + 1
 WHERE category_id = @cat_ai
   AND position > @ai_last_tgs
   AND position < 60000
   AND product_id <> @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_ai IS NOT NULL AND @ai_needs_fix = 1;

UPDATE catalog_category_product_index
   SET position = @ai_last_tgs + 1
 WHERE category_id = @cat_ai AND product_id = @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_ai IS NOT NULL AND @ai_needs_fix = 1;

UPDATE catalog_category_product
   SET position = @ai_last_tgs + 1
 WHERE category_id = @cat_ai AND product_id = @e
   AND @is_sg > 0 AND @e IS NOT NULL AND @cat_ai IS NOT NULL AND @ai_needs_fix = 1;
