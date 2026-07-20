-- Rename course C922 from "CI/CD with Jenkins Pipeline and Docker - Basic Level"
-- to "AI Devops with Jenkins" (1 day / 2 topics). Part of the AI Devops line.
-- name, overview, topics, meta (title/description/keyword), cover, url_key.
-- Price and duration unchanged (350 SG / 7.5h). Store scope 0. Idempotent. No
-- content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C922');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI Devops with Jenkins') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Automate your CI/CD pipelines with AI Devops with Jenkins. This hands-on 1-day course teaches you how to build, run and troubleshoot Jenkins pipelines with the help of AI assistants such as Cursor, GitHub Copilot and Claude. Instead of memorising Groovy and plugin syntax, you will let AI generate and debug your Jenkinsfiles and pipeline configuration while you focus on the delivery workflow.</p>
<p>Through practical projects, participants will set up Jenkins, create declarative and scripted pipelines, integrate build, test and deployment stages, and use AI to write, explain and fix pipeline code. You will also learn to review, secure and optimise AI-generated configuration so your pipelines run reliably. By the end of the course, you will be able to build and operate Jenkins CI/CD pipelines faster with an AI-assisted DevOps workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Devops and Jenkins</h3>
<ul>
<li>Introduction to CI/CD, Jenkins and AI-Assisted DevOps</li>
<li>Setting Up Jenkins and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Understanding Jobs, Pipelines and the Jenkinsfile</li>
<li>Generating and Explaining Pipeline Code with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building CI/CD Pipelines with Jenkins and AI</h3>
<ul>
<li>Declarative and Scripted Pipelines</li>
<li>Integrating Build, Test and Deployment Stages</li>
<li>Working with Docker, Agents and Credentials</li>
<li>Reviewing, Securing and Optimising AI-Generated Config</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Devops with Jenkins') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Automate CI/CD with Jenkins and AI. Build declarative and scripted pipelines with AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI DevOps, Jenkins, CI/CD, Pipelines, Jenkinsfile, Docker, Cursor, GitHub Copilot, Claude, DevOps Automation, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C922-20260712-045512.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-devops-with-jenkins') ON DUPLICATE KEY UPDATE value = VALUES(value);
