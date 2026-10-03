-- C897: "Creative Design with Generative AI (GenAI) in Photoshop and Firefly" (disabled) ->
-- "Photoshop Fundamentals for Beginners", re-enabled as the 1-day non-WSQ twin of TGS-2021003585
-- (WSQ - Professional Digital Image Editing with Photoshop). Fee $350, 7.5 h, 1 session (unchanged).
--
-- 1. status -> Enabled.
-- 2. name, url_key/url_path (creative-design-with-generative-ai-in-photoshop-and-firefly ->
--    photoshop-fundamentals-for-beginners), cover alt/gallery labels, meta title/description/keywords.
-- 3. About + topics + who-should-attend copied from the WSQ parent (opener names this course;
--    no day count). Literal upserts at store 0 (a parent-JOIN copy can no-op on prod).
-- 4. Funding block linked straight to the parent's live URL (was the GenAI Photoshop WSQ course).
-- 5. No longer a GenAI course: removed from category 200 (GenAI Content Creation).
-- 6. 301s: system rows renamed in place; every old path 301s one hop to the new bare slug;
--    legacy RP rows (adobe-photoshop-cc-essential-training-897, advanced-photoshop-cc-training)
--    flattened onto it; search terms that redirected to the old slug follow it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): cover re-render (Agent API regenerate_image), schedule template
-- A04 (gid 128) -> A01 (gid 78) via the controller code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C897' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021003585' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Photoshop Fundamentals for Beginners';
SET @old_slug  := 'creative-design-with-generative-ai-in-photoshop-and-firefly';
SET @new_slug  := 'photoshop-fundamentals-for-beginners';

SET @a_status  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');
SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');

-- ------------------------------------------------------------ enable -----
UPDATE catalog_product_entity_int SET value = 1
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_status AND store_id = 0;

DELETE FROM catalog_product_entity_int
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_status AND store_id <> 0;

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
SELECT 4, @a_mtitle, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Photoshop Fundamentals for Beginners in Singapore: a hands-on course in layers, brushes, masking, selections, retouching, blend modes, smart objects, colour adjustments and filters.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Photoshop Fundamentals, Adobe Photoshop, Photoshop for Beginners, Photoshop Course, Image Editing, Photo Retouching, Layers and Masking, Digital Imaging, Graphic Design, Tertiary Courses'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_urlkey, @a_urlpath) AND store_id <> 0;

-- ------------------------------------------ About + topics + audience ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Embark on a creative journey with our Photoshop Fundamentals for Beginners course. Gain expertise in the most sought-after image editing tools, from the fundamentals to advanced techniques. The course covers essential Photoshop features such as layers, filters, color adjustments, and photo manipulation, equipping you with the skills to excel in the field of graphic design.</p>\n<p>The course adopts a practical approach, combining instructional modules with hands-on exercises and real-world projects. These projects allow you to apply your newly acquired Photoshop skills in various industry-relevant scenarios. By the end of the course, you''ll possess the competence to produce top-quality digital images, whether for personal use or professional purposes.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Basic Photoshop Techniques</h3>\n<ul>\n<li>Understanding Digital Image Essentials</li>\n<li>Cropping, Straightening and Adjusting Canvas Size</li>\n<li>Exploring Layers</li>\n<li>Working with Brushes</li>\n<li>Exploring Masking Techniques</li>\n<li>Making Selection</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2: Improve Digital Imagery</h3>\n<ul>\n<li>Local Pixel Editing and Retouching</li>\n<li>Using Blend Modes</li>\n<li>Working with Smart Objects</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3: Evaluate Digital Imaging Techniques</h3>\n<ul>\n<li>Understanding Perspective and Transforming Images</li>\n<li>Understanding Colour Basics and Applying Layer Adjustment</li>\n<li>Applying Filters</li>\n<li>Intellectual property Considerations</li>\n</ul>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul>\n<li>Graphic Designer</li>\n<li>Photo Retoucher</li>\n<li>Digital Artist</li>\n<li>UI/UX Designer</li>\n<li>Web Designer</li>\n<li>Concept Artist</li>\n<li>Matte Painter</li>\n<li>Digital Illustrator</li>\n<li>Print Designer</li>\n<li>Multimedia Designer</li>\n<li>Advertising Designer</li>\n<li>Game Texture Artist</li>\n<li>Visual Effects Artist</li>\n<li>Fashion Editor</li>\n<li>Branding Designer</li>\n</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
UPDATE cms_block
   SET content = '<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-professional-digital-image-editing-with-photoshop.html" title="WSQ - Professional Digital Image Editing with Photoshop">WSQ - Professional Digital Image Editing with Photoshop</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C897_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed, incl. category 200).
DROP TEMPORARY TABLE IF EXISTS tmp_c897_old;
CREATE TEMPORARY TABLE tmp_c897_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c897_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Leave the GenAI category: membership + its system rewrite (its old path 301s below).
DELETE FROM catalog_category_product         WHERE @ok AND product_id = @pid AND category_id = 200;
DELETE FROM catalog_category_product_index   WHERE @ok AND product_id = @pid AND category_id = 200;
DELETE FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1 AND category_id = 200;

-- 3) Rename the remaining system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 5) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c897_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c897_old;

-- ---------------------------------------------------- search redirects ----
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');
