-- C179: "AI Vibe Coding for Python Applications" -> "Python Fundamentals Masterclass",
-- the 2-day non-WSQ twin of TGS-2019503161 (WSQ - Python Fundamental Course for Beginners).
--
-- 1. name, url_key/url_path (python-django-web-development-training -> python-fundamentals-masterclass),
--    cover alt/gallery labels, meta_title/description/keyword (orphan varchar meta_keyword dropped).
-- 2. 2 days / 15 hrs / $700 (fee + hours unchanged; Sessions 1 -> 2).
-- 3. "What's This Course About" + the 6 topics follow the WSQ parent ("WSQ-endorsed" dropped).
--    Course Info: the intermediate prerequisites (HTML/CSS/JS/Python) go - this is now a
--    beginner course; software list follows the parent (Python, VS Code, Anaconda, Colab).
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Leaves the AI Vibe Coding Series: badge cleared. Leaves Web Development (cat 4); keeps
--    All Courses 3, Programming 31, Python 32, Infocomm 55. In 31/32 it re-slots at the end of
--    the non-WSQ A-Z block (after C193 Python Data Analysis Masterclass). Index mirrored.
-- 6. Funding block -> the WSQ twin (was WSQ Build and Deploy Python Applications with Vibe Coding).
-- 7. 301s: the product's system rows are renamed in place to the new slug; every old path,
--    bare or category-prefixed, 301s one hop to the new BARE slug.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): switch the schedule template A12 (gid 129) -> B01
-- (gid 188) to match the parent's (SG) WSQ-B01 (both 2 days), then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C179' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2019503161' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Python Fundamentals Masterclass';
SET @old_slug  := 'python-django-web-development-training';
SET @new_slug  := 'python-fundamentals-masterclass';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_series  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_series_badge');

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
SELECT 4, @a_mdesc, 0, @pid, 'Python Fundamentals Masterclass in Singapore: a hands-on beginner course in Python syntax, data types, operators, control structures, loops, functions, modules and packages.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Python Fundamentals, Python for Beginners, Python Course, Python Programming, Learn Python, Data Types, Functions, Modules and Packages, Python Masterclass, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword is a TEXT attribute; the varchar row is an orphan from the vibe-series rewrite.
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mkey;

-- ------------------------------------------- 2 days / 15 hrs / $700 -----
UPDATE catalog_product_entity_decimal SET value = 700
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

UPDATE catalog_product_entity_varchar SET value = '15'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_dur;

UPDATE catalog_product_entity_varchar SET value = '2'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_sess;

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Launch your programming journey with our Python Fundamentals Masterclass. This course is tailored to provide you with a solid foundation in Python, one of the most versatile and widely-used programming languages today. Covering topics such as Python syntax, data types, and basic algorithms, our course offers hands-on exercises to ensure you acquire practical programming skills that are applicable across various industries.</p>\n<p>By the end of this course, you will have a strong grasp of Python fundamentals. You''ll be capable of writing basic Python programs, understanding code structure, and solving simple problems algorithmically. Ideal for those who are new to programming or wish to switch careers, this course equips you with the necessary skills to continue your education in Python or other programming languages.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Get Started on Python</h3>\n<ul>\n<li>Overview of Python</li>\n<li>Install Python</li>\n<li>Install Python IDE</li>\n<li>Code Your First Python Script</li>\n<li>Comment</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2: Data Types</h3>\n<ul>\n<li>Number</li>\n<li>String</li>\n<li>List</li>\n<li>Tuple</li>\n<li>Dictionary</li>\n<li>Set</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3: Operators</h3>\n<ul>\n<li>Arithmetic Operators</li>\n<li>Compound Operators</li>\n<li>Comparison Operators</li>\n<li>Membership Operators</li>\n<li>Logical Operators</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4: Control Structure, Loop and Comprehension</h3>\n<ul>\n<li>Conditional</li>\n<li>Loop</li>\n<li>Iterating Over Multiple Sequences</li>\n<li>Comprehension</li>\n</ul>\n<h3 class="course-topic-h3">Topic 5: Function</h3>\n<ul>\n<li>Function Syntax</li>\n<li>Return Values</li>\n<li>Default Arguments</li>\n<li>Variable Arguments</li>\n<li>Lambda, Map, Filter</li>\n</ul>\n<h3 class="course-topic-h3">Topic 6: Modules &amp; Packages</h3>\n<ul>\n<li>Import Modules and Packages</li>\n<li>Python Standard Packages</li>\n<li>Third Party Packages</li>\n</ul>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 18-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<p>Download and Install the following software</p>\n<ul>\n<li><span style="text-decoration: underline;"><a href="https://www.python.org/downloads/" target="_blank">Python</a></span></li>\n<li><span style="text-decoration: underline;"><a href="https://code.visualstudio.com/" target="_blank">Visual Studio Code</a></span></li>\n<li><span style="text-decoration: underline;"><a href="https://www.anaconda.com/download" target="_blank">Anaconda</a></span></li>\n</ul>\n<p>Sign up free <span style="text-decoration: underline;"><a href="https://colab.research.google.com/" target="_blank">Google Colab account</a></span></p>\n<p><strong>Hardware:</strong>&nbsp;Window or Mac Laptops</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_prereq) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover, @a_urlkey, @a_urlpath) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C179-20261003-234344.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------ leave AI Vibe Coding Series -----
UPDATE catalog_product_entity_varchar SET value = NULL
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_series;

-- ------------------------------------------------------ funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-python-fundamental-course-for-beginners.html" title="WSQ - Python Fundamental Course for Beginners">WSQ - Python Fundamental Course for Beginners</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C179_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + every category-prefixed one).
DROP TEMPORARY TABLE IF EXISTS tmp_c179_old;
CREATE TEMPORARY TABLE tmp_c179_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c179_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Leave Web Development: its system rewrite goes (its old path 301s below).
DELETE FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1 AND category_id = 4;

-- 3) Rename the remaining system rows in place, so the new slug resolves now.
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
  FROM tmp_c179_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c179_old;

-- ---------------------------------------------------------- categories ----
DELETE FROM catalog_category_product
 WHERE @ok AND product_id = @pid AND category_id = 4;

DELETE FROM catalog_category_product_index
 WHERE @ok AND product_id = @pid AND category_id = 4;

-- Programming 31 / Python 32: funded first, then non-WSQ A-Z -> "Python Fundamentals
-- Masterclass" is now the last non-WSQ entry (after "Python Data Analysis Masterclass").
SET @p31 := (SELECT MAX(position) FROM catalog_category_product WHERE category_id = 31 AND product_id <> @pid) + 1;
SET @p32 := (SELECT MAX(position) FROM catalog_category_product WHERE category_id = 32 AND product_id <> @pid) + 1;
SET @i31 := (SELECT MAX(position) FROM catalog_category_product_index WHERE category_id = 31 AND store_id = 1 AND product_id <> @pid) + 1;
SET @i32 := (SELECT MAX(position) FROM catalog_category_product_index WHERE category_id = 32 AND store_id = 1 AND product_id <> @pid) + 1;

UPDATE catalog_category_product SET position = @p31
 WHERE @ok AND category_id = 31 AND product_id = @pid AND @p31 IS NOT NULL;

UPDATE catalog_category_product SET position = @p32
 WHERE @ok AND category_id = 32 AND product_id = @pid AND @p32 IS NOT NULL;

UPDATE catalog_category_product_index SET position = @i31
 WHERE @ok AND category_id = 31 AND store_id = 1 AND product_id = @pid AND @i31 IS NOT NULL;

UPDATE catalog_category_product_index SET position = @i32
 WHERE @ok AND category_id = 32 AND store_id = 1 AND product_id = @pid AND @i32 IS NOT NULL;
