-- Repurpose course C193 from "Data Analysis with Python Essential Training"
-- to "AI Vibe Coding for Python Data Analysis" (AI Vibe Coding Series,
-- 1-day variant: 1 day / 7.5h / 2 topics). name, overview, topics, meta,
-- cover image. Price ($350, 1 day) and duration (7.5) intentionally kept —
-- this course is NOT in the shared 2-day $700 migration 347. url_key
-- intentionally UNCHANGED (series rule — preserves URL + SEO). Badge added
-- via shared migration 342.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C193.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C193');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI Vibe Coding for Python Data Analysis' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Analyze real-world data without writing every line of Python yourself. In this hands-on 1-day course you will use AI coding assistants&mdash;Cursor, GitHub Copilot and Claude&mdash;to vibe code a complete data analysis workflow: describe what you want in plain English, let the AI generate the Pandas code to import, clean and transform your dataset, then review, refine and iterate with follow-up prompts. You will learn the prompting patterns that keep AI-generated data analysis code correct, readable and reproducible.</p>
<p>Over two practical topics you will vibe code the full data preparation pipeline&mdash;importing, cleaning, filtering, joining and aggregating data with Pandas&mdash;then move on to AI-assisted visualization and analysis with Matplotlib and Seaborn, generating charts, uncovering correlations and trends, and summarizing statistical insights. By the end of the course, you will have a working analysis notebook and a repeatable AI vibe coding workflow you can apply to any dataset.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 AI Vibe Coding for Data Preparation</h3>
<ul>
<li>What Is AI Vibe Coding</li>
<li>Setting Up Cursor, GitHub Copilot and Claude for Data Analysis</li>
<li>Prompting Patterns for Correct Pandas Code</li>
<li>Importing and Exporting Data with AI Assistance</li>
<li>Cleaning, Filtering and Slicing Data</li>
<li>Joining, Transforming and Aggregating Data</li>
</ul>
<h3 class="course-topic-h3">Topic 2 AI-Assisted Data Visualization and Analysis</h3>
<ul>
<li>Generating Charts with Matplotlib and Seaborn from Prompts</li>
<li>Visualizing Relationships, Categories and Correlations</li>
<li>Statistical Data Analysis with AI Assistance</li>
<li>Time Series Trends and Insights</li>
<li>Iterating on Analysis with Follow-Up Prompts</li>
<li>Summarizing Findings into a Shareable Report</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI Vibe Coding for Python Data Analysis' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Vibe code Python data analysis with Cursor, GitHub Copilot and Claude in this hands-on 1-day course. Prepare data with Pandas, visualize with Matplotlib and Seaborn, and turn insights into reports.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI Vibe Coding, Python Data Analysis, Pandas, Matplotlib, Seaborn, Cursor, GitHub Copilot, Claude, Data Visualization, Data Cleaning, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C193-20260717-084820.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '7.5' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_img, @a_dur);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
