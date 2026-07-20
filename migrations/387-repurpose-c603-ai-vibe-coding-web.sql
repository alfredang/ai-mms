-- Rename course C603 from "Vibe Coding for Building Professional Web Apps" to
-- "AI Vibe Coding for Web Development" (1 day / 2 topics). Already in the AI
-- Vibe Coding series (badge kept). name, overview, topics, meta, cover, url_key,
-- badge. Per-market price (350/1100/1500) direct on prod. Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C603');
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
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Web Development') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build modern websites and web apps with AI Vibe Coding for Web Development. This hands-on 1-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to build professional web applications. Instead of memorising HTML, CSS and JavaScript details, you will vibe code &mdash; describing what you want in plain language and letting AI generate, refactor and debug your web code while you shape the design.</p>
<p>Through practical projects, participants will scaffold a web app, build responsive pages, add interactivity, connect to data, and deploy a working website &mdash; all with an AI pair programmer at their side. You will also learn to review, test and improve AI-generated code so your sites stay clean and fast. By the end of the course, you will be able to build and ship professional web apps faster with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Web</h3>
<ul>
<li>Introduction to Web Development and Vibe Coding</li>
<li>Setting Up AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Building Responsive Pages from Prompts</li>
<li>Effective Prompting for Web Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building and Deploying Web Apps with AI</h3>
<ul>
<li>Adding Interactivity and Components</li>
<li>Connecting to APIs and Data</li>
<li>Reviewing, Testing and Refactoring AI-Generated Code</li>
<li>Building and Deploying Your Website</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Web Development | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build modern websites and web apps with AI vibe coding. Master responsive pages, interactivity, APIs and deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Web Development, HTML, CSS, JavaScript, Cursor, GitHub Copilot, Claude, Responsive Design, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C603-20260711-103313.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-web-development') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
