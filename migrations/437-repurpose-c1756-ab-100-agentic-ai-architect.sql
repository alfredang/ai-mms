-- Repurpose course C1756 from "MB-310 Microsoft Certified Dynamics 365 Finance
-- Functional Consultant Associate" to "AB-100 Microsoft Certified Agentic AI
-- Business Solutions Architect". Microsoft certification exam-prep course.
-- name, url_key, overview (short_description), exam domains (description) with
-- official skills-measured weightings, meta (title/description/keyword). Price
-- and duration unchanged. Cover regenerated separately via CourseImage dialog.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1756');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AB-100 Microsoft Certified Agentic AI Business Solutions Architect') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>The AB-100 Microsoft Certified Agentic AI Business Solutions Architect course equips learners with the knowledge and skills required to design and deliver AI-powered, agentic-first business solutions on the Microsoft platform. Participants will explore planning AI strategies, designing single- and multi-agent solutions with Microsoft 365 Copilot, Copilot Studio and Microsoft Foundry, and grounding agents on trusted business data.</p>
<p>Learners will gain expertise in designing agent extensibility with Model Context Protocol and Computer Use, orchestrating AI features across Dynamics 365 and Microsoft Power Platform, and deploying solutions with robust testing, application lifecycle management, monitoring and telemetry. Additionally, the course covers securing and governing agents, mitigating prompt manipulation, and applying responsible AI, data residency and compliance controls. By completing this course, participants will be prepared to architect scalable, secure and measurable agentic AI solutions using Microsoft technologies.</p>
<h2>Microsoft Learning Partner</h2>
<p>We are <strong>Authorised&nbsp;Microsoft Learning Partner (Org ID:&nbsp; 5238476).</strong> To get the official Microsoft certification, please register your certification exam at Pearson Vue Test Center.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>AB-100</strong> certification exam, covering all official skills measured and their approximate weightings:</p>
<h3 class="course-topic-h3">Domain 1 Plan AI-powered business solutions (25-30%)</h3>
<ul>
<li>Analyze requirements: assess agents for task automation, data analytics and decision-making, and review grounding data for accuracy, relevance, timeliness and availability</li>
<li>Design the overall AI strategy using the AI adoption process from the Cloud Adoption Framework for Azure</li>
<li>Design multi-agent solutions with Microsoft 365 Copilot, Copilot Studio and Microsoft Foundry</li>
<li>Determine when to build custom agents, extend Microsoft 365 Copilot, or create custom AI models</li>
<li>Provide prompt library and prompt engineering guidelines and establish an AI Center of Excellence</li>
<li>Evaluate ROI and total cost of ownership, decide build/buy/extend, and implement a model router</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Design AI-powered business solutions (25-30%)</h3>
<ul>
<li>Design and customize Copilot in Dynamics 365 apps for customer experience and service</li>
<li>Design task, autonomous, and prompt-and-response agents, and propose Foundry Tools for requirements</li>
<li>Design Copilot Studio topics, agent flows and prompt actions, and choose NLP, conversational language understanding or generative orchestration</li>
<li>Design extensibility with custom Microsoft Foundry models, Model Context Protocol and Computer Use</li>
<li>Design agent behaviors including reasoning and voice mode, and agents across Microsoft 365, Teams and SharePoint</li>
<li>Orchestrate AI features across Dynamics 365 finance and supply chain and customer experience and service, Copilot for Sales and Service, and Power Platform AI</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Deploy AI-powered business solutions (40-45%)</h3>
<ul>
<li>Monitor and tune agents: monitoring tools and process, backlog and feedback analysis, performance metrics and telemetry interpretation</li>
<li>Manage testing: agent test process and metrics, custom-model validation, end-to-end test scenarios, and test cases built with Copilot</li>
<li>Design the ALM process for data, Copilot Studio agents, connectors and actions, Microsoft Foundry Agents service, custom models, and Dynamics 365 AI</li>
<li>Design agent and model security and governance, and access controls on grounding data and model tuning</li>
<li>Analyze and mitigate solution and AI vulnerabilities, including prompt manipulation</li>
<li>Review for responsible AI adherence, validate data residency and movement compliance, and design audit trails</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AB-100 Microsoft Certified Agentic AI Business Solutions Architect') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for Microsoft Exam AB-100 and become a Certified Agentic AI Business Solutions Architect. Plan, design and deploy secure multi-agent AI solutions with Copilot Studio, Microsoft Foundry and Dynamics 365 at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AB-100 course Singapore, Agentic AI Business Solutions Architect, Microsoft AI certification, Copilot Studio, Microsoft Foundry, AI agents, multi-agent solutions, Dynamics 365 AI, responsible AI, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ab-100-microsoft-certified-agentic-ai-business-solutions-architect') ON DUPLICATE KEY UPDATE value = VALUES(value);
