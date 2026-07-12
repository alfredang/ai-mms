-- Rename course C324 from "Agile Project Management Training" to "Generative AI
-- for Agile Project Management" (2 days / 4 topics). Part of the Generative AI
-- series. name, overview, topics, meta (title/description/keyword), cover,
-- url_key. Price and duration unchanged (700 SG / 15h). Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C324');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Agile Project Management') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Run agile teams smarter with Generative AI for Agile Project Management. This hands-on 2-day course teaches you how to use generative AI tools such as ChatGPT, Claude and Gemini to plan sprints, write user stories, manage backlogs, and speed up agile ceremonies and reporting. Instead of doing routine work manually, you will let AI accelerate planning, documentation and analysis while you focus on delivering value and leading the team.</p>
<p>Through practical projects, participants will use AI to draft and refine user stories and acceptance criteria, groom and prioritise backlogs, plan sprints and estimate work, generate stand-up and status summaries, and produce retrospectives and reports. You will also learn to prompt effectively, keep humans in the loop, and apply AI responsibly within agile and Scrum practices. By the end of the course, you will be able to boost your agile project management with a generative AI workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for Agile</h3>
<ul>
<li>Introduction to Agile, Scrum and Generative AI</li>
<li>Setting Up AI Tools for Agile Project Management</li>
<li>Effective Prompting for Agile Tasks</li>
<li>Responsible and Human-in-the-Loop Use of AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 AI for Backlogs, User Stories and Planning</h3>
<ul>
<li>Drafting and Refining User Stories and Acceptance Criteria</li>
<li>Grooming and Prioritising the Backlog with AI</li>
<li>Sprint Planning and Estimation Support</li>
<li>Generating Roadmaps and Release Plans</li>
</ul>
<h3 class="course-topic-h3">Topic 3 AI for Sprints, Standups and Delivery</h3>
<ul>
<li>Summarising Stand-ups and Tracking Progress</li>
<li>Identifying Risks, Blockers and Dependencies with AI</li>
<li>Assisting Documentation and Communication</li>
<li>Supporting Quality, Testing and Delivery</li>
</ul>
<h3 class="course-topic-h3">Topic 4 AI for Reporting, Retrospectives and Improvement</h3>
<ul>
<li>Generating Status Reports and Dashboards</li>
<li>Analysing Velocity and Metrics with AI</li>
<li>Running AI-Assisted Retrospectives</li>
<li>Driving Continuous Improvement</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Agile Project Management') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Run agile teams smarter with generative AI. Write user stories, manage backlogs, plan sprints and automate reporting with ChatGPT, Claude and Gemini in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, Agile, Project Management, Scrum, User Stories, Sprint Planning, AI Productivity, ChatGPT, Claude, Gemini, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C324-20260712-044007.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-agile-project-management') ON DUPLICATE KEY UPDATE value = VALUES(value);
