-- 1571: TGS-2020505925 "WSQ - Generative AI for Image and Video Creation"
--       -> "WSQ - Create Short Video Film using AI"
--
-- Retitle/refocus on an unchanged competency (admin request 2026-09-27). The
-- SKU and the accredited TSC (skills_framework block: "Computer Vision
-- Technology ICT-DIT-4022-1.1") are UNCHANGED, so every SkillsFuture / SFEC /
-- SFC / PSEA deep link, the funding_and_grant block, the 6 funding tags, the
-- price ($900), duration (16) and sessions (2) all stay.
--
-- Pre-write probe (SG prod, entity 1131):
--   * cms_block course_TGS-2020505925_learning_outcomes -- the supplied
--     LO1-LO6 match the live block (live is sentence-cased) -> NOT touched.
--   * brochure / certification / funding_and_grant / skills_framework blocks,
--     whoshouldattend (15 content/media/marketing roles), the prerequisite
--     software list (browser + GenAI image/video tool accounts) and all 13
--     categories (incl. 111 GenAI Video Creation) still fit -> NOT touched.
--   * image / small_image / thumbnail PATHS (filesystem paths) -> NOT touched.
--   * Trainer bodies render from courses_trainers (rows 197/236/284), which
--     never name this course; the per-course trainerprofile teaching
--     paragraphs are retargeted below for consistency only.
--
-- SLUG: `wsq-create-short-video-film-using-ai` -- no product name/url_key and
-- no core_url_rewrite row contains "short video film". The old bare slug 301s
-- to the new one; the 31 pre-existing 301s (OpenCV / Computer Vision Jetson
-- Nano lives + ibf-funded category prefix), all belonging to entity 1131, are
-- flattened to the new bare slug in ONE hop.
--
-- SEARCH REDIRECTS: 48 rows (incl. the course code "TGS-2020505925" and the
-- OpenCV-era spellings) point at the retiring slug; all follow the course --
-- same TGS code, same TSC.
--
-- COVER: re-rendered on the SG web container via MMD_CourseImage_Model_Cover
-- with the product's OWN badge set (WSQ, SkillsFuture Credit, PSEA, SFEC,
-- Absentee Payroll, MCES) and uploaded before this file was written:
--   course-covers/TGS-2020505925-20260926-163803.png  (162800 bytes, HTTP 200)
-- The superseded object is left on R2 so reverting is just repointing the URL.
--
-- POST-DEPLOY (code paths a migration cannot run, on the SG web container):
--   1. Mage::getSingleton('catalog/url')->refreshProductRewrite(1131)
--      then catalog_product_flat reindex + cache flush -- the NEW slug 404s
--      until this runs, even though the old slug already 301s.
--   2. scripts/local-dev/batch-generate-brochures.php --wid=1
--      --sku-like=TGS-2020505925 --regenerate --no-drive
--   3. scripts/seo/generate-sitemaps.php so the sitemap lists the new slug.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2020505925
-- no-ops. Idempotent: plain UPDATEs, INSERT IGNORE, guarded REPLACE()s.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2020505925' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------------------
-- 1. Identity: name, url_key, url_path
-- ---------------------------------------------------------------------------

-- name: keeps the `WSQ - ` prefix (the storefront H1 wants it)
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'name' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Create Short Video Film using AI'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

-- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-create-short-video-film-using-ai'
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

-- url_path: DELETE at every scope (store 0 AND store 1 rows exist) so the URL
-- Rewrites indexer regenerates it
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_path' AND entity_type_id = @et);
DELETE FROM catalog_product_entity_varchar
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL AND @a_upath IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Meta
-- ---------------------------------------------------------------------------

-- meta_title: PLAIN title -- no leading "WSQ", no brand suffix (Seotitle adds both)
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_title' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'Create Short Video Film using AI'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- meta_description: varchar(255) -- this value is 203 chars
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'Plan, generate and edit a complete short video film with generative AI: storylines, consistent characters, text-to-video and image-to-video scenes, AI voiceovers and music. Up to 70% WSQ funding subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

-- meta_keyword
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_keyword' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = 'Create Short Video Film using AI, AI short film course Singapore, AI video production course, text-to-video, image-to-video, AI storyboard, AI character consistency, AI voiceover and music, AI video editing, generative AI filmmaking, WSQ funded AI video course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Content: About narrative, Course Outline
-- ---------------------------------------------------------------------------

-- short_description ("What's This Course About"): the supplied five-paragraph
-- narrative. Sections live in cms_block rows, so a full replace is correct.
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'short_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<p>Create Short Video Film Using AI is a practical, hands-on course that equips participants with the skills to plan, create, and produce engaging short video films using Generative AI tools. Participants will explore how AI can support the entire video production process, from developing an initial concept and storyline to generating visual assets, video scenes, voiceovers, music, and the final edited film.</p>',
'<p>Participants will learn to use Generative AI to develop creative concepts, storylines, scripts, characters, dialogue, and storyboards. They will apply effective prompting techniques to generate consistent characters, locations, visual styles, camera shots, and scenes that align with the intended narrative and target audience.</p>',
'<p>The course introduces AI-powered image and video generation techniques, including text-to-image, image-to-video, and text-to-video workflows. Participants will explore cinematic concepts such as shot composition, camera angles, camera movement, lighting, pacing, transitions, and visual storytelling to create more professional and engaging video sequences.</p>',
'<p>Participants will also use AI to generate voiceovers, dialogue, sound effects, and background music before combining their assets through video editing. They will learn to refine scenes, synchronise audio and visuals, add captions and effects, and improve the overall flow of the film.</p>',
'<p>By the end of the course, participants will have planned, generated, edited, and produced a complete AI-assisted short video film while developing practical skills for future creative video projects.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- description (Course Outline): LSN_DATA JSON + rendered markup, same shape
-- the admin outline editor writes.
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: AI Vision and Generative AI for Short Film Creation","subsecs":[]},{"title":"Topic 2: AI Image Processing, Generation and Visual Enhancement","subsecs":[]},{"title":"Topic 3: AI Visual Features, Character Consistency and Scene Design","subsecs":[]},{"title":"Topic 4: AI Video Generation, Animation and Video Analytics","subsecs":[]},{"title":"Topic 5: Cloud and Edge AI Workflows for Short Film Production","subsecs":[]}] -->',
'\n<p><strong>Topic 1: AI Vision and Generative AI for Short Film Creation</strong></p>',
'\n<p><strong>Topic 2: AI Image Processing, Generation and Visual Enhancement</strong></p>',
'\n<p><strong>Topic 3: AI Visual Features, Character Consistency and Scene Design</strong></p>',
'\n<p><strong>Topic 4: AI Video Generation, Animation and Video Analytics</strong></p>',
'\n<p><strong>Topic 5: Cloud and Edge AI Workflows for Short Film Production</strong></p>',
'\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. Trainer bios: retarget ONLY the course-teaching paragraph of each of the
--    3 bios. Credentials paragraphs stay. Single-paragraph REPLACEs.
-- ---------------------------------------------------------------------------
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = @et);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In his generative AI training, Richard focuses on teaching learners how to turn prompts, reference images, and creative briefs into finished visual content. His sessions cover AI image generation, image-to-image editing, style and consistency control, and AI-assisted video creation, ensuring participants gain both conceptual and practical knowledge.',
       'In &ldquo;Create Short Video Film using AI,&rdquo; Richard teaches learners how to turn a concept, storyline, and storyboard into a finished short film. His sessions cover AI image generation, character and scene consistency, text-to-video and image-to-video workflows, and cinematic shot design, ensuring participants gain both conceptual and practical knowledge.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In his generative AI courses, Shawn emphasizes practical, beginner-friendly projects in AI image and video creation. His training covers building repeatable creative workflows and integrating AI-generated visuals into marketing, training, and business communication, enabling learners to apply generative AI in real-world scenarios.',
       'In &ldquo;Create Short Video Film using AI,&rdquo; Shawn emphasizes practical, beginner-friendly short film projects. His training covers building repeatable AI production workflows, from script and storyboard to AI-generated scenes, voiceovers, music, and final edit, enabling learners to apply generative AI in real-world video projects.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In his generative AI training, Woei Ming focuses on bridging AI-generated visuals with practical business and data storytelling applications. His sessions introduce learners to prompt engineering for images, visual style and brand consistency, and AI video generation, with applied examples in product, training, and campaign content.',
       'In &ldquo;Create Short Video Film using AI,&rdquo; Woei Ming focuses on bridging AI-generated visuals with practical visual storytelling. His sessions introduce learners to prompting for consistent characters and locations, camera shots and scene design, and AI video generation, with applied examples in product, training, and campaign films.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. Cover image + alt text
-- ---------------------------------------------------------------------------

UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
    SET v.value = 'Create Short Video Film using AI'
  WHERE v.entity_id = @e AND @e IS NOT NULL
    AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label');

-- media gallery label -- the real alt text on the product image
UPDATE catalog_product_entity_media_gallery_value gv
   JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
    SET gv.label = 'Create Short Video Film using AI'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- cover image: repoint at the regenerated PNG (global scope; clear any
-- store-scoped row that would shadow it)
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'course_image_url' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505925-20260926-163803.png'
  WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0
   AND @e IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. URL rewrites: 301 the old slug, flatten the chain history
-- ---------------------------------------------------------------------------
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- The old bare slug is held by the canonical is_system=1 row; INSERT IGNORE
-- would no-op against it, so DELETE it first. refreshProductRewrite re-mints
-- the canonical row at the NEW slug post-deploy.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'wsq-generative-ai-for-image-and-video-creation.html'
   AND @e IS NOT NULL;

-- Clear any is_system=0 squatter sitting on the NEW path
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-create-short-video-film-using-ai.html'
   AND is_system = 0;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('tgs2020505925-shortfilm-bare-', @e),
       'wsq-generative-ai-for-image-and-video-creation.html',
       'wsq-create-short-video-film-using-ai.html',
       0, 'RP', '1571: TGS-2020505925 renamed to Create Short Video Film using AI'
 WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the pre-existing 301s (bare + category-prefixed targets) that point
-- at the OLD slug so they reach the new BARE slug in ONE hop. All 31 matching
-- rows belong to entity 1131 (verified), so no foreign alias is repointed.
UPDATE core_url_rewrite
   SET target_path = 'wsq-create-short-video-film-using-ai.html'
 WHERE is_system = 0
   AND target_path LIKE '%wsq-generative-ai-for-image-and-video-creation.html'
   AND id_path NOT LIKE 'tgs2020505925-shortfilm-%';

-- ---------------------------------------------------------------------------
-- 7. Search-term redirects (SG data; partner sites have no matching rows)
-- ---------------------------------------------------------------------------
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-create-short-video-film-using-ai.html'
 WHERE redirect LIKE '%wsq-generative-ai-for-image-and-video-creation.html'
    OR (query_text = 'TGS-2020505925' AND (redirect IS NULL OR redirect = ''));
