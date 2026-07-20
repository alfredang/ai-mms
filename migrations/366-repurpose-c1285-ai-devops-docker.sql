-- Repurpose course C1285 (entity_id 1285) from "Full Docker Training" to
-- "AI Devops with Docker" (2 days / 4 topics). NOT part of the AI Vibe Coding
-- series (different name), so NO series badge. name, overview, topics, meta,
-- duration 15h, cover, url_key. Per-market price (700/2200/3000) + SG funding
-- block applied direct on prod. Store scope 0. Idempotent. No line ends in ';'.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1285');
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
VALUES (4, @a_name, 0, @e, 'AI Devops with Docker') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Master containerisation and DevOps with AI Devops with Docker. This hands-on 2-day course teaches you how to use Docker together with AI assistants such as Cursor, GitHub Copilot and Claude to build, ship and run applications in containers. Instead of memorising commands and YAML, you will let AI generate, explain and debug your Dockerfiles, Compose files and pipelines while you learn the fundamentals and stay in control of your infrastructure.</p>
<p>Through practical projects, participants will install Docker, containerise applications, write Dockerfiles and Docker Compose stacks, manage images, volumes and networks, and build a CI/CD pipeline that deploys containers &mdash; all with an AI pair programmer at their side. You will also learn to review, secure and optimise AI-generated configuration so your deployments are reliable and efficient. By the end of the course, you will be able to containerise and deploy applications faster and more confidently with an effective AI-assisted DevOps workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Docker and AI</h3>
<ul>
<li>Introduction to Containers, Docker and AI-Assisted DevOps</li>
<li>Setting Up Docker and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Running Your First Container</li>
<li>Working with Images and the Docker CLI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building Images with AI</h3>
<ul>
<li>Writing Dockerfiles with AI Assistance</li>
<li>Building and Tagging Images</li>
<li>Managing Volumes and Data</li>
<li>Networking Between Containers</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Multi-Container Apps with Docker Compose</h3>
<ul>
<li>Introduction to Docker Compose</li>
<li>Defining Multi-Container Stacks with AI</li>
<li>Environment Configuration and Secrets</li>
<li>Debugging and Explaining Compose Files with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Deploying and Scaling with AI</h3>
<ul>
<li>Building a CI/CD Pipeline</li>
<li>Deploying Containers to the Cloud</li>
<li>Monitoring, Logging and Security</li>
<li>Optimising and Scaling Your Containers</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Devops with Docker | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Master Docker and DevOps with AI. Build Dockerfiles, Compose stacks, images, networks and CI/CD pipelines using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI DevOps, Docker, Containers, Docker Compose, CI/CD, Cursor, GitHub Copilot, Claude, DevOps, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1285-20260711-095537.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-devops-with-docker') ON DUPLICATE KEY UPDATE value = VALUES(value);
