-- Convert course C104 from "Agentic AI for Accounting" to "AI for Accounting".
-- Broadens the course from an agents-only framing to general AI for the
-- accounting workflow: retitles name, url_key (ai-for-accounting), meta_title,
-- meta_keyword, meta_description, image labels; rewrites short_description and
-- the four description topics (AI fundamentals + prompting, bookkeeping &
-- transactions, reporting & analysis, compliance/audit + agentic automation as
-- the closing topic); points course_image_url at a freshly rendered R2 cover
-- (2026-07-18, no funding chips -- C104 carries no funding-badge tags).
-- Price ($350) and 2-day duration unchanged.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates (old URL 301s to the new one).
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C104.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C104');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI for Accounting' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Bring the power of AI into your accounting practice with our hands-on AI for Accounting course. Over 2 days, you will learn how modern AI tools such as ChatGPT, Claude and Microsoft Copilot fit into the accounting workflow &mdash; extracting data from invoices, reconciling bank statements, classifying expenses, analysing financial statements and drafting management reports &mdash; no programming background required.</p>
<p>Through guided exercises, participants will apply AI to accounts payable and receivable processing, speed up month-end close tasks, run financial statement and variance analysis, and use AI for tax and GST compliance checks and audit support such as anomaly detection. You will also learn to automate repetitive accounting tasks with AI-powered workflows, keep a human in the loop, validate AI outputs and govern AI use responsibly. By the end of the course, you will be able to use AI confidently to streamline your accounting operations and free you to focus on higher-value advisory work.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Introduction to AI for Accounting</h3>
<ul>
<li>Overview of Generative AI and Large Language Models</li>
<li>AI Use Cases Across the Accounting Workflow</li>
<li>AI Tools Landscape: ChatGPT, Claude, Copilot and Excel AI</li>
<li>Effective Prompting for Accounting Tasks</li>
<li>Data Privacy, Governance and Responsible AI Use</li>
</ul>
<h3 class="course-topic-h3">Topic 2: AI for Bookkeeping and Transactions</h3>
<ul>
<li>Automating Invoice Capture and Data Extraction</li>
<li>AI for Accounts Payable and Receivable</li>
<li>Bank Reconciliation with AI</li>
<li>Expense Classification and Journal Entry Automation</li>
<li>Human-in-the-Loop Review and Exception Handling</li>
</ul>
<h3 class="course-topic-h3">Topic 3: AI for Reporting and Analysis</h3>
<ul>
<li>Automating Month-End Close Tasks with AI</li>
<li>Financial Statement Analysis with AI</li>
<li>Variance Analysis and Management Reporting</li>
<li>Cash Flow Forecasting with AI</li>
<li>Building Dashboards and Visualisations with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 4: AI for Compliance, Audit and Automation</h3>
<ul>
<li>AI for Tax and GST Compliance Checks</li>
<li>Audit Support: Anomaly and Fraud Detection</li>
<li>Automating Accounting Workflows with AI Agents</li>
<li>Validating and Controlling AI Outputs</li>
<li>Risks, Ethics and the Future of AI in Accounting</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI for Accounting' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master AI for Accounting in this hands-on 2-day course. Use AI for bookkeeping, reconciliation, financial reporting, compliance and audit at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI Accounting, AI for Accountants, AI Bookkeeping Automation, Invoice Processing AI, Bank Reconciliation AI, Financial Reporting AI, AI Audit, AI Tax Compliance, Accounting Automation Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'ai-for-accounting' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title (no funding chips), uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C104-20260717-170256.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI for Accounting' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI for Accounting' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI for Accounting' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_il, @a_sil, @a_til, @a_ciu);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Stale url_path rows point at the old agentic-ai-for-accounting URL; drop them
-- at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;
