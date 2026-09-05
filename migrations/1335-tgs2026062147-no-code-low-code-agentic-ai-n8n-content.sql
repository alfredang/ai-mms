-- 1335: TGS-2026062147 "WSQ - No Code and Low Code Agentic AI Applications"
--      -- course info retargeted from the CrewAI/Autogen/ADK/Streamlit build
--      to the n8n no-code / low-code delivery (admin-supplied copy, 2026-09-05).
--
-- Probed on LIVE SG prod (entity 1869) before writing:
--   - name / url_key already read "WSQ - No Code and Low Code Agentic AI
--     Applications" / wsq-no-code-and-low-code-agentic-ai-applications -- untouched.
--   - learning_outcomes cms_block (402 B) still carried the CrewAI/Autogen/ADK LOs.
--   - description (2437 B) was the LU1-LU3 + T1..T5 scaffold with a stale LSN_DATA
--     comment (CrewAI, Streamlit Cloud, guardrails).
--   - short_description (952 B) was the CrewAI/Streamlit "About This Course".
--   - meta_title / meta_description still advertise "CrewAI, Autogen, ADK and
--     Streamlit" -- retargeted here so the SERP snippet matches the new page.
--   - No inline "Learning Outcomes"/"LO1" text in short_description (LOCATE = 0),
--     so nothing to strip -- the LOs live only in the cms_block.
--
-- Three surfaces rewritten, each as a FULL-content write (never a REPLACE --
-- the live blobs are CRLF, feedback_multiline_replace_fails_on_crlf_blobs):
--   A. Learning Outcomes card  -> cms_block course_TGS-2026062147_learning_outcomes
--   B. What You'll Learn card  -> description (attr 72), topic headings only in the
--      <h3 class="course-topic-h3"> shape the theme styles (same as 960/967/997/999)
--   C. About This Course       -> short_description (attr 73)
--   D. meta_title / meta_description / meta_keyword. meta_title is stored BARE
--      (no "WSQ", no brand) like 999/1329/1331 -- MMD_Seotitle composes the
--      "WSQ funded ... | Tertiary Courses Singapore" <title> at render time
--      (project_seo_title_render_time_composer); a baked "WSQ" doubles it.
--
-- Deliberately NOT touched: whoshouldattend, prerequisite, trainerprofile,
-- certification / skills_framework / funding_and_grant / brochure blocks,
-- categories, tags, cover image, url rewrites.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement is a guarded no-op there. Idempotent -- re-runnable. All text is
-- plain ASCII (apply.php connects charset=utf8).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026062147' LIMIT 1);

SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');

-- ------------------------------------------------------- A. Learning Outcomes
-- Guarded INSERT first so a DB where the block was never extracted still gets
-- one (feedback_course_outcomes_heading_never_extracted), then the UPDATE wins.
INSERT INTO cms_block (title, identifier, content, is_active)
SELECT 'TGS-2026062147 Learning Outcomes', 'course_TGS-2026062147_learning_outcomes', '', 1
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2026062147_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE identifier = 'course_TGS-2026062147_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Maintain proper configurations of no-code and low-code Agentic AI tools, and describe issues for appropriate escalation.</li>
<li>LO2: Apply effective prompt engineering, model configuration, and Retrieval Augmented Generation to integrate foundational models into low-code AI agent applications.</li>
<li>LO3: Troubleshoot performance issues in Agentic AI applications using standard debugging methods.</li>
</ul>',
       is_active = 1
 WHERE identifier = 'course_TGS-2026062147_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------------ B. Course Outline (description)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e,
'<h3 class="course-topic-h3">Topic 1: Develop No Code Agentic AI Workflows</h3>
<h3 class="course-topic-h3">Topic 2: Develop Low-Code Agentic AI Workflows</h3>
<h3 class="course-topic-h3">Topic 3: Real Life Applications of Agentic AI Workflows</h3>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop any store-scoped override so the store 0 value is what renders.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------- C. About This Course (short_description)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @e,
'<p>This course equips learners with practical skills to develop agentic AI applications using n8n through no-code and low-code development approaches. Participants will learn to design AI agents, connect business applications and data sources, automate multi-step processes, and create workflows that can analyse information, make decisions and perform actions with minimal coding.</p>
<p>Through hands-on, real-life applications, learners will use n8n to build solutions for customer enquiries, lead management, email processing, document handling, internal approvals, reporting and knowledge retrieval. They will explore workflow triggers, webhooks, conditional logic, human-in-the-loop approvals, error handling and data transformation to develop reliable automations for everyday business operations.</p>
<p>The course also covers the development of agentic RAG applications that retrieve relevant information from organisational knowledge sources and generate context-aware responses. Participants will learn to test, troubleshoot and improve their workflows while considering data security, accuracy, governance and appropriate human oversight.</p>
<p>Designed for beginner to intermediate learners, this course enables professionals from technical and non-technical backgrounds to rapidly prototype and deploy useful agentic AI solutions. By the end of the course, participants will be able to build an end-to-end n8n application that addresses a real business need and improves operational productivity.</p>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------- D. meta_title / meta_description / meta_keyword
SET @a_mkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @e,
       'No Code and Low Code Agentic AI Applications with n8n'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @e,
       'Build no-code and low-code Agentic AI applications and agentic RAG workflows with n8n to automate real business processes. Enjoy up to 70% WSQ funding subsidy.'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword is backend_type = text (attr 83), NOT varchar -- a varchar row is
-- never read by the product model.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @e,
       'no code agentic AI course Singapore, low code AI agent course, n8n course Singapore, n8n AI agent workflow, agentic RAG n8n, business process automation AI, AI workflow automation training, WSQ agentic AI course'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id IN (@a_mtitle, @a_mdesc) AND store_id <> 0 AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id <> 0 AND @e IS NOT NULL;
