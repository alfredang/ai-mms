-- 1009: Repurpose TGS-2025056983
--   "WSQ - Storytelling and Storyboarding with Generative AI"
--     -> "WSQ - Generative AI for Script Development and Storytelling"
--
-- SKU is UNCHANGED, so every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link
-- keyed on the course code stays valid.
--
-- The SUBJECT is unchanged (script development, storytelling, storyboarding,
-- AI video, ethics, copyright) -- this is a retitle + content refresh, not a
-- topic change. Therefore the following are deliberately LEFT ALONE:
--   * cms_block course_TGS-2025056983_learning_outcomes -- already byte-identical
--     to the requested LO1-LO5 (SSG-registered against the unchanged SKU).
--   * cms_block ..._skills_framework -- "AI Content Generation for Script
--     Development-3 MED-MED-3004-1.1" already matches the new title.
--   * cms_block ..._certification / ..._funding_and_grant / ..._brochure.
--   * whoshouldattend (20 job roles, all still accurate for the new title).
--   * trainerprofile (Kishori Chaudhari -- storytelling/storyboard/video-script
--     credentials remain exactly on-topic).
--   * prerequisite (probed: contains no old-title/old-topic text; holds the
--     whole funding apparatus -- never rewrite wholesale).
--   * all 13 category placements (subject unchanged).
--   * image / small_image / thumbnail (filesystem paths, not display text).
--
-- Partner-safe: TGS- SKUs exist only on SG. @e is NULL on MY/GH, so every
-- statement below is a guarded UPDATE / NULL-safe INSERT and no-ops there.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025056983');

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sd     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_il     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tl     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

SET @newname  := 'WSQ - Generative AI for Script Development and Storytelling';
SET @plain    := 'Generative AI for Script Development and Storytelling';
SET @newkey   := 'wsq-generative-ai-for-script-development-and-storytelling';
SET @oldkey   := 'wsq-storytelling-and-storyboarding-with-generative-ai';

-- ---------------------------------------------------------------- 1. name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, @newname FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_name AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 2. meta_title / _description
-- meta_title: PLAIN title only. MMD_Seotitle prepends "WSQ funded" for SG TGS-
-- SKUs and appends the brand postfix at render time. The existing value baked
-- in BOTH ("WSQ Storytelling ... | Tertiary Courses Singapore") -- fix it here.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, @plain FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mt AND store_id <> 0 AND @e IS NOT NULL;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e,
       'Use Generative AI for script development, storytelling and storyboarding. Refine video scripts and manage bias and copyright risks. Up to 70% WSQ funding.'
  FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_md AND store_id <> 0 AND @e IS NOT NULL;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e,
       'generative AI script development, AI storytelling course, AI scriptwriting training, AI storyboarding, video script refinement with AI, AI ethics and copyright, WSQ generative AI course, Singapore WSQ courses, AI content creation, narrative structure with AI'
  FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_mk AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------- 3. url_key
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_uk, 0, @e, @newkey FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_uk AND store_id <> 0 AND @e IS NOT NULL;

-- url_path at EVERY scope -- the Catalog URL Rewrites indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_up AND @e IS NOT NULL;

-- --------------------------------------------------- 4. short_description
-- Post-885 block model: this course's sections (Brochure / Skills Framework /
-- Certification / WSQ Funding) all live in cms_block rows, so short_description
-- is intro prose ONLY -- verified by dumping the full field. Full replace is
-- correct here; there are no inline vendor sections to preserve.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sd, 0, @e, CONCAT(
'<p>This course equips participants with practical skills to use Generative AI for script development, storytelling, storyboarding, and multimedia content creation. Learners will explore how AI can support the creative process from initial concept development to the production of complete, engaging narratives for media, advertising, education, entertainment, and digital platforms.</p>',
'<p>Participants will apply storytelling principles to develop themes, plots, narrative structures, characters, dialogue, settings, and fictional worlds. They will use Generative AI to explore creative directions, overcome idea blocks, develop alternative storylines, and adapt scripts for different audiences, formats, tones, and communication objectives.</p>',
'<p>The course also covers script evaluation and refinement. Learners will review AI-generated content for clarity, originality, pacing, emotional impact, character consistency, and narrative coherence. They will translate scripts into visual storyboards by planning scenes, camera angles, shot sequences, transitions, dialogue, voiceovers, and supporting visual elements.</p>',
'<p>Through practical projects, participants will integrate scripts, images, audio, voiceovers, and AI-generated video elements into cohesive storytelling presentations. Emphasis is placed on maintaining human creative direction and addressing responsible content creation issues such as factual accuracy, bias, cultural sensitivity, plagiarism, copyright, and appropriate disclosure of AI-generated materials.</p>',
'<p>By the end of the course, learners will be able to use Generative AI to develop, refine, visualise, and present compelling stories while improving creative productivity and maintaining professional and ethical standards. This course is suitable for beginner and intermediate learners with an interest in writing, content creation, or digital media.</p>'
) FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sd AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------- 5. description (Course Outline)
-- 5 LUs collapse to the 3 requested topics. The LSN_DATA JSON comment and the
-- <p><strong>Topic N</strong></p> HTML must stay in sync.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: Script Development and Creative Storytelling with Generative AI","subsecs":[]},',
'{"title":"Topic 2: AI-Assisted Storyboarding, Visual Design and Video Creation","subsecs":[]},',
'{"title":"Topic 3: Script Refinement, Responsible AI and Copyright Risk Management","subsecs":[]}] -->\n',
'<p><strong>Topic 1: Script Development and Creative Storytelling with Generative AI</strong></p>\n',
'<p><strong>Topic 2: AI-Assisted Storyboarding, Visual Design and Video Creation</strong></p>\n',
'<p><strong>Topic 3: Script Refinement, Responsible AI and Copyright Risk Management</strong></p>'
) FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;

-- --------------------------------------------------- 6. cover alt-text labels
-- Plain title (no "WSQ - " prefix): the cover renderer strips the prefix.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, @plain FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, @plain FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_tl, 0, @e, @plain FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_tl) AND store_id <> 0 AND @e IS NOT NULL;

-- media_gallery_value.label is the real alt text on the product-page gallery.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @plain
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------------------- 7. 301 rewrite
-- The OLD bare slug is owned by the product's own is_system = 1 rewrite, so an
-- INSERT IGNORE 301 would silently no-op against the unique (request_path,
-- store_id) key. Convert that row in place instead.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@newkey, '.html'),
       is_system   = 0,
       options     = 'RP',
       id_path     = CONCAT('product/', @e, '-rp-1009')
 WHERE @e IS NOT NULL
   AND store_id     = 1
   AND request_path = CONCAT(@oldkey, '.html')
   AND target_path  = CONCAT('catalog/product/view/id/', @e);

-- If a prior run already converted it, keep the target current (idempotent).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@newkey, '.html')
 WHERE @e IS NOT NULL
   AND store_id     = 1
   AND request_path = CONCAT(@oldkey, '.html')
   AND options      = 'RP';
