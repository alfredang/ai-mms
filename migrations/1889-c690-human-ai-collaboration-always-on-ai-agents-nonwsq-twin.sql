-- C690: "AI Agents Fundamentals for Beginners" -> "Human-AI Collaboration with Always On AI Agents",
-- the 2-day non-WSQ twin of TGS-2024043854 (WSQ - Build a Human-AI Workforce with Autonomous AI Agents).
--
-- 1. name, url_key/url_path (ai-agents-fundamentals-for-beginners ->
--    human-ai-collaboration-with-always-on-ai-agents), cover alt/gallery labels, meta title (bare),
--    meta description/keywords.
-- 2. "What's This Course About" and course topics follow the WSQ parent (its 5 About paragraphs and
--    3 topics). ASCII literals, not a parent join: the opener names this course, and the parent's
--    en dash in "Human-AI" is written as an ASCII hyphen. No day count anywhere.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. Funding block: "No funding", pointing at the WSQ twin (was WSQ - AI Agents for Business).
-- 5. 301s: the product's system rows are renamed in place to the new slug; every old path, bare or
--    category-prefixed, 301s one hop to the new BARE slug; legacy RP rows are flattened onto it.
-- Fee, duration (15) and sessions (2) are unchanged: both courses run 2 days.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Schedule template B19 -> B13 (counterpart of the parent's WSQ-B13) is switched on prod via the
-- code path, not here.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C690' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024043854' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Human-AI Collaboration with Always On AI Agents';
SET @old_slug  := 'ai-agents-fundamentals-for-beginners';
SET @new_slug  := 'human-ai-collaboration-with-always-on-ai-agents';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Human-AI collaboration course: run always-on AI agents with Hermes Agent, ground them with RAG and context in OpenClaw, and manage agent teams in Paperclip.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Human-AI collaboration course, always-on AI agents training Singapore, Hermes Agent, OpenClaw, Paperclip, multi-agent management, context engineering, AI workforce course'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p><strong>Human-AI Collaboration</strong> with <strong>Always On AI Agents</strong> equips participants with practical skills to develop, deploy, and manage autonomous AI agents that collaborate with people and other agents in a digital workforce.</p><p>Participants will begin by building LLM-powered applications with <strong>Hermes Agent</strong>. They will learn how to configure autonomous agents, connect tools and APIs, define agent skills, and design intelligent workflows for business and operational tasks.</p><p>The course then explores Retrieval-Augmented Generation (RAG) and context engineering with OpenClaw. Participants will learn to provide agents with relevant knowledge, persistent memory, user preferences, and task context. They will apply contextual retrieval and memory-driven techniques to improve the accuracy, continuity, and usefulness of agent responses.</p><p>Finally, participants will use Paperclip to manage multi-agent teams. They will learn how to define agent roles, delegate tasks, coordinate workflows, monitor progress, and facilitate effective collaboration between human users and AI agents.</p><p>By the end of the course, participants will be able to build LLM applications, develop context-aware autonomous agents, and manage multi-agent systems that support workflow automation, business operations, customer engagement, software development, and organisational digital transformation.</p>\n<p>This course is part of our <a href="/artificial-intelligence-courses.html">AI training in Singapore</a>, where you can browse all our AI courses. See more <a href="/multi-agents-series.html">multi AI agents courses</a>.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: LLM Applications with Hermes Agent","subsecs":[]},{"title":"Topic 2: RAG and Context Engineering with OpenClaw","subsecs":[]},{"title":"Topic 3: Multi-Agent Management with Paperclip","subsecs":[]}] -->\n<p><strong>Topic 1: LLM Applications with Hermes Agent</strong></p>\n<p><strong>Topic 2: RAG and Context Engineering with OpenClaw</strong></p>\n<p><strong>Topic 3: Multi-Agent Management with Paperclip</strong></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C690-20261102-023144.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C690 - Funding and Grant', 'course_C690_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C690_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C690_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C690_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p class="p1">No funding is available for this course.</p>\n<p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html" title="WSQ - Build a Human-AI Workforce with Autonomous AI Agents">WSQ - Build a Human-AI Workforce with Autonomous AI Agents</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C690_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c690_old;
CREATE TEMPORARY TABLE tmp_c690_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c690_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c690_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c690_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
