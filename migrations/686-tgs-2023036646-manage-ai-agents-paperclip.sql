-- 686: Repurpose WSQ course TGS-2023036646
--   "WSQ - Build LLM Applications Using Flowise and LangChain"
--   -> "WSQ - Manage AI Agents with Paperclip"
-- SG-only in effect: TGS- SKUs do not exist on partner sites, so @e is NULL
-- there and every statement below is a guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036646');

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
UPDATE catalog_product_entity_varchar SET value = 'WSQ - Manage AI Agents with Paperclip'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036646-20260722-161024.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label (product-page zoom gallery alt/title)
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'WSQ - Manage AI Agents with Paperclip'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope (Catalog URL Rewrites indexer regenerates)
UPDATE catalog_product_entity_varchar SET value = 'wsq-manage-ai-agents-with-paperclip'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = 'WSQ Manage AI Agents with Paperclip | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'Build, deploy, and manage intelligent AI agents with Paperclip: RAG, memory, tool calling, and multi-agent workflows for business automation. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md AND store_id = 0;
UPDATE catalog_product_entity_text SET value = 'WSQ AI agent course, Paperclip AI training Singapore, manage AI agents, agentic AI course, AI business automation, multi-agent workflows, RAG training, LLM tool calling, AI agent deployment, no-code AI agents'
  WHERE entity_id = @e AND attribute_id = @a_mk AND store_id = 0;

-- Course outline (description) — keep this course's h3.course-topic-h3 shape
UPDATE catalog_product_entity_text SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: Fundamentals of Agentic AI and Paperclip</h3>', '\n',
'<h3 class="course-topic-h3">Topic 2: Building AI Agents with Paperclip</h3>', '\n',
'<h3 class="course-topic-h3">Topic 3: Developing Intelligent Multi-Agent Systems</h3>', '\n',
'<h3 class="course-topic-h3">Topic 4: Deploying and Managing AI Agents</h3>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- About This Course (short_description): replace the intro paragraphs, keep the
-- Brochure / Skills Framework / Certification / WSQ Funding sections
-- byte-identical by splicing at the Course Brochure heading.
UPDATE catalog_product_entity_text SET value = CONCAT(
'<p><strong>WSQ Manage AI Agents with Paperclip</strong> is a practical, hands-on course that equips participants with the knowledge and skills to build, deploy, and manage intelligent AI agents for business automation. Participants will learn the fundamentals of Agentic AI, understand how AI agents differ from traditional chatbots, and discover how autonomous agents can reason, use tools, access knowledge, and collaborate to complete complex tasks.</p>', '\n',
'<p>Using Paperclip''s intuitive interface, learners will gain hands-on experience designing AI agents, configuring workflows, integrating Large Language Models (LLMs), connecting APIs, and automating business processes with minimal coding. They will create agent workflows that can retrieve information, generate content, execute actions, and interact with enterprise systems to improve productivity and operational efficiency.</p>', '\n',
'<p>The course also explores advanced AI agent capabilities, including Retrieval-Augmented Generation (RAG), knowledge base integration, memory management, tool calling, and multi-agent collaboration. Participants will learn how to build context-aware agents that access enterprise knowledge, coordinate specialized tasks, and incorporate human approval through human-in-the-loop workflows.</p>', '\n',
'<p>In addition, learners will discover best practices for deploying and managing AI agents, including prompt engineering, performance evaluation, monitoring, security, governance, and AI guardrails to ensure reliable and responsible operation.</p>', '\n',
'<p>By the end of the course, participants will be able to confidently design, build, deploy, and optimize AI agents with Paperclip to automate business workflows, enhance decision-making, and deliver scalable AI-powered solutions across customer service, operations, sales, marketing, and knowledge management.</p>', '\n',
SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('<h2>Course Brochure</h2>', value) > 0;

-- Learning Outcomes cms_block
UPDATE cms_block SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>', '\n',
'<ul>', '\n',
'<li>LO1: Identify Large Language Model (LLM) opportunities and perform feasibility scans.</li>', '\n',
'<li>LO2: Utilise OpenAI API to integrate data and develop LLM applications.</li>', '\n',
'<li>LO3: Perform tests in Langchain to verify LLM applications between disparate components and their functioning.</li>', '\n',
'<li>LO4: Resolve technical issues in Langchain and implement modifications to LLM applications.</li>', '\n',
'</ul>')
  WHERE identifier = 'course_TGS-2023036646_learning_outcomes';

-- Trainer bios: retitle course quotes; Flowise -> Paperclip. LangChain mentions
-- stay (the WSQ learning outcomes still cover OpenAI API + Langchain).
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'Build LLM Applications Using Flowise and LangChain', 'Manage AI Agents with Paperclip')
  WHERE entity_id = @e AND attribute_id = @a_tp;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'Flowise', 'Paperclip')
  WHERE entity_id = @e AND attribute_id = @a_tp;
