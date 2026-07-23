-- Repurpose C188 "AI Vibe Coding for Python Data Analytics" ->
-- "AI Vibe Coding for Python Financial Analysis": new name, overview,
-- 4 finance-focused topics (2 per day), SEO meta, re-rendered R2 cover, and
-- the Funding block re-pointed at WSQ - Python Programming for Finance
-- (target verified HTTP 200). Series terms unchanged (2 days / 15h / $700 /
-- badge). url_key intentionally unchanged.
-- Product statements key off the SKU (no-op if absent); the SG funding block
-- is guarded by @mms_instance = 'SG'. Idempotent.
-- apply.php note: no content line ends in a semicolon.

SET @attr_name              := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @attr_description       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @attr_meta_title        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @attr_meta_description  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @attr_meta_keyword      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @attr_course_image_url  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_name, 0, e.entity_id, 'AI Vibe Coding for Python Financial Analysis'
FROM catalog_product_entity e WHERE e.sku = 'C188'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_short_description, 0, e.entity_id, '<p>Turn Python into your financial analysis toolkit with AI Vibe Coding for Python Financial Analysis. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to analyse financial data with Python. Instead of memorising pandas syntax and formulas, you will vibe code &mdash; describing the analysis you want in plain language and letting AI generate, explain, refactor and fix the Python code while you stay in control of the financial logic and interpretation.</p>
<p>Through practical exercises with real market data, participants will import and clean financial datasets, compute returns, volatility and risk metrics, analyse price time series, evaluate and optimise portfolios, backtest simple trading strategies, and publish an interactive financial dashboard on Streamlit &mdash; all with an AI pair programmer at their side. You will also learn to review, test and improve AI-generated analysis code so your numbers are correct and your conclusions hold up. By the end of the course, you will be able to deliver useful financial analysis in Python faster with an effective AI vibe-coding workflow.</p>'
FROM catalog_product_entity e WHERE e.sku = 'C188'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_description, 0, e.entity_id, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Financial Analysis</h3>
<ul>
<li>Introduction to Python for Financial Analysis</li>
<li>Setting Up Python and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Working with Financial Data in Pandas</li>
<li>Importing Market Data from APIs and Files</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Analysing Financial Data with AI</h3>
<ul>
<li>Cleaning and Transforming Financial Datasets</li>
<li>Computing Returns, Volatility and Risk Metrics</li>
<li>Time Series Analysis of Stock Prices</li>
<li>Visualising Financial Data with AI-Generated Charts</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Portfolio and Investment Analysis with Vibe Coding</h3>
<ul>
<li>Measuring Portfolio Returns and Diversification</li>
<li>Portfolio Optimisation with AI Assistance</li>
<li>Backtesting Simple Trading Strategies</li>
<li>Evaluating Performance and Drawdowns</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building Financial Dashboards and Reports</h3>
<ul>
<li>Automating Financial Reports with Python</li>
<li>Building an Interactive Finance Dashboard on Streamlit</li>
<li>Reviewing and Improving AI-Generated Analysis Code</li>
<li>Deploying and Sharing Your Financial Analysis App</li>
</ul>'
FROM catalog_product_entity e WHERE e.sku = 'C188'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_meta_title, 0, e.entity_id, 'AI Vibe Coding for Python Financial Analysis | Tertiary Courses Singapore'
FROM catalog_product_entity e WHERE e.sku = 'C188'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_meta_description, 0, e.entity_id, 'Analyse financial data with Python and AI vibe coding. Master market data, returns and risk metrics, portfolio analysis, backtesting and Streamlit dashboards using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course.'
FROM catalog_product_entity e WHERE e.sku = 'C188'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_meta_keyword, 0, e.entity_id, 'python financial analysis, ai vibe coding, portfolio analysis, backtesting, pandas finance, streamlit dashboard, cursor, github copilot, claude'
FROM catalog_product_entity e WHERE e.sku = 'C188'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_course_image_url, 0, e.entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C188-20260721-120350.png'
FROM catalog_product_entity e WHERE e.sku = 'C188'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Funding block (SG only): point at the matching WSQ finance course.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C188 - Funding and Grant', 'course_C188_funding_and_grant', '', NOW(), NOW(), 1
FROM DUAL
WHERE @mms_instance = 'SG'
  AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C188_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
WHERE b.identifier = 'course_C188_funding_and_grant' AND @mms_instance = 'SG';

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-python-programming-for-finance.html" title="WSQ - Python Programming for Finance">WSQ - Python Programming for Finance</a></span></p>', update_time = NOW()
WHERE identifier = 'course_C188_funding_and_grant' AND @mms_instance = 'SG';
