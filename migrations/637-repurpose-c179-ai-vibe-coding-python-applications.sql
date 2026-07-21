-- Repurpose course C179 from "Python Django Web Development Essential Training"
-- (disabled) to "AI Vibe Coding for Python Applications" and re-enable it as a
-- member of the AI Vibe Coding Series (2 days / 15h / $700 / 4 topics / badge).
--
-- Topics follow the WSQ "Build and Deploy Python Applications with Vibe Coding"
-- course (functional apps, OOP, database + error handling, Streamlit deploy),
-- condensed to 4 topics (2 per day) with no assessment (this is non-WSQ).
-- The Funding block points at that WSQ course (target verified HTTP 200).
--
-- url_key is intentionally NOT changed (keeps /python-django-web-development-training.html
-- resolving). All product statements key off the SKU so they no-op if C179 is
-- absent; the SG-only funding block is guarded by @mms_instance = 'SG'.
-- Idempotent (INSERT ... ON DUPLICATE KEY UPDATE / guarded INSERT + UPDATE).
-- apply.php note: no content line ends in a semicolon (the runner splits
-- statements on semicolon-at-EOL).

SET @attr_status            := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');
SET @attr_name              := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @attr_description       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @attr_meta_title        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @attr_meta_description  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @attr_meta_keyword      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @attr_duration          := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @attr_course_image_url  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @attr_price             := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @attr_series_badge      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_series_badge');

-- Re-enable: default scope row Enabled, and flip any per-store override too.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_status, 0, e.entity_id, 1
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 1
WHERE i.attribute_id = @attr_status AND e.sku = 'C179';

-- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_name, 0, e.entity_id, 'AI Vibe Coding for Python Applications'
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- overview (short_description)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_short_description, 0, e.entity_id, '<p>Take your Python skills from scripts to real applications with AI Vibe Coding for Python Applications. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to build, debug and deploy complete Python applications. Instead of hand-writing every line, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and fix Python code while you stay in control of the application design and logic.</p>
<p>Through practical exercises, participants will build functional Python applications, restructure them with object-oriented programming, integrate databases, handle errors gracefully, and deploy their finished apps on Streamlit &mdash; all with an AI pair programmer at their side. You will also learn to review, test and improve AI-generated code so your applications are correct, robust and maintainable. By the end of the course, you will be able to design, build and deploy useful Python applications faster with an effective AI vibe-coding workflow.</p>'
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- topics (description) — 4 topics, 2 per day.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_description, 0, e.entity_id, '<h3 class="course-topic-h3">Topic 1 Build Functional Python Apps with Vibe Coding</h3>
<ul>
<li>Introduction to AI Vibe Coding for Python Applications</li>
<li>Setting Up Python and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Generating Functions and Modules from Prompts</li>
<li>Structuring a Complete Functional Python Application</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Build OOP Python Apps with Vibe Coding</h3>
<ul>
<li>Classes, Objects and Methods with AI Assistance</li>
<li>Encapsulation, Inheritance and Polymorphism</li>
<li>Refactoring Functional Code into OOP Design</li>
<li>Reviewing and Explaining AI-Generated Classes</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Database Integration and Error Handling with Vibe Coding</h3>
<ul>
<li>Connecting Python Applications to SQLite Databases</li>
<li>Creating, Reading, Updating and Deleting Records with AI</li>
<li>Exception Handling and Input Validation</li>
<li>Debugging and Fixing Errors with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Deploy Python Apps on Streamlit</h3>
<ul>
<li>Building an Interactive Streamlit Web Interface</li>
<li>Connecting the App Logic to Streamlit Components</li>
<li>Testing and Improving Your App with AI</li>
<li>Deploying and Sharing Your App on Streamlit Cloud</li>
</ul>'
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- SEO meta
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_meta_title, 0, e.entity_id, 'AI Vibe Coding for Python Applications | Tertiary Courses Singapore'
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_meta_description, 0, e.entity_id, 'Build and deploy Python applications with AI vibe coding. Master functional and OOP apps, database integration, error handling and Streamlit deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course.'
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_meta_keyword, 0, e.entity_id, 'python applications, ai vibe coding, streamlit, oop python, cursor, github copilot, claude'
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- duration: 2 days = 15 hours
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_duration, 0, e.entity_id, '15'
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- branded cover on R2 (rendered from the new name)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_course_image_url, 0, e.entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C179-20260721-113314.png'
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- price: $700 (2 days @ $350/day) on every store-scoped row
UPDATE catalog_product_entity_decimal d
JOIN catalog_product_entity e ON e.entity_id = d.entity_id
SET d.value = 700.0000
WHERE d.attribute_id = @attr_price AND e.sku = 'C179';

-- series badge (red pill after the Course Code)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_series_badge, 0, e.entity_id, 'AI Vibe Coding Series'
FROM catalog_product_entity e WHERE e.sku = 'C179'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Funding block (SG only — SG WSQ funding copy must not appear on partner
-- sites). C179 has no course_C179_funding_and_grant block yet: create it,
-- map it to store 0, then set the content (UPDATE keeps re-runs idempotent).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C179 - Funding and Grant', 'course_C179_funding_and_grant', '', NOW(), NOW(), 1
FROM DUAL
WHERE @mms_instance = 'SG'
  AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C179_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
WHERE b.identifier = 'course_C179_funding_and_grant' AND @mms_instance = 'SG';

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-build-and-deploy-python-applications-with-vibe-coding.html" title="WSQ - Build and Deploy Python Applications with Vibe Coding">WSQ - Build and Deploy Python Applications with Vibe Coding</a></span></p>', update_time = NOW()
WHERE identifier = 'course_C179_funding_and_grant' AND @mms_instance = 'SG';
