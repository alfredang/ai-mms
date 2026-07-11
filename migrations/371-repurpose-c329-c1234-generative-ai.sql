-- Repurpose two more Generative AI courses (NO AI Vibe Coding badge):
--   C329   Generative AI for Business Presentation (1 day / 2 topics)
--   C1234  Generative AI for Problem Solving       (2 days / 4 topics)
-- Per-market price (C329 350/1100/1500; C1234 700/2200/3000) direct on prod.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

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
-- C329 - Generative AI for Business Presentation (1 day / 2 topics)
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C329');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Business Presentation') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Create stunning business presentations in a fraction of the time with Generative AI for Business Presentation. This hands-on 1-day course teaches you how to use generative AI tools such as ChatGPT, Claude and AI slide generators to research, write, design and deliver professional presentations. You will learn to turn ideas and data into clear, persuasive slides with the help of AI.</p>
<p>Through practical exercises, participants will use generative AI to structure their message, write compelling content, generate visuals and slide designs, and rehearse their delivery. By the end of the course, you will be able to produce polished, impactful business presentations quickly using generative AI.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for Presentations</h3>
<ul>
<li>Introduction to Generative AI for Business Presentations</li>
<li>Popular GenAI Tools (ChatGPT, Claude, AI Slide Generators)</li>
<li>Writing Effective Prompts for Presentations</li>
<li>Structuring Your Message and Story</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Designing and Delivering AI-Powered Presentations</h3>
<ul>
<li>Generating Slide Content and Visuals</li>
<li>Designing Professional Slides with AI</li>
<li>Creating Charts, Images and Speaker Notes</li>
<li>Rehearsing and Delivering with Confidence</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Business Presentation | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Create professional business presentations fast with generative AI. Research, write, design and deliver slides with tools like ChatGPT and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, Business Presentation, ChatGPT, Claude, Slides, Storytelling, Presentation Design, AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C329-20260711-101003.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-business-presentation') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- =========================================================================
-- C1234 - Generative AI for Problem Solving (2 days / 4 topics)
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1234');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Problem Solving') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Solve problems faster and smarter with Generative AI for Problem Solving. This hands-on 2-day course teaches you how to apply generative AI tools such as ChatGPT and Claude together with structured critical-thinking frameworks to analyse problems, generate solutions and make better decisions. You will learn to use AI as a thinking partner while keeping your judgement in control.</p>
<p>Through practical workshops, participants will use generative AI to define problems, explore root causes, generate and evaluate options, and communicate recommendations. By the end of the course, you will be able to combine critical thinking with generative AI to tackle complex problems and make confident, well-reasoned decisions.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Foundations of Critical Thinking and Generative AI</h3>
<ul>
<li>Introduction to Problem Solving and Generative AI</li>
<li>Popular GenAI Tools (ChatGPT, Claude)</li>
<li>Writing Effective Prompts for Thinking</li>
<li>Combining Frameworks with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Defining and Analysing Problems with AI</h3>
<ul>
<li>Framing the Problem Clearly</li>
<li>Exploring Root Causes with AI</li>
<li>Gathering and Structuring Information</li>
<li>Avoiding Bias and Checking AI Output</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Generating and Evaluating Solutions with AI</h3>
<ul>
<li>Generating Options at Scale</li>
<li>Evaluating and Prioritising Solutions</li>
<li>Scenario and Risk Analysis with AI</li>
<li>Making Better Decisions</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Communicating and Applying Solutions with AI</h3>
<ul>
<li>Building a Case with AI</li>
<li>Creating Clear Recommendations</li>
<li>Presenting and Storytelling</li>
<li>Applying AI Problem Solving at Work</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Problem Solving | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Solve problems with generative AI and critical thinking. Analyse problems, generate and evaluate solutions and make better decisions with tools like ChatGPT and Claude in this 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, Problem Solving, Critical Thinking, ChatGPT, Claude, Decision Making, Innovation, AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1234-20260711-101004.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-problem-solving') ON DUPLICATE KEY UPDATE value = VALUES(value);
