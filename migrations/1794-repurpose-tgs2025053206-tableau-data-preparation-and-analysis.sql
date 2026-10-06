-- 1794: TGS-2025053206 "WSQ - Tableau Certified Data Analyst Training"
--       -> "WSQ - Tableau Data Preparation and Analysis"
--
-- REPURPOSE in place (entity 559). SKU unchanged, stays WSQ: the WSQ prefix,
-- the seven funding tags, price, duration (24h / 3 sessions), schedule options,
-- funding validity, trainers and the funding/skills-framework/certification/
-- brochure cms_blocks are deliberately left alone.
--
-- Tool KEPT (still Tableau), only the certification-exam framing retires.
-- PROBED on SG prod before writing. Surfaces rewritten here:
--   * name, url_key, url_path, meta_title (plain -- MMD_Seotitle adds "WSQ funded"
--     + the brand at render time; the stored "WSQ ... | Tertiary Courses
--     Singapore" produced a duplicated "WSQ funded WSQ ..."), meta_description,
--     meta_keyword (store 0 + store 1 rows)
--   * short_description (About), description (4-topic outline + LSN_DATA marker)
--   * prerequisite: the Software <li> still linked an OpenFOAM installer (this
--     entity's earlier life, openfoam-essential-training-559) -> Tableau Desktop
--   * trainerprofile: Quah's "In the Tableau Certified Data Analyst Training
--     course," teaching line -> new title. Career-history text stays.
--   * image/small_image/thumbnail labels + media-gallery label (alt text);
--     image PATHS untouched (filesystem paths)
--   * course_image_url -> new R2 cover, rendered with the existing badge set:
--       course-covers/TGS-2025053206-20261006-183101.png (168498 bytes)
--   * categories: OUT of 182 Certification Exam Prep, 372 + 427 Tableau
--     Certification Exam Prep (the course no longer preps the exam). Kept:
--     3, 15, 53, 55, 99, 105, 140, 248 Tableau, 287, 292, 301, 307, 345.
--   * URL rewrites: system rows renamed in place (no refreshProductRewrite
--     needed, mig 1620 pattern); dropped-category system rows deleted; every
--     old path 301s to the new bare slug; existing 301s flattened to one hop.
--   * search redirects: all 26 rows pointing at the old slug -> new slug (the
--     cert-intent terms included: the non-WSQ exam-prep twin C919 is disabled/404).
--
-- Not touched: learning_outcomes cms_block (the supplied LO1-LO4 are already
-- live verbatim -- SSG-registered against the unchanged SKU), whoshouldattend
-- (Tableau roles still apply), upsells/related (all Tableau / data courses),
-- the brochure PDF (regenerate separately), the 2 learner reviews.
--
-- SG only: keyed by SKU, no-ops where the SKU is absent. Idempotent.

SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053206' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @old_slug := 'wsq-tableau-certified-data-analyst-training';
SET @new_slug := 'wsq-tableau-data-preparation-and-analysis';

-- ---------------------------------------------------------------- varchar attrs
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'             AND entity_type_id=@et);
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'          AND entity_type_id=@et);
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path'         AND entity_type_id=@et);
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'       AND entity_type_id=@et);
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);

UPDATE catalog_product_entity_varchar SET value = 'WSQ - Tableau Data Preparation and Analysis'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = 'Tableau Data Preparation and Analysis'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- varchar(255): 202 chars.
UPDATE catalog_product_entity_varchar
   SET value = 'Learn Tableau data preparation and analysis in Singapore. Clean, transform and model data, discover patterns, build predictive dashboards and communicate insights to stakeholders. Up to 70% WSQ funding.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   SET v.value = 'Tableau Data Preparation and Analysis'
 WHERE v.entity_id = @e AND @e IS NOT NULL AND a.entity_type_id = @et
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
  JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
   SET g.label = 'Tableau Data Preparation and Analysis'
 WHERE m.entity_id = @e AND @e IS NOT NULL;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053206-20261006-183101.png'
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------- text attrs
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword'      AND entity_type_id=@et);
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description'       AND entity_type_id=@et);
SET @a_pre  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='prerequisite'      AND entity_type_id=@et);
SET @a_tp   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile'    AND entity_type_id=@et);

UPDATE catalog_product_entity_text
   SET value = 'Tableau Data Preparation and Analysis, Tableau training Singapore, Tableau Desktop, data preparation, data cleaning, data modelling, predictive dashboards, data storytelling, WSQ Tableau course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>This Tableau Data Preparation and Analysis course equips learners with practical skills to prepare, analyse, visualise, and interpret data using Tableau. The course covers the complete data analysis workflow, from connecting to different data sources and preparing datasets to performing analysis and presenting meaningful insights through interactive visualisations and dashboards.</p>\n',
     '<p>Learners will develop skills in cleaning, transforming, combining, and organising data to improve data quality and readiness for analysis. They will explore Tableau features for filtering, sorting, grouping, calculations, parameters, and data relationships, while applying appropriate analytical techniques to identify trends, patterns, relationships, and performance indicators.</p>\n',
     '<p>Through hands-on exercises and practical business scenarios, participants will create effective charts, dashboards, and interactive reports that communicate insights clearly to stakeholders. The course also introduces good practices in data visualisation, dashboard design, and analytical storytelling to support evidence-based decision-making.</p>\n',
     '<p>By the end of the course, learners will be able to use Tableau confidently to prepare data, conduct exploratory and business analysis, develop meaningful visualisations, and communicate data-driven insights for organisational decision-making.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- LSN_DATA marker (admin Lesson editor) + the HTML the storefront renders,
-- generated together from the same four topics (topics only, no sub-items).
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<!-- LSN_DATA: [',
       '{"title":"Topic 1: Data Extraction, Preparation and Validation with Tableau Desktop","subsecs":[]},',
       '{"title":"Topic 2: Data Modelling and Business Analysis with Tableau Desktop","subsecs":[]},',
       '{"title":"Topic 3: Pattern Discovery, Predictive Analytics and Dashboard Design","subsecs":[]},',
       '{"title":"Topic 4: Data Storytelling and Communicating Business Insights","subsecs":[]}] -->\n',
     '<p><strong>Topic 1: Data Extraction, Preparation and Validation with Tableau Desktop</strong></p>\n',
     '<p><strong>Topic 2: Data Modelling and Business Analysis with Tableau Desktop</strong></p>\n',
     '<p><strong>Topic 3: Pattern Discovery, Predictive Analytics and Dashboard Design</strong></p>\n',
     '<p><strong>Topic 4: Data Storytelling and Communicating Business Insights</strong></p>\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- Only the Software <li>; the rest of the blob is house entry-requirement copy.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li><a href="https://www.openfoam.com/download/openfoam-installation-on-windows-10" target="_blank"><span style="text-decoration: underline;">OpenFOAM Windows 10</span></a></li>',
       '<li><a href="https://www.tableau.com/products/desktop/download" target="_blank"><span style="text-decoration: underline;">Tableau Desktop</span></a> (free trial)</li>')
 WHERE attribute_id = @a_pre AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In the Tableau Certified Data Analyst Training course, Quah',
       'In the Tableau Data Preparation and Analysis course, Quah')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------- categories
DELETE FROM catalog_category_product
 WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (182, 372, 427);
DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (182, 372, 427);

-- ---------------------------------------------------------------- URL rewrites
-- Dropped categories: their system rows go (else the course keeps serving under
-- the exam-prep path). Their old paths still 301 below, to the bare slug.
DROP TEMPORARY TABLE IF EXISTS tmp_559_old;
CREATE TEMPORARY TABLE tmp_559_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_559_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1 AND @e IS NOT NULL
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1 AND @e IS NOT NULL AND category_id IN (182, 372, 427);

-- Free the new paths of any non-system squatter, then rename system rows in place.
DELETE FROM core_url_rewrite
 WHERE is_system = 0 AND @e IS NOT NULL
   AND (request_path = CONCAT(@new_slug, '.html') OR request_path LIKE CONCAT('%/', @new_slug, '.html'));

UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE product_id = @e AND is_system = 1 AND @e IS NOT NULL
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- Legacy 301s that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE options = 'RP' AND @e IS NOT NULL
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- Every old system path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_559_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_559_old;

-- ---------------------------------------------------------------- search redirects
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html')
   AND @e IS NOT NULL;
