-- Rename course C21 from "Mailchimp Email Marketing Training" to
-- "Agentic AI for Email Marketing" (1 day / 2 topics). Part of the Agentic AI
-- series. name, overview, topics, meta (title/description/keyword), cover,
-- url_key. Price and duration unchanged (350 SG / 7.5h). Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C21');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Agentic AI for Email Marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Automate and scale your email marketing with Agentic AI for Email Marketing. This hands-on 1-day course teaches you how to use AI agents and generative AI tools to plan campaigns, write and personalise emails, build automated flows and analyse results. Instead of manually crafting every email and sequence, you will let AI agents handle research, drafting, segmentation and optimisation while you steer the strategy.</p>
<p>Through practical projects, participants will use AI to generate campaign ideas and copy, personalise emails at scale, design automated nurture and re-engagement flows, and analyse and improve performance. You will also learn to prompt effectively, keep brand voice consistent and stay compliant with email and privacy best practices. By the end of the course, you will be able to plan, create and automate high-performing email marketing campaigns with an agentic AI workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Agentic AI for Email Marketing</h3>
<ul>
<li>Introduction to Email Marketing and Agentic AI</li>
<li>Setting Up AI Tools and Agents for Email Marketing</li>
<li>Generating Campaign Ideas, Subject Lines and Copy with AI</li>
<li>Personalisation and Segmentation with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Automating Email Campaigns with AI Agents</h3>
<ul>
<li>Designing Automated Nurture and Re-Engagement Flows</li>
<li>Building Agentic Workflows to Run Campaigns End to End</li>
<li>A/B Testing, Analytics and AI-Driven Optimisation</li>
<li>Brand Voice, Deliverability and Compliance Best Practices</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Agentic AI for Email Marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Automate email marketing with agentic AI. Generate copy, personalise at scale and build automated campaign flows with AI agents in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Agentic AI, Email Marketing, AI Agents, Marketing Automation, Generative AI, Email Campaigns, Personalisation, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C21-20260712-033650.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'agentic-ai-for-email-marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);
