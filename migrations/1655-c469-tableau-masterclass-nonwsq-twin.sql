-- C469: "Tableau Desktop Masterclass" -> "Tableau Masterclass", the 2-day non-WSQ twin of
-- TGS-2020503177 (WSQ - Data Visualisation with Tableau).
--
-- 1. name, url_key/url_path (tableau-desktop-masterclass -> tableau-masterclass), cover alt/gallery
--    labels, meta_title/description/keyword.
-- 2. "What's This Course About" and course topics follow the WSQ parent (its 2 About paragraphs,
--    "comprehensive WSQ-endorsed course" -> "hands-on Tableau Masterclass", and its 6 topics,
--    LSN_DATA JSON + HTML). Written as ASCII literals, not a parent join (see 1619). Neither text
--    states a day count. Duration 15 hrs, Sessions 2 and the fee stay as they are.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. Funding block: "No funding" now points at the WSQ twin.
-- 5. 301s: the product's system rows are renamed in place to the new slug (so the new URL resolves
--    without a rewrite refresh); every old path, bare or category-prefixed, 301s one hop to the new
--    BARE slug, legacy RP rows and search redirects are flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template -> B09 via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C469' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2020503177' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Tableau Masterclass';
SET @old_slug  := 'tableau-desktop-masterclass';
SET @new_slug  := 'tableau-masterclass';

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
SELECT 4, @a_mdesc, 0, @pid, 'Master Tableau in this hands-on masterclass: connect and model data, build charts, dashboards and stories, use calculations and parameters, and apply forecasting and clustering at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Tableau Masterclass, Tableau, Tableau Desktop, Tableau Course, Tableau Training, Data Visualisation, Data Visualization, Tableau Dashboard, Data Storytelling, Calculated Fields, Parameters, Forecasting, Clustering, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Unlock the capabilities of Tableau for visual storytelling in our hands-on Tableau Masterclass. We cover everything from the basics of data import and cleaning to crafting advanced interactive dashboards. You\'ll learn how to use Tableau\'s extensive set of tools through hands-on exercises and real-world examples, ensuring you acquire practical skills to transform raw data into insightful visual narratives.</p>\n<p>By the end of this course, you\'ll be proficient in using Tableau for a variety of data visualization needs. You\'ll be able to create compelling dashboards that communicate complex data in a straightforward, insightful manner. This course is perfect for analysts, business professionals, or anyone keen on leveraging data to make informed decisions and to tell powerful stories with data.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Basic Tableau Features","subsecs":[{"title":"Overview of Tableau","links":[]},{"title":"Explore Tableau Interface","links":[]},{"title":"Dimension and Measure","links":[]},{"title":"Continuous and Categorical Data","links":[]},{"title":"Folder and Hierarchy","links":[]}]},{"title":"Topic 2: Data Visualisation","subsecs":[{"title":"Data Sources & Extract","links":[]},{"title":"Data Join & Blending","links":[]},{"title":"Scatter Plots","links":[]},{"title":"Bar Plots","links":[]},{"title":"Treemap","links":[]}]},{"title":"Topic 3: Data Transformation","subsecs":[{"title":"Data Interpreter","links":[]},{"title":"Split & Merge Fields","links":[]},{"title":"Pivot Data","links":[]},{"title":"Filter Data","links":[]},{"title":"Organize Data by Group & Set","links":[]}]},{"title":"Topic 4: Dashboard and Story","subsecs":[{"title":"Create a Dashboard","links":[]},{"title":"Use Actions","links":[]},{"title":"Create a Story","links":[]}]},{"title":"Topic 5: Calculation & Parameter","subsecs":[{"title":"Create Calculated Field","links":[]},{"title":"Filter By Parameter","links":[]},{"title":"Add Calculation to Parameter","links":[]},{"title":"Reference Line","links":[]},{"title":"Dynamic View","links":[]}]},{"title":"Topic 6: Analytics","subsecs":[{"title":"Average Line","links":[]},{"title":"Trend Line","links":[]},{"title":"Forecast","links":[]},{"title":"Clustering","links":[]}]}] -->\n<p><strong>Topic 1: Basic Tableau Features</strong></p>\n<p><em>Overview of Tableau</em></p>\n<p><em>Explore Tableau Interface</em></p>\n<p><em>Dimension and Measure</em></p>\n<p><em>Continuous and Categorical Data</em></p>\n<p><em>Folder and Hierarchy</em></p>\n<p><strong>Topic 2: Data Visualisation</strong></p>\n<p><em>Data Sources &amp; Extract</em></p>\n<p><em>Data Join &amp; Blending</em></p>\n<p><em>Scatter Plots</em></p>\n<p><em>Bar Plots</em></p>\n<p><em>Treemap</em></p>\n<p><strong>Topic 3: Data Transformation</strong></p>\n<p><em>Data Interpreter</em></p>\n<p><em>Split &amp; Merge Fields</em></p>\n<p><em>Pivot Data</em></p>\n<p><em>Filter Data</em></p>\n<p><em>Organize Data by Group &amp; Set</em></p>\n<p><strong>Topic 4: Dashboard and Story</strong></p>\n<p><em>Create a Dashboard</em></p>\n<p><em>Use Actions</em></p>\n<p><em>Create a Story</em></p>\n<p><strong>Topic 5: Calculation & Parameter</strong></p>\n<p><em>Create Calculated Field</em></p>\n<p><em>Filter By Parameter</em></p>\n<p><em>Add Calculation to Parameter</em></p>\n<p><em>Reference Line</em></p>\n<p><em>Dynamic View</em></p>\n<p><strong>Topic 6: Analytics</strong></p>\n<p><em>Average Line</em></p>\n<p><em>Trend Line</em></p>\n<p><em>Forecast</em></p>\n<p><em>Clustering</em></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C469-20261001-051456.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C469 - Funding and Grant', 'course_C469_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C469_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C469_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C469_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-data-visualisation-with-tableau.html" title="WSQ - Data Visualisation with Tableau">WSQ - Data Visualisation with Tableau</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C469_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c469_old;
CREATE TEMPORARY TABLE tmp_c469_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c469_old
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
  FROM tmp_c469_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c469_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
