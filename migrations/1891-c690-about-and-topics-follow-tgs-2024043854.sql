-- 1891: C690 "Human-AI Collaboration with Always On AI Agents" follows its WSQ twin TGS-2024043854 again.
--
-- 1889 copied the parent's About + topics (Hermes Agent / OpenClaw / Paperclip); the parent was then
-- rewritten by 1890-tgs-2024043854-always-on-agents-hermes-about-and-topics (Always-On AI Agents ->
-- single Hermes agent -> Hermes multi-agent teams). Mirror that here (user request 2026-11-02):
--
--  1. "About This Course" (short_description): the parent's 5 paragraphs (opener names the C690 title)
--     + the internal-link paragraph. Covers Meta Muse, Claude Duet, OpenAI Dots, Manus Cue, Grok Bots.
--  2. "What You'll Learn" (description): the parent's 3 topics, LSN_DATA marker kept in sync.
--  3. Meta description + keywords: OpenClaw / Paperclip / RAG are no longer taught. Non-WSQ: no funding
--     words. meta_title (bare course name) is unchanged.
--
-- SG-only (store guard + C690 and its twin must exist) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C690' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024043854' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');

-- ------------------------------------------------------------ About -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p><strong>Human-AI Collaboration</strong> with <strong>Always On AI Agents</strong> equips participants with practical knowledge and skills to design, develop, and manage <strong>autonomous AI agents</strong> that collaborate with humans to improve business productivity, automate workflows, and enhance operational efficiency.</p><p>Participants will explore the emerging landscape of <strong>Always-On AI Agents</strong>, including Meta Muse, Claude Duet, OpenAI Dots, Manus Cue, and Grok Bots. They will examine how these AI agents operate proactively, perform tasks autonomously, and collaborate with humans across business functions. Emphasis is placed on understanding their capabilities, limitations, and the role of human oversight in managing an AI-powered workforce.</p><p>Through hands-on activities, participants will learn to design and build a single autonomous AI agent using <strong>Hermes Agent</strong>. They will configure Large Language Models (LLMs), prompts, memory, tools, skills, and integrations to enable agents to retrieve information, execute tasks, generate business content, and perform scheduled activities.</p><p>Participants will then progress to designing multi-agent systems using Hermes, where specialised AI agents collaborate, delegate tasks, and coordinate workflows. They will explore agent communication, task decomposition, group chats, and Kanban-based workflows to improve efficiency, reliability, and output quality.</p><p>By the end of the course, participants will be able to design and evaluate human-AI workflows, deploy single and multiple AI agents, and optimise agent collaboration to support business automation and workforce transformation.</p>\n<p>This course is part of our <a href="/artificial-intelligence-courses.html">AI training in Singapore</a>, where you can browse all our AI courses. See more <a href="/multi-agents-series.html">multi AI agents courses</a>.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------------------------- Topics -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Overview of Always-On AI Agents and Human-AI Collaboration","subsecs":[]},{"title":"Topic 2: Designing and Building a Single Autonomous AI Agent with Hermes","subsecs":[]},{"title":"Topic 3: Designing Multi-Agent Teams to Improve Workflow Efficiency","subsecs":[]}] -->\n<p><strong>Topic 1: Overview of Always-On AI Agents and Human-AI Collaboration</strong></p>\n<p><strong>Topic 2: Designing and Building a Single Autonomous AI Agent with Hermes</strong></p>\n<p><strong>Topic 3: Designing Multi-Agent Teams to Improve Workflow Efficiency</strong></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- -------------------------------------------------------------- Meta -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Human-AI collaboration course: work with always-on AI agents such as Meta Muse and OpenAI Dots, build an autonomous Hermes agent and run multi-agent teams.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Human-AI collaboration course, always-on AI agents training Singapore, Meta Muse, OpenAI Dots, Hermes Agent, autonomous AI agents, multi-agent systems, AI workforce course'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Store-view overrides and wrong-table orphans would shadow the store-0 values.
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid
   AND (    (attribute_id IN (@a_short, @a_desc, @a_mkey) AND store_id <> 0)
         OR  attribute_id = @a_mdesc);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid
   AND (    (attribute_id = @a_mdesc AND store_id <> 0)
         OR  attribute_id IN (@a_short, @a_desc, @a_mkey));
