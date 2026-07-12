-- Rename course C1259 from "Google Workspace Masterclass: Streamlining Your
-- Digital Office" to "AI Agents with Gemini Spark" (2 days / 4 topics). Part of
-- the AI Agents series. Content based on Google Gemini Spark
-- (gemini.google/overview/agent/spark/): an autonomous productivity agent with
-- Tasks, Skills and Schedules across Google Workspace. name, overview, topics,
-- meta, cover, url_key. Price and duration unchanged (700 SG / 15h). Store scope
-- 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1259');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Agents with Gemini Spark') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Put your productivity on autopilot with AI Agents with Gemini Spark. This hands-on 2-day course teaches you how to use Google Gemini Spark &mdash; an autonomous AI agent that works in the background 24/7 &mdash; to automate multi-step tasks across Gmail, Calendar, Drive, Docs, Sheets, Slides and more. Instead of doing repetitive work yourself, you will delegate it to an AI agent that plans, acts and reports while keeping you in control with approvals.</p>
<p>Through practical projects, participants will set up Gemini Spark, create one-off Tasks, build reusable Skills such as a personal ghostwriter, and design Schedules and conditional triggers that run workflows automatically. You will automate real use cases like inbox summaries, document organisation, research, expense tracking and lead management, and learn to guardrail agents with approvals, permissions and privacy in mind. By the end of the course, you will be able to build and run your own autonomous AI agents to streamline your digital office with Gemini Spark.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Agents and Gemini Spark</h3>
<ul>
<li>Introduction to Autonomous AI Agents and Gemini Spark</li>
<li>How Spark Works: Background Agents, Approvals and Control</li>
<li>Connecting Gemini Spark to Google Workspace (Gmail, Calendar, Drive)</li>
<li>Effective Prompting and Instructing Your Agent</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Automating Work with Gemini Spark Tasks</h3>
<ul>
<li>Creating One-Off Tasks for Research and Organisation</li>
<li>Automating Email, Inbox Summaries and Drafting</li>
<li>Working with Docs, Sheets and Slides through the Agent</li>
<li>Reviewing, Approving and Refining Agent Actions</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Building Reusable Skills and Schedules</h3>
<ul>
<li>Creating Custom, Reusable Skills (e.g., a Ghostwriter)</li>
<li>Designing Schedules and Conditional Triggers</li>
<li>Chaining Multi-Step Automated Workflows</li>
<li>Personalising Agent Behaviour and Style</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Advanced Agentic Workflows and Real-World Automation</h3>
<ul>
<li>Automating Lead Management, Expenses and Planning</li>
<li>Coordinating Multi-App Workflows across Workspace</li>
<li>Guardrails: Permissions, Privacy and Safe Automation</li>
<li>Monitoring, Improving and Scaling Your AI Agents</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Agents with Gemini Spark') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Automate your digital office with AI agents using Google Gemini Spark. Build Tasks, Skills and Schedules to automate Gmail, Calendar, Docs and more in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Agents, Gemini Spark, Google Gemini, Autonomous Agents, Agentic AI, Google Workspace Automation, AI Automation, Productivity, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1259-20260712-034839.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-agents-with-gemini-spark') ON DUPLICATE KEY UPDATE value = VALUES(value);
