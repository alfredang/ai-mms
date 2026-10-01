-- C995: "AutoCAD Electrical Training" -> "AutoCAD Electrical Masterclass", the 2-day non-WSQ
-- twin of TGS-2023037466 (WSQ - Technical Drawing with AutoCAD Electrical).
--
-- 1. name, url_key/url_path (autocad-electrical-training -> autocad-electrical-masterclass),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. "What's This Course About" and course topics follow the WSQ parent (its 3 topics).
--    The parent's inline "Autodesk ATC" paragraph is NOT copied: C995 already carries the
--    autodesk_atc partner, which renders the ATC card. Written as ASCII literals (the
--    parent's stored topics carry legacy latin1 dash/apostrophe bytes). Neither text
--    states a day count. Duration 15 hrs, Sessions 2 and $700 stay as they are.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. Funding block: the SGTech STAR funding line is removed (a non-WSQ course carries no
--    funding); the block now says no funding is available and links the WSQ twin.
-- 5. 301s: the product's system rows are renamed in place to the new slug (so the new
--    URL resolves without a rewrite refresh); every old path, bare or category-prefixed,
--    301s one hop to the new BARE slug, and legacy RP rows are flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template B01 -> B17 (counterpart of the
-- parent's (SG) WSQ-B17) via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C995' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023037466' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'AutoCAD Electrical Masterclass';
SET @old_slug  := 'autocad-electrical-training';
SET @new_slug  := 'autocad-electrical-masterclass';

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
SELECT 4, @a_mdesc, 0, @pid, 'Master AutoCAD Electrical in this hands-on masterclass. Learn schematics, PLC symbols, wiring and wire numbers, cross-referencing, panel layouts, BOM reports and PDF publishing at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'AutoCAD Electrical, AutoCAD Electrical Masterclass, Electrical CAD, Schematic Drawing, PLC Symbols, Wire Numbers, Panel Layout, Bill of Material, Technical Drawing, Autodesk, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>AutoCAD Electrical is a software program used for the creation and modification of electrical control systems and schematics. It is a specialized version of the AutoCAD software and provides an extensive library of electrical symbols, components, and circuitry. With AutoCAD Electrical, engineers and designers can create precise, detailed electrical schematics, panel layouts, and other control system designs.</p>\n<p>This course aims to equip students with the knowledge and skills necessary for the production of technical drawings using AutoCAD Electrical software. It covers topics such as drafting standards and conventions, problem-solving techniques, and quality control measures. Upon completion of the course, students will be able to create, modify, and review technical drawings while adhering to relevant standards and specifications.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Introduction to Technical Drawing Using AutoCAD Electrical</h3>\n<ul>\n<li>AutoCAD Electrical User Interface - Symbols, standards and conventions</li>\n<li>Use the AutoCAD Electrical ribbon</li>\n<li>Formulate solutions using AutoCAD Electrical tools</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2: Analysing Technical Drawings</h3>\n<ul>\n<li>Types of schematics technical drawings</li>\n<li>Utilize AutoCAD Electrical tools and features to address technical drawing issues</li>\n<li>Working with standard part lists &ndash; terminals, PLC symbols</li>\n<li>Analyze technical drawing standards to determine construction needs</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3: Drafting Design Documentation and Specification</h3>\n<ul>\n<li>Fundamentals of documentation</li>\n<li>Review technical drawings to ensure alignment to organization''s strategies</li>\n<li>Custom symbols</li>\n<li>Review technical drawings and specifications to ensure conformance to requirements</li>\n</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C995-20261001-040305.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C995 - Funding and Grant', 'course_C995_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C995_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C995_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C995_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-technical-drawing-with-autocad-electrical.html" title="WSQ - Technical Drawing with AutoCAD Electrical">WSQ - Technical Drawing with AutoCAD Electrical</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C995_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c995_old;
CREATE TEMPORARY TABLE tmp_c995_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c995_old
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
  FROM tmp_c995_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c995_old;
