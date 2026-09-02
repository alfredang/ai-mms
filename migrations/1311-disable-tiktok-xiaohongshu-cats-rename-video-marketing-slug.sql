-- 1311: Video Marketing category housekeeping (SG only)
--   1. Disable the "Tiktok" (395) and "XiaoHongshu" (103) sub-categories.
--   2. Redirect all TikTok / XiaoHongshu search terms to the Video Marketing category.
--   3. Rename Video Marketing's slug
--        video-marketing-live-streaming.html -> video-marketing-live-streaming-courses.html
--      with a 301 on the old slug, and repoint every stored reference.
--
-- Context: cat 103's only product (C927) is already disabled; cat 395's only product
-- (C1373 Generative AI for Video Creation) also sits in parent cat 418, so nothing is
-- orphaned by hiding these two children.
--
-- SG guard: COUNT is 2 on this install, so test > 0, never = 1.
-- (feedback_sg_guard_count_is_two_test_greater_than_zero)

SET @is_sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @a_is_active       := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'is_active'       AND entity_type_id = 3);
SET @a_include_in_menu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'include_in_menu' AND entity_type_id = 3);
SET @a_url_key         := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key'         AND entity_type_id = 3);

SET @new_slug := 'video-marketing-live-streaming-courses';
SET @old_url  := 'https://www.tertiarycourses.com.sg/video-marketing-live-streaming.html';
SET @new_url  := 'https://www.tertiarycourses.com.sg/video-marketing-live-streaming-courses.html';

-- ---------------------------------------------------------------------------
-- 1. Disable Tiktok (395) + XiaoHongshu (103): is_active = 0 AND include_in_menu = 0
-- ---------------------------------------------------------------------------

UPDATE catalog_category_entity_int
SET value = 0
WHERE @is_sg > 0
  AND entity_id IN (103, 395)
  AND attribute_id IN (@a_is_active, @a_include_in_menu);

-- create the rows at default scope if an install lacks them
INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, c.entity_id, 0
FROM (SELECT 103 AS entity_id UNION ALL SELECT 395) c
CROSS JOIN (SELECT @a_is_active AS attribute_id UNION ALL SELECT @a_include_in_menu) a
WHERE @is_sg > 0
  AND NOT EXISTS (
    SELECT 1 FROM catalog_category_entity_int x
    WHERE x.entity_id = c.entity_id AND x.attribute_id = a.attribute_id AND x.store_id = 0
  );

-- drop them out of the storefront category index so they stop rendering
DELETE FROM catalog_category_product_index WHERE @is_sg > 0 AND category_id IN (103, 395);

-- ---------------------------------------------------------------------------
-- 2. Rename the Video Marketing (418) slug + 301 the old one
-- ---------------------------------------------------------------------------

UPDATE catalog_category_entity_varchar
SET value = @new_slug
WHERE @is_sg > 0 AND entity_id = 418 AND attribute_id = @a_url_key;

-- category self-rewrite -> new request_path
UPDATE core_url_rewrite
SET request_path = CONCAT(@new_slug, '.html')
WHERE @is_sg > 0
  AND id_path = 'category/418'
  AND request_path <> CONCAT(@new_slug, '.html');

-- product rewrites nested under the category path
UPDATE core_url_rewrite
SET request_path = CONCAT(@new_slug, SUBSTRING(request_path, LENGTH('video-marketing-live-streaming') + 1))
WHERE @is_sg > 0
  AND category_id = 418
  AND request_path LIKE 'video-marketing-live-streaming/%';

-- 301 the old category URL to the new one ('RP' = permanent; is_system = 0 = manual)
UPDATE core_url_rewrite
SET target_path = CONCAT(@new_slug, '.html'), options = 'RP', is_system = 0
WHERE @is_sg > 0
  AND request_path = 'video-marketing-live-streaming.html'
  AND store_id IN (0, 1);

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('video-marketing-live-streaming.html'), '-', s.store_id),
       'video-marketing-live-streaming.html',
       CONCAT(@new_slug, '.html'),
       0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @is_sg > 0
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite x
    WHERE x.request_path = 'video-marketing-live-streaming.html' AND x.store_id = s.store_id
  );

-- ---------------------------------------------------------------------------
-- 3. Search-term redirects
-- ---------------------------------------------------------------------------

-- 3a. Repoint existing redirects that stored the OLD category URL (youtube,
--     live streaming, esp32-CAM, video marketing, ...) so they take one hop.
UPDATE catalogsearch_query
SET redirect = @new_url
WHERE @is_sg > 0 AND store_id = 1 AND redirect = @old_url;

-- 3b. Send every TikTok / XiaoHongshu search term to the Video Marketing category.
--     NOT (redirect <=> ?) is the NULL-safe guard: it fills unset rows AND
--     overwrites rows pointing elsewhere, while no-opping on already-correct rows.
--     (feedback_search_redirect_correction_guard_must_be_null_safe)
UPDATE catalogsearch_query
SET redirect = @new_url, num_results = 1, is_processed = 1
WHERE @is_sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @new_url)
  AND (
        LOWER(query_text) LIKE '%tiktok%'
     OR LOWER(query_text) LIKE '%tik tok%'
     OR LOWER(query_text) LIKE '%xiaohongshu%'
     OR LOWER(query_text) LIKE '%xiao hong shu%'
     OR LOWER(query_text) LIKE '%rednote%'
     OR LOWER(query_text) LIKE '%red note%'
  );

-- 3c. The two now-disabled category pages must never be a redirect target.
UPDATE catalogsearch_query
SET redirect = @new_url, num_results = 1, is_processed = 1
WHERE @is_sg > 0
  AND store_id = 1
  AND (redirect LIKE '%tiktok-social-media-courses%'
    OR redirect LIKE '%xiaohongshu-social-commerce-courses%');

-- 3d. Historical 301 rows (options='RP') whose TARGET still points at the old
--     category path would now chain: old-target -> manual 301 -> new slug.
--     Rewrite those targets onto the new slug so every 301 is a single hop.
UPDATE core_url_rewrite
SET target_path = CONCAT(@new_slug, SUBSTRING(target_path, LENGTH('video-marketing-live-streaming') + 1))
WHERE @is_sg > 0
  AND target_path LIKE 'video-marketing-live-streaming/%';
