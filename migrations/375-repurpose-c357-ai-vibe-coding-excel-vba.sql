-- Repurpose course C357 from "Visual Basic Application (VBA) for Excel Training"
-- to "AI Vibe Coding for Excel VBA" (2 days / 4 topics). AI Vibe Coding series
-- (badge set). name, overview, topics, meta, duration 15h, cover, url_key, badge.
-- Per-market price (700/2200/3000) + SG funding block direct on prod.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C357');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Excel VBA') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Automate Excel and build powerful macros with AI Vibe Coding for Excel VBA. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write VBA code that automates spreadsheets and business tasks. Instead of memorising VBA syntax, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and debug your macros while you stay in control of the logic.</p>
<p>Through practical projects, participants will record and write macros, work with ranges, workbooks and events, build custom functions and userforms, and automate reports and data processing &mdash; all with an AI pair programmer at their side. You will also learn to review, test and improve AI-generated code so your automations are reliable. By the end of the course, you will be able to automate Excel faster and more confidently with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Excel VBA</h3>
<ul>
<li>Introduction to Excel VBA and Vibe Coding</li>
<li>Setting Up the VBA Editor and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Recording and Writing Your First Macro</li>
<li>Effective Prompting for VBA Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 VBA Fundamentals with AI</h3>
<ul>
<li>Variables, Data Types and Operators</li>
<li>Control Flow, Loops and Procedures</li>
<li>Working with Ranges, Cells and Workbooks</li>
<li>Debugging and Explaining Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Automating Excel Tasks with AI</h3>
<ul>
<li>Automating Reports and Data Processing</li>
<li>Working with Events and Triggers</li>
<li>Building Custom Functions</li>
<li>Reviewing and Refactoring AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building Excel Tools and UserForms with AI</h3>
<ul>
<li>Designing UserForms and Interfaces</li>
<li>Connecting to Data and Other Apps</li>
<li>Testing and Error Handling</li>
<li>Packaging and Sharing Your Excel Tools</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Excel VBA | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Automate Excel with AI vibe coding. Master VBA macros, ranges, events, custom functions and userforms using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Excel VBA, Macros, Automation, Cursor, GitHub Copilot, Claude, Spreadsheets, UserForms, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C357-20260711-101744.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-excel-vba') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
