-- C731: "Effective Financial Budget and Control" -> "Budgeting for SMEs", the 1-day non-WSQ twin of
-- TGS-2021002336 (WSQ - Budgeting for Small and Medium Enterprises).
--
-- 1. name, url_key/url_path (effective-financial-budget-and-control -> budgeting-for-smes),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. Fee / Duration / Sessions already $350 / 7.5 hrs / 1 -> unchanged (store-scope overrides cleared below).
-- 3. "What's This Course About" and course topics follow the WSQ parent (its 2 About paragraphs, "WSQ"
--    dropped and the course name swapped; its 7 topics, LSN_DATA JSON + HTML). ASCII literals, not a
--    parent join; the parent's typo "Budget Control Pan" is written as "Budget Control Plan".
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Funding block: "No funding" pointing at the WSQ twin's canonical slug (was the legacy
--    wsq-budget-control-course.html alias).
-- 6. 301s: the product's system rows are renamed in place to the new slug; every old path, bare or
--    category-prefixed, 301s one hop to the new BARE slug; legacy RP rows and search redirects are
--    flattened onto it. Search terms naming WSQ / NICF go to the WSQ twin instead.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Schedule template A11 (gid 124) -> A17 (counterpart of the parent's WSQ-B17) is switched on prod via
-- the code path, not here.
-- Post-deploy (not doable in SQL): flat/price reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C731' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021002336' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Budgeting for SMEs';
SET @old_slug  := 'effective-financial-budget-and-control';
SET @new_slug  := 'budgeting-for-smes';
SET @wsq_url   := 'https://www.tertiarycourses.com.sg/wsq-budgeting-for-small-and-medium-enterprises.html';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

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
SELECT 4, @a_mdesc, 0, @pid, 'Learn budgeting for SMEs: financial forecasting, budget preparation, budget control plans, variance analysis, budget approval and financial compliance in this course at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Budgeting for SMEs, Budgeting Course, SME Budgeting, Financial Budgeting, Financial Forecasting, Budget Preparation, Budget Control, Cash Flow, Budget Analysis, Financial Compliance, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Elevate your financial management skills with our Budgeting for SMEs course. Tailored to address the unique financial challenges faced by SMEs, this course provides comprehensive insights into budgeting techniques, cost management, and revenue forecasting. You\'ll gain the knowledge to create and manage budgets, set financial goals, and analyze key performance indicators (KPIs), enabling you to make data-driven decisions that facilitate business growth and sustainability.</p>\n<p>Become a catalyst for financial success in your organization by mastering the principles of budgeting and financial planning. This course delves into essential topics such as cash flow analysis, variance analysis, and budget adjustments to reflect changing business conditions. Whether you are a business owner, financial manager, or an aspiring entrepreneur, this course equips you with the skills and tools necessary for effective financial management, setting you on a path toward enhanced business performance and profitability.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Introduction to Financial Budgeting","subsecs":[{"title":"Business Strategies and Objectives","links":[]},{"title":"Budgeting Parameters","links":[]},{"title":"Budgeting Types","links":[]}]},{"title":"Topic 2: Financial Forecasting","subsecs":[{"title":"Key Principles of Accounting","links":[]},{"title":"Key Principles of Corporate Finance","links":[]},{"title":"Time Value of Money","links":[]}]},{"title":"Topic 3: Budget Preparation","subsecs":[{"title":"Cash Flow Calculation","links":[]},{"title":"Preparing Budget","links":[]}]},{"title":"Topic 4: Budget Control Plan","subsecs":[{"title":"Preparing Budget Control Plan","links":[]},{"title":"Budgetary Control Techniques","links":[]}]},{"title":"Topic 5: Budget Analysis","subsecs":[{"title":"Compare Budget with Estimation","links":[]},{"title":"Financial Methodologies for Budget Control","links":[]}]},{"title":"Topic 6: Budget Approval","subsecs":[{"title":"Budget Approval Process","links":[]},{"title":"Stakeholder Precautions","links":[]}]},{"title":"Topic 7: Financial Compliance","subsecs":[{"title":"Singapore Taxation Policies","links":[]},{"title":"Financial Control and Compliance","links":[]}]}] -->\n<p><strong>Topic 1: Introduction to Financial Budgeting</strong></p>\n<p><em>Business Strategies and Objectives</em></p>\n<p><em>Budgeting Parameters</em></p>\n<p><em>Budgeting Types</em></p>\n<p><strong>Topic 2: Financial Forecasting</strong></p>\n<p><em>Key Principles of Accounting</em></p>\n<p><em>Key Principles of Corporate Finance</em></p>\n<p><em>Time Value of Money</em></p>\n<p><strong>Topic 3: Budget Preparation</strong></p>\n<p><em>Cash Flow Calculation</em></p>\n<p><em>Preparing Budget</em></p>\n<p><strong>Topic 4: Budget Control Plan</strong></p>\n<p><em>Preparing Budget Control Plan</em></p>\n<p><em>Budgetary Control Techniques</em></p>\n<p><strong>Topic 5: Budget Analysis</strong></p>\n<p><em>Compare Budget with Estimation</em></p>\n<p><em>Financial Methodologies for Budget Control</em></p>\n<p><strong>Topic 6: Budget Approval</strong></p>\n<p><em>Budget Approval Process</em></p>\n<p><em>Stakeholder Precautions</em></p>\n<p><strong>Topic 7: Financial Compliance</strong></p>\n<p><em>Singapore Taxation Policies</em></p>\n<p><em>Financial Control and Compliance</em></p>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover, @a_dur, @a_sess) AND store_id <> 0;

DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C731-20261001-183446.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C731 - Funding and Grant', 'course_C731_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C731_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C731_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C731_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-budgeting-for-small-and-medium-enterprises.html" title="WSQ - Budgeting for Small and Medium Enterprises">WSQ - Budgeting for Small and Medium Enterprises</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C731_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c731_old;
CREATE TEMPORARY TABLE tmp_c731_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c731_old
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
  FROM tmp_c731_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c731_old;

-- 5) On-site search terms that sent people to the old slug: WSQ-intent terms -> the WSQ twin,
--    everything else -> the new slug.
UPDATE catalogsearch_query
   SET redirect = @wsq_url
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html')
   AND (query_text LIKE '%wsq%' OR query_text LIKE '%nicf%' OR query_text LIKE '%ncif%');

UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
