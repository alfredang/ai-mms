-- Repurpose course C201 from "Statistical Data Analysis Training with Excel"
-- to "Claude AI for Excel Data Analysis" (1 day / 2 topics — using Claude AI
-- to clean, analyse, visualise and report on Excel data). name, overview
-- (short_description), topics (description — drives the What You'll Learn
-- card), meta and url_key. Duration/sessions untouched (already 1 day).
-- Price untouched.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C201.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C201');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Claude AI for Excel Data Analysis' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Supercharge your spreadsheet skills with our hands-on Claude AI for Excel Data Analysis course. Claude AI turns hours of manual Excel work&mdash;cleaning messy data, writing complex formulas, building pivot tables and charts&mdash;into simple plain-English conversations. In this 1-day course, you will learn how to pair Claude AI with Excel to prepare, analyse and visualise your data faster and more accurately, with no programming background required.</p>
<p>Through guided exercises on real spreadsheets, participants will use Claude AI to clean and structure raw data, generate and explain Excel formulas, summarise datasets with pivot-style analysis, uncover trends and correlations, and turn findings into charts, dashboards and management-ready reports. You will also learn effective prompting techniques for data tasks and how to validate AI outputs before acting on them. By the end of the course, you will be able to make Claude AI your everyday Excel analysis assistant and deliver data-driven insights in a fraction of the time.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Getting Started with Claude AI for Excel</h3>
<ul>
<li>Introduction to Claude AI and How It Works with Excel</li>
<li>Setting Up Claude AI for Spreadsheet Work</li>
<li>Prompting Techniques for Data Tasks</li>
<li>Importing and Understanding Your Excel Data with Claude</li>
<li>Cleaning and Structuring Messy Data</li>
<li>Generating and Explaining Excel Formulas with Claude</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Data Analysis and Insights with Claude AI</h3>
<ul>
<li>Summarising Data with Pivot-Style Analysis</li>
<li>Statistical Analysis: Trends, Outliers and Correlations</li>
<li>Creating Charts and Visualisations with Claude</li>
<li>Building Dashboards and Management Reports</li>
<li>Automating Repetitive Excel Analysis Tasks</li>
<li>Validating AI Outputs and Responsible AI Use</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Claude AI for Excel Data Analysis' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Claude AI for Excel Data Analysis in this hands-on 1-day course. Use Claude AI to clean data, generate formulas, analyse trends and build charts and reports at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Claude AI Excel, Claude AI Data Analysis, AI Excel Analysis, Excel AI Assistant, AI Data Cleaning, Excel Formulas AI, AI Charts Dashboards, Claude AI Course, Excel Data Analysis Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'claude-ai-for-excel-data-analysis' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
