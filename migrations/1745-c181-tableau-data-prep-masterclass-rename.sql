-- C181: "Tableau Certified Desktop Specialist Training" -> "Tableau Data Prep Masterclass",
-- 2-day non-WSQ twin of TGS-2025053175 (Tableau Desktop Foundations). Fee $700, 15 h,
-- 2 sessions (unchanged). Already enabled.
--
-- 1. name, url_key/url_path (tableau-certified-desktop-specialist-exam-prep ->
--    tableau-data-prep-masterclass), cover alt/gallery labels, meta title/description/keywords.
-- 2. About + topics + who-should-attend copied from the WSQ parent (opener names this course;
--    no day count). Software requirement -> Tableau Desktop (was XAMPP + Basic HTML/CSS from the
--    entity's PHP life).
-- 3. Funding block linked to the parent's live URL (was its retired WSQ slug + old title).
-- 4. 301s: system rows renamed in place; every old path + legacy RP row 301s one hop to the new
--    bare slug. Categories unchanged (alphabetical slot unchanged: still before Tableau Masterclass).
-- 5. Search: the Desktop Specialist cert-intent terms go to the WSQ parent (the cert course);
--    c181/c0181 follow the new slug.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): cover re-render (Agent API regenerate_image), schedule template
-- B13 (gid 191) -> B19 (gid 108) via the controller code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C181' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053175' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Tableau Data Prep Masterclass';
SET @old_slug  := 'tableau-certified-desktop-specialist-exam-prep';
SET @new_slug  := 'tableau-data-prep-masterclass';

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
SELECT 4, @a_mdesc, 0, @pid, 'Tableau Data Prep Masterclass in Singapore: hands-on Tableau Desktop training to connect and prepare data, analyse it with calculations and filters, and share insights through dashboards and workbooks.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Tableau Data Prep Masterclass, Tableau data preparation, Tableau Desktop, Tableau training Singapore, data visualization training, Tableau dashboards, Tableau for beginners, Tertiary Courses'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_urlkey, @a_urlpath) AND store_id <> 0;

-- ------------------------------------------ About + topics + audience ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>The <strong>Tableau Data Prep Masterclass</strong> course equips learners with the essential knowledge and practical skills needed to work confidently with Tableau Desktop while preparing for the <strong>Salesforce Certified Tableau Desktop Foundations</strong> certification.</p><p>The course provides hands-on practice with the core Tableau capabilities assessed in the certification. Participants will learn to connect to and prepare data from different sources, understand Tableau data structures, and work effectively with dimensions, measures, discrete and continuous fields, and aggregations. Learners will also develop skills in filtering, sorting, grouping, calculations, and organizing data to support accurate analysis.</p><p>Through practical exercises, participants will create a range of visualizations, including charts, tables, maps, and interactive dashboards. They will learn how to apply formatting, analytics, and dashboard features to communicate data insights clearly and effectively.</p><p>The course also emphasizes certification preparation, reinforcing key Tableau Desktop concepts, terminology, workflows, and practical techniques aligned with the Salesforce certification requirements. Practice activities and review exercises help learners strengthen their understanding and become familiar with the types of knowledge and skills expected in the certification assessment.</p><p>By the end of the course, participants will have a strong foundation in Tableau Desktop for real-world data visualization and analytics, while being better prepared to pursue the Salesforce Certified Tableau Desktop Foundations credential.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Connecting to and Preparing Data in Tableau Desktop","subsecs":[]},{"title":"Topic 2: Exploring and Analyzing Data in Tableau Desktop","subsecs":[]},{"title":"Topic 3: Sharing Insights with Dashboards and Workbooks","subsecs":[]},{"title":"Topic 4: Understanding Tableau Concepts and Certification Preparation","subsecs":[]}] -->\n<p><strong>Topic 1: Connecting to and Preparing Data in Tableau Desktop</strong></p>\n<p><strong>Topic 2: Exploring and Analyzing Data in Tableau Desktop</strong></p>\n<p><strong>Topic 3: Sharing Insights with Dashboards and Workbooks</strong></p>\n<p><strong>Topic 4: Understanding Tableau Concepts and Certification Preparation</strong></p>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul>\n<li>Data Analyst</li>\n<li>Business Intelligence Analyst</li>\n<li>Tableau Developer</li>\n<li>Data Visualization Specialist</li>\n<li>Business Analyst</li>\n<li>Marketing Analyst</li>\n<li>Financial Analyst</li>\n<li>Operations Analyst</li>\n<li>IT Analyst</li>\n<li>Tableau Consultant</li>\n<li>Reporting Analyst</li>\n<li>Dashboard Designer</li>\n<li>Data Engineer</li>\n<li>Data Scientist</li>\n<li>Product Analyst</li>\n<li>Market Research Analyst</li>\n<li>Supply Chain Analyst</li>\n<li>CRM Analyst</li>\n<li>Performance Analyst</li>\n<li>Project Analyst</li>\n</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2><p>Your will get 10% discount voucher for 2nd course onwards if you write us a <u><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" rel="noopener noreferrer" target="_blank">Google review</a>.</u></p><h2>Minimum Entry Requirement</h2><p>Knowledge and Skills</p><ul><li>Able to operate using computer functions</li><li>Minimum 3 GCE ''O'' Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li></ul><p>Attitude</p><ul><li>Positive Learning Attitude</li><li>Enthusiastic Learner</li></ul><p>Experience</p><ul><li>Minimum of 1 year of working experience.</li></ul><p>Target Age Group: 18-65 years old</p><h2>Minimum Software/Hardware Requirement</h2><p><strong>Software:</strong></p><p>You can download and install the following software:</p><ul><li><u><a href="https://www.tableau.com/products/desktop/download" rel="noopener noreferrer" target="_blank">Tableau Desktop (free trial)</a></u></li></ul><p><strong>Hardware:</strong> Windows and Mac Laptops</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey, @a_prereq) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/tableau-desktop-foundations.html" title="Tableau Desktop Foundations" target="_blank"><span style="text-decoration: underline;">Tableau Desktop Foundations</span></a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C181_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + every category-prefixed one).
DROP TEMPORARY TABLE IF EXISTS tmp_c181_old;
CREATE TEMPORARY TABLE tmp_c181_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c181_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename the system rows in place, so the new slug resolves now.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old system path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c181_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c181_old;

-- ---------------------------------------------------- search redirects ----
-- Desktop Specialist / certification intent belongs to the WSQ parent (the cert-prep course).
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/tableau-desktop-foundations.html'
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html')
   AND query_text LIKE '%desktop specialist%';

UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');
