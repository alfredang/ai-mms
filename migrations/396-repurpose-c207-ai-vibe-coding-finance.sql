-- Rename course C207 from "Python for Finance" to "AI Vibe Coding for Finance"
-- (2 days / 4 topics). Part of the AI Vibe Coding series (red badge). name,
-- overview, topics, meta, cover, url_key, badge. Per-market price ($700 SG)
-- applied direct on prod, NOT in this migration (avoids overwriting partner
-- prices). Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C207');
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

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Finance') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Automate financial analysis and reporting with AI Vibe Coding for Finance. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to analyse financial data, build models and automate workflows with Python and pandas. Instead of memorising libraries and syntax, you will vibe code &mdash; describing what you want in plain language and letting AI generate, refactor and debug the code while you focus on the financial insight.</p>
<p>Through practical projects, participants will load and clean financial data, compute returns and risk metrics, visualise trends, build simple pricing and portfolio models, and automate recurring reports &mdash; all with an AI pair programmer at their side. You will also learn to review, test and validate AI-generated code so your numbers stay accurate and auditable. By the end of the course, you will be able to deliver financial analysis and automation faster with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Finance</h3>
<ul>
<li>Introduction to Financial Analysis and Vibe Coding</li>
<li>Setting Up AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Loading and Cleaning Financial Data with AI</li>
<li>Effective Prompting for Finance Code Generation</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Financial Data Analysis with AI</h3>
<ul>
<li>Exploring Prices, Returns and Risk Metrics</li>
<li>Time Series Analysis with pandas</li>
<li>Visualising Financial Trends and Dashboards</li>
<li>Debugging and Explaining Analysis Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Financial Modelling and Automation with AI</h3>
<ul>
<li>Building Pricing and Valuation Models</li>
<li>Portfolio Construction and Optimisation</li>
<li>Automating Recurring Financial Reports</li>
<li>Connecting to Market Data APIs</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building and Deploying Finance Apps with AI</h3>
<ul>
<li>Building an Interactive Finance App</li>
<li>Reviewing, Testing and Validating AI-Generated Code</li>
<li>Ensuring Accuracy, Auditability and Governance</li>
<li>Deploying and Sharing Your Finance Tools</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Finance') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Automate financial analysis with AI vibe coding. Master returns, risk, modelling and reporting using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Finance, Python, pandas, Financial Analysis, Portfolio, Risk, Cursor, GitHub Copilot, Claude, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C207-20260711-191755.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-finance') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
