-- Repurpose course C1750 from "DP-420 Microsoft Certified Azure Cosmos DB
-- Developer Specialty" to "CompTIA SecAI+ Training". CompTIA certification
-- exam-prep course (NOT Microsoft). name, url_key, overview, exam domains with
-- official weightings, meta. Also moves it out of the Microsoft / Azure
-- certification categories into "CompTIA Certification Exam Prep" and lists it
-- under "AI Applications Series" (categories resolved by NAME so it is
-- partner-safe; ids differ per site). Price/duration unchanged.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1750');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'CompTIA SecAI+ Training') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>CompTIA SecAI+ (exam CY0-001) is a certification designed to help professionals secure, govern and responsibly integrate artificial intelligence into cybersecurity operations. It validates the skills needed to understand AI fundamentals in a security context, implement technical controls to protect AI systems, use AI to strengthen threat detection and response, and ensure compliance with global regulatory frameworks.</p>
<p>This course prepares cybersecurity practitioners for the CompTIA SecAI+ exam, building skills in securing AI models, data and pipelines, defending against adversarial attacks and prompt injection, applying AI and generative AI to security operations and automation, and governing AI with responsible AI, risk and compliance practices. A background of around three to four years in IT with two or more years of hands-on cybersecurity experience is recommended. To get certified, register for your CompTIA SecAI+ exam at a Pearson VUE test center.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>CompTIA SecAI+</strong> certification exam, covering all official exam domains and their weightings:</p>
<h3 class="course-topic-h3">Domain 1 Basic AI concepts related to cybersecurity (17%)</h3>
<ul>
<li>Understand AI, machine learning and generative AI fundamentals in a security context</li>
<li>Describe AI models, data, training and common AI use cases in cybersecurity</li>
<li>Identify AI-specific threats, risks and the AI attack surface</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Securing AI systems (40%)</h3>
<ul>
<li>Implement technical controls to protect AI models, data, pipelines and infrastructure</li>
<li>Defend against adversarial attacks, data poisoning, model theft and prompt injection</li>
<li>Secure the AI and machine learning lifecycle, supply chain and integrations</li>
<li>Apply identity, access, encryption and monitoring controls to AI systems</li>
</ul>
<h3 class="course-topic-h3">Domain 3 AI-assisted security (24%)</h3>
<ul>
<li>Use AI and generative AI tools for threat detection, hunting and analysis</li>
<li>Automate security operations, triage and incident response with AI</li>
<li>Apply AI to vulnerability management and security analytics</li>
</ul>
<h3 class="course-topic-h3">Domain 4 AI governance, risk, and compliance (19%)</h3>
<ul>
<li>Apply AI governance frameworks and responsible AI principles</li>
<li>Address global regulatory and compliance requirements for AI</li>
<li>Manage AI risk, ethics, transparency and accountability</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'CompTIA SecAI+ Training') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for the CompTIA SecAI+ (CY0-001) certification and learn to secure, govern and responsibly integrate AI into cybersecurity operations at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'CompTIA SecAI+, CY0-001, AI security certification, securing AI systems, AI-assisted security, AI governance, cybersecurity, prompt injection, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'comptia-secai-plus-training') ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id=cp.category_id AND v.store_id=0
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE cp.product_id=@e AND v.value IN ('Microsoft', 'Microsoft Certification Exam Prep', 'Azure', 'Azure Certification');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0 FROM catalog_category_entity_varchar v
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE v.store_id=0 AND v.value IN ('CompTIA Certification Exam Prep', 'AI Applications Series') AND @e IS NOT NULL;
