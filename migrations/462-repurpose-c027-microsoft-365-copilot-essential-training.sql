-- Repurpose course C027 from "Word Essential Training" to
-- "Microsoft 365 Copilot Essential Training" (1 day / 2 topics — AI-assisted
-- productivity across Word, Excel, PowerPoint, Outlook and Teams).
-- name, overview, topics, meta, url_key. Price ($350) and duration
-- (7.5h = 1 day) already correct — untouched. Clears per-store overrides of
-- the rewritten attributes so partner store scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C027.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C027');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Microsoft 365 Copilot Essential Training' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Supercharge your daily productivity with Microsoft 365 Copilot Essential Training. This hands-on 1-day course shows you how Copilot&mdash;the AI assistant built into Microsoft 365&mdash;transforms the way you write documents, build presentations, analyse data, manage email and run meetings. You will learn to craft effective prompts, use Copilot Chat to research and summarise across your files, draft and rewrite documents in Word, and generate polished presentations in PowerPoint from a simple brief.</p>
<p>Through practical exercises, participants will apply Copilot across the everyday Microsoft 365 apps&mdash;analysing data and generating formulas in Excel, drafting and summarising email threads in Outlook, and capturing meeting recaps and action items in Teams. You will also learn prompt best practices and how to use AI responsibly with your organisation''s data. By the end of the course, you will be able to work confidently with Copilot to complete routine tasks in a fraction of the time.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Getting Started with Microsoft 365 Copilot</h3>
<ul>
<li>Introduction to Microsoft 365 Copilot and How It Works</li>
<li>Writing Effective Prompts for Better Results</li>
<li>Researching and Summarising with Copilot Chat</li>
<li>Drafting, Rewriting and Summarising Documents in Word</li>
<li>Generating and Refining Presentations in PowerPoint</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Copilot Across Your Everyday Work Apps</h3>
<ul>
<li>Analysing Data and Generating Formulas in Excel</li>
<li>Drafting Emails and Summarising Threads in Outlook</li>
<li>Meeting Recaps and Action Items in Teams</li>
<li>Building End-to-End Copilot Workflows Across Apps</li>
<li>Responsible AI, Data Privacy and Best Practices</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Microsoft 365 Copilot Essential Training' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Microsoft 365 Copilot in this hands-on 1-day course. Learn effective prompting, Copilot Chat, and AI-assisted work in Word, Excel, PowerPoint, Outlook and Teams at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Microsoft 365 Copilot, Copilot Training, Copilot Chat, AI Productivity, Copilot Word, Copilot Excel, Copilot PowerPoint, Copilot Outlook, Copilot Teams, Prompt Writing, Microsoft 365 Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'microsoft-365-copilot-essential-training' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
