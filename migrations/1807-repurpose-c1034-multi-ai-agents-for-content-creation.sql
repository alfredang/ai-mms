-- C1034: "Multi Agents System with Autogen" -> "Multi AI Agents for Content Creation" — the 2-day
-- non-WSQ twin of TGS-2023036153 (WSQ - Multi AI Agents Workflow for Content Creation). Courseware
-- converted from the WSQ Claude edition v3.6
-- (github.com/tertiarycourses/C1034-Multi-AI-Agents-for-Content-Creation).
--
-- 1. name, url_key/url_path (multi-agents-system-with-autogen -> multi-ai-agents-for-content-creation),
--    cover alt/gallery labels, meta_title, meta_description (parent's, minus its WSQ funding sentence),
--    meta_keyword (parent's), new cover PNG on R2 (the PNG bakes the title).
-- 2. "What's This Course About", topics and Job Roles copied from the parent (store 0; the parent's
--    copy carries no WSQ wording and no day count). Trainer bios copied from the parent with the
--    in-text course title retitled — the AutoGen trainers belonged to the superseded course.
-- 3. Software/hardware requirement: the AutoGen list (Python, VS Code, Gemini API key) is replaced by
--    the parent's section (byte-exact span splice; the entry requirements are kept).
-- 4. Funding block repointed from WSQ AutoGen to the WSQ twin
--    https://www.tertiarycourses.com.sg/multi-ai-agents-workflow-for-content-creation.html (200, 0 hops).
-- 5. 301s: the product's system rows are renamed in place to the new slug; every old path 301s one hop
--    to the new bare slug and the legacy RP rows are flattened onto it.
-- 6. Search redirects that sent AutoGen / LangGraph / "build multi agents" searches to this course now
--    go to WSQ - Develop Multi-Agent AI Applications with AutoGen; 'C1034' goes to the new slug.
-- Fee ($700) / 15 hrs / 2 sessions unchanged. Schedule template is a code path, not SQL.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1034' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023036153' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @old_title  := 'Multi Agents System with Autogen';
SET @new_title  := 'Multi AI Agents for Content Creation';
SET @src_title  := 'Multi AI Agents Workflow for Content Creation';
SET @old_slug   := 'multi-agents-system-with-autogen';
SET @new_slug   := 'multi-ai-agents-for-content-creation';
SET @autogen_url := 'https://www.tertiarycourses.com.sg/wsq-develop-multi-agent-ai-applications-with-autogen.html';
SET @sw_head    := '<h2>Minimum Software/Hardware Requirement</h2>';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- ------------------------------------------------------------ name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ----------------------------------------------------------- image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid AND v.value = @old_title;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid AND gv.label = @old_title;

-- ------------------------------------------------------- meta + cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid,
       'Learn to design and manage multi AI agent workflows for end-to-end content creation. Coordinate research, strategy, writing, design and publishing agents to produce marketing content at scale.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1034-20261011-115533.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- ------------------------- About / topics / job roles / keywords from the parent -----
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey, @a_trainer) AND store_id <> 0;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, pt.attribute_id, 0, @pid, pt.value
  FROM catalog_product_entity_text pt
 WHERE @ok AND pt.entity_id = @src AND pt.store_id = 0
   AND pt.attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey)
   AND pt.value IS NOT NULL AND pt.value <> ''
   AND pt.value NOT LIKE '%WSQ%' AND pt.value NOT LIKE '%SkillsFuture%'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Trainer bios: the parent's trainers, with the two in-text course-title mentions retitled.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_trainer, 0, @pid, REPLACE(pt.value, @src_title, @new_title)
  FROM catalog_product_entity_text pt
 WHERE @ok AND pt.entity_id = @src AND pt.store_id = 0 AND pt.attribute_id = @a_trainer
   AND pt.value LIKE '%James Lee%' AND pt.value NOT LIKE '%WSQ%'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------ software/hardware requirement (span splice) -----
-- Keep C1034's text up to the heading; take the parent's section from the heading up to its
-- next <h2> (the WSQ-only PWM / funding sections that follow it on the parent are not copied).
-- Guarded on the AutoGen list so a re-run is a no-op.
UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_text pt
    ON pt.entity_id = @src AND pt.store_id = 0 AND pt.attribute_id = @a_prereq
   SET t.value = CONCAT(
         LEFT(t.value, LOCATE(@sw_head, t.value) - 1),
         SUBSTRING_INDEX(SUBSTRING(pt.value, LOCATE(@sw_head, pt.value)), '<h2>About Progressive Wage Model', 1))
 WHERE @ok AND t.entity_id = @pid AND t.store_id = 0 AND t.attribute_id = @a_prereq
   AND LOCATE(@sw_head, t.value) > 0 AND LOCATE(@sw_head, pt.value) > 0
   AND LOCATE('<h2>About Progressive Wage Model', pt.value) > LOCATE(@sw_head, pt.value)
   AND t.value LIKE '%aistudio.google.com%';

-- ----------------------------------------------------------- funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2> <p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/multi-ai-agents-workflow-for-content-creation.html" title="WSQ - Multi AI Agents Workflow for Content Creation">WSQ - Multi AI Agents Workflow for Content Creation</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C1034_funding_and_grant';

-- ------------------------------------------------------------ 301 rewrites -----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c1034_old;
CREATE TEMPORARY TABLE tmp_c1034_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c1034_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves without a rewrite refresh.
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
  FROM tmp_c1034_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c1034_old;

-- -------------------------------------------------------- search redirects -----
-- These searches were mapped to this course while it taught AutoGen; keep that intent.
UPDATE catalogsearch_query
   SET redirect = @autogen_url
 WHERE @ok AND store_id = 1 AND query_text <> 'C1034'
   AND (redirect LIKE '%/orchestrate-multi-ai-agents-with-autogen.html'
        OR redirect LIKE CONCAT('%/', @old_slug, '.html'));

UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND store_id = 1 AND query_text = 'C1034';
