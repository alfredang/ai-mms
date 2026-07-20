-- Repurpose course C803 from "Creating Business Applications with Microsoft
-- Power Apps and Power Automate" to "Copilot for Power Apps" (name, overview,
-- curriculum, meta, url_key, image labels, media-gallery label, cover).
-- Price ($350) and 1-day duration (7.5) are intentionally kept.
-- Cover re-rendered 2026-07-18 with the new title (no funding chips) and
-- uploaded to R2.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates the new URL (old URL 301s).
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C803.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C803');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Copilot for Power Apps' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Build business applications faster with AI in this hands-on 1-day Copilot for Power Apps course. Copilot, Microsoft&rsquo;s AI assistant built into the Power Platform, lets you create a working canvas app from a plain-English prompt, design screens and data tables conversationally, and generate Power Fx formulas without memorising syntax. You will start by enabling Copilot in Power Apps Studio, then learn the prompting techniques that turn a business requirement into a functional, well-structured app.</p>
<p>The course then goes deeper into AI-assisted app development: refining screens, controls and data with Copilot, adding an in-app Copilot chat experience for your users, and using Copilot in Power Automate to build the approval and notification flows that power your app. By the end of the course, you will be able to combine Copilot with core Power Apps skills to deliver business applications in a fraction of the time and roll out AI-assisted app building across your organisation.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Get Started with Copilot in Power Apps</h3>
<ul>
<li>What is Copilot in Power Apps and the Power Platform</li>
<li>Licensing, Requirements and Enabling Copilot</li>
<li>Copilot in Power Apps Studio</li>
<li>Effective Prompting for App Building</li>
<li>Preparing Data with Dataverse for Copilot</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Build Canvas Apps with Copilot</h3>
<ul>
<li>Creating an App from a Prompt</li>
<li>Refining Screens, Controls and Layouts with Copilot</li>
<li>Generating and Explaining Power Fx Formulas with Copilot</li>
<li>Adding an In-App Copilot Chat for Users</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Automate and Extend with Copilot</h3>
<ul>
<li>Building Power Automate Flows with Copilot</li>
<li>Integrating Flows with Canvas Apps</li>
<li>Approval and Notification Scenarios</li>
<li>Sharing and Governing AI-Assisted Apps</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Copilot for Power Apps' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Copilot for Power Apps, Power Apps Copilot, Microsoft Power Platform, AI App Development, Low Code AI, Canvas Apps, Power Fx with Copilot, Power Automate Copilot, Business Applications, Power Apps Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Build business apps faster with AI. Learn Copilot for Power Apps - create canvas apps from prompts, generate Power Fx formulas, and automate flows in this hands-on 1-day course at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'copilot-for-power-apps' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C803-20260717-180030.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Copilot for Power Apps' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Copilot for Power Apps' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Copilot for Power Apps' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Product-page zoom gallery renders the per-image label as img title/alt
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Copilot for Power Apps'
WHERE g.entity_id = @e AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_il, @a_sil, @a_til, @a_ciu);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Stale url_path rows point at the old microsoft-powerapps-flow-training URL;
-- drop them at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;

-- Funding block: the old WSQ link 301s (application -> applications); point
-- directly at the live 200 URL (WSQ - Applications Integration with Power Apps
-- and Power Automate, the funded equivalent of this course). Content-only
-- UPDATE by identifier - never a cms/block model save, which would wipe the
-- cms_block_store mapping. No-op on sites without the block.
UPDATE cms_block SET content='<h2>Funding and Grant Applications</h2>\n\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-applications-integration-with-power-apps-and-power-automate.html" title="WSQ - Applications Integration with Power Apps and Power Automate">WSQ - Applications Integration with Power Apps and Power Automate</a></span></p>'
WHERE identifier='course_C803_funding_and_grant';
