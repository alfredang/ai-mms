-- Rename course C485 from "Master Google Analytics 4 (GA4) to Turn Insights into
-- Actions and Results" to "AI Vibe Coding for Geofencing" (2 days / 4 topics).
-- Part of the AI Vibe Coding series (badge). name, overview, topics, meta, cover,
-- url_key, badge. Price and duration unchanged (600 SG / 15h). Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C485');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Geofencing') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build location-aware apps with AI Vibe Coding for Geofencing. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to build maps, location tracking and geofencing features into web and mobile apps. Instead of memorising mapping SDKs and location APIs, you will vibe code &mdash; describing what you want in plain language and letting AI generate, refactor and debug your geolocation code while you design the experience.</p>
<p>Through practical projects, participants will set up a mapping and location environment, display maps and markers, track user location in real time, define geofences and trigger enter/exit events, and build and deploy a working geofencing app &mdash; all with an AI pair programmer at their side. You will also learn to review, test and secure AI-generated location code and handle privacy and permissions correctly. By the end of the course, you will be able to build and ship geofencing and location-based apps faster with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Geofencing</h3>
<ul>
<li>Introduction to Geolocation, Geofencing and Vibe Coding</li>
<li>Setting Up AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Setting Up Maps and Location APIs</li>
<li>Effective Prompting for Location and Mapping Code</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building Maps and Location Features with AI</h3>
<ul>
<li>Displaying Maps, Markers and Layers</li>
<li>Getting and Tracking User Location in Real Time</li>
<li>Working with Coordinates, Distance and Places</li>
<li>Debugging and Explaining Location Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Geofencing Logic and Real-Time Events with AI</h3>
<ul>
<li>Defining Geofences and Boundaries</li>
<li>Detecting Enter, Exit and Dwell Events</li>
<li>Triggering Notifications and Actions</li>
<li>Handling Permissions, Privacy and Battery Efficiency</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building and Deploying a Geofencing App with AI</h3>
<ul>
<li>Assembling a Complete Geofencing App</li>
<li>Connecting to Backends and Storing Location Data</li>
<li>Reviewing, Testing and Securing AI-Generated Code</li>
<li>Building and Deploying Your Geofencing App</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Geofencing') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build geofencing and location-based apps with AI vibe coding. Create maps, real-time tracking and geofence events using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Geofencing, Geolocation, Maps, Location Based Apps, GPS, Cursor, GitHub Copilot, Claude, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C485-20260712-033508.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-geofencing') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
