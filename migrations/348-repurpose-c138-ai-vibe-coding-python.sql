-- Repurpose course C138 (entity_id 138) from "Python 3 Essential Training" to
-- "AI Vibe Coding with Python" (capitalised "AI" to match the series brand).
-- Part of the non-WSQ AI Vibe Coding series (2 days / 4 topics, 2 per day).
-- Already 15h / 2 days; price ($700) is set in the shared price migration,
-- funding block + series badge handled elsewhere.
--
-- Scope: store_id 0 (single SG store). url_key unchanged. Idempotent.
-- No content line ends in a semicolon (apply.php splits on semicolon-at-EOL).

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C138');

SET @attr_name             := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @attr_description       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @attr_meta_title        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @attr_meta_description  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @attr_meta_keyword      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @attr_duration          := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @attr_course_image_url  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

-- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_name, 0, @entity_id, 'AI Vibe Coding with Python')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description / overview
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_short_description, 0, @entity_id, '<p>Learn to build real Python programs with AI Vibe Coding with Python. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, run and debug Python code. Instead of memorising syntax, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and fix Python code while you learn the fundamentals and stay in control of the logic.</p>
<p>Through practical exercises, participants will set up a Python environment, work with variables, data structures, functions and files, automate everyday tasks, and build a small data-driven application &mdash; all with an AI pair programmer at their side. You will also learn to read, test and improve AI-generated code so your programs are correct and maintainable. By the end of the course, you will be able to write and understand Python confidently and use an effective AI vibe-coding workflow to build useful scripts and applications faster.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description / topics (4 topics, 2 per day)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_description, 0, @entity_id, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding in Python</h3>
<ul>
<li>Introduction to Python and Vibe Coding</li>
<li>Setting Up Python and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Writing and Running Your First Python Program from a Prompt</li>
<li>Effective Prompting for Python Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Python Fundamentals with AI</h3>
<ul>
<li>Variables, Data Types and Operators</li>
<li>Control Flow: Conditionals and Loops</li>
<li>Functions and Modules</li>
<li>Debugging and Explaining Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Working with Data and Files</h3>
<ul>
<li>Lists, Dictionaries and Data Structures</li>
<li>Reading and Writing Files</li>
<li>Working with Libraries and APIs</li>
<li>Reviewing and Refactoring AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building and Automating with Python</h3>
<ul>
<li>Automating Everyday Tasks with Scripts</li>
<li>Building a Small Data-Driven Application</li>
<li>Testing and Improving Your Code with AI</li>
<li>Packaging and Running Your Project</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_title, 0, @entity_id, 'AI Vibe Coding with Python | Tertiary Courses Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_description, 0, @entity_id, 'Learn Python with AI vibe coding. Master Python fundamentals, data structures, files, automation and small apps using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_keyword, 0, @entity_id, 'AI Vibe Coding, Python, Cursor, GitHub Copilot, Claude, Python Fundamentals, Data Structures, Automation, Scripting, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- duration (2 days = 15h)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_duration, 0, @entity_id, '15')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (new branded cover already uploaded to R2)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_course_image_url, 0, @entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C138-20260711-063032.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
