-- Rename course C597 from "Create Engaging TikTok Video with CapCut AI" to
-- "Generative AI with CapCut" (1 day / 2 topics). Part of the Generative AI
-- series. name, overview, topics, meta (title/description/keyword), cover,
-- url_key. Price and duration unchanged (350 SG / 7.5h). Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C597');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI with CapCut') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Create videos faster with Generative AI with CapCut. This hands-on 1-day course teaches you how to use CapCut&rsquo;s generative AI features &mdash; AI scripts, text-to-speech, avatars, auto-captions, effects and templates &mdash; to produce polished short-form and marketing videos. Instead of editing everything manually, you will let AI accelerate scripting, voiceovers, editing and captions while you focus on the creative story.</p>
<p>Through practical projects, participants will generate video scripts and hooks, create AI voiceovers and avatars, edit footage with AI tools, add auto-captions, effects and music, and export videos for TikTok, Reels, YouTube Shorts and more. You will also learn to prompt effectively, keep a consistent style, and produce content efficiently at scale. By the end of the course, you will be able to create engaging AI-powered videos quickly with CapCut.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI and CapCut</h3>
<ul>
<li>Introduction to Generative AI Video and CapCut</li>
<li>Setting Up CapCut and Its AI Features</li>
<li>Generating Scripts, Hooks and Ideas with AI</li>
<li>Effective Prompting for Video Content</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Creating and Editing AI-Powered Videos with CapCut</h3>
<ul>
<li>AI Voiceovers, Avatars and Text-to-Speech</li>
<li>AI Editing, Auto-Captions and Effects</li>
<li>Templates, Music and Transitions</li>
<li>Exporting and Publishing for TikTok, Reels and Shorts</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI with CapCut') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Create AI-powered videos with CapCut. Use generative AI for scripts, voiceovers, editing and captions to make short-form and marketing videos in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, CapCut, AI Video, Video Editing, Short Form Video, Text to Speech, AI Avatars, Content Creation, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C597-20260712-042640.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-with-capcut') ON DUPLICATE KEY UPDATE value = VALUES(value);
