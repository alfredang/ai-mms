-- Repurpose course C141 from "iOS App Development with Swift Essential
-- Training" to "AI Vibe Coding for iOS Ecommerce App" (AI Vibe Coding Series:
-- 2 days / 15h / 4 topics). name, overview, topics, meta, cover image.
-- Price ($700) and duration (15) already correct; also enforced by the shared
-- series migration 347. url_key intentionally UNCHANGED (series rule —
-- preserves URL + SEO). Badge added via shared migration 342.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C141.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C141');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI Vibe Coding for iOS Ecommerce App' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Build and ship a complete iOS ecommerce app without writing every line of Swift yourself. In this hands-on 2-day course you will use AI coding assistants&mdash;Cursor, GitHub Copilot and Claude&mdash;to vibe code a native SwiftUI shopping app in Xcode: describe what you want in plain English, let the AI generate the SwiftUI views, models and logic, then review, refine and iterate with follow-up prompts. You will learn the prompting patterns that keep AI-generated Swift code clean, idiomatic and easy to extend.</p>
<p>Over four practical topics you will scaffold the app and design its product catalog, wire up product detail pages with search and filtering, implement a shopping cart and Stripe-powered checkout, and finish with user accounts, order history, AI-assisted testing and debugging, and preparing the app for App Store submission. By the end of the course, you will have a working iOS ecommerce app on the simulator and a repeatable AI vibe coding workflow you can apply to any iOS project.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for iOS</h3>
<ul>
<li>What Is AI Vibe Coding</li>
<li>Setting Up Xcode, Cursor, GitHub Copilot and Claude</li>
<li>SwiftUI Essentials for AI-Assisted Development</li>
<li>Scaffolding the Ecommerce App from a Prompt</li>
<li>Prompting Patterns for Clean Swift Code</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building the Product Catalog</h3>
<ul>
<li>Designing Product Data Models with AI</li>
<li>Generating the Product Grid and List Views</li>
<li>Product Detail Pages with Images and Pricing</li>
<li>Search, Filtering and Categories</li>
<li>Iterating on UI with Follow-Up Prompts</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Shopping Cart and Checkout</h3>
<ul>
<li>Cart State Management in SwiftUI</li>
<li>Add to Cart, Quantities and Cart Badge</li>
<li>Building the Checkout Flow</li>
<li>Integrating Stripe Payments with AI Assistance</li>
<li>Order Confirmation and Error Handling</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Accounts, Testing and App Store Release</h3>
<ul>
<li>User Sign-In and Sign in with Apple</li>
<li>Order History and User Profile</li>
<li>AI-Assisted Debugging and Unit Testing</li>
<li>Polishing the App with App Icons and Launch Screen</li>
<li>Preparing for App Store Submission</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI Vibe Coding for iOS Ecommerce App' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Vibe code a native iOS ecommerce app with SwiftUI, Cursor, GitHub Copilot and Claude in this hands-on 2-day course. Build product catalog, cart, Stripe checkout and ship to the App Store.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI Vibe Coding, iOS App Development, SwiftUI, Xcode, Cursor, GitHub Copilot, Claude, Ecommerce App, Shopping Cart, Stripe Payments, App Store, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C141-20260717-082653.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_img);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
