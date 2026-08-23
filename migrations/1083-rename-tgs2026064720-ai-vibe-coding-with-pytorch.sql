-- 1083: Finish the TGS-2026064720 rename - "CASL - Predictive Analytics with
-- PyTorch: Transform Your Data to Prediction" -> "CASL - AI Vibe Coding with
-- PyTorch".
--
-- An earlier pass already moved most surfaces: url_key/url_path =
-- casl-ai-vibe-coding-with-pytorch (+ 301s for the old bare slug AND the
-- intermediate wsq-ai-vibe-coding-with-pytorch slug, is_system row clean, no
-- -id suffix), meta_description, meta_keyword, short_description, description
-- outline (5 AI Vibe Coding topics) and whoshouldattend are all on the new
-- topic already. This migration closes the remaining leaks found by the
-- pre-write EAV sweep (memory feedback_tgs_course_rename_checklist):
--
--   1. `name` (store 0) still carried the old title. Keep the "CASL - "
--      segment prefix (SKU unchanged, CASL tag present, casl- slug).
--   2. `meta_title` baked BOTH the "WSQ" token and the "| Tertiary Courses
--      Singapore" brand suffix that MMD_Seotitle re-adds at render time (the
--      853 bug), and this course is CASL, not WSQ. Set the PLAIN title.
--   3. The three *_label alt-text attrs + the media-gallery label said
--      "WSQ - AI Vibe Coding with PyTorch": labels carry the plain title
--      (no segment prefix), and the course is CASL.
--   4. short_description lead-in said "WSQ AI Vibe Coding with PyTorch" -
--      drop the WSQ token (CASL course).
--   5. meta_keyword led with "WSQ PyTorch course" -> "CASL PyTorch course".
--   6. trainerprofile: four COURSE-TEACHING claims still echoed the old
--      title's "transform data to prediction" framing. Retargeted those four
--      exact sentences only; every career credential ("Head of Data Science
--      at GoWild", "supervised 24 ML projects at IBM", "predictive modeling"
--      history) is factual and deliberately left alone. Single-line exact
--      REPLACEs (CRLF-safe).
--   7. catalogsearch_query rows still pointed at the superseded
--      wsq-predictive-analytics-with-pytorch-transform-your-data-to-prediction
--      slug, reaching the page only through a 301 chain. Flattened to the
--      live casl- slug, anchored on the FULL old filename so the sibling
--      PyTorch courses (deep-learning-with-pytorch,
--      wsq-building-advanced-machine-learning-and-ai-solutions-with-pytorch)
--      are untouched. Also fill the bare-course-code row (query_text =
--      'TGS-2026064720', redirect NULL) - only when empty, never overwriting
--      an intentional redirect.
--
-- Deliberately left alone (verified against live data before writing):
--   * image/small_image/thumbnail PATHS - filesystem paths, not display text;
--     the storefront renders course_image_url. Only the labels change.
--   * whoshouldattend - all 15 roles are deep-learning roles; "Predictive
--     Analytics Specialist" remains legitimate (Topic 3 is Predictive AI
--     with Regression and Classification). Not a leak.
--   * description outline, short_description body, meta_description - already
--     the AI Vibe Coding content.
--   * URL rewrites - old slug 301 and is_system row already correct.
--   * Categories (incl. 414 AI Vibe Coding Series) and badge tags (CASL,
--     SFEC, PSEA, MCES, Absentee Payroll) - already correct.
--   * Funding Validity dates - not supplied with this rename; not touched.
--   * course_image_url - the cover PNG bakes the title and is re-rendered
--     out-of-band (SQL cannot regenerate it).
--
-- Idempotent: plain converging UPDATEs / no-op REPLACEs; the bare-code fill
-- only writes NULL/empty. Partner-safe: keyed by TGS- SKU (@pid is NULL on
-- MY/GH so every UPDATE matches zero rows; the redirect LIKEs anchor on
-- SG-only slugs). ASCII-only values.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064720');
SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_ilabel := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_train  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');

-- 1. Course title (admin scope; no store-level overrides exist for name)
UPDATE catalog_product_entity_varchar
SET value = 'CASL - AI Vibe Coding with PyTorch'
WHERE entity_id = @pid AND attribute_id = @a_name AND store_id = 0;

-- 2. meta_title: PLAIN title - MMD_Seotitle composes the funding prefix and
--    the brand suffix at render time.
UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding with PyTorch'
WHERE entity_id = @pid AND attribute_id = @a_mtitle AND store_id = 0;

-- 3. Alt-text labels: plain title, no segment prefix
UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding with PyTorch'
WHERE entity_id = @pid AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'AI Vibe Coding with PyTorch'
WHERE g.entity_id = @pid AND @pid IS NOT NULL;

-- 4. short_description lead-in: drop the WSQ token (CASL course)
UPDATE catalog_product_entity_text
SET value = REPLACE(value,
    '<strong>WSQ AI Vibe Coding with PyTorch</strong>',
    '<strong>AI Vibe Coding with PyTorch</strong>')
WHERE entity_id = @pid AND attribute_id = @a_sdesc;

-- 5. meta_keyword: WSQ -> CASL
UPDATE catalog_product_entity_text
SET value = REPLACE(value, 'WSQ PyTorch course', 'CASL PyTorch course')
WHERE entity_id = @pid AND attribute_id = @a_mkey;

-- 6. trainerprofile: retarget the four course-teaching claims that echoed the
--    old "data to prediction" title. Career credentials untouched.
UPDATE catalog_product_entity_text
SET value = REPLACE(value,
    'His training emphasizes a practical, project-based approach to predictive analytics.',
    'His training emphasizes a practical, project-based approach to AI vibe coding with PyTorch.')
WHERE entity_id = @pid AND attribute_id = @a_train;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
    'applying predictive analytics to real-world challenges.',
    'applying AI-assisted deep learning to real-world challenges.')
WHERE entity_id = @pid AND attribute_id = @a_train;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
    'he equips participants to transform raw data into accurate and actionable predictions.',
    'he equips participants to build working deep learning applications rapidly with AI-assisted coding.')
WHERE entity_id = @pid AND attribute_id = @a_train;

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
    'equipping learners with practical skills to transform data into prediction.',
    'equipping learners with practical skills to build AI solutions from data.')
WHERE entity_id = @pid AND attribute_id = @a_train;

-- 7a. Flatten search-redirect 301 chains onto the live casl- slug.
-- Full-filename anchor: sibling PyTorch courses are untouched.
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect,
    '/wsq-predictive-analytics-with-pytorch-transform-your-data-to-prediction.html',
    '/casl-ai-vibe-coding-with-pytorch.html')
WHERE redirect LIKE '%/wsq-predictive-analytics-with-pytorch-transform-your-data-to-prediction.html';

-- 7b. Bare course code -> course page; only fill NULL/empty, never overwrite.
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/casl-ai-vibe-coding-with-pytorch.html'
WHERE query_text = 'TGS-2026064720'
  AND (redirect IS NULL OR redirect = '')
  AND @pid IS NOT NULL;
