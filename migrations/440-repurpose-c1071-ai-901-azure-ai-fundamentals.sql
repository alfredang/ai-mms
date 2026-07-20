-- Repurpose course C1071 from "AI-900 Azure AI Fundamentals Training" to
-- "AI-901 Microsoft Azure AI Fundamentals". Microsoft certification exam-prep
-- course. name, url_key, overview (short_description), exam domains
-- (description) with official skills-measured weightings, meta
-- (title/description/keyword). Price and duration unchanged. Cover regenerated
-- separately via CourseImage dialog.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1071');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI-901 Microsoft Azure AI Fundamentals') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>The AI-901 Microsoft Azure AI Fundamentals course equips learners with the knowledge and foundational technical skills required to understand and build AI solutions on Microsoft Azure. Participants will explore core AI concepts and capabilities, the principles of responsible AI, how generative AI models work, and how to choose the right model, deployment options and configuration for a workload.</p>
<p>Learners will gain hands-on expertise implementing AI solutions with Microsoft Foundry &mdash; creating effective prompts, deploying models, building lightweight chat and agent applications with the Foundry SDK, and adding text analysis, speech, computer vision, image generation and information extraction capabilities. By completing this course, participants will be prepared to work confidently with Azure AI services and Microsoft Foundry to deliver practical AI solutions.</p>
<h2>Microsoft Learning Partner</h2>
<p>We are <strong>Authorised&nbsp;Microsoft Learning Partner (Org ID:&nbsp; 5238476).</strong> To get the official Microsoft certification, please register your certification exam at Pearson Vue Test Center.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>AI-901</strong> certification exam, covering all official skills measured and their approximate weightings:</p>
<h3 class="course-topic-h3">Domain 1 Identify AI concepts and capabilities (40-45%)</h3>
<ul>
<li>Describe the principles of responsible AI: fairness, reliability and safety, privacy and security, inclusiveness, transparency and accountability</li>
<li>Describe how generative AI models work, and identify an appropriate AI model based on capabilities</li>
<li>Identify appropriate model deployment options and configuration parameters</li>
<li>Identify scenarios for common AI workloads, including generative and agentic AI, text analysis, speech, computer vision and information extraction</li>
<li>Describe common text analysis techniques such as keyword extraction, entity detection, sentiment analysis and summarization</li>
<li>Identify features and capabilities of speech recognition and synthesis, computer vision, image generation, and extracting information from text, images, audio and video</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Implement AI solutions by using Microsoft Foundry (55-60%)</h3>
<ul>
<li>Create effective system and user prompts, deploy a model, and interact with it in the Foundry portal</li>
<li>Create a lightweight chat client with the Foundry SDK, and create and test a single-agent solution</li>
<li>Build a lightweight application that includes text analysis, and respond to spoken prompts using a deployed multimodal model</li>
<li>Build a lightweight application by using Azure Speech in Foundry Tools</li>
<li>Interpret visual input and create new visual outputs using deployed multimodal and generative models, and build vision-enabled applications</li>
<li>Extract information from documents, forms, images, audio and video using Azure Content Understanding in Foundry Tools</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI-901 Microsoft Azure AI Fundamentals') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for Microsoft Exam AI-901 and earn the Azure AI Fundamentals certification. Learn AI concepts, responsible AI, and build AI solutions with Microsoft Foundry at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI-901 course Singapore, Azure AI Fundamentals, Microsoft AI certification, Microsoft Foundry, generative AI, computer vision, responsible AI, Azure AI, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-901-microsoft-azure-ai-fundamentals') ON DUPLICATE KEY UPDATE value = VALUES(value);
