-- 1016-repurpose-tgs2021006714-ai-vibe-code-of-image-generation.sql
--
-- Repurpose TGS-2021006714
--   FROM "WSQ - End-to-End Creative Image Generation with Agentic AI and Vibe Coding"
--     TO "WSQ - AI Vibe Code of Image Generation"
--
-- SKU is UNCHANGED, so every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link
-- keyed on the course code stays valid.
--
-- Subject shift: the course moves off the n8n / agentic-workflow-automation
-- framing onto Python AI vibe coding with GANs, VAEs and Stable Diffusion.
-- That makes this a REPURPOSE, so category placement moves too.
--
-- Surfaces touched (per feedback_tgs_course_rename_checklist):
--   1  name
--   2  meta_title (plain title - MMD_Seotitle adds the WSQ prefix + brand suffix)
--   3  url_key + url_path (all scopes) + 301 from the old bare slug
--   4  short_description (About This Course - full replace; sections live in cms blocks)
--   5  image_label / small_image_label / thumbnail_label + media gallery label
--   6  learning_outcomes cms_block (guarded INSERT then UPDATE)
--   9  meta_description + meta_keyword
--   10 whoshouldattend (job roles re-pointed off GAN-only framing)
--   -- description (Course Outline, 6 topics)
--   -- categories: drop n8n / Agentic-AI listings, add the Vibe Coding listings
--
-- prerequisite + trainerprofile were probed and hold NO old-title / n8n /
-- agentic text - deliberately left untouched (prerequisite also carries the
-- whole funding apparatus).
--
-- Idempotent: every statement is a guarded UPDATE / INSERT IGNORE /
-- ON DUPLICATE KEY UPDATE and converges on re-run.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021006714');

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_ilab    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ---------------------------------------------------------------------------
-- 1. name  (keep the "WSQ - " prefix; the storefront H1 wants it)
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'WSQ - AI Vibe Code of Image Generation'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_name AND store_id <> 0;

-- ---------------------------------------------------------------------------
-- 2. meta_title  (NO leading "WSQ", NO "| Tertiary Courses Singapore" suffix -
--    MMD_Seotitle prepends the funding token and appends the brand at render)
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @e, 'AI Vibe Code of Image Generation'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND store_id <> 0;

-- ---------------------------------------------------------------------------
-- 9. meta_description + meta_keyword
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @e,
  'Learn AI vibe coding to build image generation applications with Stable Diffusion, GANs and VAEs. Generate, refine and deploy Python image workflows. Enjoy up to 70% WSQ funding subsidy.'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND store_id <> 0;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @e,
  'AI vibe coding course, image generation course Singapore, Stable Diffusion training, GAN course, variational autoencoder course, text-to-image generation, image-to-image transformation, AI assisted coding Python, generative image models, prompt engineering for images, WSQ funded course Singapore'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id <> 0;

-- ---------------------------------------------------------------------------
-- 3. url_key + url_path
--    New slug "wsq-ai-vibe-code-of-image-generation" was probed for collisions
--    (no live twin owns it). url_path is DELETED at every scope so the Catalog
--    URL Rewrites indexer regenerates it.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_urlkey, 0, @e, 'wsq-ai-vibe-code-of-image-generation'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpath;

-- 301 from the old bare slug.
-- The old path is owned by the product's own is_system = 1 rewrite, so an
-- INSERT IGNORE would silently no-op against the (request_path, store_id)
-- unique key. Convert that system row in place instead.
-- See feedback_rename_301_vs_system_rewrite_suffix_trap.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-vibe-code-of-image-generation.html',
       is_system   = 0,
       options     = 'RP',
       id_path     = CONCAT('tgs2021006714-rp-', store_id)
 WHERE request_path = 'wsq-end-to-end-creative-image-generation-with-agentic-ai-and-vibe-coding.html'
   AND is_system = 1;

-- Any non-system alias rows already pointing at the old bare slug follow it to
-- the new one (anchored on the FULL old filename so sibling courses are safe).
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-vibe-code-of-image-generation.html'
 WHERE is_system = 0
   AND target_path = 'wsq-end-to-end-creative-image-generation-with-agentic-ai-and-vibe-coding.html';

-- ---------------------------------------------------------------------------
-- 4. short_description  (About This Course)
--    This course's standard sections (Brochure / Skills Framework / Funding)
--    already live in cms_block rows - probed: no "<h2>Course Brochure</h2>"
--    tail in the field - so a full replace is correct here, not a splice.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @e, CONCAT(
'<p>This course equips learners with practical skills to use AI vibe coding techniques to build and customise image generation applications. Through natural-language instructions and AI-assisted coding, participants will generate, explain, test, and refine Python code for developing creative AI workflows without needing to write every component manually.</p>',
'<p>Learners will explore the foundations of generative image models, including Generative Adversarial Networks (GANs), Variational Autoencoders (VAEs), and Stable Diffusion. They will understand how these models learn visual representations, generate new images, and support applications such as text-to-image generation, image-to-image transformation, style variation, image enhancement, and creative asset production.</p>',
'<p>The course covers essential processes such as preparing image datasets, configuring model parameters, writing and improving prompts, controlling image properties, training or fine-tuning models, and evaluating output quality. Participants will use AI vibe coding to troubleshoot errors, compare different approaches, create user interfaces, and integrate image generation models into practical Python applications.</p>',
'<p>Through hands-on projects, learners will develop end-to-end image generation workflows for marketing, design, media, and business applications. By the end of the course, participants will be able to use AI-assisted coding to build image generation solutions with Stable Diffusion, GANs, and VAEs while applying responsible practices relating to data quality, copyright, bias, and appropriate content generation.</p>')
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0;

-- ---------------------------------------------------------------------------
-- description  (Course Outline - 6 topics, same <h3> shape as before)
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, CONCAT(
'<h3>Topic 1: Fundamentals of AI Image Generation and Computational Modelling</h3>',
'<h3>Topic 2: Image Generation with Generative Adversarial Networks (GANs)</h3>',
'<h3>Topic 3: Image Generation with Variational Autoencoders (VAEs)</h3>',
'<h3>Topic 4: Stable Diffusion and Controlled Image Generation</h3>',
'<h3>Topic 5: Image-to-Image Transformation, Enhancement and New Applications</h3>',
'<h3>Topic 6: Algorithm Evaluation, Selection, Optimisation and Deployment</h3>')
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0;

-- ---------------------------------------------------------------------------
-- 6. learning_outcomes cms_block
--    Guarded INSERT first - a bare UPDATE silently no-ops when the block was
--    never created (surface 6b). This course DOES have one, but the guard keeps
--    the migration correct on a rebuilt DB.
-- ---------------------------------------------------------------------------
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2021006714 - Learning Outcomes',
       'course_TGS-2021006714_learning_outcomes',
       '', NOW(), NOW(), 1
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block
        WHERE identifier = 'course_TGS-2021006714_learning_outcomes') x);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE identifier = 'course_TGS-2021006714_learning_outcomes';

UPDATE cms_block
   SET content = CONCAT(
'<p>By the end of the course, learners will be able to:</p><ul>',
'<li>Direct modeling efforts across the organization.</li>',
'<li>Apply computational methodologies to the problem.</li>',
'<li>Design advanced computational model.</li>',
'<li>Evaluate a broad range of algorithms.</li>',
'<li>Spearhead the application of algorithms to new domains.</li>',
'<li>Establish guidelines on algorithm selection.</li></ul>'),
       update_time = NOW()
 WHERE identifier = 'course_TGS-2021006714_learning_outcomes';

-- ---------------------------------------------------------------------------
-- 10. whoshouldattend
--     The old list was GAN-only ("Bioinformatics Researcher (for GAN-based
--     simulations)", "Game Developer (using GANs for content generation)").
--     Re-pointed at the broader generative-image / vibe-coding audience.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @e, CONCAT(
'<ul><li>Data Scientist</li>',
'<li>Machine Learning Engineer</li>',
'<li>AI Researcher</li>',
'<li>Deep Learning Specialist</li>',
'<li>Computer Vision Engineer</li>',
'<li>AI Product Developer</li>',
'<li>Graphics Software Developer</li>',
'<li>Multimedia Artist (using AI)</li>',
'<li>Creative Technologist</li>',
'<li>Digital Content Designer</li>',
'<li>Marketing Creative (producing AI visuals)</li>',
'<li>R&amp;D Specialist in AI</li>',
'<li>Game Developer (generating visual assets)</li>',
'<li>Innovation Manager (in tech firms)</li>',
'<li>Computational Scientist</li></ul>')
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id <> 0;

-- ---------------------------------------------------------------------------
-- 5. Cover alt text: the three *_label attrs + the media gallery label.
--    These still carried an EVEN OLDER title ("...Image Generation Automation
--    with Agentic AI & n8n") from a previous rename that missed them.
--    Value is the plain title (no "WSQ - " prefix) - the cover strips it.
--    The cover PNG itself still bakes the old title; re-render it after deploy.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ilab, 0, @e, 'AI Vibe Code of Image Generation' WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_slab, 0, @e, 'AI Vibe Code of Image Generation' WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_tlab, 0, @e, 'AI Vibe Code of Image Generation' WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND store_id <> 0;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'WSQ - AI Vibe Code of Image Generation'
 WHERE g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- Categories. Resolved BY NAME (ids differ per site; TGS- is SG-only but the
-- guards keep partner deploys safe). Mirrored into catalog_category_product_index
-- or the storefront listings never change.
-- See feedback_category_swap_needs_index_mirror.
--
-- DROP: the n8n / agentic-workflow listings - the course no longer teaches
--       agentic workflow automation or n8n.
-- ---------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_1016_drop;
CREATE TEMPORARY TABLE tmp_1016_drop (category_id INT PRIMARY KEY);

INSERT IGNORE INTO tmp_1016_drop (category_id)
SELECT cv.entity_id FROM catalog_category_entity_varchar cv
 WHERE cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
   AND cv.value IN ('n8n AI Automations', 'Agentic AI Series', 'WSQ Agentic AI Courses');

DELETE cp FROM catalog_category_product cp
  JOIN tmp_1016_drop d ON d.category_id = cp.category_id
 WHERE cp.product_id = @e AND @e IS NOT NULL;

DELETE ci FROM catalog_category_product_index ci
  JOIN tmp_1016_drop d ON d.category_id = ci.category_id
 WHERE ci.product_id = @e AND @e IS NOT NULL;

-- ADD: the vibe-coding / programming listings its 17 siblings belong to.
DROP TEMPORARY TABLE IF EXISTS tmp_1016_add;
CREATE TEMPORARY TABLE tmp_1016_add (category_id INT PRIMARY KEY);

INSERT IGNORE INTO tmp_1016_add (category_id)
SELECT cv.entity_id FROM catalog_category_entity_varchar cv
 WHERE cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
   AND cv.value IN ('AI Vibe Coding Series', 'WSQ Programming & VIbe Coding',
                    'Programming', 'WSQ IT & Security Courses');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT a.category_id, @e,
       COALESCE((SELECT MAX(cp2.position) FROM catalog_category_product cp2
                  WHERE cp2.category_id = a.category_id), 0) + 1
  FROM tmp_1016_add a
 WHERE @e IS NOT NULL;

-- Mirror the additions into the index so the storefront listings pick them up
-- before the next full reindex.
INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT a.category_id, @e, cp.position, 1, s.store_id, 4
  FROM tmp_1016_add a
  JOIN catalog_category_product cp ON cp.category_id = a.category_id AND cp.product_id = @e
  JOIN core_store s ON s.store_id > 0
 WHERE @e IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_1016_drop;
DROP TEMPORARY TABLE IF EXISTS tmp_1016_add;
