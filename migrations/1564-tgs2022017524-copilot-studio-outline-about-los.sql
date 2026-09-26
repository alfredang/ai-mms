-- 1564: TGS-2022017524 "WSQ - Business Process Automation with Power Automate
--       and Copilot Studio Agents" -- supplied About / Learning Outcomes /
--       Course Outline (2026-09-27).
--
-- Rewrites three things, all keyed by SKU so a site without the course is a
-- no-op (SG-only WSQ course; MY/GH have no TGS- SKUs):
--   * short_description -- the "About This Course" copy (5 paragraphs, new
--     Copilot Studio experience: agents, workflows, Power Automate).
--   * description -- the "What You'll Learn" outline, reduced from the six
--     stale Power Platform topics to the three supplied topic headings. Same
--     headings-only house shape as 999 / 960 / 967 (<h3 class="course-topic-h3">),
--     LSN_DATA comment dropped with the old topics (nothing reads it).
--   * cms_block course_TGS-2022017524_learning_outcomes -- LO1-LO3 still
--     described the retired "Develop Intelligent Chatbots" course; replaced
--     with the supplied Copilot Studio agents/workflows outcomes in the same
--     "<p>By the end...</p><ul><li>LOn: ...</li></ul>" shape as the live block.
--     Keyed by identifier, not block_id (ids drift between local and prod).
--
-- Untouched: name, url_key, meta_*, sessions (2), duration (16), price,
-- categories, trainers, brochure / funding_and_grant / skills_framework blocks.
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2022017524' LIMIT 1);
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course equips participants with practical, hands-on skills to automate business processes using Microsoft Copilot Studio workflows, agents, and Power Automate. Based on the new Copilot Studio experience, the course focuses on the fundamentals of creating agents, building workflows, connecting business applications and data, and enabling agents to perform real-world business tasks.</p><p>Participants will learn how to create and configure Copilot Studio agents, define agent instructions and capabilities, design workflows with inputs and outputs, trigger automated actions, and integrate workflows with Power Automate. Through guided hands-on exercises, learners will explore how agents and workflows work together to receive requests, process information, make decisions, execute actions, and return structured results.</p><p>The course emphasizes practical workplace applications. Participants will build automation solutions for common scenarios such as handling customer enquiries, processing applications, routing approvals, onboarding customers, updating business records, generating documents, sending notifications, and coordinating multi-step processes.</p><p>Learners will also practise testing and troubleshooting workflows and agents, handling exceptions, refining agent behaviour, and improving automation reliability.</p><p>By the end of the course, participants will be able to design and build practical Copilot Studio agents and workflows that reduce repetitive work, improve process efficiency, and support day-to-day business operations with minimal coding.</p>'
FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Copilot Studio Workflows</h3>
<h3 class="course-topic-h3">Topic 2: Copilot Studio Agents</h3>
<h3 class="course-topic-h3">Topic 3: Real-Life Applications of Copilot Studio Workflows and Agents</h3>'
FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- drop any store-scope overrides so the store-0 copy is what every scope serves
DELETE FROM catalog_product_entity_text WHERE entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0 AND @pid IS NOT NULL;

UPDATE cms_block
SET content = '<p>By the end of the course, learners will be able to:</p><ul><li>LO1: Contextualize ideas for Copilot Studio agents and map out storyboards to suit customer preferences.</li><li>LO2: Determine the frequency and types of Copilot Studio workflows and agents content to be delivered to customers.</li><li>LO3: Determine the modes of distributing chatbots and evaluate the Copilot Studio workflows and agents execution.</li></ul>'
WHERE identifier = 'course_TGS-2022017524_learning_outcomes';
