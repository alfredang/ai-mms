-- Repurpose course C1231 from "Build MCP Tools with FastMCP and Vibe Coding" to
-- "AI Vibe Coding for MCP Tool Development" (AI Vibe Coding Series standard:
-- 2 days / 15h / 4 topics / $700).
-- name, overview, topics, meta, cover image, duration, price, badge, image labels.
-- Price set here (NOT in shared 347 — that file is already in the prod ledger
-- and edited migrations never re-run on prod).
-- url_key intentionally UNCHANGED (series rule — preserves URL + SEO).
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1231.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1231');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_price := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='price');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI Vibe Coding for MCP Tool Development' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Build MCP (Model Context Protocol) tools without wrestling with boilerplate. In this hands-on 2-day course you will use AI coding assistants&mdash;Cursor, GitHub Copilot and Claude&mdash;to vibe code MCP servers end to end with FastMCP: describe the tool you want in plain English, let the AI generate the code, then review, test and iterate with follow-up prompts. You will learn the prompting patterns that keep AI-generated MCP tools correct, secure and reliable when connected to real AI assistants.</p>
<p>Over four practical topics you will vibe code the full MCP workflow&mdash;from standing up your first FastMCP server, to building tool functions, resources and prompt templates, connecting them to APIs, databases and AI assistants, and finally deploying and securing production-ready MCP servers. By the end of the course, you will have working MCP tools you built with AI assistance and a repeatable AI vibe coding workflow you can apply to any AI integration project.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 AI Vibe Coding for MCP Fundamentals</h3>
<ul>
<li>What Is AI Vibe Coding</li>
<li>Setting Up Cursor, GitHub Copilot and Claude for MCP Development</li>
<li>Overview of Model Context Protocol (MCP) Architecture</li>
<li>Understanding MCP Tools, Resources and Prompts</li>
<li>Installing and Configuring FastMCP</li>
<li>Vibe Coding Your First MCP Server</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Vibe Coding MCP Tools with FastMCP</h3>
<ul>
<li>Designing MCP Tools for Real-World Workflows</li>
<li>Vibe Coding Tool Functions from Plain-English Prompts</li>
<li>Adding Resources and Prompt Templates to MCP Servers</li>
<li>Handling Inputs, Outputs and Errors in MCP Tools</li>
<li>Testing MCP Tools with AI Clients</li>
<li>Reviewing and Debugging AI-Generated MCP Code</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Connecting MCP Tools to AI Assistants and APIs</h3>
<ul>
<li>Connecting MCP Servers to Claude and Other AI Assistants</li>
<li>Vibe Coding API Integrations for MCP Tools</li>
<li>Working with Databases and Files from MCP Tools</li>
<li>Authentication and Permission Management for MCP Tools</li>
<li>Iterating and Improving MCP Tools with Follow-Up Prompts</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Deploying and Scaling MCP Tools</h3>
<ul>
<li>Packaging and Deploying FastMCP Servers</li>
<li>Local and Remote MCP Transports (stdio and HTTP)</li>
<li>Security Best Practices for MCP Tools</li>
<li>Performance Optimisation and Debugging</li>
<li>Real-World Use Cases of MCP Tools in AI Workflow Automation</li>
<li>Capstone: Vibe Code an End-to-End MCP Tool</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI Vibe Coding for MCP Tool Development' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Vibe code MCP tools with Cursor, GitHub Copilot and Claude in this hands-on 2-day course. Build, connect and deploy FastMCP servers for AI assistants from plain-English prompts.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI Vibe Coding, MCP, Model Context Protocol, FastMCP, MCP Server, MCP Tools, AI Assistants, AI Integration, Cursor, GitHub Copilot, Claude, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1231-20260717-101021.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '15' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @e, 700.0000 FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_decimal SET value = 700.0000
WHERE entity_id = @e AND attribute_id = @a_price AND @e IS NOT NULL;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_badge, 0, @e, 'AI Vibe Coding Series' FROM DUAL WHERE @e IS NOT NULL AND @a_badge IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI Vibe Coding for MCP Tool Development' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI Vibe Coding for MCP Tool Development' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI Vibe Coding for MCP Tool Development' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_img, @a_dur, @a_badge, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
