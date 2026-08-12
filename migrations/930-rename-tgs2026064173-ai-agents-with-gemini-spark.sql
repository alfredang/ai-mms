-- 930: Rename TGS-2026064173
--        "CASL - Build a Conversational AI Agent with Google Gemini"
--      -> "CASL - AI Agents with Gemini Spark"
--      + new Course Outline (description) and About This Course (short_description)
--
-- Course code (SKU) is UNCHANGED - TGS-2026064173 stays, so every funding /
-- SkillsFuture deep link keyed on the course code remains correct. Follows the
-- 851/853/855 TGS- rename playbook via the 925/929 precedent shapes.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels -> new title
--   2. url_key -> casl-ai-agents-with-gemini-spark ; url_path deleted at every
--      scope so the Catalog URL Rewrites indexer regenerates it
--   3. 301 the old slug at the new one (repoint the pre-reindex system row +
--      INSERT IGNORE fallback, both scopes), and repoint the four legacy alias
--      rewrites that 301 INTO the old slug (wsq-blockchain-business-innovation-1090,
--      wsq-dialogflow-ai-chatbot-course, wsq-build-a-conversational-...,
--      build-a-conversational-...) so inbound links take one hop, not a chain
--   4. description -> the new 4-topic Course Outline (Mode of Assessment kept:
--      PP + OQ, unchanged)
--   5. short_description -> the new 4-paragraph About This Course, spliced so
--      the Certification section onward stays byte-identical
--   6. meta_keyword refreshed to lead with the new course name
--   7. media gallery per-image label
--   8. search-term redirects: 15 live SG rows point at the old slug (incl.
--      query "Build a Conversational AI Agent with Google Gemini") - retarget
--      by full SG-domain URL (partner-safe); also applied live on prod per
--      feedback_search_redirects_always_apply_live
--
-- meta_title deliberately omits BOTH the leading segment prefix and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time, prepending the funding prefix for any SG TGS- SKU and appending
-- the brand postfix (Block/Html/Head.php). Baking either in yields the
-- duplicated title tag that 853 had to clean up.
--
-- NOT rewritten (verified against prod before authoring):
--   - cms_block course_TGS-2026064173_learning_outcomes: LO1-LO4 already match
--     the requested outcomes verbatim (AI chatbot strategy / content+media
--     platforms / implementation plan / performance)
--   - cms_block course_TGS-2026064173_brochure + _funding_and_grant +
--     _funding_validity: keyed on the unchanged SKU, no old-title mention
--   - trainerprofile: no trainer bio quotes the course title (checked)
--   - news_from/to_date Funding Validity window: unchanged registration
--
-- The cover PNG and brochure PDF bake the old title - regenerate both on prod
-- after this applies (MMD_CourseImage strips the "CASL - " prefix at render).
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops); rewrite/search statements are
-- additionally guarded on the SG store. Idempotent - re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064173' LIMIT 1);
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_keyword');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'description');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'CASL - AI Agents with Gemini Spark' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No segment prefix and no brand suffix - MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'AI Agents with Gemini Spark Training' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'AI Agents with Gemini Spark training in Singapore. Build and manage autonomous AI agents with reusable agent skills, scheduled workflows, tool integrations and human-in-the-loop controls.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'casl-ai-agents-with-gemini-spark' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "CASL -" prefix) - they are alt text
-- on the course cover, which itself renders without the prefix (Cover.php
-- cleanTitle strips WSQ/CASL/IBF).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'AI Agents with Gemini Spark' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'AI Agents with Gemini Spark' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'AI Agents with Gemini Spark' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------- 2. url_path at all scopes
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Repoint the existing rewrite row (the system row still holds the old
-- request_path until reindex) and force it permanent + manual; create the row
-- where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'casl-ai-agents-with-gemini-spark.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'casl-build-a-conversational-ai-agent-with-google-gemini.html'
    AND store_id IN (0, 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('casl-build-a-conversational-ai-agent-with-google-gemini.html'), '-', s.store_id),
       'casl-build-a-conversational-ai-agent-with-google-gemini.html',
       'casl-ai-agents-with-gemini-spark.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'casl-build-a-conversational-ai-agent-with-google-gemini.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old slug - repoint straight at the
-- new slug so inbound links take one hop, not a chain.
UPDATE core_url_rewrite
  SET target_path = 'casl-ai-agents-with-gemini-spark.html'
  WHERE @sg = 1 AND @e IS NOT NULL
    AND target_path = 'casl-build-a-conversational-ai-agent-with-google-gemini.html'
    AND request_path <> 'casl-build-a-conversational-ai-agent-with-google-gemini.html';

-- --------------------------------------------- 4. description (Course Outline)
-- New 4-topic outline as provided; Mode of Assessment unchanged (PP + OQ).
-- Bare <h3> topic rows are normalised by the theme shim (course-topic-h3).
UPDATE catalog_product_entity_text
  SET value = '<h3>Topic 1: AI Agent Strategy and Gemini Spark Fundamentals</h3><h3>Topic 2: Building Agent Skills, Tasks and Tool Integrations</h3><h3>Topic 3: Agent Workflow Implementation, Scheduling and Governance</h3><h3>Topic 4: Agent Monitoring, Performance Evaluation and Optimisation</h3><h3>Mode of Assessment</h3><ul><li>Practical Performance (PP)</li><li>Oral Questioning (OQ)</li></ul>'
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_desc AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_desc;

-- ---------------------------------- 5. short_description (About This Course)
-- Splice, don't rewrite: new intro paragraphs + everything from the first <h2>
-- (the Certification section) kept byte-identical. Guarded on the new
-- distinctive phrase for idempotency.
UPDATE catalog_product_entity_text
  SET value = CONCAT(
    '<p>AI Agents with Gemini Spark equips participants with practical skills to build and manage autonomous AI agents that streamline everyday business and administrative work. Through hands-on activities, learners will delegate multi-step tasks to AI agents capable of planning actions, using connected tools, executing workflows and reporting outcomes with appropriate human oversight.</p>',
    '<p>Participants will learn to configure Gemini Spark, create one-off tasks and develop reusable agent skills for common workplace needs. They will design scheduled and event-triggered workflows that can operate automatically across email, calendars, cloud storage, documents, spreadsheets and presentations.</p>',
    '<p>The course covers practical applications such as summarising inbox activity, organising documents, conducting research, preparing content, tracking expenses and managing leads. Learners will also explore how to write effective agent instructions, provide relevant context, define expected outputs and troubleshoot unsuccessful workflows.</p>',
    '<p>Emphasis is placed on responsible agent deployment through permissions management, approval checkpoints, privacy safeguards and human-in-the-loop controls. By the end of the course, participants will be able to create, test and optimise Gemini Spark agents that reduce repetitive work, improve productivity and support more efficient digital workplace operations.</p>',
    SUBSTRING(value, LOCATE('<h2>', value)))
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_sd AND store_id = 0
    AND LOCATE('<h2>', value) > 0
    AND LOCATE('Gemini Spark', value) = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_sd;

-- ------------------------------------------------------------ 6. meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'AI agents course, Gemini Spark training, Gemini Spark course Singapore, autonomous AI agents, agentic AI workflow training, AI agent skills, AI workflow automation, CASL AI agents course, AI productivity course, human-in-the-loop AI, Google Gemini AI agent course, AI task automation Singapore' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- ------------------------------------------------ 7. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI Agents with Gemini Spark'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------- 8. search-term redirects (15 rows)
-- Retarget every live row pointing at the old slug (incl. the old-title query
-- itself). REPLACE on the full SG-domain URL - partner-safe.
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/casl-build-a-conversational-ai-agent-with-google-gemini.html', 'https://www.tertiarycourses.com.sg/casl-ai-agents-with-gemini-spark.html')
  WHERE redirect LIKE '%casl-build-a-conversational-ai-agent-with-google-gemini.html%';
