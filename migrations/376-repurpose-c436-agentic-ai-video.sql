-- Repurpose course C436 to "Agentic AI for Video Creation" (2 days / 4 topics).
-- NO AI Vibe Coding badge (Agentic AI brand). Per-market price (700/2200/3000)
-- direct on prod. Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C436');
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
VALUES (4, @a_name, 0, @e, 'Agentic AI for Video Creation') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Create short-form videos at scale with Agentic AI for Video Creation. This hands-on 2-day course teaches you how to build end-to-end AI agent workflows that plan, script, generate and edit short-form videos for social media, using tools such as ChatGPT, Claude, AI video and voice generators, and agentic automation platforms. You will learn to design agents that turn ideas into finished videos automatically.</p>
<p>Through practical projects, participants will build AI agents that research trends, write scripts, generate visuals, voiceovers and edits, and publish videos across platforms. By the end of the course, you will be able to design and deploy agentic AI pipelines that produce engaging short-form video content quickly and consistently.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Agentic AI for Video</h3>
<ul>
<li>Introduction to Agentic AI for Video Creation</li>
<li>Popular AI Video, Voice and Agent Tools</li>
<li>Writing Effective Prompts for Video</li>
<li>Designing an End-to-End Video Agent Workflow</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Scripting and Generating Content with AI</h3>
<ul>
<li>Researching Trends and Ideas</li>
<li>Generating Scripts and Storyboards</li>
<li>Creating Visuals and B-Roll with AI</li>
<li>Generating Voiceovers and Music</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Editing and Assembling Videos with AI</h3>
<ul>
<li>Automating Video Editing</li>
<li>Adding Captions, Effects and Branding</li>
<li>Assembling Short-Form Videos</li>
<li>Reviewing and Refining with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Automating and Scaling Video Production</h3>
<ul>
<li>Building Multi-Step Video Agents</li>
<li>Publishing and Scheduling Across Platforms</li>
<li>Analysing Performance</li>
<li>Scaling Your Video Content Pipeline</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Agentic AI for Video Creation | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Create short-form videos with agentic AI. Plan, script, generate, edit and publish videos with AI agents and tools like ChatGPT and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Agentic AI, Video Creation, Short-Form Video, AI Agents, ChatGPT, Claude, AI Video, Content Creation, Automation, AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C436-20260711-101845.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'agentic-ai-for-video-creation') ON DUPLICATE KEY UPDATE value = VALUES(value);
