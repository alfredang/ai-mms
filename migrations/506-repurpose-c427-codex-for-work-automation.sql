-- Repurpose course C427 from "Agent Skills Fundamentals" to
-- "Codex for Work Automation" (OpenAI Codex used to automate everyday
-- work tasks). Full content rewrite: name, overview, 2 topics (1 day),
-- meta, url_key, image labels, fresh cover. Duration (7.5h / 1 day) and
-- price ($350) are intentionally unchanged.
-- url_key changes (agent-skills-fundamentals -> codex-for-work-automation)
-- because the subject changed entirely; url_path is dropped at every scope
-- so the Catalog URL Rewrites indexer regenerates (old URL 301s).
-- Funding block points at WSQ - Building Agentic AI Workflows to Automate
-- Business Processes (validated 200 on www.tertiarycourses.com.sg).
-- Clears per-store overrides so partner scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C427.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C427');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_cimg  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_stat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Codex for Work Automation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Put OpenAI Codex to work on the repetitive parts of your job in this hands-on 1-day course. Codex is OpenAI&rsquo;s AI coding agent that turns plain-English instructions into working automation &mdash; available in your terminal via the Codex CLI, inside your editor through the IDE extension, and in the cloud where tasks run on their own while you carry on with other work. You will set up Codex, learn the prompting patterns that get reliable results, and use AGENTS.md files to give the agent standing instructions about your projects and preferences so every task starts with the right context.</p>
<p>Through practical exercises, participants will delegate real work tasks to Codex: cleaning and transforming spreadsheets and data files, batch-renaming and organising documents, generating reports and summaries, and building small scripts that automate recurring workflows end to end. You will also connect Codex to GitHub to review changes and keep your automation under version control, and build the verify-then-trust habit of checking every AI-generated script before relying on it. By the end of the course, you will be able to hand routine work to Codex with confidence and free your time for higher-value tasks.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with OpenAI Codex</h3>
<ul>
<li>What Codex Is and How the Agent Works</li>
<li>Setting Up the Codex CLI, IDE Extension and Codex Cloud</li>
<li>Prompting Patterns for Reliable Automation</li>
<li>Standing Instructions with AGENTS.md</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Automating Work Tasks with Codex</h3>
<ul>
<li>Cleaning and Transforming Data and Spreadsheets</li>
<li>Organising Files and Generating Reports</li>
<li>Building Reusable Automation Scripts</li>
<li>GitHub Integration and Verify-Then-Trust Review</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Codex for Work Automation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Automate everyday work tasks with OpenAI Codex in this hands-on 1-day course - set up the Codex CLI, IDE extension and Codex cloud, use AGENTS.md, and delegate data cleaning, file organisation, reports and reusable scripts to the AI agent.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Codex, OpenAI Codex, Work Automation, Codex CLI, AI Agent, Task Automation, AGENTS.md, Automation Scripts, GitHub, Productivity, AI Coding Agent, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'codex-for-work-automation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Fresh cover rendered 2026-07-18 from the new title (no funding badges)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cimg, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C427-20260717-173906.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Codex for Work Automation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Codex for Work Automation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Codex for Work Automation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Keep the course ENABLED (status 1 at store 0)
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_stat, 0, @e, 1 FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear per-store overrides so no scope shadows the new store-0 values
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_cimg, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
DELETE FROM catalog_product_entity_int
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id=@a_stat;

-- Stale url_path rows point at the old agent-skills-fundamentals URL;
-- drop them at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;

-- Funding block: point at the WSQ agentic work-automation twin (validated 200)
UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-building-agentic-ai-workflows-to-automate-business-processes.html" title="WSQ - Building Agentic AI Workflows to Automate Business Processes">WSQ - Building Agentic AI Workflows to Automate Business Processes</a></span></p>'
WHERE identifier = 'course_C427_funding_and_grant';
