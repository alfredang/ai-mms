-- Repurpose course C435 (entity_id 435) from "Augmented Reality (AR) Mobile App
-- Development" to "AI Vibe Coding for Augmented Reality (AR)" (1 day / 2 topics).
-- name, overview, topics, meta, duration 7.5h, cover, url_key, series badge.
-- Per-market price (350/1100/1500) and SG funding block applied direct on prod.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C435');
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
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Augmented Reality (AR)') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build augmented reality experiences with AI Vibe Coding for Augmented Reality (AR). This hands-on 1-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to build AR mobile apps. Instead of memorising SDK details, you will vibe code &mdash; describing the AR experience you want in plain language and letting AI generate, refactor and debug your AR code while you shape the interaction.</p>
<p>Through practical exercises, participants will set up an AR development environment, place and track virtual objects in the real world, add interaction and animation, and build a small AR application &mdash; all with an AI pair programmer at their side. You will also learn to review, test and improve AI-generated code so your AR apps run smoothly on real devices. By the end of the course, you will be able to build augmented reality experiences faster and more confidently with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for AR</h3>
<ul>
<li>Introduction to Augmented Reality and Vibe Coding</li>
<li>Setting Up an AR Development Environment and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Placing and Tracking Virtual Objects</li>
<li>Effective Prompting for AR Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building and Deploying AR Apps with AI</h3>
<ul>
<li>Adding Interaction and Animation</li>
<li>Working with Images, Faces and the Real World</li>
<li>Building an AR Application</li>
<li>Testing, Improving and Running Your Project</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Augmented Reality (AR) | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build augmented reality apps with AI vibe coding. Master AR object tracking, interaction and mobile AR using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Augmented Reality, AR, Mobile Apps, Cursor, GitHub Copilot, Claude, Object Tracking, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C435-20260711-094825.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-augmented-reality-ar') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
