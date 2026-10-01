-- C1306: re-activate and rename "Building Information Modeling (BIM) with Revit" -> "Revit BIM Masterclass",
-- the 2-day non-WSQ twin of TGS-2026064717 (WSQ - Application of BIM using Revit).
--
-- 1. status -> Enabled (the course was disabled).
-- 2. name, url_key/url_path (building-information-modeling-bim-with-revit -> revit-bim-masterclass),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 3. "What's This Course About" and course topics follow the WSQ parent (its 2 About paragraphs,
--    "WSQ-accredited Application of BIM using Revit course" -> "hands-on Revit BIM Masterclass", and its
--    4 topics, LSN_DATA JSON + HTML). Written as ASCII literals. Neither text states a day count.
--    Duration 15 hrs, Sessions 2 and $700 stay as they are.
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Funding block already points at the WSQ twin -> untouched.
-- 6. 301s: the product's system rows are renamed in place to the new slug (so the new URL resolves
--    without a rewrite refresh); every old path, bare or category-prefixed, 301s one hop to the new
--    BARE slug, legacy RP rows and search redirects are flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template B05 -> B15 (gid 258) via the code path, then
-- full reindex (re-enabled product needs price + stock indexes rebuilt) + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1306' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064717' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Revit BIM Masterclass';
SET @old_slug  := 'building-information-modeling-bim-with-revit';
SET @new_slug  := 'revit-bim-masterclass';

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

-- ----------------------------------------------------------- activate -----
UPDATE catalog_product_entity_int SET value = 1
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_status;

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
SELECT 4, @a_mdesc, 0, @pid, 'Master Building Information Modeling with Autodesk Revit in this hands-on masterclass: BIM modeling, design integration, analysis, compliance and BIM documentation at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Revit BIM Masterclass, Revit BIM, Revit Course, Revit Training, Building Information Modeling, BIM Course, BIM Modeling, BIM Documentation, BIM e-submission, Autodesk Revit, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Get ahead in the construction and design sectors with our hands-on Revit BIM Masterclass. From beginners to seasoned professionals, this course is designed to cover every aspect of Building Information Modeling (BIM) through the powerful Revit software. You\'ll acquire practical skills in design automation, creating 3D models, and managing construction documents, setting you on the path to project management excellence.</p><p>Upon completion of this hands-on course, you\'ll be adept in utilizing Revit for various applications in BIM, including construction management and design optimization. You\'ll be able to streamline workflows, reduce project risk, and enhance design quality, making you an invaluable asset in any architecture or construction project. Take advantage of our comprehensive curriculum to excel in one of the industry\'s most sought-after skill sets.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Introduction to BIM and Revit","subsecs":[{"title":"What is BIM","links":[]},{"title":"Principles of BIM","links":[]},{"title":"Value proposition of BIM","links":[]},{"title":"Requirements and applications of BIM","links":[]},{"title":"Introduction of Revit for BIM","links":[]}]},{"title":"Topic 2: BIM Modeling","subsecs":[{"title":"Develop Models for building elements","links":[]},{"title":"BIM design integration","links":[]}]},{"title":"Topic 3: BIM Application","subsecs":[{"title":"Apply and operate BIM","links":[]},{"title":"Interpret Output","links":[]},{"title":"Analyze Performance and Check Compliance","links":[]}]},{"title":"Topic 4: BIM Documentation","subsecs":[{"title":"Maintain BIM databases and information systems","links":[]},{"title":"Documentation required for BIM","links":[]},{"title":"BIM e-submission documentation requirements and standards","links":[]}]}] -->\n<p><strong>Topic 1: Introduction to BIM and Revit</strong></p>\n<p><em>What is BIM</em></p>\n<p><em>Principles of BIM</em></p>\n<p><em>Value proposition of BIM</em></p>\n<p><em>Requirements and applications of BIM</em></p>\n<p><em>Introduction of Revit for BIM</em></p>\n<p><strong>Topic 2: BIM Modeling</strong></p>\n<p><em>Develop Models for building elements</em></p>\n<p><em>BIM design integration</em></p>\n<p><strong>Topic 3: BIM Application</strong></p>\n<p><em>Apply and operate BIM</em></p>\n<p><em>Interpret Output</em></p>\n<p><em>Analyze Performance and Check Compliance</em></p>\n<p><strong>Topic 4: BIM Documentation</strong></p>\n<p><em>Maintain BIM databases and information systems</em></p>\n<p><em>Documentation required for BIM</em></p>\n<p><em>BIM e-submission documentation requirements and standards</em></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1306-20261001-045501.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c1306_old;
CREATE TEMPORARY TABLE tmp_c1306_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c1306_old
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
  FROM tmp_c1306_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c1306_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
