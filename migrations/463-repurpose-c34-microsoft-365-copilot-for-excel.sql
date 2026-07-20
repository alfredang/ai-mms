-- Repurpose course C34 from "Advanced Excel Essential Training" to
-- "Microsoft 365 Copilot for Excel" (1 day / 2 topics — AI-assisted data
-- analysis in Excel with Copilot). name, overview, topics, meta, url_key.
-- Price ($350) and duration (7.5h = 1 day) already correct — untouched.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C34.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C34');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Microsoft 365 Copilot for Excel' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Transform the way you work with spreadsheets in Microsoft 365 Copilot for Excel. This hands-on 1-day course shows you how Copilot&mdash;the AI assistant built into Excel&mdash;lets you analyse data, generate formulas and build reports using plain-English prompts instead of memorising functions. You will learn to prepare your data as Excel tables so Copilot works at its best, ask Copilot to highlight, sort and filter data, generate complex formula columns, and surface trends and insights instantly.</p>
<p>Through practical exercises, participants will use Copilot to clean and enrich real-world datasets, build PivotTables and charts from a simple request, run deeper analysis with Advanced Analysis and Python in Excel, and turn raw data into presentation-ready summaries. You will also learn prompt best practices and the limits of AI-generated analysis so you can verify results with confidence. By the end of the course, you will be able to complete everyday Excel analysis tasks in a fraction of the time&mdash;no advanced formula knowledge required.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Getting Started with Copilot in Excel</h3>
<ul>
<li>Introduction to Microsoft 365 Copilot in Excel</li>
<li>Preparing Data as Excel Tables for Copilot</li>
<li>Writing Effective Prompts for Data Tasks</li>
<li>Highlighting, Sorting and Filtering Data with Copilot</li>
<li>Generating Formula Columns from Plain-English Requests</li>
</ul>
<h3 class="course-topic-h3">Topic 2: AI-Powered Data Analysis and Insights</h3>
<ul>
<li>Cleaning and Enriching Data with Copilot</li>
<li>Building PivotTables and Charts from a Prompt</li>
<li>Surfacing Trends, Outliers and Insights</li>
<li>Advanced Analysis with Python in Excel</li>
<li>Verifying Results and Prompt Best Practices</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Microsoft 365 Copilot for Excel' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Microsoft 365 Copilot in Excel with this hands-on 1-day course. Analyse data, generate formulas, build PivotTables and charts, and surface insights with AI prompts at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Copilot Excel, Microsoft 365 Copilot, AI Data Analysis, Excel Formulas AI, PivotTable Copilot, Excel Charts AI, Python in Excel, Advanced Analysis, Prompt Writing, Excel Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'microsoft-365-copilot-for-excel' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
