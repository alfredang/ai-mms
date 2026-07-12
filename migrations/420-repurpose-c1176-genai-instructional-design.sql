-- Rename course C1176 from "Supercharge Learning and Instructional Design with
-- Generative AI (GenAI)" to "Generative AI for Instructional Design"
-- (1 day / 2 topics). Part of the Generative AI series. name, overview, topics,
-- meta (title/description/keyword), cover, url_key. Price and duration unchanged
-- (350 SG / 7.5h). Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1176');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Instructional Design') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Design better learning faster with Generative AI for Instructional Design. This hands-on 1-day course teaches you how to use generative AI tools such as ChatGPT, Claude and Gemini to plan courses, write learning content, create assessments and produce learning materials. Instead of building everything from scratch, you will let AI accelerate needs analysis, content drafting and media creation while you apply sound instructional design principles.</p>
<p>Through practical projects, participants will use AI to analyse learning needs and objectives, structure courses and lessons, generate content, activities and assessments, and create scripts, visuals and job aids. You will also learn to prompt effectively, align content to learning outcomes, and review and quality-check AI output. By the end of the course, you will be able to design and develop engaging, effective learning experiences faster with a generative AI workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for Instructional Design</h3>
<ul>
<li>Introduction to Instructional Design and Generative AI</li>
<li>Setting Up AI Tools for Learning Design</li>
<li>Analysing Learning Needs, Audiences and Objectives with AI</li>
<li>Structuring Courses and Lessons with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Creating Learning Content and Assessments with AI</h3>
<ul>
<li>Generating Content, Activities and Scenarios</li>
<li>Creating Quizzes, Assessments and Rubrics</li>
<li>Producing Scripts, Visuals and Job Aids</li>
<li>Aligning to Outcomes and Quality-Checking AI Output</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Instructional Design') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Design learning faster with generative AI. Plan courses, write content and create assessments with ChatGPT, Claude and Gemini in this hands-on 1-day instructional design course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, Instructional Design, Learning Design, eLearning, Course Design, Training, ChatGPT, Claude, Gemini, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1176-20260712-042051.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-instructional-design') ON DUPLICATE KEY UPDATE value = VALUES(value);
