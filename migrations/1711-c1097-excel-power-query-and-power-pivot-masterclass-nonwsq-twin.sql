-- C1097: "Data Analytics Using Power Query and Power Pivot" -> "Excel Power Query and
-- Power Pivot Masterclass", the 2-day non-WSQ twin of TGS-2026064177 (CASL - Excel Power
-- Query and Power Pivot). Already 2 days / 15 hrs / $700 - fee, duration and sessions unchanged.
--
-- 1. name, url_key/url_path (data-analytics-using-power-query-and-power-pivot ->
--    excel-power-query-and-power-pivot-masterclass), cover alt/gallery labels, meta data.
-- 2. "What's This Course About" and course topics copied from the parent (literals; trailing
--    NBSPs on the parent's topic titles dropped).
-- 3. Prerequisite software: Python 3.x (left over from the entity's Quantum Computing life)
--    -> Microsoft Excel for Microsoft 365 (Windows); hardware Windows laptop.
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Funding block linked straight to the parent's live URL (casl-...); the old wsq- link 301s.
-- 6. 301s: system rows renamed in place; every old path 301s one hop to the new bare slug;
--    search terms that redirected to the old slug follow it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template B17 (gid 189) -> B05 to match the
-- parent's (SG) WSQ-B05 (gid 273), then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1097' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064177' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Excel Power Query and Power Pivot Masterclass';
SET @old_slug  := 'data-analytics-using-power-query-and-power-pivot';
SET @new_slug  := 'excel-power-query-and-power-pivot-masterclass';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
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
SELECT 4, @a_mtitle, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master Excel Power Query and Power Pivot in this hands-on masterclass. Clean, reshape, merge and join data, then pivot, group and model it to turn raw datasets into business insights.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Excel Power Query and Power Pivot Masterclass, Excel Power Query, Power Pivot, Excel data analysis, data transformation, Power Query joins, fuzzy matching, pivot and unpivot, business intelligence, advanced Excel'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------- About / topics / prereq --
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course equips participants with the skills to leverage Excel Power Query and Power Pivot for advanced data analysis. Starting with Power Query, learners will explore various data types, perform queries from different sources, and manipulate data using techniques like fill up/down, split columns, merge columns, and sort/filter data. These foundational skills enable uncovering trends and patterns effectively in diverse datasets.</p><p>The course progresses to complex analyses using Power Pivot, teaching participants to use IF formulas, nest logical functions, and utilize advanced features like Pivot, Group By, and Append Queries. Advanced Power Query topics such as joins, fuzzy matching, and the use of transformation tables will also be covered, providing learners with the tools to address business issues through robust data analysis.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Review Data with Power Query","subsecs":[{"title":"Data types explained","links":[]},{"title":"Query data from a table or range","links":[]},{"title":"Query data from another Excel file","links":[]},{"title":"Load data only as a connection","links":[]},{"title":"Fill up and fill down","links":[]},{"title":"Split column by delimiter","links":[]},{"title":"Split into rows","links":[]},{"title":"Add conditional and custom columns","links":[]},{"title":"Add column by example","links":[]},{"title":"Merge columns","links":[]},{"title":"Sort and filter data in Power Query","links":[]}]},{"title":"Topic 2: Data Analysis with Power Query and Power Pivot","subsecs":[{"title":"Use IF formulas","links":[]},{"title":"Nest IF and AND","links":[]},{"title":"AddDays to determine the deadline","links":[]},{"title":"Pivot data in Power Query","links":[]},{"title":"Pivot and append data","links":[]},{"title":"Pivot and don\'t aggregate","links":[]},{"title":"Unpivot data in Power Query","links":[]},{"title":"Unpivot warnings","links":[]},{"title":"Group By feature","links":[]},{"title":"Appending Queries","links":[]}]},{"title":"Topic 3: Advanced Data Analysis using Power Query","subsecs":[{"title":"Overview of joins in Power Query","links":[]},{"title":"Walk through all six joins","links":[]},{"title":"Joins: Left or right","links":[]},{"title":"Outer join versus XLOOKUP","links":[]},{"title":"Merge with multiple fields","links":[]},{"title":"Approximate match equivalent of VLOOKUP: Binning","links":[]},{"title":"Approximate match equivalent of VLOOKUP: Conditional column","links":[]},{"title":"Cross Join","links":[]},{"title":"Drill down to create a variable in Power Query","links":[]},{"title":"Fuzzy matching by percentage","links":[]},{"title":"Merging inconsistent data with a transformation table","links":[]}]}] -->\r\n<p><strong>Topic 1: Review Data with Power Query</strong></p>\r\n<p><em>Data types explained</em></p>\r\n<p><em>Query data from a table or range</em></p>\r\n<p><em>Query data from another Excel file</em></p>\r\n<p><em>Load data only as a connection</em></p>\r\n<p><em>Fill up and fill down</em></p>\r\n<p><em>Split column by delimiter</em></p>\r\n<p><em>Split into rows</em></p>\r\n<p><em>Add conditional and custom columns</em></p>\r\n<p><em>Add column by example</em></p>\r\n<p><em>Merge columns</em></p>\r\n<p><em>Sort and filter data in Power Query</em></p>\r\n<p><strong>Topic 2: Data Analysis with Power Query and Power Pivot</strong></p>\r\n<p><em>Use IF formulas</em></p>\r\n<p><em>Nest IF and AND</em></p>\r\n<p><em>AddDays to determine the deadline</em></p>\r\n<p><em>Pivot data in Power Query</em></p>\r\n<p><em>Pivot and append data</em></p>\r\n<p><em>Pivot and don\'t aggregate</em></p>\r\n<p><em>Unpivot data in Power Query</em></p>\r\n<p><em>Unpivot warnings</em></p>\r\n<p><em>Group By feature</em></p>\r\n<p><em>Appending Queries</em></p>\r\n<p><strong>Topic 3: Advanced Data Analysis using Power Query</strong></p>\r\n<p><em>Overview of joins in Power Query</em></p>\r\n<p><em>Walk through all six joins</em></p>\r\n<p><em>Joins: Left or right</em></p>\r\n<p><em>Outer join versus XLOOKUP</em></p>\r\n<p><em>Merge with multiple fields</em></p>\r\n<p><em>Approximate match equivalent of VLOOKUP: Binning</em></p>\r\n<p><em>Approximate match equivalent of VLOOKUP: Conditional column</em></p>\r\n<p><em>Cross Join</em></p>\r\n<p><em>Drill down to create a variable in Power Query</em></p>\r\n<p><em>Fuzzy matching by percentage</em></p>\r\n<p><em>Merging inconsistent data with a transformation table</em></p>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\r\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\r\n<h2>Minimum Entry Requirement</h2>\r\n<p>Knowledge and Skills</p>\r\n<ul>\r\n<li>Able to operate using computer functions</li>\r\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\r\n</ul>\r\n<p>Attitude</p>\r\n<ul>\r\n<li>Positive Learning Attitude</li>\r\n<li>Enthusiastic Learner</li>\r\n</ul>\r\n<p>Experience</p>\r\n<ul>\r\n<li>Minimum of 1 year of working experience.</li>\r\n</ul>\r\n<p>Target Age Group: 18-65 years old</p>\r\n<h2>Minimum Software/Hardware Requirement</h2>\r\n<p><strong>Software:</strong></p>\r\n<ul>\r\n<li>Microsoft Excel for Microsoft 365 (Windows) with Power Query and Power Pivot&nbsp;<a href="https://www.microsoft.com/en-sg/microsoft-365/excel" title="Microsoft Excel" target="_blank">https://www.microsoft.com/en-sg/microsoft-365/excel</a></li>\r\n</ul>\r\n<p><strong>Hardware:</strong>&nbsp;Windows laptop (Power Pivot is not available in Excel for Mac)</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_prereq) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1097-20261002-185939.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C1097 - Funding and Grant', 'course_C1097_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C1097_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C1097_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s WHERE s.block_id = cms_block.block_id);

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p>\r\n<p>For funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-excel-power-query-and-power-pivot.html" title="CASL - Excel Power Query and Power Pivot">CASL - Excel Power Query and Power Pivot</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C1097_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c1097_old;
CREATE TEMPORARY TABLE tmp_c1097_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c1097_old
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
  FROM tmp_c1097_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c1097_old;

-- ---------------------------------------------------- search redirects ----
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');
