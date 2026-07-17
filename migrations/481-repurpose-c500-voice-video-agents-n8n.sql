-- Repurpose course C500 from "Practical Applications of AI Digital Humans in
-- Education and Service" to "Voice and Video Agents with n8n" (1 day / 2
-- topics — building AI voice agents and AI avatar video agents with n8n
-- workflow automation). name, overview, topics, meta, url_key, image labels.
-- Price ($350, 1 day) and duration (7.5) intentionally kept.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0 (C500 store-1 labels still carried an even
-- older "Time Series" title).
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C500.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C500');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Voice and Video Agents with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Bring your business communications to life with our hands-on Voice and Video Agents with n8n course. AI agents can now speak to your customers on the phone and appear on screen as lifelike video avatars&mdash;answering enquiries, taking bookings, delivering training and presenting your products around the clock. In this practical 1-day course, you will learn how to build both voice agents and video agents using n8n, the popular no-code workflow automation platform&mdash;no programming background required.</p>
<p>Through guided exercises, participants will build AI voice agents that listen, think and talk&mdash;wiring up speech-to-text, large language models and text-to-speech in n8n workflows and connecting them to phone and chat channels. You will then create AI video agents that generate talking-head avatar videos automatically and publish them to your audience. By the end of the course, you will be able to deploy voice and video agents that handle customer conversations and content production for your organisation.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Voice Agent</h3>
<ul>
<li>Introduction to AI Voice Agents and the n8n Automation Platform</li>
<li>Building Voice Agent Workflows with Webhooks and AI Agent Nodes</li>
<li>Speech-to-Text and Text-to-Speech Integration with Whisper and ElevenLabs</li>
<li>Connecting Voice Agents to Phone and Chat Channels</li>
<li>Voice Agent Use Cases: Customer Service, Bookings and Enquiry Hotlines</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Video Agent</h3>
<ul>
<li>Introduction to AI Video Agents and Digital Avatars</li>
<li>Generating Talking-Head Avatar Videos with AI Video APIs in n8n</li>
<li>Automating End-to-End Video Production Workflows</li>
<li>Building Video Agents for Marketing, Training and Customer Engagement</li>
<li>Publishing and Distributing AI Videos to Social Media Automatically</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Voice and Video Agents with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Voice and Video Agents with n8n in this hands-on 1-day course. Build AI voice agents and avatar video agents with no-code n8n workflow automation at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Voice Agents n8n, Video Agents n8n, AI Voice Agent Course, AI Video Agent Course, n8n Workflow Automation, AI Avatar Video, Text to Speech, Speech to Text, ElevenLabs, Talking Head Video, No Code AI Agents, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'voice-and-video-agents-with-n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C500-20260717-091433.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image alt labels still carried the old "AI Digital Humans" title.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Voice and Video Agents with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Voice and Video Agents with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Voice and Video Agents with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_img, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
