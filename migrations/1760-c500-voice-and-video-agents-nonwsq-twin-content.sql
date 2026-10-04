-- C500 "Voice and Video Agents with n8n" becomes the non-WSQ twin of TGS-2024052081
-- (WSQ - Automate Video and Voice AI Agents with n8n); its courseware is now the converted
-- WSQ set (github.com/tertiarycourses/C500-Voice-and-Video-Agents-with-n8n): 2 days, all
-- 3 topics, all 12 labs.
--
-- 1. 2 days / 15 hrs / $700 (was 1 day / 7.5 hrs / $350): price, duration, sessions.
-- 2. About + topics copied from the WSQ parent (replaces the previous 1-day build's 2-topic
--    copy, which opened "In this practical 1-day course"). The About's opening sentence names
--    the parent's title, so it is swapped for C500's. Neither text states a day count.
-- 3. meta_description rewritten (the old one said "hands-on 1-day course"); meta_keyword
--    aligned with the converted labs.
-- 4. Funding block repointed from wsq-agentic-ai-for-business-process-automation.html (a
--    different course) to the real twin, wsq-automate-video-and-voice-ai-agents-with-n8n.html.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Not in SQL: the schedule template switch A02 -> B11 (both courses now run 2 days and the
-- parent is on (SG) WSQ-B11, so the same-code rule applies) is a code path
-- (CoursesaveController::switchScheduleTemplateAction), run on prod.
-- Post-deploy: flat + price reindex and cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C500' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024052081' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_price := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ------------------------------------------- 2 days / 15 hrs / $700 ----
INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 700 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- every scope row, or a store override keeps serving the old fee
UPDATE catalog_product_entity_decimal SET value = 700
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '15' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '2' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_dur, @a_sess) AND store_id <> 0;

-- ---------------------------------------------- About + topics (parent) ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid,
       REPLACE(value, 'The Automate Video and Voice AI Agents with n8n course', 'The Voice and Video Agents with n8n course')
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_short AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_desc AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Build AI chatbots, voice agents and avatar video agents with n8n. Hands-on labs with RAG, ElevenLabs, Vapi, HeyGen, LiveAvatar and Google Veo 3 at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- an orphan TEXT-table meta_description would shadow the varchar value
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Voice Agents n8n, Video Agents n8n, AI Voice Agent Course, AI Avatar Video, RAG Chatbot, ElevenLabs, Vapi, HeyGen, LiveAvatar, Google Veo 3, Ollama, n8n Workflow Automation, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------------------- funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-automate-video-and-voice-ai-agents-with-n8n.html" title="WSQ - Automate Video and Voice AI Agents with n8n">WSQ - Automate Video and Voice AI Agents with n8n</a></span></p>'
 WHERE @ok AND identifier = 'course_C500_funding_and_grant';
