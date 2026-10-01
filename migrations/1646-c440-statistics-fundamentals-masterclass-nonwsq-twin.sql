-- C440: "Statistics for Data Analysis Masterclass" -> "Statistics Fundamentals Masterclass", the
-- 2-day non-WSQ twin of TGS-2026064180 (CASL - Statistics Fundamental Training for Beginners).
--
-- 1. name, url_key/url_path (statistics-for-data-analysis-masterclass ->
--    statistics-fundamentals-masterclass), cover alt/gallery labels, meta_title/description/keyword.
-- 2. "What's This Course About" and course topics follow the CASL parent (its 2 About paragraphs,
--    "WSQ-endorsed ... course" -> "hands-on Statistics Fundamentals Masterclass", and its 7 topics,
--    LSN_DATA JSON + HTML). Written as ASCII literals, not a parent join (see 1619). Neither text
--    states a day count. Duration 15 hrs, Sessions 2 and $700 stay as they are.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. Funding block: "No funding" now points at the CASL twin.
-- 5. 301s: the product's system rows are renamed in place to the new slug (so the new URL resolves
--    without a rewrite refresh); every old path, bare or category-prefixed, 301s one hop to the new
--    BARE slug, legacy RP rows and search redirects are flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template -> B03 via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C440' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064180' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Statistics Fundamentals Masterclass';
SET @old_slug  := 'statistics-for-data-analysis-masterclass';
SET @new_slug  := 'statistics-fundamentals-masterclass';

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
SELECT 4, @a_mdesc, 0, @pid, 'Build a solid foundation in statistics in this hands-on masterclass: probability, sampling, hypothesis testing, chi-square, ANOVA, regression and correlation at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Statistics Fundamentals Masterclass, Statistics Fundamentals, Statistics Course, Statistics Training, Statistics for Beginners, Descriptive Statistics, Probability, Sampling, Confidence Interval, Hypothesis Testing, Chi Square Test, ANOVA, Regression, Correlation, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Embark on your journey into the world of statistics with our hands-on Statistics Fundamentals Masterclass. This comprehensive training covers essential statistical concepts, including data collection, types of data, basic probability, and data interpretation methods. Through real-world examples and hands-on exercises, you\'ll gain the skills needed to understand, analyze, and interpret data in various contexts.</p>\n<p>By the end of this course, you\'ll possess a strong foundational understanding of basic statistics. You\'ll be equipped to tackle data with confidence, understand statistical tests, and make informed decisions based on your analyses. Whether you\'re entering the workforce, looking to upskill, or just interested in the power of data, this course serves as an excellent stepping stone into the world of statistics.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Introduction to Statistics","subsecs":[{"title":"Why Statistics Matter","links":[]},{"title":"Categorical and Quantitative Data","links":[]},{"title":"Descriptive Statistics: Mean and Standard Deviation","links":[]},{"title":"Probability and Conditional Probability","links":[]},{"title":"Bayes Theorem","links":[]},{"title":"Discrete Probability Distributions","links":[]},{"title":"Continuous Probability Distributions","links":[]},{"title":"Software for Statistical Analysis","links":[]}]},{"title":"Topic 2: Sampling","subsecs":[{"title":"Sampling Consideration","links":[]},{"title":"Central Limit Theorem","links":[]},{"title":"Sampling Distribution of the Mean","links":[]},{"title":"Standard Errors for Proportion and Mean","links":[]},{"title":"Confidence Interval","links":[]},{"title":"T-Statistics vs Z-Statistics","links":[]},{"title":"T-Score Table and Degree of Freedom","links":[]},{"title":"Calculating Confidence Interval of T-Score","links":[]}]},{"title":"Topic 3: Hypothesis Testing","subsecs":[{"title":"Overview of Hypothesis Testing","links":[]},{"title":"Steps for Performing a Hypothesis Testing","links":[]},{"title":"One Tailed vs Two Tailed Hypothesis Testing","links":[]},{"title":"One Sample Hypothesis Testing","links":[]},{"title":"Two Sample Hypothesis Testing","links":[]},{"title":"Pooled Sample T-Test","links":[]},{"title":"Type 1 and Type 2 Errors","links":[]}]},{"title":"Topic 4: Chi Square Test","subsecs":[{"title":"Chi Square Distribution","links":[]},{"title":"Goodness of Fit Test","links":[]}]},{"title":"Topic 5: ANOVA: Analysis of Variance","subsecs":[{"title":"What is Analysis of Variance","links":[]},{"title":"One Way ANOVA","links":[]},{"title":"Total Sum of Squares","links":[]},{"title":"Within Variance and Between Variance (SSW and SSB)","links":[]},{"title":"Hypothesis Testing with F-Statistic","links":[]}]},{"title":"Topic 6: Regression","subsecs":[{"title":"What is Regression?","links":[]},{"title":"Residues and Mean Square Error","links":[]},{"title":"Perform Regression Modeling","links":[]}]},{"title":"Topic 7: Correlation Analysis","subsecs":[{"title":"What is Correlation Analysis?","links":[]},{"title":"Computation of Correlation Coefficient","links":[]},{"title":"Correlation and Covariance Matrices","links":[]}]}] -->\n<p><strong>Topic 1: Introduction to Statistics</strong></p>\n<p><em>Why Statistics Matter</em></p>\n<p><em>Categorical and Quantitative Data</em></p>\n<p><em>Descriptive Statistics: Mean and Standard Deviation</em></p>\n<p><em>Probability and Conditional Probability</em></p>\n<p><em>Bayes Theorem</em></p>\n<p><em>Discrete Probability Distributions</em></p>\n<p><em>Continuous Probability Distributions</em></p>\n<p><em>Software for Statistical Analysis</em></p>\n<p><strong>Topic 2: Sampling</strong></p>\n<p><em>Sampling Consideration</em></p>\n<p><em>Central Limit Theorem</em></p>\n<p><em>Sampling Distribution of the Mean</em></p>\n<p><em>Standard Errors for Proportion and Mean</em></p>\n<p><em>Confidence Interval</em></p>\n<p><em>T-Statistics vs Z-Statistics</em></p>\n<p><em>T-Score Table and Degree of Freedom</em></p>\n<p><em>Calculating Confidence Interval of T-Score</em></p>\n<p><strong>Topic 3: Hypothesis Testing</strong></p>\n<p><em>Overview of Hypothesis Testing</em></p>\n<p><em>Steps for Performing a Hypothesis Testing</em></p>\n<p><em>One Tailed vs Two Tailed Hypothesis Testing</em></p>\n<p><em>One Sample Hypothesis Testing</em></p>\n<p><em>Two Sample Hypothesis Testing</em></p>\n<p><em>Pooled Sample T-Test</em></p>\n<p><em>Type 1 and Type 2 Errors</em></p>\n<p><strong>Topic 4: Chi Square Test</strong></p>\n<p><em>Chi Square Distribution</em></p>\n<p><em>Goodness of Fit Test</em></p>\n<p><strong>Topic 5: ANOVA: Analysis of Variance</strong></p>\n<p><em>What is Analysis of Variance</em></p>\n<p><em>One Way ANOVA</em></p>\n<p><em>Total Sum of Squares</em></p>\n<p><em>Within Variance and Between Variance (SSW and SSB)</em></p>\n<p><em>Hypothesis Testing with F-Statistic</em></p>\n<p><strong>Topic 6: Regression</strong></p>\n<p><em>What is Regression?</em></p>\n<p><em>Residues and Mean Square Error</em></p>\n<p><em>Perform Regression Modeling</em></p>\n<p><strong>Topic 7: Correlation Analysis</strong></p>\n<p><em>What is Correlation Analysis?</em></p>\n<p><em>Computation of Correlation Coefficient</em></p>\n<p><em>Correlation and Covariance Matrices</em></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C440-20261001-040734.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C440 - Funding and Grant', 'course_C440_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C440_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C440_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C440_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For CASL funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-statistics-fundamental-training-for-beginners.html" title="CASL - Statistics Fundamental Training for Beginners">CASL - Statistics Fundamental Training for Beginners</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C440_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c440_old;
CREATE TEMPORARY TABLE tmp_c440_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c440_old
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
  FROM tmp_c440_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c440_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
