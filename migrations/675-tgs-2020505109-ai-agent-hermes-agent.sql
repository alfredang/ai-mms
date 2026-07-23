-- 675: Repurpose WSQ course TGS-2020505109
--   "WSQ - Build Agentic AI and NLP Applications with Langflow"
--   -> "WSQ - AI Agent with Hermes Agent"
-- SG-only in effect: TGS- SKUs do not exist on partner sites, so @e is NULL
-- there and every statement below is a guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505109');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_tp    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');

-- Name + labels + cover
UPDATE catalog_product_entity_varchar SET value = 'WSQ - AI Agent with Hermes Agent'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505109-20260722-152300.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label (product-page zoom gallery alt/title)
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'WSQ - AI Agent with Hermes Agent'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope (Catalog URL Rewrites indexer regenerates)
UPDATE catalog_product_entity_varchar SET value = 'wsq-ai-agent-with-hermes-agent'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta (store 0), and drop the NULL store-scope shadow rows
UPDATE catalog_product_entity_varchar SET value = 'WSQ AI Agent with Hermes Agent | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'Build, deploy, and manage autonomous AI agents with Hermes Agent: RAG, memory, tool calling, and multi-agent workflows. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md AND store_id = 0;
UPDATE catalog_product_entity_text SET value = 'WSQ AI agent course, Hermes Agent training Singapore, agentic AI course, AI agent development, multi-agent workflows, RAG training, LLM tool calling, AI automation course, AI agent deployment, enterprise AI agents'
  WHERE entity_id = @e AND attribute_id = @a_mk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id IN (@a_mt, @a_md) AND store_id <> 0;
DELETE FROM catalog_product_entity_text WHERE entity_id = @e AND attribute_id = @a_mk AND store_id <> 0;

-- Course outline (description) — keep this course's h3.course-topic-h3 shape
UPDATE catalog_product_entity_text SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: Fundamentals of Agentic AI and Hermes Agent</h3>', '\n',
'<h3 class="course-topic-h3">Topic 2: Building AI Agents with Hermes Agent</h3>', '\n',
'<h3 class="course-topic-h3">Topic 3: AI Agent Memory, Tools, and Knowledge Integration</h3>', '\n',
'<h3 class="course-topic-h3">Topic 4: Multi-Agent Collaboration and Workflow Automation</h3>', '\n',
'<h3 class="course-topic-h3">Topic 5: Deploying, Securing, and Optimizing AI Agents</h3>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- About This Course (short_description): replace the intro paragraphs, keep the
-- Brochure / Skills Framework / Certification / WSQ Funding sections
-- byte-identical by splicing at the Course Brochure heading.
UPDATE catalog_product_entity_text SET value = CONCAT(
'<p><strong>WSQ AI Agent with Hermes Agent</strong> equips participants with the knowledge and practical skills to build, deploy, and manage autonomous AI agents using the Hermes Agent framework. Participants will learn the fundamentals of Agentic AI, understand how AI agents reason, plan, use tools, and collaborate, and explore how intelligent agents can automate complex business and development workflows.</p>', '\n',
'<p>Through hands-on exercises, learners will build AI agents capable of interacting with Large Language Models (LLMs), external APIs, enterprise systems, and knowledge bases. They will learn to create single-agent and multi-agent workflows, integrate Retrieval-Augmented Generation (RAG) for context-aware responses, and implement memory, tool calling, and human-in-the-loop interactions to develop reliable and intelligent AI applications.</p>', '\n',
'<p>The course also covers best practices for agent orchestration, prompt engineering, evaluation, security, governance, and AI guardrails to ensure safe, scalable, and production-ready deployments. Participants will gain practical experience in designing AI agents that can automate customer support, software development tasks, business operations, research, and knowledge management.</p>', '\n',
'<p>By the end of the course, learners will be able to confidently design, develop, deploy, and manage AI agents with Hermes Agent, enabling organizations to improve productivity, streamline workflows, and build intelligent automation solutions for real-world applications.</p>', '\n',
SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('<h2>Course Brochure</h2>', value) > 0;

-- Learning Outcomes cms_block
UPDATE cms_block SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>', '\n',
'<ul>', '\n',
'<li>LO1: Identify the tasks associated with natural language processing (NLP)</li>', '\n',
'<li>LO2: Perform text representation using word embedding</li>', '\n',
'<li>LO3: Perform language processing and modeling</li>', '\n',
'<li>LO4: Build text classification using machine learning</li>', '\n',
'<li>LO5: Determine strategies to enhance memory networks</li>', '\n',
'</ul>')
  WHERE identifier = 'course_TGS-2020505109_learning_outcomes';

-- Trainer bios: retarget course-title quotes and the Langflow tooling mentions
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'Build Agentic AI and NLP Applications with Langflow', 'AI Agent with Hermes Agent')
  WHERE entity_id = @e AND attribute_id = @a_tp;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'Langflow&rsquo;s', 'Hermes Agent&rsquo;s')
  WHERE entity_id = @e AND attribute_id = @a_tp;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'Langflow', 'Hermes Agent')
  WHERE entity_id = @e AND attribute_id = @a_tp;
