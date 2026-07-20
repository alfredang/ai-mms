-- Repurpose course C155 from "AI Applications to Google Workspace" to
-- "Google Workspace with Gemini". The existing content was already
-- Gemini-centric, so this is a retitle: name, overview, topics headings,
-- meta, url_key, image labels and a freshly rendered cover
-- (course_image_url). Price ($700) and duration intentionally kept.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates the new URL.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C155.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C155');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_cimg  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Google Workspace with Gemini' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Work smarter across Google Workspace with Gemini. This hands-on 2-day course teaches you how to use Gemini and generative AI inside Gmail, Docs, Sheets, Slides, Meet and Drive to write, summarise, analyse and create faster. Instead of doing everything manually, you will apply Gemini to real workplace tasks and build practical, everyday productivity habits with Google Workspace.</p>
<p>Through practical projects, participants will draft and summarise emails and documents, generate slides and images, analyse and visualise data in Sheets, run AI-assisted meetings, and build simple automations that connect Workspace apps. You will also learn to prompt effectively, fact-check AI output and apply AI responsibly and securely at work. By the end of the course, you will be able to apply Gemini across Google Workspace to boost your everyday productivity and output.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Gemini in Google Workspace</h3>
<ul>
<li>Introduction to Generative AI and Gemini in Workspace</li>
<li>Setting Up and Accessing Gemini Across Workspace Apps</li>
<li>Effective Prompting for Everyday Work Tasks</li>
<li>Responsible, Secure and Private Use of AI at Work</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Gemini in Docs, Slides and Gmail</h3>
<ul>
<li>Drafting, Rewriting and Summarising in Docs</li>
<li>Generating Slides, Layouts and Images in Slides</li>
<li>Writing, Replying and Summarising Emails in Gmail</li>
<li>Reviewing and Refining AI-Generated Content</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Gemini in Sheets and Data Analysis</h3>
<ul>
<li>Generating Formulas, Tables and Insights in Sheets</li>
<li>Analysing and Summarising Data with Gemini</li>
<li>Creating Charts and Visualisations</li>
<li>Cleaning and Organising Data with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 4 AI-Powered Workflows and Automation in Workspace</h3>
<ul>
<li>AI-Assisted Meetings and Notes in Google Meet</li>
<li>Organising and Searching Drive with Gemini</li>
<li>Connecting Apps and Building Simple Automations</li>
<li>Designing Practical AI Productivity Workflows</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Google Workspace with Gemini' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Gemini in Google Workspace in this hands-on 2-day course. Use AI in Gmail, Docs, Sheets, Slides, Meet and Drive to write, summarise, analyse data and automate everyday work.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Google Workspace, Gemini, Generative AI, Gmail, Google Docs, Google Sheets, Google Slides, Google Meet, AI Productivity, Workplace AI, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'google-workspace-with-gemini' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Fresh cover rendered 2026-07-18 from the new title (no funding badges)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cimg, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C155-20260717-164147.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Google Workspace with Gemini' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Google Workspace with Gemini' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Google Workspace with Gemini' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_cimg, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Stale url_path rows point at the old ai-applications-to-google-workspace
-- URL; drop them at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;
