-- Re-enable course C143 ("Advanced R Data Analysis Training", currently
-- disabled) and repurpose it to "AI Vibe Coding with R" (1 day / 2 topics).
-- Part of the AI Vibe Coding series (badge). name, overview, topics, meta
-- (title/description/keyword), duration 7.5h, cover, url_key, badge, status=1
-- (enabled), and adds it to the "AI Vibe Coding Series" category (resolved by
-- NAME so it is partner-safe; the id differs per site). Price unchanged
-- (already 350 SG). Points the Funding block at IBF - Machine Learning 101 for
-- Financial Trading (validated 200 on www.tertiarycourses.com.sg). Clears
-- per-store overrides of the rewritten attributes so partner store scopes can't
-- shadow store 0. Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C143');
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
SET @a_status:= (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding with R') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Analyse data faster with AI Vibe Coding with R. This hands-on 1-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, run and debug R code for data analysis and statistics. Instead of memorising R syntax and package APIs, you will vibe code &mdash; describing the analysis you want in plain language and letting AI generate, refactor and explain your R scripts while you focus on the questions and the insight.</p>
<p>Through practical exercises, participants will set up R and RStudio with an AI assistant, import and clean datasets, run statistical analysis and build visualisations, and produce a shareable report &mdash; all with an AI pair programmer at their side. You will also learn to review, correct and improve AI-generated R code so your results stay accurate and reproducible. By the end of the course, you will be able to analyse data with R far more productively using an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding in R</h3>
<ul>
<li>Introduction to R, Data Analysis and Vibe Coding</li>
<li>Setting Up R, RStudio and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Generating R Code to Import and Clean Data with AI</li>
<li>Effective Prompting for R Data Analysis</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Analysing and Visualising Data with AI in R</h3>
<ul>
<li>Exploring and Summarising Data with AI-Generated R Code</li>
<li>Statistical Analysis and Modelling with R and AI</li>
<li>Creating Charts and Visualisations with the Tidyverse and ggplot2</li>
<li>Reviewing, Debugging and Reproducing AI-Generated R Results</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding with R') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Analyse data with R using AI vibe coding. Generate, run and debug R scripts for statistics and visualisation with AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, R, RStudio, Data Analysis, Statistics, Tidyverse, ggplot2, Data Science, Cursor, GitHub Copilot, Claude, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C143-20260717-190920.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'advanced-r-data-analysis-training') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Re-enable (was disabled, status=2). Enable at store 0 and clear any per-store override.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_status, 0, @e, 1) ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_int WHERE entity_id=@e AND store_id<>0 AND attribute_id=@a_status;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_dur, @a_img, @a_url, @a_badge);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Add to the "AI Vibe Coding Series" category (resolved by name; id differs per site).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0 FROM catalog_category_entity_varchar v
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE v.store_id=0 AND v.value = 'AI Vibe Coding Series' AND @e IS NOT NULL;

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For IBF funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html" title="IBF - Machine Learning 101 for Financial Trading">IBF - Machine Learning 101 for Financial Trading</a></span></p>'
WHERE identifier = 'course_C143_funding_and_grant';
