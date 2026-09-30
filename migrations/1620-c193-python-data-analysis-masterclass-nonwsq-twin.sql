-- C193: "AI Vibe Coding for Python Data Analysis" -> "Python Data Analysis Masterclass",
-- the 2-day non-WSQ twin of TGS-2020504082 (WSQ - Data Analytics and Visualization
-- with Python).
--
-- 1. name, url_key/url_path (python-data-analysis-training -> python-data-analysis-masterclass),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. 1 day -> 2 days to match the parent: fee $350 -> $700, Duration 7.5 -> 15 hrs,
--    Sessions 1 -> 2.
-- 3. "What's This Course About" and course topics follow the WSQ parent (About with the
--    "WSQ-endorsed" wording dropped). Written as literals, not a parent join (see 1619).
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Leaves the AI Vibe Coding Series: badge cleared, removed from categories 414
--    (AI Vibe Coding Series) and 252 (AI Courses) - base and index rows.
-- 6. Funding block created (C193 had none) and linked to the WSQ twin.
-- 7. 301s: the product's system rows are renamed in place to the new slug (so the new
--    URL resolves without a rewrite refresh); every old path, bare or category-prefixed,
--    301s one hop to the new BARE slug.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): switch the schedule template A05 (gid 184) -> B11
-- (gid 132) to match the parent's (SG) WSQ-B11, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C193' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2020504082' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Python Data Analysis Masterclass';
SET @old_slug  := 'python-data-analysis-training';
SET @new_slug  := 'python-data-analysis-masterclass';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
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
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mtitle;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master Python data analysis in this hands-on masterclass. Prepare, transform and visualize data with Pandas, Matplotlib and Seaborn, and run statistical and time series analysis at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Python Data Analysis, Data Analytics, Data Visualization, Pandas, Matplotlib, Seaborn, Statistical Analysis, Time Series Analysis, Linear Regression, Python Masterclass, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- 2 days / 15 hrs / $700 -----
UPDATE catalog_product_entity_decimal SET value = 700
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

UPDATE catalog_product_entity_varchar SET value = '15'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_dur;

UPDATE catalog_product_entity_varchar SET value = '2'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_sess;

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Expand your knowledge in data analytics and visualization with our hands-on masterclass focused on Python. Dive into key topics like data manipulation, statistical analysis, and visualization techniques using Python''s powerful libraries. Through practical exercises and real-world examples, you''ll learn to transform raw data into actionable insights and visual narratives that are compelling and easy to understand.</p>\n<p>By the end of this course, you''ll be adept at leveraging Python for advanced data analytics and visualization tasks. Whether you''re a data scientist, business analyst, or someone interested in generating insights from data, this course will provide you with the tools and skills to make impactful, data-driven decisions.</p>\n<h2>Course Objective</h2>\n<p>Learners will be able to prepare data, perform data analysis and data visualization to gain insights into data.&nbsp;</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Data Preparation</h3>\n<ul>\n<li>Data Analytics with Pandas</li>\n<li>Pandas DataFrame and Series</li>\n<li>Import and Export Data</li>\n<li>Filter and Slice Data</li>\n<li>Clean Data</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2: Data Transformation</h3>\n<ul>\n<li>Join Data</li>\n<li>Transform Data</li>\n<li>Aggregate Data</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3: Data Visualization</h3>\n<ul>\n<li>Data Visualization with Matplotlib and Seaborn</li>\n<li>Visualize Statistical Relationships with Scatter Plot</li>\n<li>Visualize Categorical Data with Bar Plot</li>\n<li>Visualize Correlation with Pair Plot and Heatmap</li>\n<li>Visualize Linear Relationships with Regression</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4: Data Analysis</h3>\n<ul>\n<li>Statistical Data Analysis</li>\n<li>Time Series Analysis</li>\n</ul>\n<h3 class="course-topic-h3">Topic 5: Advanced Data Analytics</h3>\n<ul>\n<li>Data Piping</li>\n<li>Groupby and Apply Custom Functions</li>\n<li>Linear Regression</li>\n</ul>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C193-20260930-190800.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------ leave AI Vibe Coding Series -----
UPDATE catalog_product_entity_varchar SET value = NULL
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_series;

DELETE FROM catalog_category_product
 WHERE @ok AND product_id = @pid AND category_id IN (414, 252);

DELETE FROM catalog_category_product_index
 WHERE @ok AND product_id = @pid AND category_id IN (414, 252);

DELETE FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1 AND category_id IN (414, 252);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C193 - Funding and Grant', 'course_C193_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C193_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C193_funding_and_grant';

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-data-analytics-and-visualization-with-python.html" title="WSQ - Data Analytics and Visualization with Python">WSQ - Data Analytics and Visualization with Python</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C193_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c193_old;
CREATE TEMPORARY TABLE tmp_c193_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c193_old
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
  FROM tmp_c193_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c193_old;
