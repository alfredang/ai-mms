-- Rename course C11 from "Search Engine Optimisation SEO Essential Training" to
-- "Generative AI for SEO" (1 day / 2 topics). name, overview, topics, meta
-- (title/description/keyword), cover, url_key. Price and duration unchanged
-- (350 SG / 7.5h). Part of the Generative AI series. Store scope 0. Idempotent.
-- No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C11');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for SEO') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Supercharge your search rankings with Generative AI for SEO. This hands-on 1-day course teaches you how to use generative AI tools such as ChatGPT, Claude and Gemini to research keywords, plan content, write and optimise pages, and scale your SEO workflow. Instead of doing everything manually, you will let AI accelerate keyword research, content creation and technical SEO while you keep control of strategy and quality.</p>
<p>Through practical projects, participants will use generative AI to build keyword and topic clusters, generate optimised titles, meta descriptions and on-page content, create briefs and outlines, and audit and improve existing pages. You will also learn how to prompt effectively, fact-check AI output and keep content aligned with search intent and Google guidelines. By the end of the course, you will be able to plan, create and optimise SEO content faster with a generative AI workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for SEO</h3>
<ul>
<li>Introduction to SEO and Generative AI</li>
<li>Setting Up AI Tools (ChatGPT, Claude, Gemini) for SEO</li>
<li>AI-Powered Keyword Research and Topic Clusters</li>
<li>Understanding Search Intent and Content Planning with AI</li>
<li>Effective Prompting for SEO Tasks</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Creating and Optimising SEO Content with Generative AI</h3>
<ul>
<li>Generating Titles, Meta Descriptions and On-Page Content</li>
<li>Writing Briefs, Outlines and Long-Form Content with AI</li>
<li>On-Page and Technical SEO Optimisation with AI</li>
<li>Auditing and Improving Existing Pages</li>
<li>Fact-Checking, Quality Control and Aligning with Google Guidelines</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for SEO') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Boost your search rankings with generative AI. Use ChatGPT, Claude and Gemini for keyword research, content creation and on-page optimisation in this hands-on 1-day Generative AI for SEO course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, SEO, AI SEO, ChatGPT, Claude, Gemini, keyword research, content optimisation, search engine optimisation, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C11-20260712-033100.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-seo') ON DUPLICATE KEY UPDATE value = VALUES(value);
