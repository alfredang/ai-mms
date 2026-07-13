-- Repurpose course C864 from "MS-700 Microsoft Teams Administrator Associate
-- Training" to "AB-730 Microsoft Certified AI Business Professional". Microsoft
-- certification exam-prep course. name, url_key, overview (short_description),
-- exam domains (description) with official skills-measured weightings, meta
-- (title/description/keyword). Price and duration unchanged. Cover regenerated
-- separately via CourseImage dialog.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C864');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AB-730 Microsoft Certified AI Business Professional') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>The AB-730 Microsoft Certified AI Business Professional course equips business users and professionals with the knowledge and skills required to use generative AI productivity tools such as Microsoft 365 Copilot and agents like Researcher and Analyst to improve daily work and make better decisions &mdash; without building AI apps or writing code. Participants will explore generative AI fundamentals, how Copilot keeps information private and secure, and how to apply responsible AI and data protection practices.</p>
<p>Learners will gain expertise in creating effective prompts, saving, scheduling and sharing prompts, managing conversations, and building and configuring Microsoft 365 Copilot agents. Additionally, the course covers drafting business documents, generating management summaries, moving insights between Microsoft 365 apps, and using Copilot for meetings and collaboration with Copilot Pages. By completing this course, participants will be prepared to work more productively and confidently with AI in everyday business contexts.</p>
<h2>Microsoft Learning Partner</h2>
<p>We are <strong>Authorised&nbsp;Microsoft Learning Partner (Org ID:&nbsp; 5238476).</strong> To get the official Microsoft certification, please register your certification exam at Pearson Vue Test Center.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>AB-730</strong> certification exam, covering all official skills measured and their approximate weightings:</p>
<h3 class="course-topic-h3">Domain 1 Understand generative AI fundamentals (25-30%)</h3>
<ul>
<li>Understand how Copilot keeps organizational information private and secure, and how context such as work files, web data or the app in use affects Copilot responses</li>
<li>Understand the difference between a chat experience and an agent experience, and the use case for creating your own agent</li>
<li>Understand the differences in features and capabilities of the Copilot experience across various Microsoft 365 apps</li>
<li>Identify common risks including fabrications, prompt injection and over-reliance</li>
<li>Select verification steps appropriate to the task, including citation checks and human review</li>
<li>Recognize and mitigate risks to sensitive data, and understand how data protection restricts prompt results</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Manage prompts and conversations by using AI (35-40%)</h3>
<ul>
<li>Create effective prompts and select appropriate resources to reference in a prompt</li>
<li>Save, schedule and share prompts in Microsoft 365 Copilot</li>
<li>Manage conversations: find previous conversations, delete and rename chats, and add a conversation to a notebook</li>
<li>Understand when to use the Agent Store versus creating a new agent</li>
<li>Create an agent by using a template and configure an agent that has knowledge</li>
<li>Configure agent settings such as instructions, capabilities and suggested prompts, and share an agent with team members</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Draft and analyze business content by using AI (25-30%)</h3>
<ul>
<li>Create a new document from a prompt, and generate a document from an existing document</li>
<li>Generate a management summary based on a document</li>
<li>Move data and insights between Microsoft 365 apps</li>
<li>Use Microsoft 365 Copilot for meetings</li>
<li>Use Copilot Pages for collaboration</li>
<li>Describe how Copilot uses memory and instructions</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AB-730 Microsoft Certified AI Business Professional') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for Microsoft Exam AB-730 and become a Certified AI Business Professional. Learn to use Microsoft 365 Copilot, craft prompts, manage agents, and draft business content with AI at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AB-730 course Singapore, AI Business Professional, Microsoft AI certification, Microsoft 365 Copilot, generative AI, prompt engineering, Copilot agents, responsible AI, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ab-730-microsoft-certified-ai-business-professional') ON DUPLICATE KEY UPDATE value = VALUES(value);
