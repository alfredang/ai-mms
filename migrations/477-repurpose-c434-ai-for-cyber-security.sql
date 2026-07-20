-- Repurpose course C434 from "Network Penetration Testing for Beginners" to
-- "AI for Cyber Security" (1 day / 2 topics — generative AI and AI agents for
-- threat detection, phishing analysis, security operations, incident response
-- and vulnerability management). name, overview, topics, meta, url_key,
-- image labels, cover. Price ($350, 1 day) and duration intentionally kept.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C434.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C434');
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
SELECT 4, @a_name, 0, @e, 'AI for Cyber Security' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Stay ahead of today&rsquo;s cyber threats with our hands-on AI for Cyber Security course. AI is transforming how organisations defend themselves&mdash;from spotting phishing emails and analysing suspicious logs to automating threat intelligence, incident response and vulnerability management. In this practical 1-day course, you will learn what modern AI tools can do for cyber defence, and how to apply generative AI and AI agents to your daily security work&mdash;no programming background required.</p>
<p>Through guided exercises, participants will use AI assistants to detect phishing and social-engineering attempts, analyse security alerts and logs, summarise threat intelligence, draft incident reports and security policies, and build simple AI workflows for routine security operations. You will also learn the risks AI itself introduces&mdash;deepfakes, AI-powered attacks, data leakage&mdash;and how to use AI safely and responsibly. By the end of the course, you will be able to put AI to work to strengthen your organisation&rsquo;s security posture and respond to threats faster.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Introduction to AI for Cyber Security</h3>
<ul>
<li>The AI Landscape: From Generative AI to AI Agents</li>
<li>AI Use Cases Across the Cyber Defence Lifecycle</li>
<li>Hands-On with AI Assistants: ChatGPT, Claude and Copilot</li>
<li>Detecting Phishing, Scams and Social Engineering with AI</li>
<li>AI-Powered Threats: Deepfakes, Data Leakage and Responsible AI Use</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Applying AI to Security Operations</h3>
<ul>
<li>AI-Assisted Log Analysis and Anomaly Detection</li>
<li>Summarising Threat Intelligence and Security Alerts with AI</li>
<li>AI for Incident Response, Reporting and Playbooks</li>
<li>Vulnerability Management and Security Policy Drafting with AI</li>
<li>Building Simple AI Workflows for Day-to-Day Security Tasks</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI for Cyber Security' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master AI for Cyber Security in this hands-on 1-day course. Apply AI to phishing detection, log analysis, threat intelligence, incident response and vulnerability management at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI for Cyber Security, Cyber Security AI Course, Generative AI Security, AI Agents Security, Phishing Detection AI, Threat Intelligence AI, Incident Response AI, Log Analysis AI, Security Operations AI, Cyber Defence Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'ai-for-cyber-security' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C434-20260717-090946.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image alt labels still carried the old "Network Penetration Testing" title.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI for Cyber Security' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI for Cyber Security' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI for Cyber Security' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_img, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
