-- Repurpose course C28 (entity_id 28) from "PHP Essential Training" to
-- "AI Vibe Coding for PHP and MySQL" (2 days / 4 topics, 2 per day). Sets name,
-- overview, topics, meta, duration (15h), cover, url_key and the AI Vibe Coding
-- Series badge. Per-market price (SG 700 / MY 2200 / GH 3000) and the SG-only
-- funding block are applied direct on each prod DB. Store scope 0. Idempotent.
-- No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C28');
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
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for PHP and MySQL') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build database-driven web applications with AI Vibe Coding for PHP and MySQL. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write PHP and design MySQL databases. Instead of memorising syntax and SQL, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and debug your PHP and SQL while you learn the fundamentals and stay in control of the logic.</p>
<p>Through practical projects, participants will set up a PHP and MySQL environment, work with variables, control flow and functions, build and query MySQL databases, handle forms and sessions, and create a small database-driven web application &mdash; all with an AI pair programmer at their side. You will also learn to review, test and secure AI-generated code so your applications stay reliable and safe. By the end of the course, you will be able to build PHP and MySQL applications faster and more confidently with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for PHP</h3>
<ul>
<li>Introduction to PHP, MySQL and Vibe Coding</li>
<li>Setting Up PHP, MySQL and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Writing Your First PHP Script from a Prompt</li>
<li>Effective Prompting for PHP Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 PHP Fundamentals with AI</h3>
<ul>
<li>Variables, Data Types and Operators</li>
<li>Control Flow, Loops and Functions</li>
<li>Working with Forms and User Input</li>
<li>Debugging and Explaining Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Databases with MySQL and AI</h3>
<ul>
<li>Designing a MySQL Database</li>
<li>Writing SQL Queries with AI Assistance</li>
<li>Connecting PHP to MySQL</li>
<li>Reviewing and Refactoring AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building and Securing a Web App with AI</h3>
<ul>
<li>Sessions, Authentication and Security</li>
<li>Building a Database-Driven Web Application</li>
<li>Testing and Improving Your Code with AI</li>
<li>Deploying Your PHP and MySQL App</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for PHP and MySQL | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build database-driven web apps with AI vibe coding. Master PHP, MySQL, forms, sessions, security and deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, PHP, MySQL, Cursor, GitHub Copilot, Claude, SQL, Web Development, Databases, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C28-20260711-092925.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-php-and-mysql') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
