-- Repurpose course C207 from "AI Vibe Coding for Finance" to "AI for Finance"
-- (2 days / 4 topics — Agentic AI and AI agents for financial analysis,
-- reporting, forecasting, risk and compliance). name, overview, topics, meta,
-- url_key, cover; clears the "AI Vibe Coding Series" badge (course leaves the
-- series). Duration stays 15 (2 days); price untouched.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C207.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C207');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI for Finance' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Step into the next era of finance with our hands-on AI for Finance course. Unlike ordinary AI chatbots that only answer questions, AI agents can plan, reason and act&mdash;autonomously extracting financial data, analysing statements, building forecasts, monitoring risk and drafting management reports. Over 2 days, you will learn how agentic AI works, where it fits across the finance function, and how to build practical AI agents that take repetitive analysis and reporting tasks off your plate&mdash;no programming background required.</p>
<p>Through guided exercises, participants will build AI agents for financial data extraction and analysis, automate budgeting, forecasting and management reporting with agentic workflows, and apply AI agents to risk assessment, fraud detection and compliance checks. You will also learn how to keep a human in the loop, validate agent outputs and govern AI use responsibly in a regulated environment. By the end of the course, you will be able to design, deploy and supervise AI agents that streamline your finance operations and free you to focus on higher-value analysis and decision-making.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Introduction to AI and Agentic AI for Finance</h3>
<ul>
<li>From Generative AI to Autonomous AI Agents</li>
<li>How AI Agents Work: LLMs, Tools, Memory and Reasoning</li>
<li>Agentic AI Use Cases Across the Finance Function</li>
<li>Overview of AI Agent Platforms and No-Code Tools</li>
<li>Data Privacy, Governance and Responsible AI in Finance</li>
</ul>
<h3 class="course-topic-h3">Topic 2: AI Agents for Financial Data and Analysis</h3>
<ul>
<li>Extracting and Consolidating Financial Data with AI Agents</li>
<li>Automating Financial Statement Analysis</li>
<li>Ratio, Trend and Variance Analysis with AI Agents</li>
<li>AI-Powered Market and Investment Research</li>
<li>Human-in-the-Loop Review and Validation</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Agentic Workflows for Financial Planning and Reporting</h3>
<ul>
<li>Building Multi-Step Agentic Workflows</li>
<li>Automating Budgeting and Forecasting with AI Agents</li>
<li>Cash Flow Monitoring and Treasury Agents</li>
<li>Automating Management Reports and Dashboards</li>
<li>Connecting Agents to Spreadsheets and Finance Systems</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Risk, Compliance and Deploying Finance AI Agents</h3>
<ul>
<li>AI Agents for Risk Assessment and Monitoring</li>
<li>Fraud and Anomaly Detection with AI Agents</li>
<li>Compliance and Regulatory Checks with AI Agents</li>
<li>Deploying, Supervising and Governing AI Agents</li>
<li>Risks, Ethics and the Future of Agentic Finance</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI for Finance' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master AI for Finance in this hands-on 2-day course. Build AI agents for financial analysis, reporting, forecasting, risk and compliance at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI for Finance, Agentic AI Finance, AI Agents Finance, Financial Analysis AI, Financial Reporting AI, Cash Flow Forecasting AI, AI Risk Management, Fraud Detection AI, AI Compliance, Finance Automation Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'ai-for-finance' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '15' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C207-20260717-085434.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Course leaves the AI Vibe Coding Series — clear the red badge.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_badge, 0, @e, '' FROM DUAL WHERE @e IS NOT NULL AND @a_badge IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image alt labels still carried the pre-2026 "Python for Finance" title.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI for Finance' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI for Finance' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI for Finance' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_dur, @a_img, @a_badge, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
