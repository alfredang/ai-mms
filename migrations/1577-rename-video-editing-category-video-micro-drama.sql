-- 1577: Rename the "Video Editing" category (SG cat 129) to "Video & Micro Drama"
--   name     Video Editing                -> Video & Micro Drama
--   url_key  video-editing-courses-in     -> video-micro-drama-courses
--   description + meta_title/description/keywords rewritten for the new scope.
--
-- Slug-rename collateral (feedback_category_slug_rename_breaks_stored_redirects_and_chains,
-- feedback_category_slug_301_guard_and_flat_meta):
--   * category + category-prefixed product system rewrites move to the new slug,
--     and every old path gets a 301 (is_system = 0, survives catalog_url reindex);
--   * historical RP rows whose TARGET is on the old slug are flattened (no 301 chains);
--   * stored search redirects are matched on the `redirect` column, not query_text;
--   * catalog_category_flat_store_1 is updated too (storefront reads flat meta).
--
-- SG-guarded (store code 'singapore'; test > 0) and the category is resolved by its
-- url_key, so partners no-op. Idempotent: every statement keys off old/new slug state.

SET @is_sg := (SELECT COUNT(*) FROM core_store WHERE code = 'singapore');

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_urlpth := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @a_metat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_metad  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description');
SET @a_metak  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords');

SET @old := 'video-editing-courses-in';
SET @new := 'video-micro-drama-courses';

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE @is_sg > 0 AND v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value IN (@old, @new)
  LIMIT 1);

SET @new_name  := 'Video & Micro Drama';
SET @new_metat := 'Video & Micro Drama Courses in Singapore';
SET @new_metad := 'Learn video production and micro drama creation in Singapore: scriptwriting, mobile filming, Premiere Pro and After Effects editing, and generative AI video workflows. WSQ and CASL courses with SkillsFuture funding.';
SET @new_metak := 'micro drama, short drama, vertical video, video production, video editing, Premiere Pro, After Effects, AI video creation, scriptwriting, storytelling, mobile videography';
SET @new_desc  := '<p>Micro dramas - bite-sized, vertical-format drama series told in episodes of one to three minutes - are one of the fastest-growing forms of video entertainment, and short-form video now drives marketing, training and brand storytelling across every industry. Our Video &amp; Micro Drama courses teach you to take an idea from script to screen: writing hooks and cliffhangers, storyboarding, shooting on a smartphone or camera, and editing footage into polished, platform-ready episodes.</p>\n<p>Build hands-on skills with industry-standard tools such as Adobe Premiere Pro and After Effects for editing, colour and visual effects, and learn how generative AI and agentic AI workflows speed up scriptwriting, storyboarding, video generation and post-production. Topics span mobile photography and videography, compositing and motion graphics, AI-assisted script development and storytelling, and producing short films and serialised content with AI.</p>\n<p>Whether you are a content creator, marketer, educator or aspiring filmmaker, our practical, instructor-led classes help you produce engaging video and micro drama content with confidence. Many of our WSQ and CASL courses are eligible for SkillsFuture funding. Browse the courses below and start creating today.</p>';

-- ---------------------------------------------------------------------------
-- 1. EAV (store 0) - name, slug, url_path, description, meta
-- ---------------------------------------------------------------------------

UPDATE catalog_category_entity_varchar SET value = @new_name
WHERE entity_id = @cat AND attribute_id = @a_name AND store_id = 0;

UPDATE catalog_category_entity_varchar SET value = @new
WHERE entity_id = @cat AND attribute_id = @a_urlkey AND store_id = 0;

UPDATE catalog_category_entity_varchar SET value = REPLACE(value, CONCAT(@old, '.html'), CONCAT(@new, '.html'))
WHERE entity_id = @cat AND attribute_id = @a_urlpth;

UPDATE catalog_category_entity_varchar SET value = @new_metat
WHERE entity_id = @cat AND attribute_id = @a_metat AND store_id = 0;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metat, 0, @cat, @new_metat FROM DUAL
WHERE @cat IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_varchar x
  WHERE x.entity_id = @cat AND x.attribute_id = @a_metat AND x.store_id = 0);

UPDATE catalog_category_entity_text SET value = @new_desc
WHERE entity_id = @cat AND attribute_id = @a_desc AND store_id = 0;

UPDATE catalog_category_entity_text SET value = @new_metad
WHERE entity_id = @cat AND attribute_id = @a_metad AND store_id = 0;

UPDATE catalog_category_entity_text SET value = @new_metak
WHERE entity_id = @cat AND attribute_id = @a_metak AND store_id = 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, a.val
FROM (SELECT @a_desc AS attribute_id, @new_desc AS val
      UNION ALL SELECT @a_metad, @new_metad
      UNION ALL SELECT @a_metak, @new_metak) a
WHERE @cat IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_text x
  WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- ---------------------------------------------------------------------------
-- 2. Flat table (the storefront reads name/meta/url from here)
-- ---------------------------------------------------------------------------

SET @has_flat := (SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1');

SET @sql := IF(@has_flat > 0 AND @cat IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET name = @new_name, url_key = @new, url_path = CONCAT(@new, ''.html''), description = @new_desc, meta_title = @new_metat, meta_description = @new_metad, meta_keywords = @new_metak WHERE entity_id = @cat',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------------
-- 3. URL rewrites
-- ---------------------------------------------------------------------------

-- 3a. category system rows -> new slug
UPDATE core_url_rewrite SET request_path = CONCAT(@new, '.html')
WHERE @cat IS NOT NULL AND id_path = CONCAT('category/', @cat) AND is_system = 1
  AND request_path = CONCAT(@old, '.html');

-- 3b. category-prefixed product system rows -> new slug prefix
UPDATE core_url_rewrite
SET request_path = CONCAT(@new, SUBSTRING(request_path, LENGTH(@old) + 1))
WHERE @cat IS NOT NULL AND is_system = 1 AND category_id = @cat
  AND request_path LIKE 'video-editing-courses-in/%';

-- 3c. 301 the old category URL (the system row has moved off it in 3a)
INSERT INTO core_url_rewrite (store_id, category_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, @cat, CONCAT('mmd_cat_rename_', MD5(CONCAT(@old, '.html'))),
       CONCAT(@old, '.html'), CONCAT(@new, '.html'), 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @cat IS NOT NULL AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
  WHERE x.request_path = CONCAT(@old, '.html') AND x.store_id = s.store_id);

-- 3d. 301 each old category-prefixed product URL to its new-prefix twin
INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT r.store_id, r.category_id, r.product_id,
       CONCAT('mmd_cat_rename_', MD5(CONCAT(@old, SUBSTRING(r.request_path, LENGTH(@new) + 1)))),
       CONCAT(@old, SUBSTRING(r.request_path, LENGTH(@new) + 1)), r.request_path, 0, 'RP'
FROM core_url_rewrite r
WHERE @cat IS NOT NULL AND r.is_system = 1 AND r.category_id = @cat
  AND r.request_path LIKE 'video-micro-drama-courses/%'
  AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite) x
    WHERE x.request_path = CONCAT(@old, SUBSTRING(r.request_path, LENGTH(@new) + 1))
      AND x.store_id = r.store_id);

-- 3e. flatten historical 301s whose TARGET is still on the old slug
UPDATE core_url_rewrite
SET target_path = CONCAT(@new, SUBSTRING(target_path, LENGTH(@old) + 1))
WHERE @cat IS NOT NULL AND is_system = 0
  AND (target_path LIKE 'video-editing-courses-in/%' OR target_path = CONCAT(@old, '.html'));

-- ---------------------------------------------------------------------------
-- 4. Stored search redirects that pointed at the old category URL
-- ---------------------------------------------------------------------------

UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, CONCAT('/', @old, '.html'), CONCAT('/', @new, '.html'))
WHERE @cat IS NOT NULL AND redirect LIKE '%/video-editing-courses-in.html';
