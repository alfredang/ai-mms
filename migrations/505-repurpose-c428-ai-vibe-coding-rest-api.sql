-- Repurpose course C428 from "Hands-On REST API Development with FastAPI"
-- to "AI Vibe Coding for REST API". Joins the AI Vibe Coding Series:
-- 2 days / 15h, $700, 4 topics (2 per day), series badge, fresh cover,
-- funding block pointing at WSQ - Build Modern RESTFUL API Applications
-- with AI Assisted Programming (the WSQ FastAPI twin, current URL).
-- url_key intentionally UNCHANGED (hands-on-rest-api-development-with-fastapi).
-- Badge + price statements are self-contained here (migrations 342/347 are
-- already applied on prod and edited files never re-run there).
-- Clears per-store overrides so partner scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C428.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C428');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_cimg  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_stat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
SET @a_price := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='price');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI Vibe Coding for REST API' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Build production-grade REST APIs with FastAPI by directing AI coding assistants instead of typing every line yourself. This hands-on 2-day course teaches you how to use AI vibe coding tools such as Cursor, GitHub Copilot and Claude to scaffold a FastAPI project, design clean endpoints with path and query parameters, model request and response data with Pydantic, and wire up full CRUD operations — all by describing what you want in plain English and reviewing what the AI produces.</p>
<p>Through practical projects, participants will drive an AI assistant through the complete API development workflow: connecting a database, securing endpoints with JWT authentication, generating interactive API documentation, and testing every route before release. Crucially, you will build the verify-then-trust habit — auditing every AI-generated endpoint, query and auth flow before relying on it. By the end of the course, you will be able to ship secure, well-documented REST APIs faster with AI assistance while staying firmly in control of quality.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 AI Vibe Coding Workflow and FastAPI Project Setup</h3>
<ul>
<li>Introduction to AI Vibe Coding for API Development</li>
<li>Setting Up Cursor, GitHub Copilot and Claude</li>
<li>Prompting Patterns for Backend Tasks</li>
<li>Scaffolding a FastAPI Project and First Endpoint</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Designing REST Endpoints and Data Models with AI</h3>
<ul>
<li>Path and Query Parameters</li>
<li>Request Bodies and Pydantic Models</li>
<li>Building Full CRUD Operations with AI Assistance</li>
<li>Reviewing and Validating AI-Generated Endpoints</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Database Integration and Authentication with Vibe Coding</h3>
<ul>
<li>Connecting FastAPI to a Database</li>
<li>Persisting CRUD Operations with an ORM</li>
<li>Securing Endpoints with JWT Authentication</li>
<li>Auditing AI-Generated Queries and Auth Flows</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Testing, Documenting and Shipping Your API</h3>
<ul>
<li>Generating Interactive API Documentation</li>
<li>Testing Endpoints with AI-Written Tests</li>
<li>Error Handling and API Hardening</li>
<li>Verify-Then-Trust: Auditing AI-Generated API Code</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI Vibe Coding for REST API' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Use AI vibe coding assistants like Cursor, GitHub Copilot and Claude to build FastAPI REST APIs with Pydantic models, CRUD operations, database integration and JWT authentication in this hands-on 2-day course.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI Vibe Coding, REST API, FastAPI, Python, Pydantic, CRUD, JWT Authentication, Cursor, GitHub Copilot, Claude, API Development, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- 2 days / 15 hours (series standard)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '15' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Fresh cover rendered 2026-07-18 from the new title (no funding badges)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cimg, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C428-20260717-171339.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI Vibe Coding for REST API' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI Vibe Coding for REST API' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI Vibe Coding for REST API' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Series badge (attribute created by migration 342; guarded if absent)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_badge, 0, @e, 'AI Vibe Coding Series' FROM DUAL WHERE @e IS NOT NULL AND @a_badge IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Keep the course ENABLED (status 1 at store 0)
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_stat, 0, @e, 1 FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Price $700 (2 days @ $350/day) at every store scope
UPDATE catalog_product_entity_decimal
SET value = 700.0000
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_price;

-- Clear per-store overrides so no scope shadows the new store-0 values
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_cimg, @a_il, @a_sil, @a_til, @a_dur, @a_badge);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
DELETE FROM catalog_product_entity_int
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id=@a_stat;

-- Funding block: point at the WSQ FastAPI twin (current URL, old one 301s)
UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-build-modern-restful-api-applications-with-ai-assisted-programming.html" title="WSQ - Build Modern RESTFUL API Applications with AI Assisted Programming">WSQ - Build Modern RESTFUL API Applications with AI Assisted Programming</a></span></p>'
WHERE identifier = 'course_C428_funding_and_grant';
