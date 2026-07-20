-- Repurpose course C1800 (entity_id 1800) from "Vibe Coding for Full Stack Web
-- Development" to "AI Vibe Coding for Full Stack Web Development". Part of the
-- non-WSQ AI Vibe Coding series. Already 2 days / 15h / $700 / 4 topics, so
-- this refreshes name, overview, topics, meta and the cover image only (price
-- and duration unchanged). Funding block + series badge handled elsewhere.
--
-- Scope: store_id 0 (single SG store). url_key unchanged. Idempotent.
-- No content line ends in a semicolon (apply.php splits on semicolon-at-EOL).

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1800');

SET @attr_name             := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @attr_description       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @attr_meta_title        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @attr_meta_description  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @attr_meta_keyword      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @attr_course_image_url  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

-- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_name, 0, @entity_id, 'AI Vibe Coding for Full Stack Web Development')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description / overview
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_short_description, 0, @entity_id, '<p>Go from idea to deployed web app with AI Vibe Coding for Full Stack Web Development. This hands-on 2-day course teaches you how to build modern, database-backed web applications using AI coding assistants such as Cursor, GitHub Copilot and Claude. Rather than hand-writing every layer, you will vibe code &mdash; describing the pages, APIs and data models you need in plain language and letting AI generate, refactor and debug the code while you direct the design and architecture.</p>
<p>Through practical projects, participants will scaffold a full stack web app, build a responsive user interface, create RESTful APIs, model and connect a database, and add authentication before deploying to the web &mdash; all with an AI pair programmer at their side. You will also learn to review, test and secure AI-generated code so your web apps stay fast, reliable and production ready. By the end of the course, you will be able to design, build and ship full stack web applications faster and more confidently with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description / topics (4 topics, 2 per day)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_description, 0, @entity_id, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Web</h3>
<ul>
<li>Introduction to Full Stack Web Development and Vibe Coding</li>
<li>Setting Up AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Scaffolding a Web App from a Prompt</li>
<li>Effective Prompting for Full Stack Web Code</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building the Web Front End with AI</h3>
<ul>
<li>Generating Responsive Pages and Components with AI</li>
<li>Managing State and Client-Side Routing</li>
<li>Consuming APIs from the Browser</li>
<li>Styling and Improving AI-Generated UI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Building APIs and Database with AI</h3>
<ul>
<li>Creating RESTful APIs with AI Assistance</li>
<li>Modelling and Connecting a Database</li>
<li>Adding Authentication and Sessions</li>
<li>Reviewing and Refactoring AI-Generated Server Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Testing, Securing and Deploying the Web App</h3>
<ul>
<li>AI-Assisted Debugging and Error Fixing</li>
<li>Generating Tests for the Full Stack</li>
<li>Securing and Optimising the Web App</li>
<li>Building and Deploying to Production</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_title, 0, @entity_id, 'AI Vibe Coding for Full Stack Web Development | Tertiary Courses Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_description, 0, @entity_id, 'Build database-backed full stack web apps with AI vibe coding. Master responsive UI, REST APIs, databases, auth and deployment using AI assistants like Cursor, GitHub Copilot and Claude in this 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_keyword, 0, @entity_id, 'AI Vibe Coding, Full Stack Web Development, Cursor, GitHub Copilot, Claude, REST API, Database, Authentication, Responsive UI, Deployment, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (new branded cover already uploaded to R2)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_course_image_url, 0, @entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1800-20260711-062530.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
