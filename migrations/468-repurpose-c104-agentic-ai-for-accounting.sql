-- Repurpose course C104 from "Excel for Accounting" (1 day) to
-- "Agentic AI for Accounting" (2 days / 4 topics — AI agents for bookkeeping,
-- reporting, compliance and audit). name, overview, topics, meta, url_key,
-- duration (7.5 -> 15) and sessions (1 -> 2). Price untouched.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
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
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_sess  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='sessions');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Agentic AI for Accounting' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Step into the next era of accounting with our hands-on Agentic AI for Accounting course. Unlike ordinary AI chatbots that only answer questions, AI agents can plan, reason and act&mdash;autonomously extracting data from invoices, reconciling bank statements, classifying expenses and drafting management reports. Over 2 days, you will learn how agentic AI works, where it fits in the accounting workflow, and how to build practical AI agents that take repetitive bookkeeping and reporting tasks off your plate&mdash;no programming background required.</p>
<p>Through guided exercises, participants will build AI agents for accounts payable and receivable processing, automate month-end close tasks, run financial statement and variance analysis with AI, and apply agents to tax compliance checks and audit support such as anomaly detection. You will also learn how to keep a human in the loop, validate agent outputs and govern AI use responsibly. By the end of the course, you will be able to design, deploy and supervise AI agents that streamline your accounting operations and free you to focus on higher-value advisory work.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Introduction to Agentic AI for Accounting</h3>
<ul>
<li>From AI Chatbots to Autonomous AI Agents</li>
<li>How AI Agents Work: LLMs, Tools, Memory and Reasoning</li>
<li>Agentic AI Use Cases Across the Accounting Workflow</li>
<li>Overview of Agent Platforms and No-Code Tools</li>
<li>Data Privacy, Governance and Responsible AI Use</li>
</ul>
<h3 class="course-topic-h3">Topic 2: AI Agents for Bookkeeping and Transactions</h3>
<ul>
<li>Automating Invoice Capture and Data Extraction</li>
<li>AI Agents for Accounts Payable and Receivable</li>
<li>Bank Reconciliation with AI Agents</li>
<li>Expense Classification and Journal Entry Automation</li>
<li>Human-in-the-Loop Review and Exception Handling</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Agentic Workflows for Reporting and Analysis</h3>
<ul>
<li>Building Multi-Step Agentic Workflows</li>
<li>Automating Month-End Close Tasks</li>
<li>Financial Statement Analysis with AI Agents</li>
<li>Variance Analysis and Management Reporting</li>
<li>Cash Flow Forecasting with Agentic Pipelines</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Compliance, Audit and Deploying Accounting Agents</h3>
<ul>
<li>AI Agents for Tax and GST Compliance Checks</li>
<li>Audit Support: Anomaly and Fraud Detection</li>
<li>Validating and Controlling Agent Outputs</li>
<li>Deploying and Monitoring Agents in Your Practice</li>
<li>Risks, Ethics and the Future of Agentic Accounting</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Agentic AI for Accounting' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Agentic AI for Accounting in this hands-on 2-day course. Build AI agents for bookkeeping, reconciliation, financial reporting, compliance and audit at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Agentic AI Accounting, AI Agents Accounting, AI Bookkeeping Automation, Invoice Processing AI, Bank Reconciliation AI, Financial Reporting AI, AI Audit, AI Tax Compliance, Accounting Automation Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'agentic-ai-for-accounting' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '15' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @e, '2' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_dur, @a_sess);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
