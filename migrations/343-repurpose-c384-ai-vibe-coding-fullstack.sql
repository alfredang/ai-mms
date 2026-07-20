-- Repurpose course C384 (entity_id 384) from "Basic React.js Training" to
-- "AI Vibe Coding for Full Stack Development". Part of the non-WSQ AI Vibe
-- Coding series (2 days / 4 topics, 2 topics per day). Duration set to 15h
-- (2 days). Price ($700) is set in the shared price migration; funding block
-- and series badge are handled in their own migrations.
--
-- Scope: store_id 0 (single SG store). url_key intentionally unchanged so the
-- existing URL keeps resolving. Idempotent (INSERT ... ON DUPLICATE KEY UPDATE).
-- apply.php note: no content line ends in a semicolon.

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C384');

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
VALUES (4, @attr_name, 0, @entity_id, 'AI Vibe Coding for Full Stack Development')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description / overview
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_short_description, 0, @entity_id, '<p>Learn to build complete web applications end to end with AI Vibe Coding for Full Stack Development. This hands-on 2-day course shows you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to design, build and connect both the front end and the back end of a modern full stack application. Instead of writing every line by hand, you will vibe code &mdash; describing features in plain language and letting AI generate, refactor and debug your UI, API and database code while you direct the architecture.</p>
<p>Through practical projects, participants will scaffold a full stack app, build a responsive front end, create backend APIs, connect a database, and handle authentication and deployment &mdash; all with an AI pair programmer at their side. You will also learn to review, test and secure AI-generated code so your applications stay reliable and production ready. By the end of the course, you will be able to ship full stack web applications faster and more confidently by combining solid engineering fundamentals with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description / topics (4 topics, 2 per day)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_description, 0, @entity_id, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Full Stack</h3>
<ul>
<li>Introduction to Full Stack Development and Vibe Coding</li>
<li>Setting Up AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Scaffolding a Full Stack Project from a Prompt</li>
<li>Effective Prompting for Full Stack Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building the Front End with AI</h3>
<ul>
<li>Generating Responsive UI Components with AI</li>
<li>Managing State and Client-Side Routing</li>
<li>Consuming APIs from the Front End</li>
<li>Styling and Improving AI-Generated UI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Building the Back End and Database with AI</h3>
<ul>
<li>Creating Backend APIs with AI Assistance</li>
<li>Designing and Connecting a Database</li>
<li>Implementing Authentication and Authorization</li>
<li>Reviewing and Refactoring AI-Generated Server Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Testing, Securing and Deploying the Full Stack App</h3>
<ul>
<li>AI-Assisted Debugging and Error Fixing</li>
<li>Generating Tests for Front End and Back End</li>
<li>Securing and Optimising the Application</li>
<li>Building and Deploying the Full Stack App</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_title, 0, @entity_id, 'AI Vibe Coding for Full Stack Development | Tertiary Courses Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_description, 0, @entity_id, 'Build full stack web apps with AI vibe coding. Master the front end, backend APIs, databases, auth and deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_keyword, 0, @entity_id, 'AI Vibe Coding, Full Stack Development, Cursor, GitHub Copilot, Claude, Front End, Backend API, Database, Authentication, Deployment, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- duration (2 days = 15h)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_duration, 0, @entity_id, '15')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (new branded cover already uploaded to R2)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_course_image_url, 0, @entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C384-20260711-062530.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
