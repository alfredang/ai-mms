-- Repurpose course C139 (entity_id 139) from "Android Apps Development with Java
-- Programming" to "AI Vibe Coding for Android Apps Development" (2 days / 4 topics).
-- name, overview, topics, meta, duration 15h, cover, url_key, series badge.
-- Per-market price (700/2200/3000) and SG funding block applied direct on prod.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C139');
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
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Android Apps Development') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build native Android mobile apps with AI Vibe Coding for Android Apps Development. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to build Android apps with Kotlin and Jetpack Compose. Instead of memorising framework details, you will vibe code &mdash; describing the screens and behaviour you want in plain language and letting AI generate, refactor and debug your Android code while you shape the user experience.</p>
<p>Through practical projects, participants will set up Android Studio and a Kotlin project, compose responsive screens with Jetpack Compose, manage state, navigate between screens, and connect to APIs and local storage &mdash; all with an AI pair programmer at their side. You will also learn to review, test and polish AI-generated code so your apps run smoothly on real devices. By the end of the course, you will be able to design, build and ship Android apps faster and more confidently by combining solid mobile fundamentals with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Android</h3>
<ul>
<li>Introduction to Android, Kotlin and Vibe Coding</li>
<li>Setting Up Android Studio and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Scaffolding an Android App from a Prompt</li>
<li>Effective Prompting for Android Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building Android UI with AI</h3>
<ul>
<li>Generating Jetpack Compose Screens and Layouts with AI</li>
<li>Composing and Reusing UI Components</li>
<li>Handling User Input and Events</li>
<li>Styling and Theming AI-Generated UI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 State, Navigation and Data with AI Assistance</h3>
<ul>
<li>Managing State in Compose</li>
<li>Navigating Between Screens</li>
<li>Fetching and Displaying API Data</li>
<li>Storing Data on the Device</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Testing, Building and Deploying Android Apps with AI</h3>
<ul>
<li>AI-Assisted Debugging and Error Fixing</li>
<li>Generating Tests for Your App</li>
<li>Optimising and Documenting Your Code</li>
<li>Building and Deploying to Google Play</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Android Apps Development | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build native Android apps with AI vibe coding. Master Kotlin, Jetpack Compose, navigation, state, APIs and Google Play deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Android, Kotlin, Jetpack Compose, Android Studio, Cursor, GitHub Copilot, Claude, Mobile Apps, Google Play, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C139-20260711-094718.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-android-apps-development') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
