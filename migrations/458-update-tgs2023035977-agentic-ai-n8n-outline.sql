-- Update WSQ course TGS-2023035977 "WSQ - Agentic AI Automation with n8n":
-- course outline topics (description) and course overview (short_description).
-- Name, url_key and the learning-outcomes cms_block are unchanged (the new
-- LOs are identical to the existing block).
-- Partner-safe: TGS- SKUs exist only on SG, so @e is NULL on MY/GH and every
-- statement is a no-op. Store scope 0; per-store overrides of the rewritten
-- attributes are cleared. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2023035977');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>WSQ Agentic AI Automation with n8n introduces participants to the concepts and practical applications of building intelligent automation using n8n, AI agents, webhooks, and Retrieval-Augmented Generation (RAG). The course is designed for professionals who want to automate business processes by combining low-code workflow orchestration with autonomous AI capabilities.</p>
<p>Participants will learn to design workflow automation using n8n, including triggers, actions, integrations, and API connectivity. Building on this foundation, the course explores Agentic AI, where AI agents can plan, reason, make decisions, and execute multi-step tasks autonomously.</p>
<p>The course also covers event-driven automation using webhooks and HTTP requests to integrate AI agents with external applications and enterprise systems. Participants will further enhance workflows with Agentic RAG, enabling AI agents to retrieve relevant knowledge from external sources to generate more accurate, context-aware responses.</p>
<p>Finally, participants will learn human-in-the-loop workflow design, monitoring, error handling, and security best practices for deploying reliable AI-powered automation. Through hands-on exercises and real-world use cases, they will build end-to-end intelligent workflows that improve operational efficiency, automate complex processes, and support smarter business decision-making across a wide range of industries.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Workflow Automation with n8n</h3>
<h3 class="course-topic-h3">Topic 2: Agentic Process Automation with AI Agents</h3>
<h3 class="course-topic-h3">Topic 3: Agentic Automation with Webhooks and HTTP Requests</h3>
<h3 class="course-topic-h3">Topic 4: Enhancing Workflow Automation with Agentic RAG</h3>
<h3 class="course-topic-h3">Topic 5: Human-in-the-Loop, Monitoring, and Security in n8n</h3>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE @e IS NOT NULL AND entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc);
