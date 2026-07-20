-- Retitle course C384 (entity_id 384) from "AI Vibe Coding for Full Stack
-- Development" to "AI Vibe Coding for React Native". Updates name, overview
-- (short_description), the 4 topics (description), SEO meta and the branded
-- cover (rendered from the new name). Everything else stays as-is: price
-- (per-market: SG $700 / MY 2200 / GH 3000), duration (15h / 2 days), the
-- AI Vibe Coding Series badge, and the funding pointer.
--
-- Market-neutral content, so it applies to SG/MY/GH alike (same as the original
-- repurpose migration 343). Scope: store_id 0. Idempotent. No content line ends
-- in a semicolon (apply.php splits on semicolon-at-EOL).

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C384');

SET @attr_name             := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @attr_description       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @attr_meta_title        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @attr_meta_description  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @attr_meta_keyword      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @attr_course_image_url  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

-- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_name, 0, @entity_id, 'AI Vibe Coding for React Native')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description / overview
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_short_description, 0, @entity_id, '<p>Build cross-platform mobile apps with AI Vibe Coding for React Native. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to design and build React Native apps for both Android and iOS. Instead of memorising component and navigation boilerplate, you will vibe code &mdash; describing the screens and behaviour you want in plain language and letting AI generate, refactor and debug your React Native code while you shape the user experience.</p>
<p>Through practical projects, participants will scaffold a React Native app, compose responsive screens with reusable components, manage state, navigate between screens, and connect to APIs and device storage &mdash; all with an AI pair programmer at their side. You will also learn to review, test and polish AI-generated code so your apps run smoothly on real devices. By the end of the course, you will be able to design, build and ship cross-platform React Native apps faster and more confidently by combining solid mobile fundamentals with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description / topics (4 topics, 2 per day)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_description, 0, @entity_id, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for React Native</h3>
<ul>
<li>Introduction to React Native and Vibe Coding</li>
<li>Setting Up React Native and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Scaffolding a React Native App from a Prompt</li>
<li>Effective Prompting for React Native Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building React Native UI with AI</h3>
<ul>
<li>Generating Screens and Components with AI</li>
<li>Styling with Flexbox and Reusable Components</li>
<li>Handling User Input and Events</li>
<li>Working with Lists and Images</li>
</ul>
<h3 class="course-topic-h3">Topic 3 State, Navigation and Data with AI Assistance</h3>
<ul>
<li>Managing State with Hooks</li>
<li>Navigating Between Screens with React Navigation</li>
<li>Fetching and Displaying API Data</li>
<li>Storing Data on the Device</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Testing, Building and Deploying React Native Apps with AI</h3>
<ul>
<li>AI-Assisted Debugging and Error Fixing</li>
<li>Generating Tests for Your Components</li>
<li>Optimising and Documenting Your Code</li>
<li>Building and Deploying for Android and iOS</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_title, 0, @entity_id, 'AI Vibe Coding for React Native | Tertiary Courses Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_description, 0, @entity_id, 'Build cross-platform React Native mobile apps with AI vibe coding. Master components, navigation, state, APIs and deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_keyword, 0, @entity_id, 'AI Vibe Coding, React Native, Cursor, GitHub Copilot, Claude, Components, React Navigation, State Management, Mobile Apps, Android, iOS, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (new branded cover already uploaded to R2)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_course_image_url, 0, @entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C384-20260711-085739.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
