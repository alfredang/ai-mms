-- Repurpose course C735 (entity_id 735) from "Mastering Agentic AI Automations
-- with n8n" to "AI Agents with n8n" (3 days / 6 topics, 2 per day). NOTE: this
-- is NOT part of the AI Vibe Coding series (different name/branding), so NO
-- series badge is set. Sets name, overview, 6 topics, meta, duration 22.5h,
-- cover and url_key. Per-market price (SG 1100) and SG-only funding block are
-- applied direct on prod. Store scope 0. Idempotent. No content line ends in ';'.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C735');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Agents with n8n') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build powerful AI agents and automations with AI Agents with n8n. This hands-on 3-day course teaches you how to use n8n, the popular open-source workflow automation platform, to design, build and deploy AI-powered agents that connect your apps, data and large language models. From simple automations to autonomous multi-step agents, you will learn to orchestrate tools, APIs and AI models into reliable workflows that get real work done.</p>
<p>Through practical projects, participants will set up n8n, build workflows that call LLMs, connect to services and databases, add memory and tools to agents, and design multi-agent automations that handle real business tasks such as customer support, data processing and content generation. You will also learn to test, secure and monitor your agents so they run reliably in production. By the end of the course, you will be able to design, build and deploy AI agents and automations with n8n that save time and scale your operations.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with n8n and AI Automation</h3>
<ul>
<li>Introduction to n8n and Workflow Automation</li>
<li>Setting Up n8n (Cloud and Self-Hosted)</li>
<li>Building Your First Workflow</li>
<li>Working with Triggers, Nodes and Data</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Connecting Apps, APIs and Data</h3>
<ul>
<li>Using Built-in Integrations</li>
<li>Calling REST APIs and Webhooks</li>
<li>Working with Databases and Spreadsheets</li>
<li>Transforming and Routing Data</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Adding AI and LLMs to Your Workflows</h3>
<ul>
<li>Introduction to AI Nodes and LLMs</li>
<li>Prompting and Chaining AI Calls</li>
<li>Building an AI Chatbot Workflow</li>
<li>Handling AI Outputs and Errors</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building AI Agents</h3>
<ul>
<li>Introduction to AI Agents in n8n</li>
<li>Giving Agents Tools and Memory</li>
<li>Retrieval Augmented Generation (RAG) Workflows</li>
<li>Building an Autonomous Task Agent</li>
</ul>
<h3 class="course-topic-h3">Topic 5 Multi-Agent Automations</h3>
<ul>
<li>Designing Multi-Agent Workflows</li>
<li>Coordinating Agents and Tools</li>
<li>Human-in-the-Loop Approvals</li>
<li>Real-World Automation Use Cases</li>
</ul>
<h3 class="course-topic-h3">Topic 6 Deploying and Scaling AI Agents</h3>
<ul>
<li>Testing and Debugging Workflows</li>
<li>Securing Credentials and Access</li>
<li>Monitoring and Error Handling</li>
<li>Deploying and Scaling n8n in Production</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Agents with n8n | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build AI agents and automations with n8n. Master workflows, integrations, LLM nodes, RAG, multi-agent orchestration and deployment in this hands-on 3-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Agents, n8n, Workflow Automation, LLM, RAG, Multi-Agent, Automation, No-Code, AI Coding, Integrations')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '22.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C735-20260711-094543.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-agents-with-n8n') ON DUPLICATE KEY UPDATE value = VALUES(value);
