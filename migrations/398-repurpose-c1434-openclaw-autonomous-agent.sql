-- Rename course C1434 from "Mastering OpenClaw - Super Personal AI Assistant"
-- to "Build Autonomous AI Agent with Openclaw" (1 day / 2 topics). Part of the
-- AI Agents series. name, overview, topics, meta, cover, url_key. Price and
-- duration unchanged (350 SG / 7.5h). Store scope 0. Idempotent. No content
-- line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1434');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Build Autonomous AI Agent with Openclaw') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build your own autonomous AI agent with Build Autonomous AI Agent with Openclaw. This hands-on 1-day course teaches you how to use the OpenClaw platform to design, configure and deploy AI agents that plan, reason and complete multi-step tasks on their own. Instead of scripting every step, you will define goals, tools and guardrails and let your OpenClaw agent take action while you stay in control.</p>
<p>Through practical projects, participants will set up an OpenClaw agent, connect tools and data sources, design agent workflows and memory, and deploy an autonomous agent that automates a real task end to end. You will also learn to monitor, guardrail and improve your agent so it runs reliably and safely. By the end of the course, you will be able to build and deploy a working autonomous AI agent with OpenClaw.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with OpenClaw</h3>
<ul>
<li>Introduction to Autonomous AI Agents and OpenClaw</li>
<li>Setting Up Your OpenClaw Agent Environment</li>
<li>Defining Goals, Tools and Guardrails</li>
<li>Designing Agent Workflows and Memory</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building and Deploying Autonomous Agents with OpenClaw</h3>
<ul>
<li>Connecting Tools, APIs and Data Sources</li>
<li>Building a Multi-Step Autonomous Agent</li>
<li>Monitoring, Guardrailing and Improving Your Agent</li>
<li>Deploying and Running Your OpenClaw Agent</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Build Autonomous AI Agent with Openclaw') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build and deploy your own autonomous AI agent with the OpenClaw platform. Design goals, tools, workflows and guardrails in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'OpenClaw, Autonomous AI Agent, AI Agents, Agentic AI, AI Automation, Agent Workflows, AI Agent Development')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1434-20260711-230625.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'build-autonomous-ai-agent-with-openclaw') ON DUPLICATE KEY UPDATE value = VALUES(value);
