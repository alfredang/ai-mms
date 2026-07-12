-- Rename course C1311 from "Mastering Sustainability Reporting and Engineering
-- Strategies for Senior Executives" to "Generative AI for Sustainability
-- Reporting" (2 days / 4 topics). Part of the Generative AI series. name,
-- overview, topics, meta (title/description/keyword), cover, url_key. Price and
-- duration unchanged (700 SG / 15h). Store scope 0. Idempotent. No content line
-- ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1311');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Sustainability Reporting') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Produce ESG and sustainability reports faster with Generative AI for Sustainability Reporting. This hands-on 2-day course teaches you how to use generative AI tools such as ChatGPT, Claude and Gemini to gather and analyse ESG data, draft disclosures, and align reports to leading frameworks. Instead of writing everything manually, you will let AI accelerate research, data analysis and drafting while you ensure accuracy, materiality and compliance.</p>
<p>Through practical projects, participants will use AI to collect and structure ESG data, calculate and interpret metrics, draft narrative disclosures, and map content to frameworks such as GRI, SASB, TCFD and ISSB. You will also learn to prompt effectively, fact-check and validate AI output, and apply AI responsibly and transparently for sustainability reporting. By the end of the course, you will be able to prepare credible, framework-aligned sustainability reports faster with a generative AI workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for Sustainability Reporting</h3>
<ul>
<li>Introduction to ESG, Sustainability Reporting and Generative AI</li>
<li>Setting Up AI Tools for Reporting</li>
<li>Overview of Frameworks (GRI, SASB, TCFD, ISSB)</li>
<li>Effective Prompting and Responsible, Transparent AI Use</li>
</ul>
<h3 class="course-topic-h3">Topic 2 AI for ESG Data Collection and Analysis</h3>
<ul>
<li>Gathering and Structuring ESG Data with AI</li>
<li>Calculating and Interpreting Metrics and Emissions</li>
<li>Conducting Materiality and Gap Analysis</li>
<li>Visualising and Summarising ESG Data</li>
</ul>
<h3 class="course-topic-h3">Topic 3 AI for Drafting and Structuring Reports</h3>
<ul>
<li>Drafting Narrative Disclosures and Executive Summaries</li>
<li>Structuring Reports and Sections with AI</li>
<li>Ensuring Consistency, Tone and Readability</li>
<li>Fact-Checking and Validating AI Output</li>
</ul>
<h3 class="course-topic-h3">Topic 4 AI for Compliance, Frameworks and Continuous Reporting</h3>
<ul>
<li>Mapping Content to GRI, SASB, TCFD and ISSB</li>
<li>Assurance-Readiness, Audit Trails and Governance</li>
<li>Automating Recurring and Multi-Year Reporting</li>
<li>Building an Efficient Sustainability Reporting Workflow</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Sustainability Reporting') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Produce ESG and sustainability reports faster with generative AI. Analyse ESG data, draft disclosures and align to GRI, SASB, TCFD and ISSB in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, Sustainability Reporting, ESG, GRI, SASB, TCFD, ISSB, ESG Reporting, AI Reporting, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1311-20260712-044227.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-sustainability-reporting') ON DUPLICATE KEY UPDATE value = VALUES(value);
