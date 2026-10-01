-- C012: "Generative AI for Powerpoint" -> "Microsoft Copilot for Powerpoint Masterclass",
-- still the 1-day non-WSQ twin of TGS-2026064178 (CASL - Create Powerpoint Infographics with AI).
--
-- 1. name, url_key/url_path (generative-ai-for-powerpoint ->
--    microsoft-copilot-for-powerpoint-masterclass), cover alt/gallery labels,
--    meta_title/description/keyword.
-- 2. "What's This Course About" and the 3 course topics are NOT touched: migration 1584
--    already copied them from the parent and the live pages are byte-identical.
--    Duration 7.5 hrs, Sessions 1 and the funding block (-> CASL twin) stay as they are.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. 301s: the product's system rows are renamed in place to the new slug (so the new
--    URL resolves without a rewrite refresh); every old path, bare or category-prefixed,
--    301s one hop to the new BARE slug, and legacy RP rows (incl. the Powerpoint
--    Essential Training ones from 1584) are flattened onto it. On-site search redirects
--    are repointed too.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C012' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064178' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Microsoft Copilot for Powerpoint Masterclass';
SET @old_slug  := 'generative-ai-for-powerpoint';
SET @new_slug  := 'microsoft-copilot-for-powerpoint-masterclass';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
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
SELECT 4, @a_mdesc, 0, @pid, 'Master Microsoft Copilot and AI in PowerPoint to turn data and ideas into clear, professional infographics. Learn visual hierarchy, layout, colour, typography and data storytelling for business presentations.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Microsoft Copilot for PowerPoint, Copilot PowerPoint Masterclass, Microsoft Copilot, AI PowerPoint infographics, AI infographic design, PowerPoint infographics course, AI-assisted presentation design, visual storytelling, business infographics Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C012-20261001-043039.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c012_old;
CREATE TEMPORARY TABLE tmp_c012_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c012_old
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
  FROM tmp_c012_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c012_old;

-- ------------------------------------------------- search redirects -----
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect, CONCAT('/', @old_slug, '.html'), CONCAT('/', @new_slug, '.html'))
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
