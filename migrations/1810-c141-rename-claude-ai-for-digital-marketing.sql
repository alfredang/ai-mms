-- C141: "Claude Cowork for Digital Marketing" -> "Claude AI for Digital Marketing", and the
-- slug claude-code-for-digital-marketing -> claude-ai-for-digital-marketing. C141 is the
-- non-WSQ twin of TGS-2023018659 (WSQ - Claude Cowork for Digital Marketing); its
-- courseware was re-converted from the WSQ v10.0 set as v3.0 on 2026-10-12.
--
-- 1. name, url_key/url_path, cover alt/gallery labels, meta_title/meta_description/
--    meta_keyword. About (short_description) + topics (description) copied from the WSQ
--    parent (store 0) so both catalogue entries describe the same course; neither states a
--    day count. Duration 15 / sessions 2 / $700 are already correct and untouched.
-- 2. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 3. 301s. The new slug was squatted: the bare path by a gsc404 301 to
--    google-cloud-platform-courses.html (stores 0 and 1), and ten category-prefixed paths by
--    301s left by retired product 154 (an earlier "claude-ai-for-digital-marketing", now
--    -retired and disabled). Squatters on a path C141 itself needs are deleted; the rest are
--    repointed one hop at the new bare slug. Then C141's system rows are renamed in place
--    (new URL resolves without a rewrite refresh), every old path 301s to the new bare
--    slug, and legacy RP rows into any old path are flattened onto it. Search redirects
--    repointed.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.
-- Post-deploy: refreshProductRewrite(141), flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C141' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023018659' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @old_title := 'Claude Cowork for Digital Marketing';
SET @new_title := 'Claude AI for Digital Marketing';
SET @old_slug  := 'claude-code-for-digital-marketing';
SET @new_slug  := 'claude-ai-for-digital-marketing';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
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
 WHERE @ok AND v.entity_id = @pid AND v.value = @old_title;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid AND gv.label = @old_title;

-- ---------------------------------------------- meta (title stored bare) -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid,
       'Use Claude AI for digital marketing - build an AI marketing team with Claude Cowork and Claude Code, connect MCP tools, create reusable Claude Skills and analyse campaign performance at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_text
   SET value = CONCAT('Claude AI, ', value)
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mkey AND store_id = 0
   AND value NOT LIKE 'Claude AI,%';

-- ------------------------- About + topics copied from the WSQ parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, s.attribute_id, 0, @pid, s.value
  FROM catalog_product_entity_text s
 WHERE @ok AND s.entity_id = @src AND s.store_id = 0 AND s.attribute_id IN (@a_sdesc, @a_desc)
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_sdesc, @a_desc) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C141-20261011-225106.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------- 301 rewrites ----
-- 0) Squatters on the new slug that are not C141's own rows.
--    a) on a path C141 will occupy (its bare slug, or a category it is in) -> delete;
DROP TEMPORARY TABLE IF EXISTS tmp_c141_new;
CREATE TEMPORARY TABLE tmp_c141_new (store_id SMALLINT, p VARCHAR(255));
INSERT INTO tmp_c141_new
SELECT store_id, REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
  FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

DELETE r FROM core_url_rewrite r
  JOIN tmp_c141_new n ON n.store_id = r.store_id AND n.p = r.request_path
 WHERE @ok AND r.is_system = 0 AND (r.product_id IS NULL OR r.product_id <> @pid);

DROP TEMPORARY TABLE IF EXISTS tmp_c141_new;

DELETE FROM core_url_rewrite
 WHERE @ok AND store_id IN (0, 1) AND request_path = CONCAT(@new_slug, '.html') AND is_system = 0
   AND (product_id IS NULL OR product_id <> @pid);

--    b) anywhere else (retired product 154's other category paths) -> one hop to C141.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html'), options = 'RP'
 WHERE @ok AND is_system = 0 AND (product_id IS NULL OR product_id <> @pid)
   AND request_path LIKE CONCAT('%/', @new_slug, '.html');

-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c141_old;
CREATE TEMPORARY TABLE tmp_c141_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c141_old
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
  FROM tmp_c141_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c141_old;

-- ------------------------------------------------- search redirects -----
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect, CONCAT('/', @old_slug, '.html'), CONCAT('/', @new_slug, '.html'))
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
