-- C605: "Basic Semiconductor Devices Course" -> "Semiconductor Device and Process Integration Masterclass",
-- the 2-day non-WSQ twin of TGS-2024049339 (WSQ - Fundamentals of Semiconductor Device Physics and
-- Process Integration). Re-activated (was Disabled).
--
-- 1. status -> Enabled (store 0 + any per-store override).
-- 2. name, url_key/url_path (basic-semiconductor-devices-course ->
--    semiconductor-device-and-process-integration-masterclass), cover alt/gallery labels,
--    meta_title/description/keyword.
-- 3. Fee $350 -> $700; Duration tile 7.5 -> 15 hrs; Sessions tile 1 -> 2.
-- 4. "What's This Course About" and course topics copied from the WSQ parent (its 2 About paragraphs
--    and its 2 topics, h3/ul HTML). Written as ASCII literals, not a parent join.
-- 5. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 6. Funding block already points at the WSQ twin -> untouched.
-- 7. 301s: the product's system rows are renamed in place to the new slug; every old path, bare or
--    category-prefixed, 301s one hop to the new BARE slug; legacy RP rows and search redirects are
--    flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): refreshProductRewrite, schedule template -> B19 via the code path,
-- then flat/price reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C605' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024049339' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Semiconductor Device and Process Integration Masterclass';
SET @old_slug  := 'basic-semiconductor-devices-course';
SET @new_slug  := 'semiconductor-device-and-process-integration-masterclass';

SET @a_status  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');
SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

-- ------------------------------------------------------------ activate -----
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_status, 0, @pid, 1
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int SET value = 1
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_status;

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------- fee / duration / sessions -----
UPDATE catalog_product_entity_decimal SET value = 700
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

UPDATE catalog_product_entity_varchar SET value = '15'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_dur;

UPDATE catalog_product_entity_varchar SET value = '2'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_sess;

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
SELECT 4, @a_mdesc, 0, @pid, 'Learn semiconductor device physics, process modules, manufacturing process flows, layout and design rules, and solve process integration, yield and reliability issues in this 2-day masterclass at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Semiconductor Device and Process Integration Masterclass, Semiconductor Course, Semiconductor Device Physics, Process Integration, Device Fabrication, Process Modules, Yield, Device Reliability, Wafer Fabrication, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course provides an in-depth understanding of semiconductor device physics and the fundamentals of device fabrication. Participants will learn the essential concepts of semiconductor processes, from the basics of device physics to advanced manufacturing process flows, including layout and design rules. The course covers the foundational knowledge needed to understand the relationship between device physics and fabrication processes.</p>\n<p>The second part of the course focuses on process integration challenges and their impact on yield, performance, and reliability. Participants will explore key issues in device performance and reliability and learn how to determine appropriate follow-up actions for process integration problems. This course is ideal for individuals looking to enhance their expertise in semiconductor manufacturing and process optimization.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Fundamentals of Device Physics and Device Fabrication</h3>\n<ul>\n<li>Introduction to semiconductor device physics</li>\n<li>Introduction to process modules</li>\n<li>Basic manufacturing process flows</li>\n<li>Layout and design rules</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2: Process Integration Issues</h3>\n<ul>\n<li>Process integration and yield issues</li>\n<li>Device performance issues</li>\n<li>Device reliability issues</li>\n<li>Follow up actions</li>\n</ul>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover, @a_dur, @a_sess) AND store_id <> 0;

DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C605-20261001-073632.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c605_old;
CREATE TEMPORARY TABLE tmp_c605_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c605_old
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
  FROM tmp_c605_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c605_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
