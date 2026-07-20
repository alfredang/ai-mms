-- Rename course C1873 from "Jump Start Your New Business with OpenClaw" to
-- "Manage AI Agents with Paperclip" (2 days / 4 topics). Part of the AI Agents
-- series. name, overview, topics, meta, cover, url_key. Price and duration
-- unchanged (700 SG / 15h). Store scope 0. Idempotent. No content line ends in
-- a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1873');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Manage AI Agents with Paperclip') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Take control of your AI agents at scale with Manage AI Agents with Paperclip. This hands-on 2-day course teaches you how to use the Paperclip platform to build, orchestrate, monitor and govern fleets of AI agents across your organisation. Instead of managing agents one by one, you will centrally configure, coordinate and observe them so they work together reliably and safely.</p>
<p>Through practical projects, participants will onboard agents into Paperclip, design multi-agent orchestration and hand-offs, set guardrails and permissions, and monitor performance, cost and reliability from a single control plane. You will also learn to version, audit and scale your agents as demand grows. By the end of the course, you will be able to manage a production fleet of AI agents with Paperclip.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Paperclip</h3>
<ul>
<li>Introduction to AI Agent Management and Paperclip</li>
<li>Setting Up Your Paperclip Workspace</li>
<li>Onboarding and Registering AI Agents</li>
<li>Roles, Permissions and Access Control</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Configuring and Orchestrating Agents</h3>
<ul>
<li>Configuring Agent Goals, Tools and Guardrails</li>
<li>Designing Multi-Agent Orchestration and Hand-offs</li>
<li>Managing Shared Memory and Context</li>
<li>Connecting Tools, APIs and Data Sources</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Monitoring and Governing Agent Fleets</h3>
<ul>
<li>Monitoring Performance, Cost and Reliability</li>
<li>Logging, Tracing and Auditing Agent Actions</li>
<li>Applying Guardrails, Safety and Compliance Controls</li>
<li>Diagnosing and Resolving Agent Failures</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Deploying and Scaling Agents with Paperclip</h3>
<ul>
<li>Versioning and Rolling Out Agents</li>
<li>Scaling Agent Fleets with Demand</li>
<li>Automating Workflows Across Teams</li>
<li>Operating a Production Agent Fleet</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Manage AI Agents with Paperclip') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build, orchestrate, monitor and govern fleets of AI agents with the Paperclip platform. Manage a production agent fleet from one control plane in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Paperclip, AI Agent Management, AI Agents, Agentic AI, Agent Orchestration, Agent Monitoring, AI Governance, Multi-Agent Systems')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1873-20260711-230711.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'manage-ai-agents-with-paperclip') ON DUPLICATE KEY UPDATE value = VALUES(value);
