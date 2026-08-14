-- 1013: Rename TGS-2023036088
--   "WSQ - End to End Creative Video Creation with Agentic AI and Vibe Coding"
--   -> "WSQ - Agentic AI for Video Creation"
--
-- Scope: TITLE-ONLY rename. The subject (AI-driven video creation) is unchanged,
-- so categories, whoshouldattend, prerequisite, trainerprofile and the funding /
-- certification / skills-framework / brochure cms_blocks all stay as-is
-- (verified clean of the old title by an EAV + cms_block sweep before writing).
--
-- Live twin: C436 is already named "Agentic AI for Video Creation" and owns the
-- bare slug `agentic-ai-for-video-creation`. Per settled precedent this WSQ
-- course keeps its `WSQ - ` prefix and takes the `wsq-`-prefixed slug, which
-- keeps the two pages' core_url_rewrite rows permanently apart.
--
-- SKU is deliberately unchanged so every SkillsFuture / SFEC / SFC / PSEA deep
-- link keyed on the course code stays valid.
--
-- Idempotent: safe to re-run.

SET @sku := 'TGS-2023036088';
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = @sku);

SET @a_name        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_meta_title  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_meta_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_meta_kw     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_url_key     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_url_path    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_img_lbl     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_simg_lbl    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_thumb_lbl   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_desc        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- ---------------------------------------------------------------------------
-- Surface 1: name (keep the "WSQ - " prefix; storefront H1 wants it)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Agentic AI for Video Creation'
 WHERE entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- Surface 2: meta_title — plain title, NO leading "WSQ", NO brand suffix.
-- MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs and appends the brand
-- postfix at render time; baking either in yields a duplicated title.
-- (The existing value had BOTH baked in — fixing that here.)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Video Creation'
 WHERE entity_id = @e AND attribute_id = @a_meta_title;

-- ---------------------------------------------------------------------------
-- Surface 9: meta_description — feeds <meta description>, og:, twitter: and
-- the JSON-LD description. Retitled; subject copy still accurate.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'Create professional videos end to end with Agentic AI - from scripting and storyboarding to editing, quality assurance and publishing. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_meta_desc;

UPDATE catalog_product_entity_text
   SET value = 'WSQ agentic AI video course, agentic AI video production, AI video creation Singapore, AI video editing training, script writing storyboarding AI, AI voiceover generation, video quality assurance AI, WSQ funded media course, end to end video workflow'
 WHERE entity_id = @e AND attribute_id = @a_meta_kw;

-- ---------------------------------------------------------------------------
-- Surface 3: url_key + drop url_path at every scope so the URL Rewrites
-- indexer regenerates. `wsq-` prefix avoids the live twin C436's bare slug.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-agentic-ai-for-video-creation'
 WHERE entity_id = @e AND attribute_id = @a_url_key;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_url_path;

-- Clear any is_system = 0 squatter on the NEW bare path first, or the
-- INSERT IGNORE below silently no-ops against a stale row.
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-agentic-ai-for-video-creation.html' AND is_system = 0;

-- Explicit 301 from the old bare slug to the new one. The indexer auto-301s
-- the ~13 category-prefixed paths; only the bare path needs seeding.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('rename1013/', @e),
       'wsq-end-to-end-creative-video-creation-with-agentic-ai-and-vibe-coding.html',
       'wsq-agentic-ai-for-video-creation.html',
       0, 'RP', 'Rename TGS-2023036088 to Agentic AI for Video Creation'
  FROM DUAL
 WHERE NOT EXISTS (
       SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
        WHERE x.request_path = 'wsq-end-to-end-creative-video-creation-with-agentic-ai-and-vibe-coding.html'
          AND x.is_system = 0);

-- ---------------------------------------------------------------------------
-- Surface 5: cover alt text. The *_label attrs and the media_gallery label are
-- alt text and carry the plain title (the cover renderer strips "WSQ - ").
-- image/small_image/thumbnail hold filesystem paths - deliberately untouched.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Video Creation'
 WHERE entity_id = @e AND attribute_id IN (@a_img_lbl, @a_simg_lbl, @a_thumb_lbl);

UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'Agentic AI for Video Creation'
 WHERE g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- Surface 4: short_description — About This Course narrative.
-- This course's sections were already moved to cms_blocks (no
-- "<h2>Course Brochure</h2>" tail, no inline <h2> at all), so a full replace
-- is the correct shape here - verified by probing LOCATE('<h2', value) = 0.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
   SET value = CONCAT(
       '<p>This course equips media professionals, content creators, marketers, and digital storytellers with the skills to create professional-quality videos using Agentic AI and vibe coding methodologies. Participants will learn how to design, build, and manage end-to-end AI-powered video creation workflows, from content ideation to final video publishing.</p>\n',
       '<p>The course covers the complete creative video production lifecycle, including idea generation, script writing, storyboard development, voiceover creation, image and video asset generation, video editing, post-production, quality assurance, and content distribution. Learners will explore how multiple AI agents can collaborate to automate and optimize different stages of the creative process while maintaining consistency, quality, and alignment with creative objectives.</p>\n',
       '<p>A key focus of the course is the use of vibe coding techniques to rapidly develop and customize agentic workflows without extensive programming expertise. Participants will learn how to orchestrate AI agents, automate repetitive production tasks, improve creative efficiency, and scale content creation operations.</p>\n',
       '<p>By the end of the course, participants will be able to design and manage AI-powered video production pipelines, evaluate and enhance creative outputs, integrate emerging AI technologies into their workflows, and efficiently produce high-quality video content using Agentic AI and vibe coding approaches.</p>')
 WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- ---------------------------------------------------------------------------
-- description — Course Outline, retitled to the three supplied topics.
-- Bullets are preserved: they still describe what each topic delivers.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
   SET value = CONCAT(
       '<h3 class="course-topic-h3">Topic 1: Creative Strategy and End-to-End Video Production with Agentic AI</h3>\n<ul>\n',
       '<li>Define creative goals, content strategies, and video production workflows</li>\n',
       '<li>Design and orchestrate AI-powered workflows for script writing, storyboarding, asset generation, voiceovers, editing, and publishing</li>\n</ul>\n',
       '<h3 class="course-topic-h3">Topic 2: AI-Assisted Video Editing, Storytelling and Quality Assurance</h3>\n<ul>\n',
       '<li>Review video content for storytelling effectiveness, brand consistency, and audience engagement</li>\n',
       '<li>Use AI agents to automate quality checks, content validation, feedback collection, and optimization processes</li>\n</ul>\n',
       '<h3 class="course-topic-h3">Topic 3: Workflow Optimisation, Industry Compliance and Emerging Video Technologies</h3>\n<ul>\n',
       '<li>Apply improvements and enhancements using AI-powered creative workflows</li>\n',
       '<li>Explore new Agentic AI tools, multimodal AI models, and vibe coding techniques for scalable video content creation</li>\n</ul>')
 WHERE entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------------------------------
-- Surface 6b: the learning_outcomes cms_block does NOT exist for this course
-- (it predates the 885-891 block extraction), so the "What You'll Learn" card
-- renders empty today. A bare UPDATE would silently no-op - guarded-INSERT
-- first, then UPDATE so re-runs converge.
-- ---------------------------------------------------------------------------
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2023036088 - Learning Outcomes',
       'course_TGS-2023036088_learning_outcomes',
       '', NOW(), NOW(), 1
  FROM DUAL
 WHERE NOT EXISTS (
       SELECT 1 FROM (SELECT * FROM cms_block) b
        WHERE b.identifier = 'course_TGS-2023036088_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE identifier = 'course_TGS-2023036088_learning_outcomes';

UPDATE cms_block
   SET content = CONCAT(
       '<p>By the end of the course, learners will be able to:</p>\n<ul>\n',
       '<li>LO1 - Develop editing strategies and work plans to achieve creative vision.</li>\n',
       '<li>LO2 - Assess edited footage to enhance storytelling and ensure technical compliance.</li>\n',
       '<li>LO3 - Develop remedial actions to ensure industry compliance and facilitate the adoption of new technologies in visual editing.</li>\n</ul>'),
       is_active = 1,
       update_time = NOW()
 WHERE identifier = 'course_TGS-2023036088_learning_outcomes';

-- ---------------------------------------------------------------------------
-- Surface 8: brochure cms_block title (PDF path is keyed on the unchanged SKU)
-- ---------------------------------------------------------------------------
UPDATE cms_block
   SET title = 'Course Brochure - TGS-2023036088'
 WHERE identifier = 'course_TGS-2023036088_brochure';

-- ---------------------------------------------------------------------------
-- Keep the flat tables coherent until the next reindex.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_flat_1
   SET name = 'WSQ - Agentic AI for Video Creation',
       url_key = 'wsq-agentic-ai-for-video-creation',
       url_path = 'wsq-agentic-ai-for-video-creation.html'
 WHERE entity_id = @e;
