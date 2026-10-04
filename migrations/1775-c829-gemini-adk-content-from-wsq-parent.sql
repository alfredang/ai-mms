-- C829 "Building Multi Agent Aplications with Gemini ADK": re-aligned to its WSQ parent
-- TGS-2024042961 (WSQ - Develop Multi AI Agent Applications with Gemini Agent ADK), whose
-- courseware it now carries (converted 2026-10-04). Name, slug, fee, duration (15 hrs) and
-- sessions (2) are already correct and are not touched.
--
-- 1. About (short_description) + topics (description) copied from the WSQ parent. The parent's
--    Topic 4 title carries a typo ("Build a Agenti AI App"); it is corrected on C829 only to the
--    courseware's wording. The copy also drops C829's inline "Funding and Grant Applications"
--    section, which linked a different WSQ course.
-- 2. meta_title (bare - the composer adds the brand) / meta_description / meta_keyword rewritten:
--    the old ones described the retired SupportOps syllabus (production deployment) and the
--    meta_title held a mis-encoded dash.
-- 3. Funding block: was linking wsq-develop-artificial-intelligence-and-large-language-model-llm-
--    applications-with-google-gemini.html -> the actual parent's page. Content-only UPDATE
--    (a cms/block model save would wipe cms_block_store).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Not in SQL: schedule template B09 (gid 67) -> B07 (gid 190, same code as the 2-day WSQ twin on
-- (SG) WSQ-B07) is switched on prod via the code path (CoursesaveController).
-- Post-deploy: flat reindex + cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C829' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024042961' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ---------------------------------------------- About + topics (parent) ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_short AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_desc AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'Topic 4 Build a Agenti AI App with Gemini Agent ADK and Streamlit',
                              'Topic 4 Build an Agentic AI App with Gemini Agent ADK and Streamlit')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_desc AND store_id = 0;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, 'Building Multi Agent Aplications with Gemini ADK'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Build single and multi-agent AI apps in Python with Google Gemini ADK - tools, sessions, Sequential, Parallel and Loop workflows, guardrails, MCP, agentic RAG and a Streamlit app. Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- an orphan TEXT-table meta_description would shadow the varchar value
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Gemini ADK course, Google Agent Development Kit, multi-agent AI applications, agentic AI, Gemini API, AI agent tools, sessions and state, SequentialAgent, ParallelAgent, LoopAgent, agent guardrails, structured output, Model Context Protocol MCP, agentic RAG, Streamlit AI app, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- clear store-level overrides -----
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_mtitle, @a_mdesc) AND store_id <> 0;

-- ----------------------------------------------------- funding block -----
UPDATE cms_block
   SET content = '<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-develop-multi-ai-agent-applications-with-gemini-agent-adk.html">WSQ - Develop Multi AI Agent Applications with Gemini Agent ADK</a></span></p>'
 WHERE @ok AND identifier = 'course_C829_funding_and_grant';
