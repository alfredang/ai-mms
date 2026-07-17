-- Re-enable course C188 (currently disabled) and repurpose it from
-- "AI Vibe Coding for Python Machine Learning" to
-- "AI Vibe Coding for Python Data Analytics" (2 days / 4 topics). Already a
-- full AI Vibe Coding series member (badge, 15h duration, $700 price) — this
-- migration flips status=1, rewrites name/overview/topics/meta to a Data
-- Analytics focus, refreshes the cover, and repoints the Funding block at
-- WSQ - Data Analytics and Visualization with Python (validated 200 on
-- www.tertiarycourses.com.sg). Keeps it in the Python + AI Vibe Coding Series
-- categories. url_key preserved. Clears per-store overrides so partner scopes
-- can't shadow store 0. Store scope 0. Idempotent. No content line ends in a
-- semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C188');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');
SET @a_status:= (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Python Data Analytics') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Turn raw data into insight with AI Vibe Coding for Python Data Analytics. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, run and debug Python code for data analysis and visualisation. Instead of memorising Pandas, NumPy and Matplotlib APIs, you will vibe code &mdash; describing the analysis you want in plain language and letting AI generate, refactor and explain your Python scripts while you focus on the questions and the insight.</p>
<p>Through practical projects, participants will set up a Python data stack with an AI assistant, import and clean messy datasets, explore and summarise data, build charts and dashboards, and produce a shareable analysis report &mdash; all with an AI pair programmer at their side. You will also learn to review, correct and improve AI-generated code so your results stay accurate and reproducible. By the end of the course, you will be able to analyse data with Python far more productively using an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 AI Vibe Coding Workflow and Python Data Stack Setup</h3>
<ul>
<li>Introduction to AI Vibe Coding for Data Analytics</li>
<li>Setting Up Python, Jupyter, Cursor, GitHub Copilot and Claude</li>
<li>Prompting Patterns for Data Analysis Tasks</li>
<li>Structuring a Python Data Analytics Project</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Importing and Cleaning Data with AI</h3>
<ul>
<li>Loading Data from CSV, Excel and APIs with Pandas</li>
<li>Cleaning Data and Handling Missing Values</li>
<li>Reshaping, Merging and Aggregating DataFrames</li>
<li>Reviewing and Validating AI-Generated Data Pipelines</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Exploring and Analysing Data with Vibe Coding</h3>
<ul>
<li>Exploratory Data Analysis and Descriptive Statistics</li>
<li>Grouping, Pivoting and Time-Series Analysis</li>
<li>Finding Patterns and Correlations with AI Assistance</li>
<li>Explaining and Debugging Analysis Code with the AI Assistant</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Visualising and Communicating Insights</h3>
<ul>
<li>Creating Charts with Matplotlib, Seaborn and Plotly</li>
<li>Building an Interactive Dashboard</li>
<li>Packaging the Analysis into a Shareable Report</li>
<li>Verify-Then-Trust: Auditing AI-Generated Analytics Code</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Python Data Analytics') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Analyse data with Python using AI vibe coding. Generate, run and debug Pandas, Matplotlib and Seaborn code with AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Python, Data Analytics, Data Analysis, Pandas, NumPy, Matplotlib, Seaborn, Data Visualisation, Data Science, Cursor, GitHub Copilot, Claude, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C188-20260717-191732.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'python-machine-learning-scikit-learn') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Re-enable (was disabled, status=2). Enable at store 0 and clear any per-store override.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_status, 0, @e, 1) ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_int WHERE entity_id=@e AND store_id<>0 AND attribute_id=@a_status;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_img, @a_url, @a_badge);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Ensure it is in the "AI Vibe Coding Series" category (resolved by name; partner-safe).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0 FROM catalog_category_entity_varchar v
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE v.store_id=0 AND v.value = 'AI Vibe Coding Series' AND @e IS NOT NULL;

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-python-data-analytics-visualization.html" title="WSQ - Data Analytics and Visualization with Python">WSQ - Data Analytics and Visualization with Python</a></span></p>'
WHERE identifier = 'course_C188_funding_and_grant';

-- C143 "AI Vibe Coding with R" keeps its home in the "R" category (it still
-- teaches R). It was repurposed in 540 but never (re)added to that category, so
-- ensure the assignment here (resolved by name; partner-safe).
SET @c143 := (SELECT entity_id FROM catalog_product_entity WHERE sku='C143');
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @c143, 0 FROM catalog_category_entity_varchar v
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE v.store_id=0 AND v.value = 'R' AND @c143 IS NOT NULL;
