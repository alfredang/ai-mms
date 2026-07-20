-- Rename course C818 from "Vibe Coding for Agentic AI Automations" to
-- "AI Vibe Coding with Codex" (2 days / 4 topics). Part of the AI Vibe Coding
-- series (badge). name, overview, topics, meta (title/description/keyword),
-- cover, url_key, badge. Price and duration unchanged (700 SG / 15h). Store
-- scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C818');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding with Codex') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build software faster with AI Vibe Coding with Codex. This hands-on 2-day course teaches you how to use OpenAI Codex and the Codex CLI as an agentic pair programmer that plans, writes, runs and fixes code. Instead of coding every line yourself, you will vibe code &mdash; describing what you want in plain language and letting Codex generate, refactor and debug your code while you review, guide and ship.</p>
<p>Through practical projects, participants will set up Codex, delegate multi-step coding tasks, build and run real applications, connect to tools and repositories, and test, debug and refactor with AI. You will also learn to review, secure and validate AI-generated code so your software stays reliable. By the end of the course, you will be able to build, automate and ship software faster with an effective AI vibe-coding workflow powered by Codex.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding and Codex</h3>
<ul>
<li>Introduction to Vibe Coding and OpenAI Codex</li>
<li>Setting Up the Codex CLI and Environment</li>
<li>Delegating Coding Tasks to Codex</li>
<li>Effective Prompting and Guardrails for Codex</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building Applications with Codex</h3>
<ul>
<li>Generating Code, Files and Project Scaffolding</li>
<li>Building Front End, Back End and Data Layers</li>
<li>Connecting to Tools, Repositories and APIs</li>
<li>Explaining and Navigating Codebases with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Testing, Debugging and Refactoring with Codex</h3>
<ul>
<li>Generating Tests and Running Them with Codex</li>
<li>Debugging and Fixing Issues with AI</li>
<li>Refactoring and Improving Code Quality</li>
<li>Reviewing, Securing and Validating AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Automating and Shipping with Codex</h3>
<ul>
<li>Automating Repetitive Coding Tasks and Workflows</li>
<li>Integrating Codex into Development and CI/CD</li>
<li>Building and Deploying Applications</li>
<li>Best Practices for Agentic Coding at Scale</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding with Codex') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build software faster with AI vibe coding using OpenAI Codex. Delegate multi-step coding, testing and refactoring to an AI agent in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Codex, OpenAI Codex, Codex CLI, Agentic Coding, AI Coding, Software Development, AI Automation, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C818-20260712-051848.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-with-codex') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
