-- Rename course C819 from "Automating IT Processes with Google Apps Script: A
-- Practical Approach" to "AI Vibe Coding for Google Apps Script" (2 days /
-- 4 topics). Part of the AI Vibe Coding series (badge). name, overview, topics,
-- meta, cover, url_key, badge. Price and duration unchanged (700 SG / 15h).
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C819');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Vibe Coding for Google Apps Script') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Automate Google Workspace with AI Vibe Coding for Google Apps Script. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write Google Apps Script that automates Sheets, Docs, Gmail, Drive and Calendar. Instead of memorising the Apps Script API, you will vibe code &mdash; describing what you want in plain language and letting AI generate, refactor and debug your scripts while you design the automation.</p>
<p>Through practical projects, participants will set up the Apps Script environment, automate spreadsheets and documents, build custom functions, menus and triggers, connect to Gmail, Drive and external APIs, and deploy simple web apps &mdash; all with an AI pair programmer at their side. You will also learn to review, test and secure AI-generated scripts so your automations run reliably. By the end of the course, you will be able to automate your Google Workspace faster with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Google Apps Script</h3>
<ul>
<li>Introduction to Google Apps Script and Vibe Coding</li>
<li>Setting Up Apps Script and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Generating and Running Your First Script with AI</li>
<li>Effective Prompting for Apps Script Code</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Automating Google Workspace with AI</h3>
<ul>
<li>Automating Google Sheets and Docs</li>
<li>Working with Gmail, Drive and Calendar</li>
<li>Custom Functions, Menus and Triggers</li>
<li>Debugging and Explaining Scripts with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Building Integrations and Web Apps with AI</h3>
<ul>
<li>Connecting to External APIs and Services</li>
<li>Handling Data, JSON and Authentication</li>
<li>Building Simple Web Apps and Dialogs</li>
<li>Scheduling and Event-Driven Automation</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Deploying and Scaling Apps Script Automations with AI</h3>
<ul>
<li>Reviewing, Testing and Securing AI-Generated Scripts</li>
<li>Managing Permissions and Best Practices</li>
<li>Deploying and Sharing Automations</li>
<li>Scaling Workspace Automation Workflows</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Vibe Coding for Google Apps Script') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Automate Google Workspace with AI vibe coding. Write Apps Script for Sheets, Docs, Gmail and Drive using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Vibe Coding, Google Apps Script, Google Workspace, Automation, Sheets, Gmail, Cursor, GitHub Copilot, Claude, AI Coding, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C819-20260712-045702.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-vibe-coding-for-google-apps-script') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_badge, 0, @e, 'AI Vibe Coding Series') ON DUPLICATE KEY UPDATE value = VALUES(value);
