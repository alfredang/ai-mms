-- Rename course C1440 from "Explainable AI in Practice: Case Studies and
-- Applications" to "AI Security and Governance for AI Agents" (1 day / 2 topics).
-- Part of the AI Security series. name, overview, topics, meta
-- (title/description/keyword), cover, url_key. Price and duration unchanged
-- (350 SG / 7.5h). Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1440');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Security and Governance for AI Agents') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Deploy AI agents safely with AI Security and Governance for AI Agents. This hands-on 1-day course teaches you how to secure, govern and guardrail autonomous and agentic AI systems. As agents gain the ability to take actions, use tools and access data, they introduce new risks &mdash; and this course shows you how to manage them, from prompt injection and data leakage to access control, oversight and compliance.</p>
<p>Through practical scenarios, participants will identify agent-specific threats and failure modes, design guardrails, approvals and human-in-the-loop controls, secure tools, data and credentials, and apply governance frameworks and monitoring. You will also learn to test and red-team agents, and align deployments to responsible AI and regulatory expectations. By the end of the course, you will be able to secure and govern AI agents so they operate reliably, safely and in compliance.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Security and Governance for Agents</h3>
<ul>
<li>Introduction to AI Agents, Security and Governance</li>
<li>Agent-Specific Threats and Failure Modes</li>
<li>Prompt Injection, Jailbreaks and Data Leakage</li>
<li>Risk Assessment for Agentic Systems</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Securing, Governing and Guardrailing AI Agents</h3>
<ul>
<li>Designing Guardrails, Approvals and Human-in-the-Loop Controls</li>
<li>Securing Tools, Data, Identity and Credentials</li>
<li>Governance Frameworks, Monitoring and Audit Trails</li>
<li>Testing, Red-Teaming and Responsible, Compliant Deployment</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Security and Governance for AI Agents') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Secure and govern AI agents. Manage agent-specific risks, guardrails, access control and compliance for autonomous AI in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Security, AI Governance, AI Agents, Agentic AI, Responsible AI, Prompt Injection, Guardrails, AI Risk, AI Compliance, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1440-20260712-052149.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-security-and-governance-for-ai-agents') ON DUPLICATE KEY UPDATE value = VALUES(value);
