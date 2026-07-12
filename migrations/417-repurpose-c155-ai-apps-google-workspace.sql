-- Rename course C155 from "Google Cloud Certified Professional Google Workspace
-- Administrator Training" to "AI Applications to Google Workspace"
-- (2 days / 4 topics). Part of the AI Applications series. name, overview,
-- topics, meta (title/description/keyword), cover, url_key. Price and duration
-- unchanged (700 SG / 15h). Store scope 0. Idempotent. No content line ends in a
-- semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C155');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Applications to Google Workspace') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Work smarter across Google Workspace with AI Applications to Google Workspace. This hands-on 2-day course teaches you how to use Gemini and generative AI inside Gmail, Docs, Sheets, Slides, Meet and Drive to write, summarise, analyse and create faster. Instead of doing everything manually, you will apply AI to real workplace tasks and build practical, everyday productivity habits with Google Workspace.</p>
<p>Through practical projects, participants will draft and summarise emails and documents, generate slides and images, analyse and visualise data in Sheets, run AI-assisted meetings, and build simple automations that connect Workspace apps. You will also learn to prompt effectively, fact-check AI output and apply AI responsibly and securely at work. By the end of the course, you will be able to apply AI across Google Workspace to boost your everyday productivity and output.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI in Google Workspace</h3>
<ul>
<li>Introduction to Generative AI and Gemini in Workspace</li>
<li>Setting Up and Accessing AI Across Workspace Apps</li>
<li>Effective Prompting for Everyday Work Tasks</li>
<li>Responsible, Secure and Private Use of AI at Work</li>
</ul>
<h3 class="course-topic-h3">Topic 2 AI in Docs, Slides and Gmail</h3>
<ul>
<li>Drafting, Rewriting and Summarising in Docs</li>
<li>Generating Slides, Layouts and Images in Slides</li>
<li>Writing, Replying and Summarising Emails in Gmail</li>
<li>Reviewing and Refining AI-Generated Content</li>
</ul>
<h3 class="course-topic-h3">Topic 3 AI in Sheets and Data Analysis</h3>
<ul>
<li>Generating Formulas, Tables and Insights in Sheets</li>
<li>Analysing and Summarising Data with AI</li>
<li>Creating Charts and Visualisations</li>
<li>Cleaning and Organising Data with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 4 AI-Powered Workflows and Automation in Workspace</h3>
<ul>
<li>AI-Assisted Meetings and Notes in Google Meet</li>
<li>Organising and Searching Drive with AI</li>
<li>Connecting Apps and Building Simple Automations</li>
<li>Designing Practical AI Productivity Workflows</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Applications to Google Workspace') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Apply AI across Google Workspace. Use Gemini in Gmail, Docs, Sheets, Slides and Meet to write, analyse and automate everyday work in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI Applications, Google Workspace, Gemini, Generative AI, Gmail, Google Docs, Google Sheets, AI Productivity, Workplace AI, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C155-20260712-041119.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-applications-to-google-workspace') ON DUPLICATE KEY UPDATE value = VALUES(value);
