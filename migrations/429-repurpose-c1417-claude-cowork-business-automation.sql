-- Rename course C1417 from "Digital Transformation with Generative AI (GenAI)"
-- to "Claude Cowork for Business Automation" (2 days / 4 topics). Part of the
-- Claude AI series. name, overview, topics, meta (title/description/keyword),
-- cover, url_key. Price and duration unchanged (700 SG / 15h). Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1417');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Claude Cowork for Business Automation') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Automate your business with Claude Cowork for Business Automation. This hands-on 2-day course teaches you how to use Anthropic&rsquo;s Claude as a collaborative AI coworker to automate documents, data, communications and multi-step business workflows. Instead of doing repetitive work manually, you will delegate tasks to Claude, connect it to your tools and data, and build automations that run reliably with you in control.</p>
<p>Through practical projects, participants will identify automation opportunities, build Claude-powered workflows for reporting, research, drafting and data processing, connect Claude to files, apps and MCP tools, and add approvals, guardrails and monitoring. You will also learn to prompt effectively, keep humans in the loop, and apply AI securely with business data. By the end of the course, you will be able to design and deploy Claude-powered automations that save time and scale across your business.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Claude Cowork</h3>
<ul>
<li>Introduction to Claude and Business Automation</li>
<li>Setting Up Claude as a Collaborative AI Coworker</li>
<li>Identifying Automation Opportunities and Use Cases</li>
<li>Effective Prompting and Responsible, Secure AI Use</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building AI Workflows and Automations with Claude</h3>
<ul>
<li>Automating Documents, Drafting and Summarisation</li>
<li>Automating Data Processing and Analysis</li>
<li>Automating Research and Reporting</li>
<li>Designing Multi-Step Business Workflows</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Connecting Tools, Data and Teams</h3>
<ul>
<li>Connecting Claude to Files, Apps and Systems</li>
<li>Using MCP Tools and Integrations</li>
<li>Collaborating with Claude Across Teams</li>
<li>Adding Approvals, Guardrails and Human-in-the-Loop</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Deploying and Scaling Business Automation with Claude</h3>
<ul>
<li>Testing, Monitoring and Improving Automations</li>
<li>Governance, Security and Compliance</li>
<li>Scaling Automations Across the Business</li>
<li>Building an AI Automation Roadmap</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Claude Cowork for Business Automation') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Automate your business with Claude. Build Claude-powered workflows for documents, data, research and reporting in this hands-on 2-day Claude Cowork course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Claude, Claude Cowork, Business Automation, Anthropic, AI Automation, Workflow Automation, MCP, AI Productivity, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1417-20260712-045053.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'claude-cowork-for-business-automation') ON DUPLICATE KEY UPDATE value = VALUES(value);
