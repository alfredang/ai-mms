-- Repurpose course C711 from "Microsoft Azure Developer Associate (AZ-204)" to
-- "AB-731 Microsoft Certified AI Transformation Leader". Microsoft certification
-- exam-prep course. name, url_key, overview (short_description), exam domains
-- (description) with official skills-measured weightings, meta
-- (title/description/keyword). Price and duration unchanged. Cover regenerated
-- separately via CourseImage dialog.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C711');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AB-731 Microsoft Certified AI Transformation Leader') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>The AB-731 Microsoft Certified AI Transformation Leader course equips business leaders and decision-makers with the knowledge and skills required to recognize AI opportunities, plan AI adoption, and drive innovation with Microsoft 365 Copilot and Microsoft Foundry Tools &mdash; no coding required. Participants will explore the business value of generative AI, prompt engineering, grounding and retrieval-augmented generation, and how to align AI investments with business goals.</p>
<p>Learners will gain expertise in mapping business processes to Microsoft 365 Copilot, Copilot Studio, Microsoft Graph and Foundry Tools, championing responsible AI, and building an organization-wide adoption strategy with governance, an AI council and a champions program. Additionally, the course covers Copilot licensing and Foundry subscription models, AI security and cost considerations. By completing this course, participants will be prepared to lead AI transformation and adoption across their teams and organization.</p>
<h2>Microsoft Learning Partner</h2>
<p>We are <strong>Authorised&nbsp;Microsoft Learning Partner (Org ID:&nbsp; 5238476).</strong> To get the official Microsoft certification, please register your certification exam at Pearson Vue Test Center.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>AB-731</strong> certification exam, covering all official skills measured and their approximate weightings:</p>
<h3 class="course-topic-h3">Domain 1 Identify the business value of generative AI solutions (35-40%)</h3>
<ul>
<li>Describe how generative AI differs from other types of AI, and select a generative AI solution to meet a business need</li>
<li>Describe AI model types, including pretrained and fine-tuned models</li>
<li>Explain cost drivers including tokens and ROI, and challenges such as fabrications, reliability and bias</li>
<li>Identify when generative AI provides business value, including scalability and automation</li>
<li>Apply prompt engineering, grounding requirements and retrieval-augmented generation (RAG)</li>
<li>Understand the impact of data quality, secure AI, machine learning value and lifecycle, and AI security considerations</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Identify benefits, capabilities, and opportunities for Microsoft AI apps and services (35-40%)</h3>
<ul>
<li>Map business processes and use cases to Microsoft 365 Copilot and Microsoft Copilot</li>
<li>Understand capabilities across Copilot versions, Copilot Chat web and mobile, and Microsoft 365 apps</li>
<li>Understand Microsoft Copilot Studio and Microsoft Graph capabilities</li>
<li>Identify benefits of an integrated Microsoft AI solution, including risk mitigation and safety</li>
<li>Identify when to use Researcher or Analyst in Copilot, and when to build, buy or extend</li>
<li>Map use cases to Foundry Tools, match an AI model to a business need, and understand Microsoft Foundry benefits</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Identify an implementation and adoption strategy for Microsoft AI apps and services (20-25%)</h3>
<ul>
<li>Explain the importance of responsible AI and establish AI governance principles</li>
<li>Establish an AI council for strategy, oversight and cross-functional alignment</li>
<li>Ensure solutions meet responsible AI standards: fairness, reliability, safety, privacy, security, inclusiveness, transparency and accountability</li>
<li>Plan AI adoption: establish an adoption team, identify common barriers, and run an AI champions program</li>
<li>Understand potential impacts to data, security, privacy and cost</li>
<li>Understand Copilot license types and Foundry Tools subscription models</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AB-731 Microsoft Certified AI Transformation Leader') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for Microsoft Exam AB-731 and become a Certified AI Transformation Leader. Learn to identify AI business value, drive adoption, and lead responsible AI with Microsoft 365 Copilot and Foundry Tools at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AB-731 course Singapore, AI Transformation Leader, Microsoft AI certification, Microsoft 365 Copilot, Copilot Studio, Microsoft Foundry, generative AI, responsible AI, AI adoption, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ab-731-microsoft-certified-ai-transformation-leader') ON DUPLICATE KEY UPDATE value = VALUES(value);
