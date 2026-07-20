-- Repurpose course C1468 to "Generative AI for Digital Marketing" (2 days /
-- 4 topics). This becomes the canonical GenAI Digital Marketing course; the
-- old C429 was disabled in migration 372, freeing the slug. NO AI Vibe Coding
-- badge. Per-market price (700/2200/3000) direct on prod. Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1468');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Digital Marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Supercharge your marketing with Generative AI for Digital Marketing. This hands-on 2-day course teaches you how to use generative AI tools such as ChatGPT, Claude and image and video generators to plan campaigns, create content and accelerate your digital marketing across channels. You will learn to write effective prompts, generate copy and visuals, and build an AI-assisted marketing workflow that saves time and improves results.</p>
<p>Through practical projects, participants will use generative AI to research audiences, write ad, email and social copy, create images and videos, plan and optimise campaigns, and analyse performance. By the end of the course, you will be able to apply generative AI across your entire digital marketing to work faster and create more engaging, higher-converting content.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for Marketing</h3>
<ul>
<li>Introduction to Generative AI for Digital Marketing</li>
<li>Popular GenAI Tools (ChatGPT, Claude, Image and Video Generators)</li>
<li>Writing Effective Prompts for Marketing</li>
<li>Generating Copy, Images and Ideas</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Content Creation with Generative AI</h3>
<ul>
<li>Creating Social Media Content</li>
<li>Writing Ad and Email Copy</li>
<li>Generating Images and Videos</li>
<li>Maintaining Brand Voice and Consistency</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Campaign Planning and Optimisation with AI</h3>
<ul>
<li>Researching Audiences and Keywords</li>
<li>Planning Multi-Channel Campaigns</li>
<li>Personalising and Scaling Content</li>
<li>A/B Testing and Optimisation</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Analytics and Workflow with AI</h3>
<ul>
<li>Analysing Marketing Performance with AI</li>
<li>Automating Marketing Workflows</li>
<li>Reporting and Insights</li>
<li>Building Your AI Marketing Playbook</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Digital Marketing | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Accelerate your digital marketing with generative AI. Create copy, images, video, campaigns and analytics with tools like ChatGPT and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, Digital Marketing, ChatGPT, Claude, Content Creation, Campaigns, Social Media, Marketing, AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1468-20260711-101522.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-digital-marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);
