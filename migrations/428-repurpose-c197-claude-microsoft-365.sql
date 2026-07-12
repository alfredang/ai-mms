-- Rename course C197 from "Create Infographics with PowerPoint" to
-- "Claude for Microsoft 365" (1 day / 2 topics). Part of the Claude AI series.
-- name, overview, topics, meta (title/description/keyword), cover, url_key.
-- Price and duration unchanged (350 SG / 7.5h). Store scope 0. Idempotent. No
-- content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C197');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Claude for Microsoft 365') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Work smarter across Microsoft 365 with Claude for Microsoft 365. This hands-on 1-day course teaches you how to use Anthropic&rsquo;s Claude to draft, summarise, analyse and create across Word, Excel, PowerPoint, Outlook and Teams. Instead of doing everything manually, you will use Claude as an AI assistant to speed up writing, data analysis, slide creation and email &mdash; while you stay in control of quality and accuracy.</p>
<p>Through practical projects, participants will use Claude to write and refine documents, summarise long content, analyse and explain spreadsheet data, generate slide outlines and content, and draft and reply to emails. You will also learn to prompt effectively, connect Claude to your files, fact-check output, and apply AI responsibly and securely with work data. By the end of the course, you will be able to boost your everyday Microsoft 365 productivity with Claude.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Claude for Microsoft 365</h3>
<ul>
<li>Introduction to Claude and Microsoft 365</li>
<li>Setting Up and Connecting Claude to Your Files and Apps</li>
<li>Effective Prompting for Everyday Work Tasks</li>
<li>Responsible, Secure and Private Use of AI at Work</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Boosting Productivity Across Microsoft 365 with Claude</h3>
<ul>
<li>Writing, Rewriting and Summarising in Word</li>
<li>Analysing and Explaining Data in Excel</li>
<li>Generating Slide Outlines and Content for PowerPoint</li>
<li>Drafting and Replying to Email in Outlook and Teams</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Claude for Microsoft 365') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Boost your Microsoft 365 productivity with Claude. Use Anthropic Claude to write, analyse and create across Word, Excel, PowerPoint and Outlook in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Claude, Microsoft 365, Anthropic, AI Productivity, Word, Excel, PowerPoint, Outlook, Office AI, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C197-20260712-044924.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'claude-for-microsoft-365') ON DUPLICATE KEY UPDATE value = VALUES(value);
