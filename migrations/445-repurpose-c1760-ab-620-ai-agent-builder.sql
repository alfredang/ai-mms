-- Repurpose course C1760 from "MB-700 Microsoft Certified Dynamics 365 Finance
-- and Operations Apps Solution Architect Expert" to "AB-620 Microsoft Certified
-- AI Agent Builder Associate". Microsoft certification exam-prep course. name,
-- url_key, overview (short_description), exam domains (description) with official
-- skills-measured weightings, meta (title/description/keyword). Price and
-- duration unchanged. Cover regenerated separately via CourseImage dialog.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1760');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AB-620 Microsoft Certified AI Agent Builder Associate') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>The AB-620 Microsoft Certified AI Agent Builder Associate course equips developers and advanced builders with the knowledge and skills required to design, build, extend and integrate custom AI agents for enterprise-grade solutions in Microsoft Copilot Studio. Participants will explore planning agent solutions, creating agent flows and topics, and configuring advanced responses with custom prompts, knowledge sources and adaptive cards.</p>
<p>Learners will gain hands-on expertise integrating agents with enterprise knowledge sources, Model Context Protocol (MCP) tools, custom connectors and REST APIs, building multi-agent solutions with the Agent2Agent (A2A) protocol and Microsoft Foundry, and connecting to Azure AI Search and Microsoft Fabric. Additionally, the course covers testing and evaluating agents and applying application lifecycle management with Microsoft Power Platform Pipelines. By completing this course, participants will be prepared to build and ship integrated, production-ready AI agents in Copilot Studio.</p>
<h2>Microsoft Learning Partner</h2>
<p>We are <strong>Authorised&nbsp;Microsoft Learning Partner (Org ID:&nbsp; 5238476).</strong> To get the official Microsoft certification, please register your certification exam at Pearson Vue Test Center.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>AB-620</strong> certification exam, covering all official skills measured and their approximate weightings:</p>
<h3 class="course-topic-h3">Domain 1 Plan and configure agent solutions (30-35%)</h3>
<ul>
<li>Plan an agent solution: integration with enterprise systems, identity strategy, channels and deployment, and responsible AI strategy</li>
<li>Evaluate security and governance considerations, plan reusable agent components, and design agents for internal or external audiences</li>
<li>Create and monitor agent flows in Copilot Studio, including human-in-the-loop flows, actions and connectors, input/output parameters and error handling</li>
<li>Configure topics: add agent flows and tools, and configure response formatting and adaptive cards</li>
<li>Configure advanced agent responses with custom prompts, custom knowledge sources, and API and Send HTTP requests</li>
<li>Configure the generative answers node and manage variables</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Integrate and extend agents in Copilot Studio (40-45%)</h3>
<ul>
<li>Connect to enterprise knowledge sources: Copilot connectors, Microsoft Power Platform connectors and Azure AI Search</li>
<li>Add tools to agents: configure and monitor computer use, MCP tools, custom connectors and REST APIs</li>
<li>Configure multi-agent collaboration: design multi-agent solutions, integrate a Foundry agent, an existing agent, and a Fabric data agent</li>
<li>Create a multi-agent solution by using the Agent2Agent (A2A) protocol</li>
<li>Integrate agents with Azure: generative answers using Azure AI Search with Foundry, and custom prompts using the Foundry model catalog</li>
<li>Monitor agents by using Application Insights</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Test and manage agents (20-25%)</h3>
<ul>
<li>Evaluate agent performance: create a test set, choose an evaluation method, and review test results</li>
<li>Implement application lifecycle management (ALM): create a solution and add existing agents</li>
<li>Create and use environment variables</li>
<li>Implement and extend Microsoft Power Platform Pipelines</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AB-620 Microsoft Certified AI Agent Builder Associate') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for Microsoft Exam AB-620 and become a Certified AI Agent Builder Associate. Design, build and integrate custom AI agents in Copilot Studio with MCP, A2A and Microsoft Foundry at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AB-620 course Singapore, AI Agent Builder, Microsoft Copilot Studio, Microsoft AI certification, multi-agent, MCP, A2A protocol, Microsoft Foundry, AI agents, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ab-620-microsoft-certified-ai-agent-builder-associate') ON DUPLICATE KEY UPDATE value = VALUES(value);
