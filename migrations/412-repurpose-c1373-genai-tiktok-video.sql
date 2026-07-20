-- Rename course C1373 from "Master TikTok Marketing - Create Videos That
-- Captivate Audiences" to "Generative AI for Tiktok Video Creation"
-- (2 days / 4 topics). Part of the Generative AI series. name, overview, topics,
-- meta (title/description/keyword), cover, url_key. Per-market price ($700 SG)
-- applied direct on prod, not in this migration. Duration unchanged (15h).
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1373');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Tiktok Video Creation') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Create scroll-stopping TikTok videos with Generative AI for Tiktok Video Creation. This hands-on 2-day course teaches you how to use generative AI tools to ideate, script, generate, edit and publish short-form videos that captivate audiences. Instead of spending hours on production, you will let AI accelerate scripting, voiceovers, visuals and editing while you focus on creativity and strategy.</p>
<p>Through practical projects, participants will use AI to generate video ideas and hooks, write scripts and captions, create visuals, voiceovers and B-roll, edit videos into polished TikToks, and plan a posting and growth strategy. You will also learn to prompt effectively, keep a consistent brand style, and analyse and improve performance. By the end of the course, you will be able to produce and scale engaging TikTok video content with a generative AI workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for TikTok</h3>
<ul>
<li>Introduction to Short-Form Video and Generative AI</li>
<li>Setting Up AI Tools for Video Creation</li>
<li>Understanding the TikTok Algorithm and Audience</li>
<li>Effective Prompting for Video Ideas and Content</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Generating Scripts, Ideas and Hooks with AI</h3>
<ul>
<li>Generating Video Ideas, Angles and Hooks</li>
<li>Writing Scripts, Captions and Hashtags with AI</li>
<li>Planning Series and Content Calendars</li>
<li>Keeping a Consistent Brand Voice and Style</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Creating and Editing Videos with Generative AI</h3>
<ul>
<li>Generating Visuals, B-Roll and Images with AI</li>
<li>AI Voiceovers, Avatars and Text-to-Video</li>
<li>Editing, Captions and Effects with AI Tools</li>
<li>Adding Music, Sound and Transitions</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Publishing, Optimising and Scaling TikTok Content</h3>
<ul>
<li>Publishing and Scheduling TikTok Videos</li>
<li>Analysing Performance and Iterating with AI</li>
<li>Repurposing Content Across Platforms</li>
<li>Scaling a Content Production Workflow with AI</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Tiktok Video Creation') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Create captivating TikTok videos with generative AI. Ideate, script, generate, edit and scale short-form video content in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, TikTok, Video Creation, Short Form Video, AI Video, Content Creation, Social Media, Text to Video, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1373-20260712-033946.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-tiktok-video-creation') ON DUPLICATE KEY UPDATE value = VALUES(value);
