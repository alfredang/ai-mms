-- Repurpose course C169 (entity_id 169) from "C Programming Essential Training"
-- to "AI Vibe Coding with C". Part of the non-WSQ AI Vibe Coding series
-- (2 days / 4 topics, 2 per day). Sets name, overview, topics, meta,
-- duration (15h), the branded cover, the url_key (matching the new title) and
-- the AI Vibe Coding Series badge.
--
-- Per-market PRICE (SG 700 / MY 2200 / GH 3000) and the SG-only funding block
-- are applied directly on each prod DB, NOT here (a shared price/funding
-- migration would misprice partners / leak SG funding — see memory
-- sku-migrations-hit-partners-irreversibly).
--
-- The url_key lands before the post-deploy catalog_url reindex, which writes
-- the 301 from the old slug (c-programming-training). Store scope 0. Idempotent.
-- No content line ends in a semicolon.

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C169');

SET @attr_name             := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @attr_description       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @attr_meta_title        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @attr_meta_description  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @attr_meta_keyword      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @attr_duration          := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @attr_course_image_url  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @attr_url_key           := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @attr_series_badge      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');

-- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_name, 0, @entity_id, 'AI Vibe Coding with C')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description / overview
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_short_description, 0, @entity_id, '<p>Learn to write real C programs with AI Vibe Coding with C. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, compile and debug C code. Instead of getting stuck on syntax and pointers, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and fix C code while you learn the fundamentals and stay in control of the logic.</p>
<p>Through practical exercises, participants will set up a C toolchain, work with variables, control flow, functions, arrays, pointers and structs, manage memory, and build a small command-line program &mdash; all with an AI pair programmer at their side. You will also learn to read, test and improve AI-generated code so your programs are correct and reliable. By the end of the course, you will be able to write and understand C confidently and use an effective AI vibe-coding workflow to build efficient programs faster.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description / topics (4 topics, 2 per day)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_description, 0, @entity_id, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding in C</h3>
<ul>
<li>Introduction to C and Vibe Coding</li>
<li>Setting Up a C Compiler and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Writing and Compiling Your First C Program from a Prompt</li>
<li>Effective Prompting for C Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 C Fundamentals with AI</h3>
<ul>
<li>Variables, Data Types and Operators</li>
<li>Control Flow: Conditionals and Loops</li>
<li>Functions and Program Structure</li>
<li>Debugging and Explaining Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Working with Data, Pointers and Memory</h3>
<ul>
<li>Arrays and Strings</li>
<li>Pointers and Memory Management</li>
<li>Structs and Data Organisation</li>
<li>Reviewing and Refactoring AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building and Testing C Programs with AI</h3>
<ul>
<li>Reading and Writing Files</li>
<li>Building a Command-Line Application</li>
<li>Testing and Improving Your Code with AI</li>
<li>Compiling, Optimising and Running Your Project</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_title, 0, @entity_id, 'AI Vibe Coding with C | Tertiary Courses Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_description, 0, @entity_id, 'Learn C programming with AI vibe coding. Master variables, control flow, functions, pointers, memory and files using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_keyword, 0, @entity_id, 'AI Vibe Coding, C Programming, Cursor, GitHub Copilot, Claude, Pointers, Memory Management, Functions, Arrays, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- duration (2 days = 15h)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_duration, 0, @entity_id, '15')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (new branded cover already uploaded to R2)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_course_image_url, 0, @entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C169-20260711-091957.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- url_key (matches the new title)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_url_key, 0, @entity_id, 'ai-vibe-coding-with-c')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- AI Vibe Coding Series badge
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_series_badge, 0, @entity_id, 'AI Vibe Coding Series')
ON DUPLICATE KEY UPDATE value = VALUES(value);
