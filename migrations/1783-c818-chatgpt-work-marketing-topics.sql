-- C818 "ChatGPT WORK for Digital Marketing": the live page still carried the OpenAI Codex outline
-- (topics "Getting Started with Codex", "Campaign Assets with Codex", "Data and Analytics Pipelines",
-- "Integrating the Marketing Stack"), a Codex meta description/keywords, and the 1781 About text,
-- which described that same outline. Re-aligned to the C818 v1.0 courseware (ChatGPT Work, Cook &
-- Bake Academy campaign, 8 labs).
--
-- 1. Topics (description): the 4 courseware topics, headings only (no sub-bullets), house
--    h3.course-topic-h3 format so each renders as a teal-dot row.
-- 2. About (short_description): 3 paragraphs, ASCII, no day count, grounded in the 4 topics.
--    Supersedes the C818 copy written by 1781.
-- 3. meta_description + meta_keyword: Codex wording removed.
--
-- Written to store 0 and to any store-scope override, so no stale per-store copy survives.
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.
-- Not changed here (needs a decision): prerequisite (still Vue.js), whoshouldattend, and the
-- course_C818_funding_and_grant block (links WSQ - Agentic AI Applications with Codex).
-- Post-deploy: flat reindex + cache flush (/reindex/api/run?flush=1).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C818' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');

SET @v_desc := '<h3 class="course-topic-h3">Topic 1: ChatGPT Work and a Grounded Campaign Brief</h3>
<h3 class="course-topic-h3">Topic 2: Flyer Design and Visual Review</h3>
<h3 class="course-topic-h3">Topic 3: Social Articles and Content Planning</h3>
<h3 class="course-topic-h3">Topic 4: Email Campaign and Measurement</h3>';

SET @v_short := '<p>ChatGPT WORK for Digital Marketing turns ChatGPT Work into a practical digital marketing assistant. This hands-on course shows marketers, business owners and content creators how to delegate real campaign work to ChatGPT Work, from a source-checked campaign brief to finished flyers, social content and an email sequence, while keeping every fact accurate and every asset on brand. Instead of starting from a blank page for each channel, you will learn to build one trusted brief and turn it into consistent content across print, social and email.</p><p>Throughout the course, you will run one complete campaign for a fictional baking school. You will build a grounded campaign brief and a reusable marketing workflow, then design editable flyers and adapt them into print and social formats. Next, you will write a social article, repurpose it into platform-ready posts and plan a content calendar with a clear editorial review gate. Finally, you will prepare a segmented email sequence, interpret campaign metrics and package everything into a clean handoff that another marketer can review and use.</p><p>Each topic is backed by guided labs, so you leave with a working method, not just a set of prompts. You will learn how to check AI output against your sources, preserve brand voice and visual identity, catch errors before anything is published and organise your files for team review. No coding or design background is needed, and the skills transfer directly to your own products, services and campaigns. By the end of the course, you will be able to plan, create and review a multi-channel marketing campaign faster and with more confidence using ChatGPT Work.</p>';

SET @v_mdesc := 'Use ChatGPT Work for digital marketing: build a grounded campaign brief, editable flyers, social articles and a segmented email campaign at Tertiary Courses Singapore.';
SET @v_mkey  := 'ChatGPT Work, ChatGPT for Marketing, Digital Marketing, AI Marketing, Flyer Design, Social Media Content, Content Calendar, Email Marketing, Singapore';

-- ------------------------------------------------------------ text -------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, @v_desc FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, @v_short FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_text SET value = @v_desc
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_desc AND store_id > 0;
UPDATE catalog_product_entity_text SET value = @v_short
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_short AND store_id > 0;

-- ------------------------------------------------------------- meta ------
-- meta_description / meta_keyword backend type differs between installs; write whichever table
-- the attribute actually uses.
SET @t_mdesc := (SELECT backend_type FROM eav_attribute WHERE attribute_id = @a_mdesc);
SET @t_mkey  := (SELECT backend_type FROM eav_attribute WHERE attribute_id = @a_mkey);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, @v_mdesc FROM DUAL WHERE @ok AND @t_mdesc = 'varchar'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, @v_mdesc FROM DUAL WHERE @ok AND @t_mdesc = 'text'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, @v_mkey FROM DUAL WHERE @ok AND @t_mkey = 'varchar'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, @v_mkey FROM DUAL WHERE @ok AND @t_mkey = 'text'
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_varchar SET value = @v_mdesc
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id > 0;
UPDATE catalog_product_entity_text SET value = @v_mdesc
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id > 0;
UPDATE catalog_product_entity_varchar SET value = @v_mkey
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mkey AND store_id > 0;
UPDATE catalog_product_entity_text SET value = @v_mkey
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mkey AND store_id > 0;
