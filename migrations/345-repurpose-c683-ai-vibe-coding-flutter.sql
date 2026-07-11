-- Repurpose course C683 (entity_id 683) from "Basic React Native Training" to
-- "AI Vibe Coding for Flutter Development" (typo "Developent" corrected to
-- "Development" per admin confirmation). Part of the non-WSQ AI Vibe Coding
-- series (2 days / 4 topics, 2 topics per day). Duration set to 15h (2 days).
-- Price ($700) is set in the shared price migration; funding block and series
-- badge are handled in their own migrations.
--
-- Scope: store_id 0 (single SG store). url_key intentionally unchanged.
-- Idempotent (INSERT ... ON DUPLICATE KEY UPDATE). No content line ends in a
-- semicolon (apply.php splits on semicolon-at-EOL).

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C683');

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
VALUES (4, @attr_name, 0, @entity_id, 'AI Vibe Coding for Flutter Development')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description / overview
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_short_description, 0, @entity_id, '<p>Build beautiful cross-platform mobile apps with AI Vibe Coding for Flutter Development. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to design and build Flutter apps in Dart for both Android and iOS. Instead of memorising widget boilerplate, you will vibe code &mdash; describing the screens and behaviour you want in plain language and letting AI generate, refactor and debug your Flutter code while you shape the user experience.</p>
<p>Through practical projects, participants will scaffold a Flutter app, compose responsive widget layouts, manage state, navigate between screens, and connect to APIs and local storage &mdash; all with an AI pair programmer at their side. You will also learn to review, test and polish AI-generated code so your apps run smoothly on real devices. By the end of the course, you will be able to design, build and ship cross-platform Flutter apps faster and more confidently by combining solid mobile fundamentals with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description / topics (4 topics, 2 per day)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_description, 0, @entity_id, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Flutter</h3>
<ul>
<li>Introduction to Flutter, Dart and Vibe Coding</li>
<li>Setting Up Flutter and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Scaffolding a Flutter App from a Prompt</li>
<li>Effective Prompting for Flutter Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building Flutter UI with AI</h3>
<ul>
<li>Generating Widgets and Responsive Layouts with AI</li>
<li>Composing and Reusing Widgets</li>
<li>Handling User Input and Events</li>
<li>Styling and Theming AI-Generated UI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 State, Navigation and Data with AI Assistance</h3>
<ul>
<li>Managing State in Flutter</li>
<li>Navigating Between Screens and Routes</li>
<li>Fetching and Displaying API Data</li>
<li>Storing Data Locally</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Testing, Building and Deploying Flutter Apps with AI</h3>
<ul>
<li>AI-Assisted Debugging and Error Fixing</li>
<li>Generating Widget and Unit Tests</li>
<li>Optimising and Documenting Your Code</li>
<li>Building and Deploying for Android and iOS</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_title, 0, @entity_id, 'AI Vibe Coding for Flutter Development | Tertiary Courses Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_description, 0, @entity_id, 'Build cross-platform Flutter mobile apps with AI vibe coding. Master Dart, widgets, state, navigation and deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_keyword, 0, @entity_id, 'AI Vibe Coding, Flutter Development, Dart, Cursor, GitHub Copilot, Claude, Widgets, State Management, Mobile Apps, Android, iOS, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- duration (2 days = 15h)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_duration, 0, @entity_id, '15')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (new branded cover already uploaded to R2)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_course_image_url, 0, @entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C683-20260711-062530.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
