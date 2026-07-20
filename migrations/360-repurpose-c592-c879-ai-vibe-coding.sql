-- Repurpose two more courses into the AI Vibe Coding series:
--   C592  AI Vibe Coding for Computer Vision          (1 day / 2 topics; was Python OpenCV)
--   C879  AI Vibe Coding for iOS Mobile Apps Development (2 days / 4 topics; was Full Swift)
-- Each: name, overview, topics, meta, duration, cover, url_key, series badge.
-- Per-market price (C592 350/1100/1500; C879 700/2200/3000) and SG-only funding
-- blocks are applied direct on each prod DB. Store scope 0. Idempotent.
-- No content line ends in a semicolon.

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

-- =========================================================================
-- C592 - AI Vibe Coding for Computer Vision (1 day / 2 topics)
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C592');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Computer Vision') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build computer vision applications with AI Vibe Coding for Computer Vision. This hands-on 1-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write Python computer vision code with libraries like OpenCV. Instead of memorising APIs, you will vibe code &mdash; describing what you want in plain language and letting AI generate, explain, refactor and debug your vision code while you learn the fundamentals and stay in control of the logic.</p>
<p>Through practical exercises, participants will set up a Python computer vision environment, load and process images and video, detect edges, shapes, faces and objects, and build a small vision-powered application &mdash; all with an AI pair programmer at their side. You will also learn to review, test and improve AI-generated code so your applications are correct and reliable. By the end of the course, you will be able to build computer vision solutions faster and more confidently with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started and Image Processing with AI Vibe Coding</h3>
<ul>
<li>Introduction to Computer Vision, OpenCV and Vibe Coding</li>
<li>Setting Up Python, OpenCV and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Loading, Displaying and Transforming Images</li>
<li>Filtering, Edges and Contours with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Detection and Building Vision Apps with AI</h3>
<ul>
<li>Detecting Shapes, Faces and Objects</li>
<li>Working with Video Streams</li>
<li>Building a Computer Vision Application</li>
<li>Testing, Improving and Running Your Project</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Computer Vision | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build computer vision apps with AI vibe coding. Master image processing, edge and object detection and video using OpenCV and AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Computer Vision, OpenCV, Python, Cursor, GitHub Copilot, Claude, Image Processing, Object Detection, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C592-20260711-093116.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-computer-vision') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- =========================================================================
-- C879 - AI Vibe Coding for iOS Mobile Apps Development (2 days / 4 topics)
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C879');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for iOS Mobile Apps Development') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build native iOS mobile apps with AI Vibe Coding for iOS Mobile Apps Development. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to build iPhone and iPad apps in Swift and SwiftUI. Instead of memorising framework details, you will vibe code &mdash; describing the screens and behaviour you want in plain language and letting AI generate, refactor and debug your Swift code while you shape the user experience.</p>
<p>Through practical projects, participants will set up Xcode and a Swift project, compose responsive SwiftUI screens with reusable views, manage state, navigate between screens, and connect to APIs and local storage &mdash; all with an AI pair programmer at their side. You will also learn to review, test and polish AI-generated code so your apps run smoothly on real devices. By the end of the course, you will be able to design, build and ship iOS apps faster and more confidently by combining solid mobile fundamentals with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for iOS</h3>
<ul>
<li>Introduction to Swift, SwiftUI and Vibe Coding</li>
<li>Setting Up Xcode and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Scaffolding an iOS App from a Prompt</li>
<li>Effective Prompting for Swift Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building iOS UI with AI</h3>
<ul>
<li>Generating SwiftUI Views and Layouts with AI</li>
<li>Composing and Reusing Views</li>
<li>Handling User Input and Events</li>
<li>Styling and Theming AI-Generated UI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 State, Navigation and Data with AI Assistance</h3>
<ul>
<li>Managing State in SwiftUI</li>
<li>Navigating Between Screens</li>
<li>Fetching and Displaying API Data</li>
<li>Storing Data on the Device</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Testing, Building and Deploying iOS Apps with AI</h3>
<ul>
<li>AI-Assisted Debugging and Error Fixing</li>
<li>Generating Tests for Your Views</li>
<li>Optimising and Documenting Your Code</li>
<li>Building and Deploying to the App Store</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for iOS Mobile Apps Development | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build native iOS apps with AI vibe coding. Master Swift, SwiftUI, navigation, state, APIs and App Store deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, iOS, Swift, SwiftUI, Xcode, Cursor, GitHub Copilot, Claude, Mobile Apps, App Store, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C879-20260711-093409.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-ios-mobile-apps-development') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
