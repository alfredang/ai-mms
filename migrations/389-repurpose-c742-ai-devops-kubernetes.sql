-- Repurpose course C742 to "AI Devops with Kubernetes" (2 days / 4 topics).
-- Part of the AI Devops line (with C1285 AI Devops with Docker). NO AI Vibe
-- Coding badge. Per-market price (700/2200/3000) direct on prod. Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C742');
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
VALUES (4, @a_name, 0, @e, 'AI Devops with Kubernetes') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Master container orchestration with AI Devops with Kubernetes. This hands-on 2-day course teaches you how to deploy, scale and manage containerised applications with Kubernetes, using AI assistants such as Cursor, GitHub Copilot and Claude to generate and debug manifests and pipelines. Instead of memorising YAML and kubectl commands, you will let AI accelerate your Kubernetes workflow while you stay in control.</p>
<p>Through practical projects, participants will set up a Kubernetes cluster, deploy applications with Pods, Deployments and Services, manage configuration, scaling and networking, and build a CI/CD pipeline that ships to Kubernetes &mdash; all with an AI pair programmer at their side. You will also learn to review, secure and optimise AI-generated configuration so your clusters run reliably. By the end of the course, you will be able to deploy and operate applications on Kubernetes faster and more confidently with an AI-assisted DevOps workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Kubernetes and AI</h3>
<ul>
<li>Introduction to Containers, Kubernetes and AI-Assisted DevOps</li>
<li>Setting Up Kubernetes and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Understanding Pods, Nodes and Clusters</li>
<li>Running Your First Application on Kubernetes</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Deploying Applications with AI</h3>
<ul>
<li>Writing Deployments and Services with AI</li>
<li>Managing Configuration and Secrets</li>
<li>Scaling and Rolling Updates</li>
<li>Debugging and Explaining Manifests with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Networking, Storage and Operations</h3>
<ul>
<li>Kubernetes Networking and Ingress</li>
<li>Persistent Storage and Volumes</li>
<li>Monitoring, Logging and Health Checks</li>
<li>Reviewing and Refactoring AI-Generated Config</li>
</ul>
<h3 class="course-topic-h3">Topic 4 CI/CD and Scaling with AI</h3>
<ul>
<li>Building a CI/CD Pipeline to Kubernetes</li>
<li>Helm and Package Management</li>
<li>Securing Your Cluster</li>
<li>Deploying and Scaling in Production</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI Devops with Kubernetes | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Master Kubernetes with AI. Deploy, scale, network and operate containers with AI-assisted manifests, Helm and CI/CD using tools like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI DevOps, Kubernetes, Containers, Docker, Helm, CI/CD, Cursor, GitHub Copilot, Claude, DevOps, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C742-20260711-103613.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-devops-with-kubernetes') ON DUPLICATE KEY UPDATE value = VALUES(value);
