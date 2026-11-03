-- 1896: TGS-2025053175 "Tableau Desktop Foundations"
--       -> "Tableau Data Prep Fundamentals for Beginners"
--
-- REPURPOSE in place (entity 501). SKU unchanged, stays WSQ: the seven funding tags, price,
-- duration (16h / 2 sessions), schedule options, funding validity (already 2025-02-25 ..
-- 2027-02-24 as requested), trainers and the funding/skills-framework/certification/brochure
-- cms_blocks are left alone. Name keeps its current no-prefix shape (user-supplied title).
--
-- Tool stays Tableau; the focus moves from Tableau Desktop + the Salesforce Tableau Desktop
-- Foundations certification to Tableau Prep data preparation. PROBED on SG prod before writing.
--   * name, url_key/url_path (tableau-desktop-foundations -> tableau-data-prep-fundamentals-
--     for-beginners), meta_title (full rendered shape, seo-meta.md), meta_description,
--     meta_keyword, cover alt labels + media-gallery label, course_image_url (new R2 cover,
--     same 7 badges): course-covers/TGS-2025053175-20261103-025724.png (180188 bytes)
--   * short_description (About), description (4 topics + LSN_DATA marker)
--   * learning_outcomes cms_block -> the supplied LO1-LO4 (no longer "in Tableau Desktop")
--   * prerequisite Software list: Tableau Prep Builder + Tableau Desktop trial (was Desktop
--     trial + Tableau Public account)
--   * trainerprofile: Dr. Ang's and Quah's course-teaching lines -> new title / data prep.
--     Career-history text stays.
--   * categories: OUT of 372 + 427 "Tableau Certification Exam Prep" and 182 "Certification
--     Exam Prep" (the course no longer preps an exam). Stays in 248 Tableau and the rest.
--   * URL rewrites: system rows renamed in place (mig 1620 pattern, no refreshProductRewrite);
--     dropped-category system rows deleted; every old path 301s to the new bare slug; legacy
--     301s flattened to one hop.
--   * search redirects: course code + "tableau fundamental" -> new slug; Tableau Desktop /
--     Desktop Specialist (certification) intent -> Tableau category page (this course no longer
--     teaches Desktop, and the cert twin C919 is retired); stale "open foam" (an earlier life
--     of this entity) cleared so Magento search runs.
--   * twin C181 "Tableau Data Prep Masterclass" Funding block -> the new URL + title.
--
-- Not touched: whoshouldattend (Tableau / analyst roles still apply), upsells/related, the
-- learner reviews, the brochure PDF (regenerated separately).
--
-- SG-only (store guard + SKU must exist) -> no-op on MY/GH. Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @e0 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053175' LIMIT 1);
SET @e  := IF(@sg = 1, @e0, NULL);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @old_slug  := 'tableau-desktop-foundations';
SET @new_slug  := 'tableau-data-prep-fundamentals-for-beginners';
SET @new_title := 'Tableau Data Prep Fundamentals for Beginners';

-- ---------------------------------------------------------------- varchar attrs
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'             AND entity_type_id=@et);
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'          AND entity_type_id=@et);
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path'         AND entity_type_id=@et);
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'       AND entity_type_id=@et);
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et AND backend_type='varchar');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);

UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Funded up to 70% WSQ Tableau Data Prep Fundamentals for Beginners | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- varchar(255): 155 chars.
UPDATE catalog_product_entity_varchar
   SET value = 'Tableau Data Prep for beginners: clean, join and union data and build repeatable Prep flows. Up to 70% WSQ funding; SkillsFuture Credit and UTAP claimable.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   SET v.value = @new_title
 WHERE v.entity_id = @e AND @e IS NOT NULL AND a.entity_type_id = @et
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
  JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
   SET g.label = @new_title
 WHERE m.entity_id = @e AND @e IS NOT NULL;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053175-20261103-025724.png'
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------- text attrs
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword'      AND entity_type_id=@et AND backend_type='text');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description'       AND entity_type_id=@et);
SET @a_pre  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='prerequisite'      AND entity_type_id=@et);
SET @a_tp   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile'    AND entity_type_id=@et);

UPDATE catalog_product_entity_text
   SET value = 'Tableau Prep course, Tableau Prep training Singapore, data cleaning, joins and unions, Tableau Prep Builder flows, WSQ Tableau Prep course, SkillsFuture Credit course, UTAP claimable course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p><strong>Tableau Data Prep Fundamentals for Beginners</strong> is a practical, beginner-friendly course designed to help learners develop essential skills in preparing, cleaning, combining, and organising data for analysis using <strong>Tableau Prep</strong>.</p>',
     '<p>The course introduces the fundamentals of data preparation, including connecting to different data sources, reviewing data quality, identifying inconsistencies, and transforming raw data into structured and analysis-ready datasets. Learners will gain hands-on experience using Tableau Prep to clean data, rename and group fields, change data types, remove unnecessary records, handle missing values, and create calculated fields.</p>',
     '<p>Participants will also learn how to combine datasets using joins and unions, aggregate data, and design repeatable data preparation flows. The course covers how to validate outputs and prepare clean datasets for further analysis and visualisation in Tableau Desktop or other analytics tools.</p>',
     '<p>Through guided exercises and practical examples, learners will build confidence in managing common data preparation tasks and understanding how good data quality contributes to more accurate and meaningful analysis.</p>',
     '<p>This course is suitable for beginners, business users, analysts, and professionals who want to build a strong foundation in data preparation using Tableau Prep without requiring prior programming experience.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- LSN_DATA marker (admin Lesson editor) + the HTML the storefront renders, same four topics.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<!-- LSN_DATA: [',
       '{"title":"Topic 1: Data Sources and Data Quality","subsecs":[]},',
       '{"title":"Topic 2: Data Organisation and Structuring","subsecs":[]},',
       '{"title":"Topic 3: Data Cleaning and Transformation","subsecs":[]},',
       '{"title":"Topic 4: Data Processing and Business Insights","subsecs":[]}] -->\n',
     '<p><strong>Topic 1: Data Sources and Data Quality</strong></p>\n',
     '<p><strong>Topic 2: Data Organisation and Structuring</strong></p>\n',
     '<p><strong>Topic 3: Data Cleaning and Transformation</strong></p>\n',
     '<p><strong>Topic 4: Data Processing and Business Insights</strong></p>\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- Only the two Software <li>s; the rest of the blob is house entry-requirement copy.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li><a href="https://www.tableau.com/products/trial" target="_blank">Tableau Desktop</a> &ndash; 14-day free trial</li>',
       '<li><a href="https://www.tableau.com/products/prep/download" target="_blank">Tableau Prep Builder</a> &ndash; free trial</li>')
 WHERE attribute_id = @a_pre AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li><a href="https://public.tableau.com/" target="_blank">A free Tableau Public account</a></li>',
       '<li><a href="https://www.tableau.com/products/trial" target="_blank">Tableau Desktop</a> &ndash; 14-day free trial (to analyse the prepared data)</li>')
 WHERE attribute_id = @a_pre AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In Tableau Desktop Foundations, Dr. Ang guides learners from connecting data to publishing dashboards that tell a clear story. They build effective charts, use calculations, parameters and analytics features, and design dashboards and stories for their audience. As a data scientist who teaches visual analytics alongside statistics, he stresses choosing the right visual and avoiding misleading charts, so learners communicate insights with confidence.',
       'In Tableau Data Prep Fundamentals for Beginners, Dr. Ang guides learners from raw, messy data to clean, analysis-ready datasets in Tableau Prep. They review data quality, clean and reshape fields, combine sources with joins and unions, and build repeatable prep flows. As a data scientist who teaches analytics alongside statistics, he stresses validating every output, so learners can trust the data behind their analysis.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In the Tableau Certified Data Analyst Training course, Quah focuses on helping learners master the principles of data visualization and storytelling for effective decision-making.',
       'In the Tableau Data Prep Fundamentals for Beginners course, Quah focuses on helping learners prepare clean, well-structured data as the foundation for effective decision-making.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------- learning outcomes block
UPDATE cms_block
   SET content = CONCAT(
     '<p>By end of the course, learners should be able to:</p>\n<ul>\n',
     '<li>LO1: Identify data sources to meet analysis requirements and data quality standards.</li>\n',
     '<li>LO2: Organize data into effective visual elements</li>\n',
     '<li>LO3: Perform database queries to extract and process data sets</li>\n',
     '<li>LO4: Process data using standard procedures to deliver meaningful insights.</li>\n</ul>'),
       update_time = NOW()
 WHERE identifier = 'course_TGS-2025053175_learning_outcomes' AND @e IS NOT NULL;

-- ---------------------------------------------------------------- twin C181 funding link
UPDATE cms_block
   SET content = REPLACE(REPLACE(content,
       'https://www.tertiarycourses.com.sg/tableau-desktop-foundations.html',
       'https://www.tertiarycourses.com.sg/tableau-data-prep-fundamentals-for-beginners.html'),
       'Tableau Desktop Foundations', 'Tableau Data Prep Fundamentals for Beginners'),
       update_time = NOW()
 WHERE identifier = 'course_C181_funding_and_grant' AND @e IS NOT NULL;

-- ---------------------------------------------------------------- categories
DELETE FROM catalog_category_product
 WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (182, 372, 427);
DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (182, 372, 427);

-- ---------------------------------------------------------------- URL rewrites
DROP TEMPORARY TABLE IF EXISTS tmp_501_old;
CREATE TEMPORARY TABLE tmp_501_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_501_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1 AND @e IS NOT NULL
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- Dropped categories: their system rows go (else the course keeps serving under the
-- exam-prep path). Their old paths still 301 below, to the bare slug.
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
  FROM tmp_501_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_501_old;

-- ---------------------------------------------------------------- search redirects
SET @old_url := CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');

UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE redirect = @old_url AND @e IS NOT NULL
   AND query_text IN ('TGS-2025053175', 'tableau fundamental');

UPDATE catalogsearch_query
   SET redirect = ''
 WHERE redirect = @old_url AND @e IS NOT NULL AND query_text = 'open foam';

UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/tableau-software-courses.html'
 WHERE redirect = @old_url AND @e IS NOT NULL;
