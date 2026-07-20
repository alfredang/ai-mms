-- Repurpose two Generative AI courses (NO AI Vibe Coding badge — different
-- branding, they belong under the Generative AI category):
--   C429  Generative AI for Digital Marketing (1 day / 2 topics; was Accelerate ...)
--   C924  Generative AI for Design Thinking   (2 days / 4 topics; was Agile Design Thinking ...)
-- Per-market price (C429 350/1100/1500; C924 700/2200/3000) applied direct on
-- prod. Store scope 0. Idempotent. No content line ends in a semicolon.

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

-- =========================================================================
-- C429 - Generative AI for Digital Marketing (1 day / 2 topics)
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C429');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Digital Marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Supercharge your marketing with Generative AI for Digital Marketing. This hands-on 1-day course teaches you how to use generative AI tools such as ChatGPT, Claude and image generators to plan campaigns, create content and accelerate your digital marketing. You will learn to write effective prompts, generate copy and visuals, and build an AI-assisted marketing workflow that saves time and improves results.</p>
<p>Through practical exercises, participants will use generative AI to research audiences, write ad and social copy, create images and videos, plan campaigns and analyse performance. By the end of the course, you will be able to apply generative AI across your digital marketing to work faster and create more engaging content.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for Marketing</h3>
<ul>
<li>Introduction to Generative AI for Digital Marketing</li>
<li>Popular GenAI Tools (ChatGPT, Claude, Image and Video Generators)</li>
<li>Writing Effective Prompts for Marketing</li>
<li>Generating Copy, Images and Ideas</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building an AI-Powered Marketing Workflow</h3>
<ul>
<li>Creating Social Media and Ad Content</li>
<li>Planning Campaigns with AI</li>
<li>Personalising and Scaling Content</li>
<li>Analysing and Improving Marketing Performance</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Digital Marketing | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Accelerate your digital marketing with generative AI. Create copy, images, campaigns and content with tools like ChatGPT and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, Digital Marketing, ChatGPT, Claude, Content Creation, Prompt Engineering, Marketing, AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C429-20260711-100732.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-digital-marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- =========================================================================
-- C924 - Generative AI for Design Thinking (2 days / 4 topics)
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C924');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Design Thinking') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Reinvent your innovation process with Generative AI for Design Thinking. This hands-on 2-day course teaches you how to combine the design thinking methodology with generative AI tools such as ChatGPT and Claude to empathise, define, ideate, prototype and test faster. You will learn to use AI to accelerate every stage of design thinking while keeping human insight at the centre.</p>
<p>Through practical workshops, participants will use generative AI to research users, synthesise insights, generate and refine ideas, create prototypes and craft compelling stories. By the end of the course, you will be able to run AI-accelerated design thinking sprints that produce better solutions in less time.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Foundations of Design Thinking and Generative AI</h3>
<ul>
<li>Introduction to Design Thinking and Generative AI</li>
<li>Popular GenAI Tools (ChatGPT, Claude, Image Generators)</li>
<li>Writing Effective Prompts for Innovation</li>
<li>The AI-Accelerated Design Thinking Process</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Empathise and Define with AI</h3>
<ul>
<li>Researching and Understanding Users with AI</li>
<li>Synthesising Insights and Personas</li>
<li>Defining Problems and Opportunities</li>
<li>Framing How-Might-We Questions</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Ideate and Prototype with AI</h3>
<ul>
<li>Generating Ideas at Scale with AI</li>
<li>Selecting and Refining Concepts</li>
<li>Creating Rapid Prototypes with AI</li>
<li>Visualising Solutions</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Test, Story-tell and Deliver with AI</h3>
<ul>
<li>Testing Ideas and Gathering Feedback</li>
<li>Iterating with AI</li>
<li>Crafting Compelling Stories and Pitches</li>
<li>Running AI-Accelerated Design Sprints</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Design Thinking | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Accelerate design thinking with generative AI. Empathise, ideate, prototype and test faster with tools like ChatGPT and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, Design Thinking, Innovation, ChatGPT, Claude, Prototyping, Ideation, UX, AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C924-20260711-100751.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-design-thinking') ON DUPLICATE KEY UPDATE value = VALUES(value);
