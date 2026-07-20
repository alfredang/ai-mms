-- Rename course C989 from "Codex CLI Fundamentals for Agentic Vibe Coding" to
-- "Agentic AI with Codex" (1 day / 2 topics). Part of the Codex AI series.
-- name, overview, topics, meta, cover, url_key. Price and duration unchanged
-- (350 SG / 7.5h). Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C989');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Agentic AI with Codex') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build agentic AI software with Agentic AI with Codex. This hands-on 1-day course teaches you how to use OpenAI Codex and the Codex CLI as an autonomous coding agent that plans, writes, runs and fixes code on its own. Instead of coding every step yourself, you will describe goals in plain language and let Codex act as an agentic pair programmer while you review and guide the work.</p>
<p>Through practical projects, participants will set up the Codex CLI, delegate multi-step coding tasks to the agent, connect tools and repositories, and build and automate a working application end to end. You will also learn to review, test and guardrail AI-generated code so your agent stays reliable and safe. By the end of the course, you will be able to build and ship software faster with an agentic AI workflow powered by Codex.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Agentic AI and Codex</h3>
<ul>
<li>Introduction to Agentic AI and OpenAI Codex</li>
<li>Setting Up the Codex CLI Environment</li>
<li>Delegating Multi-Step Coding Tasks to the Agent</li>
<li>Effective Prompting and Guardrails for Codex</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building and Deploying Agentic AI with Codex</h3>
<ul>
<li>Connecting Tools, Repositories and Data Sources</li>
<li>Building and Automating an Application with Codex</li>
<li>Reviewing, Testing and Refactoring AI-Generated Code</li>
<li>Deploying and Operating Your Codex-Powered Workflow</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Agentic AI with Codex') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build agentic AI software with OpenAI Codex and the Codex CLI. Delegate multi-step coding tasks to an autonomous agent in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Codex, OpenAI Codex, Codex CLI, Agentic AI, AI Coding Agent, Agentic Coding, AI Automation, AI Software Development')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C989-20260711-230925.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'agentic-ai-with-codex') ON DUPLICATE KEY UPDATE value = VALUES(value);
