-- Rename course C879 from "AI Vibe Coding for iOS Mobile Apps Development" to
-- "AI Vibe Coding for Quick iOS Mobile Apps Deployment" and realign the
-- overview, topics, meta and cover image to the deployment emphasis.
-- Already in the AI Vibe Coding Series: price ($700), duration (15) and badge
-- unchanged (enforced by shared migrations 347 / 342). url_key intentionally
-- UNCHANGED (series rule — preserves URL + SEO).
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C879.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C879');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI Vibe Coding for Quick iOS Mobile Apps Deployment' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Go from idea to a live App Store submission fast with AI Vibe Coding for Quick iOS Mobile Apps Deployment. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to rapidly build and ship iPhone and iPad apps in Swift and SwiftUI. Instead of memorising framework details, you will vibe code &mdash; describing the screens and behaviour you want in plain language and letting AI generate, refactor and debug your Swift code while you focus on getting a polished app out the door.</p>
<p>Through practical projects, participants will set up Xcode and a Swift project, compose responsive SwiftUI screens with reusable views, manage state, navigate between screens, and connect to APIs and local storage &mdash; all with an AI pair programmer at their side. You will then take the app all the way to release: AI-assisted debugging and testing, app icons and signing, beta distribution with TestFlight, and submitting to the App Store for review. By the end of the course, you will have a repeatable AI vibe-coding workflow for building and deploying iOS apps quickly and confidently.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for iOS</h3>
<ul>
<li>Introduction to Swift, SwiftUI and Vibe Coding</li>
<li>Setting Up Xcode and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Scaffolding an iOS App from a Prompt</li>
<li>Effective Prompting for Swift Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Rapidly Building iOS UI with AI</h3>
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
<h3 class="course-topic-h3">Topic 4 Quick Deployment to the App Store</h3>
<ul>
<li>AI-Assisted Debugging and Testing</li>
<li>App Icons, Launch Screen and Code Signing</li>
<li>Distributing Beta Builds with TestFlight</li>
<li>Submitting to the App Store for Review</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI Vibe Coding for Quick iOS Mobile Apps Deployment' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Quickly build and deploy native iOS apps with AI vibe coding. Master Swift, SwiftUI, state, APIs, TestFlight and App Store submission using Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI Vibe Coding, iOS App Development, iOS Deployment, SwiftUI, Xcode, Cursor, GitHub Copilot, Claude, TestFlight, App Store, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C879-20260717-083131.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_img);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
