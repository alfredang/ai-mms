-- Repurpose course C1768 from "MS-721 Microsoft Certified Collaboration
-- Communications Systems Engineer" to "AB-900 Microsoft 365 Copilot and Agent
-- Administration Fundamentals". Microsoft certification exam-prep course. name,
-- url_key, overview (short_description), exam domains (description) with official
-- skills-measured weightings, meta (title/description/keyword). Price and
-- duration unchanged. Cover regenerated separately via CourseImage dialog.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1768');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AB-900 Microsoft 365 Copilot and Agent Administration Fundamentals') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>The AB-900 Microsoft 365 Copilot and Agent Administration Fundamentals course equips learners with the foundational knowledge required to administer Microsoft 365 Copilot and agents securely and effectively. Participants will explore the core features and objects of Microsoft 365 services across the admin centers, Zero Trust security principles, Microsoft Entra ID, conditional access and single sign-on.</p>
<p>Learners will gain expertise in data protection and governance with Microsoft Purview &mdash; sensitivity labels, data loss prevention, Insider Risk Management and DSPM for AI &mdash; and in how Copilot accesses data and protects against oversharing risks. Additionally, the course covers basic administrative tasks for Copilot and agents, including license assignment, usage monitoring, prompt management, and agent creation and approval. By completing this course, participants will be prepared to administer Microsoft 365 Copilot and agents with confidence.</p>
<h2>Microsoft Learning Partner</h2>
<p>We are <strong>Authorised&nbsp;Microsoft Learning Partner (Org ID:&nbsp; 5238476).</strong> To get the official Microsoft certification, please register your certification exam at Pearson Vue Test Center.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>AB-900</strong> certification exam, covering all official skills measured and their approximate weightings:</p>
<h3 class="course-topic-h3">Domain 1 Identify the core features and objects of Microsoft 365 services (30-35%)</h3>
<ul>
<li>Identify core objects across the Microsoft 365, Exchange, SharePoint and Teams admin centers, and how license types affect access to features</li>
<li>Identify roles and permissions for SharePoint sites</li>
<li>Explain core Zero Trust principles, authorization, authentication methods, and threat protection with Microsoft Defender XDR</li>
<li>Understand Microsoft Entra ID, conditional access policies and single sign-on (SSO)</li>
<li>Troubleshoot common sign-in issues (MFA, conditional access, risky sign-ins) and interpret Identity Secure Score</li>
<li>Review audit logs, and understand Privileged Identity Management (PIM), App registrations and Enterprise apps</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Understand data protection and governance tasks for Microsoft 365 and Copilot (35-40%)</h3>
<ul>
<li>Understand Microsoft Purview capabilities: Information Protection, Data Loss Prevention (DLP), Insider Risk Management, Communication Compliance, DSPM for AI and Data Lifecycle Management</li>
<li>Understand sensitivity labels, data classification and retention</li>
<li>Understand how Copilot accesses data, how Microsoft Graph influences responses, and how Copilot uses permissions and controls to protect against risks</li>
<li>Identify data protection and governance risks using Compliance Manager, Data Explorer, Insider Risk Management, and DLP and Communication Compliance alerts</li>
<li>Discover and manage AI activity with DSPM for AI, and search files and emails with Content search in eDiscovery</li>
<li>Identify and monitor oversharing in SharePoint, run data access governance reports, and use SharePoint Advanced Management</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Perform basic administrative tasks for Copilot and agents (25-30%)</h3>
<ul>
<li>Compare the built-in capabilities of Copilot and agents, and monthly versus pay-as-you-go license models</li>
<li>Identify which Copilot features can be enabled or disabled, and use cases for Researcher, Analyst and custom agents</li>
<li>Assign Copilot licenses and manage pay-as-you-go billing policies</li>
<li>Monitor Copilot usage and adoption with Copilot Analytics and the Microsoft 365 admin center, and manage prompts (save, share, schedule, delete)</li>
<li>Configure user access to agents, create an agent, and understand the agent approval process</li>
<li>Monitor agents (usage, operational insights and lifecycle) using the Microsoft 365 and Microsoft Power Platform admin centers</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AB-900 Microsoft 365 Copilot and Agent Administration Fundamentals') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for Microsoft Exam AB-900 and master Microsoft 365 Copilot and Agent Administration Fundamentals. Learn core Microsoft 365 services, Microsoft Purview data protection, and Copilot and agent administration at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AB-900 course Singapore, Microsoft 365 Copilot Administration, Microsoft AI certification, Microsoft Purview, Copilot agents, Microsoft Entra, data protection, Microsoft 365 admin, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ab-900-microsoft-365-copilot-and-agent-administration-fundamentals') ON DUPLICATE KEY UPDATE value = VALUES(value);
