-- Rename course C817 from "Google Sheet Essential Training" to "AI Application
-- for Google Sheet" (1 day / 2 topics). name, overview, topics, meta
-- (title/description/keyword), cover, url_key. Price and duration unchanged
-- (350 SG / 7.5h). Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C817');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Application for Google Sheet') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Work faster with your data using AI Application for Google Sheet. This hands-on 1-day course teaches you how to use Gemini and generative AI inside Google Sheets to build formulas, clean and organise data, analyse trends and create charts &mdash; all in plain language. Instead of memorising functions, you will describe what you want and let AI help you get answers and insights from your spreadsheets.</p>
<p>Through practical projects, participants will use AI to generate and explain formulas, transform and tidy data, summarise and analyse datasets, and build tables and visualisations. You will also learn to prompt effectively, validate AI output and apply AI safely to real work data. By the end of the course, you will be able to use AI to work smarter and faster in Google Sheets.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI in Google Sheets</h3>
<ul>
<li>Introduction to Generative AI and Gemini in Google Sheets</li>
<li>Setting Up and Accessing AI in Sheets</li>
<li>Generating and Explaining Formulas with AI</li>
<li>Effective Prompting for Spreadsheet Tasks</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Analysing and Automating Data with AI in Sheets</h3>
<ul>
<li>Cleaning, Transforming and Organising Data with AI</li>
<li>Summarising and Analysing Datasets</li>
<li>Creating Tables, Charts and Visualisations</li>
<li>Validating AI Output and Applying AI Safely to Work Data</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Application for Google Sheet') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Use AI in Google Sheets. Generate formulas, clean data, analyse trends and build charts with Gemini and generative AI in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Application, Google Sheets, Gemini, Generative AI, Spreadsheets, Data Analysis, Formulas, AI Productivity, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C817-20260712-041402.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-application-for-google-sheet') ON DUPLICATE KEY UPDATE value = VALUES(value);
