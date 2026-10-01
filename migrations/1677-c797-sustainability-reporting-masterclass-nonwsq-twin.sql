-- C797: "Sustainability GRI Reporting" -> "Sustainability Reporting Masterclass", the 2-day non-WSQ twin of
-- TGS-2025052343 (WSQ - Sustainability Reporting and Engineering Strategies for Senior Leaders).
--
-- 1. name, url_key/url_path (sustainability-gri-reporting -> sustainability-reporting-masterclass),
--    cover alt/gallery labels, meta_title/description/keyword (old meta was GRI-only).
-- 2. Fee / Duration / Sessions already $700 / 15 hrs / 2 -> unchanged (store-scope overrides cleared below).
-- 3. "What's This Course About" and course topics follow the WSQ parent (its 2 About paragraphs and its
--    4 topics, LSN_DATA JSON + HTML). Replaces C797's old About, which also carried a stale "Funding and
--    Grant" section linking the retired WSQ GRI course. ASCII literals, not a parent join: the parent's
--    topic titles carry stray NBSP bytes, its WSQ K-codes "(K2)" / "(K5)" are dropped, and its HTML-only
--    "Case Studies" item is added to the LSN_DATA JSON so both renderings agree.
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Funding block: "No funding" pointing at the WSQ twin (no block existed).
-- 6. 301s: the product's system rows are renamed in place to the new slug; every old path, bare or
--    category-prefixed, 301s one hop to the new BARE slug; legacy RP rows and search redirects are
--    flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Schedule template A13 (gid 64, a 1-day template) -> B13 (gid 191, counterpart of the parent's WSQ-B13)
-- is switched on prod via the code path, not here.
-- Post-deploy (not doable in SQL): refreshProductRewrite, then flat/price reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C797' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025052343' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Sustainability Reporting Masterclass';
SET @old_slug  := 'sustainability-gri-reporting';
SET @new_slug  := 'sustainability-reporting-masterclass';

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
SELECT 4, @a_mdesc, 0, @pid, 'Learn sustainability reporting and ESG strategy: IFRS S1 and S2, GRI, SASB, TCFD and SGX disclosure, materiality assessment, circular economy and carbon reduction in this masterclass at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Sustainability Reporting Masterclass, Sustainability Reporting Training, ESG Reporting, ESG Strategy, IFRS S1, IFRS S2, GRI Standards, SASB, TCFD, SGX Sustainability Reporting, Materiality Assessment, Circular Economy, Carbon Reduction, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course equips senior leaders with advanced knowledge and practical strategies to address sustainability challenges in engineering and organizational contexts. Participants will review and evaluate engineering solutions to tackle environmental issues, align organizational strategies with sustainable industry trends, and ensure compliance with global and local sustainability reporting standards. Through case studies, participants will explore real-world applications of sustainable engineering and ESG frameworks to create lasting value for their organizations.</p>\n<p>The program also delves into circular economy principles, sustainable supply chain management, and carbon reduction strategies. Leaders will gain the expertise to develop ESG strategies that engage stakeholders, manage risks, and enhance market competitiveness while contributing to ecological and societal benefits. By the end of the course, participants will be prepared to lead their organizations towards achieving sustainability excellence.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Foundations of Sustainability and ESG","subsecs":[{"title":"Fundamentals of Sustainability and ESG","links":[]},{"title":"Definitions, Concepts, and Scope of ESG and Sustainability","links":[]},{"title":"Key Trends and Emerging Risks in Sustainable Engineering","links":[]},{"title":"Regulatory and Compliance Frameworks","links":[]},{"title":"Key Global Regulations (UN SDGs, COP21, COP26)","links":[]},{"title":"Local Policy and Compliance Requirements","links":[]},{"title":"Business Case for Sustainability","links":[]},{"title":"Business Rationale for ESG Adoption and Sustainable Value Creation","links":[]},{"title":"Case Studies: Endorsing Engineering Solutions for Sustainability","links":[]}]},{"title":"Topic 2: ESG Strategy, Stakeholder Engagement, and Market Positioning","subsecs":[{"title":"ESG Strategy Development and Market Positioning","links":[]},{"title":"Designing ESG Strategies for Business Value Creation","links":[]},{"title":"Building Sustainability Scorecards to Track Performance","links":[]},{"title":"Stakeholder Engagement and ESG Risk Management","links":[]},{"title":"Identifying and Engaging Key Stakeholders","links":[]},{"title":"ESG Risk Assessment and Mitigation","links":[]},{"title":"ESG Ratings and Benchmarking","links":[]},{"title":"Overview of ESG Ratings (MSCI, Sustainalytics)","links":[]},{"title":"Industry Best Practices for ESG Positioning","links":[]}]},{"title":"Topic 3: Sustainability Reporting, ESG Disclosure, and Compliance","subsecs":[{"title":"Sustainability Reporting Frameworks","links":[]},{"title":"IFRS S1 & S2 for Sustainability and Climate-Related Disclosures","links":[]},{"title":"Alignment with Global and Local Standards (GRI, SASB, TCFD, and SGX)","links":[]},{"title":"Reporting Process and Data Assurance","links":[]},{"title":"Data Collection, Validation, and Verification for ESG Reports","links":[]},{"title":"Conducting Materiality Assessments Using SGX Guidelines","links":[]},{"title":"Compliance with ESG Disclosure Requirements","links":[]},{"title":"Compliance Obligations for IFRS, SGX, and International Frameworks","links":[]},{"title":"Reporting ESG Disclosures to Meet Regulatory Requirements","links":[]}]},{"title":"Topic 4: Circular Economy, Sustainable Supply Chains, and Carbon Reduction Strategies","subsecs":[{"title":"Circular Economy and Resource Optimization","links":[]},{"title":"Principles of the Circular Economy for Business Transformation","links":[]},{"title":"Circular Design and End-of-Life Product Management","links":[]},{"title":"Sustainable Supply Chain Management","links":[]},{"title":"Embedding Sustainability into Supply Chains","links":[]},{"title":"Supply Chain ESG Disclosure (SGX) and Compliance","links":[]},{"title":"Carbon Reduction and Decarbonization Strategies","links":[]},{"title":"Corporate Carbon Reduction Plans and Life Cycle Assessment (LCA)","links":[]},{"title":"Role of the Carbon Disclosure Project (CDP) and ESG Reporting","links":[]}]}] -->\n<p><strong>Topic 1: Foundations of Sustainability and ESG</strong></p>\n<p><em>Fundamentals of Sustainability and ESG</em></p>\n<p><em>Definitions, Concepts, and Scope of ESG and Sustainability</em></p>\n<p><em>Key Trends and Emerging Risks in Sustainable Engineering</em></p>\n<p><em>Regulatory and Compliance Frameworks</em></p>\n<p><em>Key Global Regulations (UN SDGs, COP21, COP26)</em></p>\n<p><em>Local Policy and Compliance Requirements</em></p>\n<p><em>Business Case for Sustainability</em></p>\n<p><em>Business Rationale for ESG Adoption and Sustainable Value Creation</em></p>\n<p><em>Case Studies: Endorsing Engineering Solutions for Sustainability</em></p>\n<p><strong>Topic 2: ESG Strategy, Stakeholder Engagement, and Market Positioning</strong></p>\n<p><em>ESG Strategy Development and Market Positioning</em></p>\n<p><em>Designing ESG Strategies for Business Value Creation</em></p>\n<p><em>Building Sustainability Scorecards to Track Performance</em></p>\n<p><em>Stakeholder Engagement and ESG Risk Management</em></p>\n<p><em>Identifying and Engaging Key Stakeholders</em></p>\n<p><em>ESG Risk Assessment and Mitigation</em></p>\n<p><em>ESG Ratings and Benchmarking</em></p>\n<p><em>Overview of ESG Ratings (MSCI, Sustainalytics)</em></p>\n<p><em>Industry Best Practices for ESG Positioning</em></p>\n<p><strong>Topic 3: Sustainability Reporting, ESG Disclosure, and Compliance</strong></p>\n<p><em>Sustainability Reporting Frameworks</em></p>\n<p><em>IFRS S1 &amp; S2 for Sustainability and Climate-Related Disclosures</em></p>\n<p><em>Alignment with Global and Local Standards (GRI, SASB, TCFD, and SGX)</em></p>\n<p><em>Reporting Process and Data Assurance</em></p>\n<p><em>Data Collection, Validation, and Verification for ESG Reports</em></p>\n<p><em>Conducting Materiality Assessments Using SGX Guidelines</em></p>\n<p><em>Compliance with ESG Disclosure Requirements</em></p>\n<p><em>Compliance Obligations for IFRS, SGX, and International Frameworks</em></p>\n<p><em>Reporting ESG Disclosures to Meet Regulatory Requirements</em></p>\n<p><strong>Topic 4: Circular Economy, Sustainable Supply Chains, and Carbon Reduction Strategies</strong></p>\n<p><em>Circular Economy and Resource Optimization</em></p>\n<p><em>Principles of the Circular Economy for Business Transformation</em></p>\n<p><em>Circular Design and End-of-Life Product Management</em></p>\n<p><em>Sustainable Supply Chain Management</em></p>\n<p><em>Embedding Sustainability into Supply Chains</em></p>\n<p><em>Supply Chain ESG Disclosure (SGX) and Compliance</em></p>\n<p><em>Carbon Reduction and Decarbonization Strategies</em></p>\n<p><em>Corporate Carbon Reduction Plans and Life Cycle Assessment (LCA)</em></p>\n<p><em>Role of the Carbon Disclosure Project (CDP) and ESG Reporting</em></p>\n'
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
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C797-20261001-180357.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C797 - Funding and Grant', 'course_C797_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C797_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C797_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C797_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-sustainability-reporting-and-engineering-strategies-for-senior-leaders.html" title="WSQ - Sustainability Reporting and Engineering Strategies for Senior Leaders">WSQ - Sustainability Reporting and Engineering Strategies for Senior Leaders</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C797_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c797_old;
CREATE TEMPORARY TABLE tmp_c797_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c797_old
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
  FROM tmp_c797_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c797_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
