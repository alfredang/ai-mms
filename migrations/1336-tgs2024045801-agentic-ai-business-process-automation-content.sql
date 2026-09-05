-- 1336: TGS-2024045801 "WSQ - Agentic AI for Business Process Automation"
--      -- course info retargeted from the Semantic Kernel / multi-agent
--      workforce build to the n8n webhook + human-in-the-loop + agentic RAG
--      delivery (admin-supplied copy, 2026-09-05).
--
-- Probed on LIVE SG prod (entity 185) before writing:
--   - name / url_key already read "WSQ - Agentic AI for Business Process
--     Automation" / wsq-agentic-ai-for-business-process-automation -- untouched.
--   - learning_outcomes cms_block 1710 (298 B) still carried the Microsoft
--     Semantic Kernel / Chat Copilot LOs.
--   - description (2277 B) was the 3-topic multi-agent-workforce outline with a
--     matching LSN_DATA comment.
--   - short_description (1374 B) was the multi-agent / APA "About This Course".
--   - No inline "Learning Outcomes"/"LO1" text in short_description (LOCATE = 0),
--     so nothing to strip -- the LOs live only in the cms_block.
--
-- Three surfaces rewritten, each as a FULL-content write (never a REPLACE --
-- the live description blob is CRLF, feedback_multiline_replace_fails_on_crlf_blobs):
--   A. Learning Outcomes card  -> cms_block course_TGS-2024045801_learning_outcomes
--   B. What You'll Learn card  -> description (attr 72), topic headings only in the
--      <h3 class="course-topic-h3"> shape the theme styles (same as 1335/999/997),
--      plus a fresh LSN_DATA marker so the admin Lesson view stays in sync.
--   C. About This Course       -> short_description (attr 73)
--
-- Deliberately NOT touched: meta_title / meta_description (still accurate),
-- whoshouldattend, prerequisite, trainerprofile, certification /
-- skills_framework / funding_and_grant / brochure blocks, categories, tags,
-- cover image, url rewrites.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement is a guarded no-op there. Idempotent -- re-runnable. All text is
-- plain ASCII (apply.php connects charset=utf8).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045801' LIMIT 1);

SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- ------------------------------------------------------- A. Learning Outcomes
-- Guarded INSERT first so a DB where the block was never extracted still gets
-- one (feedback_course_outcomes_heading_never_extracted), then the UPDATE wins.
INSERT INTO cms_block (title, identifier, content, is_active)
SELECT 'TGS-2024045801 Learning Outcomes', 'course_TGS-2024045801_learning_outcomes', '', 1
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2024045801_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE identifier = 'course_TGS-2024045801_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Identify and evaluate prompt engineering for Agentic AI applications and related issues.</li>
<li>LO2: Implement AI agent applications.</li>
<li>LO3: Deploy Agentic AI workflows according to plan.</li>
</ul>',
       is_active = 1
 WHERE identifier = 'course_TGS-2024045801_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------------ B. Course Outline (description)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e,
'<!-- LSN_DATA: [{"title":"Topic 1: Fundamentals of Agentic AI and n8n AI Agents","subsecs":[]},{"title":"Topic 2: Webhook Automation and Human-in-the-Loop Workflows","subsecs":[]},{"title":"Topic 3: Building an Agentic RAG Chatbot","subsecs":[]}] -->
<h3 class="course-topic-h3">Topic 1: Fundamentals of Agentic AI and n8n AI Agents</h3>
<h3 class="course-topic-h3">Topic 2: Webhook Automation and Human-in-the-Loop Workflows</h3>
<h3 class="course-topic-h3">Topic 3: Building an Agentic RAG Chatbot</h3>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop any store-scoped override so the store 0 value is what renders.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------- C. About This Course (short_description)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @e,
'<p>This course equips participants with practical skills to automate business processes using agentic AI and n8n. Participants will explore the fundamentals of agentic AI, understand how AI agents reason, use tools and perform multi-step tasks, and build intelligent workflows that connect business applications, data sources and operational processes.</p>
<p>Through hands-on activities, participants will learn to use webhooks to trigger real-time automations and exchange data between systems. They will also implement human-in-the-loop mechanisms that allow employees to review, approve or intervene in important decisions, ensuring that automated processes remain accurate, controlled and aligned with business requirements.</p>
<p>The course also introduces Agentic Retrieval-Augmented Generation (RAG) for developing business chatbots that can retrieve information from organisational knowledge sources, generate context-aware responses and take appropriate actions through connected workflows. Participants will learn to design, test and improve an end-to-end agentic automation solution for applications such as customer service, administrative operations, document processing and internal knowledge support.</p>'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;
