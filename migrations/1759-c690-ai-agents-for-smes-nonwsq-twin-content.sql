-- C690 "AI Agents for SMEs": non-WSQ twin of TGS-2023018987 "WSQ - AI Agents for Business"
-- (courseware converted 2026-10-04; repo github.com/tertiarycourses/C690-AI-Agents-for-SMEs).
--
-- 1. "What's This Course About" (short_description) and the 4 course topics (description,
--    LSN_DATA) copied from the WSQ parent, "WSQ" dropped from the opening sentence. No day
--    count anywhere (replaces the "1-day"/"2-day" copy left by 1758).
-- 2. meta_description rewritten without a day count.
-- 3. Funding block now points at the WSQ twin (was WSQ - No Code and Low Code Agentic AI
--    Applications).
-- 4. Records the cover re-rendered with the new title (C690-20261004-085225.png).
-- Schedule: already on B19 (gid 108) = parent's (SG) WSQ-B19; switched on prod 2026-10-04.
--
-- SG-only (store guard + parent must exist) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C690' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023018987' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_cover := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This AI Agents for SMEs course equips learners with the knowledge and practical skills to design, build, and deploy AI agents that automate business processes, improve productivity, and support intelligent decision-making. Participants will learn how AI agents combine large language models (LLMs), reasoning, planning, memory, and tool integration to perform business tasks autonomously while collaborating effectively with human users.</p><p>The course introduces the fundamentals of agentic AI, prompt engineering, context engineering, and AI-powered workflow automation. Learners will gain hands-on experience in building AI agents that can retrieve information, interact with enterprise applications through APIs, execute business workflows, and automate repetitive tasks across different business functions.</p><p>Participants will also explore Retrieval-Augmented Generation (RAG), Model Context Protocol (MCP), memory management, multi-agent collaboration, and human-in-the-loop workflows to develop reliable, context-aware, and scalable AI solutions. Practical exercises demonstrate how AI agents can be applied to customer service, sales, marketing, finance, human resources, operations, and knowledge management.</p><p>The course further covers responsible AI practices, governance, security, guardrails, and deployment considerations to ensure AI agents operate safely and effectively in enterprise environments. By the end of the course, learners will be able to design, develop, and deploy business AI agents that integrate with existing systems, automate end-to-end processes, and create an AI-powered digital workforce capable of increasing organisational efficiency, innovation, and business value.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Foundations of AI Agents for Business","subsecs":[]},{"title":"Topic 2: Building and Integrating Business AI Agents","subsecs":[]},{"title":"Topic 3: Intelligent Business Automation with AI Agents","subsecs":[]},{"title":"Topic 4: Deploying, Governing, and Optimising AI Agents","subsecs":[]}] -->\r\n<p><strong>Topic 1: Foundations of AI Agents for Business</strong></p>\r\n<p><strong>Topic 2: Building and Integrating Business AI Agents</strong></p>\r\n<p><strong>Topic 3: Intelligent Business Automation with AI Agents</strong></p>\r\n<p><strong>Topic 4: Deploying, Governing, and Optimising AI Agents</strong></p>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Learn how SMEs can design, build and deploy AI agents that automate business workflows, from grounded retrieval and tool integration to human approval and governance, at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C690-20261004-085225.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_mdesc, @a_cover) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C690 - Funding and Grant', 'course_C690_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C690_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C690_funding_and_grant';

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p class="p1">No funding is available for this course.</p>\n<p>For WSQ funding, please checkout the details at <span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-agents-for-business.html" title="WSQ - AI Agents for Business" target="_self">WSQ - AI Agents for Business</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C690_funding_and_grant';
