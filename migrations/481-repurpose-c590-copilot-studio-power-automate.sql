-- Repurpose course C590 from "RPA with Power Automate" to "Copilot Studio and
-- Power Automate" (2 days / 4 topics — building AI agents with Microsoft
-- Copilot Studio and automating workflows with Power Automate).
-- name, overview, topics, meta, url_key, cover, image labels.
-- Price ($700, 2 days) and duration (15) intentionally kept.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C590.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C590');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Copilot Studio and Power Automate' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Build your own AI agents and automate your business processes with our hands-on Copilot Studio and Power Automate course. Microsoft Copilot Studio lets you create custom AI copilots and agents that answer questions, take actions and serve your customers and staff&mdash;while Power Automate connects your everyday apps and services into automated workflows. In this practical 2-day course, you will learn how to design, build and publish AI agents with Copilot Studio and automate repetitive tasks with Power Automate&mdash;no programming background required.</p>
<p>Through guided exercises, participants will build conversational agents grounded on their own knowledge sources, publish them to channels such as websites and Microsoft Teams, and design cloud flows that automate approvals, notifications and data handling across Microsoft 365 and third-party services. You will then connect the two&mdash;triggering Power Automate flows from your Copilot Studio agents so they can take real actions on your behalf. By the end of the course, you will be able to deploy AI agents and automated workflows that boost productivity across your organisation.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Getting Started with Copilot Studio</h3>
<ul>
<li>Introduction to Microsoft Copilot Studio and AI Agents</li>
<li>Creating Your First Agent with Topics and Trigger Phrases</li>
<li>Generative Answers and Grounding Agents on Knowledge Sources</li>
<li>Managing Conversations with Entities, Variables and Slot Filling</li>
<li>Testing and Debugging Agents in Copilot Studio</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Building and Publishing Intelligent Agents</h3>
<ul>
<li>Extending Agents with Actions, Tools and Plugins</li>
<li>Connecting Agents to Websites, Documents and Dataverse</li>
<li>Publishing Agents to Websites, Microsoft Teams and Other Channels</li>
<li>Authentication, Security and Governance for Agents</li>
<li>Monitoring Agent Performance with Analytics</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Workflow Automation with Power Automate</h3>
<ul>
<li>Introduction to Power Automate and Cloud Flows</li>
<li>Building Automated, Instant and Scheduled Flows with Triggers and Connectors</li>
<li>Working with Conditions, Loops and Expressions</li>
<li>Automating Approvals, Notifications and Email Handling</li>
<li>Integrating Flows with Microsoft 365, SharePoint and Excel</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Integrating Copilot Studio with Power Automate</h3>
<ul>
<li>Calling Power Automate Flows from Copilot Studio Agents</li>
<li>Passing Inputs and Outputs Between Agents and Flows</li>
<li>Building Agent Flows for End-to-End Business Scenarios</li>
<li>Use Cases: Customer Service, Helpdesk, Bookings and Data Entry</li>
<li>Best Practices for Deploying AI Agents and Automations</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Copilot Studio and Power Automate' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Copilot Studio and Power Automate in this hands-on 2-day course. Build custom AI agents with Microsoft Copilot Studio and automate workflows with Power Automate at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Copilot Studio Course, Power Automate Course, Microsoft Copilot Studio Training, Power Automate Training, AI Agents, Custom Copilot, Workflow Automation, Cloud Flows, Microsoft Power Platform, No Code AI, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'copilot-studio-and-power-automate' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C590-20260717-091656.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Copilot Studio and Power Automate' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Copilot Studio and Power Automate' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Copilot Studio and Power Automate' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_img, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
