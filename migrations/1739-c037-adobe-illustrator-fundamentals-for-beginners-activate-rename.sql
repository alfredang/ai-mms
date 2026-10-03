-- C037: "Generative AI for Concept Art" (disabled) -> "Adobe Illustrator Fundamentals for Beginners",
-- re-enabled as the 1-day non-WSQ twin of TGS-2021003160 (WSQ - Creating Professional Graphics with
-- Adobe Illustrator). Fee $350, 7.5 h, 1 session (unchanged).
--
-- 1. status -> Enabled.
-- 2. name, url_key/url_path (generative-ai-for-concept-art -> adobe-illustrator-fundamentals-for-beginners),
--    cover alt/gallery labels, meta title/description/keywords.
-- 3. About + topics + who-should-attend copied from the WSQ parent (opener names this course;
--    no day count). Software requirement -> Adobe Illustrator (was "TBD").
-- 4. Funding block linked straight to the parent's live URL (was WSQ GenAI for Content Creation).
-- 5. Categories: leave Infocomm 55, GenAI Content Creation 200, AI Courses 252, Generative AI
--    Series 433; join Graphics Design 70 + Adobe Illustrator 242 (funded first, then non-WSQ
--    alphabetical). Master listing 3 kept. Delta mirrored into catalog_category_product_index.
-- 6. 301s: system rows renamed in place; dropped-category paths + every legacy RP row 301 one hop
--    to the new bare slug. Search terms follow the slug; the "Mastering Concept Art" terms are
--    cleared (the course is no longer concept art) so Magento search handles them.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): cover re-render (Agent API regenerate_image), schedule template
-- A11 (gid 124) -> A07 (gid 69) via the controller code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C037' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021003160' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Adobe Illustrator Fundamentals for Beginners';
SET @old_slug  := 'generative-ai-for-concept-art';
SET @new_slug  := 'adobe-illustrator-fundamentals-for-beginners';

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
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

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
SELECT 4, @a_mdesc, 0, @pid, 'Adobe Illustrator Fundamentals for Beginners in Singapore: a hands-on course in vector shapes, drawing tools, colour, gradients, patterns, symbols, type, image tracing and artboards.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Adobe Illustrator Fundamentals, Adobe Illustrator, Illustrator for Beginners, Illustrator Course, Vector Graphics, Logo Design, Typography, Digital Graphics, Graphic Design, Tertiary Courses'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_urlkey, @a_urlpath) AND store_id <> 0;

-- ------------------------------------------ About + topics + audience ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Unleash your creativity with our Adobe Illustrator Fundamentals for Beginners course. Our comprehensive program will guide you through the core features of Adobe Illustrator, including vector graphics creation, logo design, and typography. Designed to cater to both beginners and those looking to refine their skills, this course equips you with the essentials needed to produce professional-grade graphic designs.</p>\n<p>Structured around practical, hands-on exercises and industry-relevant projects, you''ll be enabled to apply your newfound skills in various real-world applications. Whether you aim to advance your career in graphic design or improve your skill set for personal projects, you''ll emerge from this course with a portfolio showcasing your capabilities in digital graphics creation.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Basic Digital Graphics Design with Illustrator</h3>\n<ul>\n<li>Illustrator Environment</li>\n<li>Selection</li>\n<li>Shape</li>\n<li>Drawing Tools</li>\n<li>Color</li>\n<li>Strokes</li>\n<li>Arrange and Ordering Layers</li>\n<li>Groups</li>\n<li>Transforms</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2: Improve Digital Graphics Design with Illustrator</h3>\n<ul>\n<li>Drawing by Construction</li>\n<li>Guides and Grids</li>\n<li>Gradients</li>\n<li>Patterns</li>\n<li>Symbols</li>\n<li>Blends</li>\n<li>Appearances</li>\n<li>Type</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3: Evaluate Graphics Design with Illustrator</h3>\n<ul>\n<li>Using Images</li>\n<li>Pixel to Vector</li>\n<li>Artboards</li>\n<li>Output Intellectual property Considerations</li>\n</ul>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul><li>Graphic Designer</li><li>Illustration Artist</li><li>Logo Designer</li><li>Branding Designer</li><li>Visual Identity Designer</li><li>UI/UX Designer</li><li>Vector Artist</li><li>Print Designer</li><li>Motion Graphics Designer</li><li>Apparel and Merchandise Designer</li><li>Packaging Designer</li><li>Web Designer</li><li>Icon Designer</li><li>Digital Media Artist</li><li>Signage and Banner Designer</li></ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2><p>Your will get 10% discount voucher for 2nd course onwards if you write us a <u><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" rel="noopener noreferrer" target="_blank">Google review</a>.</u></p><h2>Minimum Entry Requirement</h2><p>Knowledge and Skills</p><ul><li>Able to operate using computer functions</li><li>Minimum 3 GCE ''O'' Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li></ul><p>Attitude</p><ul><li>Positive Learning Attitude</li><li>Enthusiastic Learner</li></ul><p>Experience</p><ul><li>Minimum of 1 year of working experience.</li></ul><p>Target Age Group: 18-65 years old</p><h2>Minimum Software/Hardware Requirement</h2><p><strong>Software:</strong></p><p>You can download and install the following software:</p><ul><li><u><a href="https://www.adobe.com/products/illustrator.html" rel="noopener noreferrer" target="_blank">Adobe Illustrator</a></u></li></ul><p><strong>Hardware:</strong> Windows and Mac Laptops</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey, @a_prereq) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-creating-professional-graphics-with-adobe-illustrator.html" title="WSQ - Creating Professional Graphics with Adobe Illustrator">WSQ - Creating Professional Graphics with Adobe Illustrator</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C037_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + every category-prefixed one).
DROP TEMPORARY TABLE IF EXISTS tmp_c037_old;
CREATE TEMPORARY TABLE tmp_c037_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c037_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Leave the old categories: their system rewrites go (their old paths 301 below).
DELETE FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1 AND category_id IN (55, 200, 252, 433);

-- 3) Rename the remaining system rows (bare + category 3) in place, so the new slug resolves now.
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
  FROM tmp_c037_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c037_old;

-- ---------------------------------------------------- search redirects ----
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');

UPDATE catalogsearch_query
   SET redirect = NULL
 WHERE @ok AND redirect = 'https://www.tertiarycourses.com.sg/mastering-concept-art-with-generative-ai-genai-unlock-your-creativity.html';

-- ---------------------------------------------------------- categories ----
DELETE FROM catalog_category_product
 WHERE @ok AND product_id = @pid AND category_id IN (55, 200, 252, 433);

SET @in70  := (SELECT COUNT(*) FROM catalog_category_product WHERE category_id = 70  AND product_id = @pid);
SET @in242 := (SELECT COUNT(*) FROM catalog_category_product WHERE category_id = 242 AND product_id = @pid);

-- Graphics Design 70: funded first, then non-WSQ A-Z -> C037 heads the non-WSQ block.
UPDATE catalog_category_product SET position = position + 1
 WHERE @ok AND category_id = 70 AND position >= 9 AND product_id <> @pid AND @in70 = 0;
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 70, @pid, 9 FROM DUAL WHERE @ok;

-- Adobe Illustrator 242: WSQ twin, then C037, then C152 (Generative AI for Adobe Illustrator).
UPDATE catalog_category_product SET position = position + 1
 WHERE @ok AND category_id = 242 AND position >= 2 AND product_id <> @pid AND @in242 = 0;
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 242, @pid, 2 FROM DUAL WHERE @ok;

-- ------------------------------------------------ category index mirror ----
-- The listing reads catalog_category_product_index, and a full reindex scrambles curated
-- anchor positions, so mirror the delta here. Direct members (3, 70, 242) get is_parent=1;
-- their anchor ancestors (root 2, 69 Media & Design, 53 Software Training, 65 Adobe) inherit.
DELETE FROM catalog_category_product_index
 WHERE @ok AND product_id = @pid AND category_id IN (55, 200, 252, 433);

UPDATE catalog_category_product_index i
  JOIN catalog_category_product cp ON cp.category_id = i.category_id AND cp.product_id = i.product_id
   SET i.position = cp.position
 WHERE @ok AND i.category_id IN (70, 242) AND i.store_id = 1;

INSERT INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT c.category_id, @pid, c.position, c.is_parent, 1, 4
  FROM (SELECT 3 AS category_id, 1 AS is_parent, (SELECT position FROM catalog_category_product WHERE category_id = 3 AND product_id = @pid) AS position
        UNION ALL SELECT 70,  1, 9
        UNION ALL SELECT 242, 1, 2
        UNION ALL SELECT 2,   0, (SELECT position FROM catalog_category_product WHERE category_id = 3 AND product_id = @pid)
        UNION ALL SELECT 69,  0, 9
        UNION ALL SELECT 53,  0, 2
        UNION ALL SELECT 65,  0, 2) c
 WHERE @ok AND c.position IS NOT NULL
ON DUPLICATE KEY UPDATE position = VALUES(position), is_parent = VALUES(is_parent);
