-- 1323 : Retitle TGS-2025053175 (product 501)
--        "WSQ - Tableau Certified Desktop Specialist Training"
--     -> "Tableau Desktop Foundations"
--
-- This is a RETITLE, not a repurpose. The subject (Tableau Desktop) is
-- unchanged; the title follows Salesforce renaming the credential
-- "Tableau Desktop Specialist" -> "Salesforce Certified Tableau Desktop
-- Foundations" (Trailhead Academy migration, 21 Jul 2025). The 4 exam domains
-- (Connecting 25% / Exploring 35% / Sharing 25% / Concepts 15%) are exactly the
-- 4 topics below, so the outline is a relabel of the existing one.
--
-- SKU UNCHANGED, so every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link and
-- the funding_and_grant / certification / skills_framework / brochure blocks
-- (registered against this SKU) stay valid and are NOT touched.
--
-- The "WSQ - " prefix is dropped from `name` per the admin's supplied title.
-- The storefront <title> still reads "WSQ funded ..." because MMD_Seotitle
-- derives that prefix from the TGS- SKU at render time, not from `name`
-- (Seotitle/Block/Html/Head.php::_fundingPrefix) - no funding signal is lost.
--
-- Surfaces touched: name, url_key/url_path + 301 + chain-flatten, meta_title,
-- meta_description, meta_keyword, image/small_image/thumbnail LABELS,
-- media-gallery label, short_description (About This Course), description
-- (course outline: 4 topics), search redirects.
--
-- Deliberately NOT touched (probed on SG prod 2026-09-05):
--  * learning_outcomes cms_block - the supplied LO1-LO4 are BYTE-IDENTICAL to
--    the live block. They are the accredited outcomes registered against the
--    unchanged SKU.
--  * certification block - names the Tertiary Certificate of Achievement + the
--    SkillsFuture OpenCert, both keyed on the unchanged SKU. The Salesforce
--    credential is an external exam this course PREPARES for, not one we issue,
--    so it belongs in the About copy (below), not in the Certification card.
--  * skills_framework block - "Data Analytics ATP-PIN-2001-1.1" (Air Transport
--    Skills Framework), accredited against the unchanged SKU.
--  * prerequisite - probed: holds the whole funding apparatus (PWM, eligibility
--    table, SkillsFuture/PSEA/SFEC/UTAP deep links). Never rewrite wholesale;
--    it names no old title.
--  * whoshouldattend - 20 tool-neutral / Tableau-correct roles (Data Analyst,
--    Tableau Developer, ...). Still accurate; the tool has not changed.
--  * trainerprofile - probed: LOCATE('Desktop Specialist') = 0, no leak.
--  * image / small_image / thumbnail - filesystem paths; renaming 404s them.
--  * categories - all 15 placements still describe the course.
--  * The C181 twin "Tableau Certified Desktop Specialist Training"
--    (tableau-certified-desktop-specialist-exam-prep) is a SEPARATE live course.
--    Every LIKE below is anchored on the full '/wsq-' old filename so none of
--    its rows are swept in.
--
-- SG-only. Partner sites (MY/GH) never held this TGS- SKU; @is_sg makes this a
-- no-op there.

SET @is_sg := (SELECT COUNT(*) FROM core_config_data
               WHERE path = 'web/unsecure/base_url' AND value LIKE '%tertiarycourses.com.sg%');

SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025053175');
SET @et := 4;

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='meta_description');
SET @a_mkw     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='meta_keyword');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='thumbnail_label');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='description');

SET @newname := 'Tableau Desktop Foundations';
SET @newslug := 'tableau-desktop-foundations';
SET @oldslug := 'wsq-tableau-certified-desktop-specialist-training';

-- ------------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = @newname
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_name;

-- ------------------------------------- 2. alt-text labels (cover alt text)
UPDATE catalog_product_entity_varchar
   SET value = @newname
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e
   AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

-- Media-gallery per-image label is the REAL alt text rendered on the cover.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @newname
 WHERE @is_sg > 0 AND @e IS NOT NULL AND g.entity_id = @e;

-- ------------------------- 3. meta_title (PLAIN - MMD_Seotitle adds prefix+brand)
UPDATE catalog_product_entity_varchar
   SET value = 'Tableau Desktop Foundations Training'
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mtitle;

-- --------------------------------------------- 4. meta_description (<= 255 chars)
UPDATE catalog_product_entity_varchar
   SET value = 'Build core Tableau Desktop skills to connect and prepare data, create visualizations and share dashboards, while preparing for the Salesforce Certified Tableau Desktop Foundations exam. Up to 70% WSQ funding subsidy.'
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mdesc;

-- ------------------------------------------------------------- 5. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'Tableau Desktop Foundations, Tableau training Singapore, Salesforce Certified Tableau Desktop Foundations, Tableau certification, data visualization training, Tableau dashboards, Tableau for beginners, WSQ Tableau course'
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mkw;

-- --------------------------------------------------- 6. url_key + drop url_path
-- Dropping url_path at EVERY scope lets the URL Rewrites indexer regenerate.
-- New slug probed free on prod: no product owns 'tableau-desktop-foundations'.
UPDATE catalog_product_entity_varchar
   SET value = @newslug
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_urlkey;
DELETE FROM catalog_product_entity_varchar
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ 7. short_description
-- "About This Course". Probed on prod: prose-only (Brochure / Skills Framework /
-- Certification / Funding sections were extracted to cms_blocks by 885-891), so
-- a full replace is correct - there is no <h2>Course Brochure</h2> tail.
UPDATE catalog_product_entity_text
   SET value = '<p>The <strong>Tableau Desktop Foundations</strong> course equips learners with the essential knowledge and practical skills needed to work confidently with Tableau Desktop while preparing for the <strong>Salesforce Certified Tableau Desktop Foundations</strong> certification.</p><p>The course provides hands-on practice with the core Tableau capabilities assessed in the certification. Participants will learn to connect to and prepare data from different sources, understand Tableau data structures, and work effectively with dimensions, measures, discrete and continuous fields, and aggregations. Learners will also develop skills in filtering, sorting, grouping, calculations, and organizing data to support accurate analysis.</p><p>Through practical exercises, participants will create a range of visualizations, including charts, tables, maps, and interactive dashboards. They will learn how to apply formatting, analytics, and dashboard features to communicate data insights clearly and effectively.</p><p>The course also emphasizes certification preparation, reinforcing key Tableau Desktop concepts, terminology, workflows, and practical techniques aligned with the Salesforce certification requirements. Practice activities and review exercises help learners strengthen their understanding and become familiar with the types of knowledge and skills expected in the certification assessment.</p><p>By the end of the course, participants will have a strong foundation in Tableau Desktop for real-world data visualization and analytics, while being better prepared to pursue the Salesforce Certified Tableau Desktop Foundations credential.</p>'
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_sdesc;

-- --------------------------------------------------- 8. description (outline)
-- Topics-only shape (no sub-bullets), matching 967/999/1007/1321. The LSN_DATA
-- JSON comment drives the outline widget and must stay in sync with the markup.
-- This also drops the stray U+00A0 that the old Topic 1 / Topic 4 titles carried.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: Connecting to and Preparing Data in Tableau Desktop","subsecs":[]},',
'{"title":"Topic 2: Exploring and Analyzing Data in Tableau Desktop","subsecs":[]},',
'{"title":"Topic 3: Sharing Insights with Dashboards and Workbooks","subsecs":[]},',
'{"title":"Topic 4: Understanding Tableau Concepts and Certification Preparation","subsecs":[]}] -->\n',
'<p><strong>Topic 1: Connecting to and Preparing Data in Tableau Desktop</strong></p>\n',
'<p><strong>Topic 2: Exploring and Analyzing Data in Tableau Desktop</strong></p>\n',
'<p><strong>Topic 3: Sharing Insights with Dashboards and Workbooks</strong></p>\n',
'<p><strong>Topic 4: Understanding Tableau Concepts and Certification Preparation</strong></p>\n')
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_desc;

-- ------------------------------------------------ 9. URL rewrites: 301 old->new
-- The is_system=1 row still occupies the OLD bare slug; INSERT IGNORE would
-- silently no-op against it, so delete it FIRST (trap from migrations 647/1024).
DELETE FROM core_url_rewrite
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND request_path = CONCAT(@oldslug, '.html')
   AND is_system = 1;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5(CONCAT(@oldslug, '.html')), '-', s.store_id),
       CONCAT(@oldslug, '.html'),
       CONCAT(@newslug, '.html'),
       0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT store_id, request_path FROM core_url_rewrite) x
                   WHERE x.request_path = CONCAT(@oldslug, '.html') AND x.store_id = s.store_id);

-- Force any surviving row on the old path to a permanent manual 301.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@newslug, '.html'), options = 'RP', is_system = 0
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND request_path = CONCAT(@oldslug, '.html');

-- Chain-flatten: alias rows that 301 INTO the old bare slug take one hop now.
-- This includes the recycled-entity aliases this product inherited
-- (ansys-fluent-essential-training-501.html, openfoam-essential-training.html).
-- Anchored on the FULL old filename, so the C181 twin's
-- tableau-certified-desktop-specialist-exam-prep.html rows are never matched.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@newslug, '.html')
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND target_path = CONCAT(@oldslug, '.html')
   AND request_path <> CONCAT(@newslug, '.html');

-- --------------------------------------------------------- 10. search redirects
-- Retarget ONLY rows already pointing at this course's old bare slug (8 on prod:
-- 'open foam', 'tableau desktop', 'specialist', 'tableau fundamental',
-- 'TGS-2025053175', 'Tableau Certified Desktop Specialist', 'desktop engineer
-- course', 'Desktop specialist', 'WSQ - Tableau Certified Desktop Specialist
-- Training', 'tableau deskto['). Rows pointing at the C181 exam-prep twin, the
-- data-analyst course or the category pages are deliberately left alone.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @newslug, '.html')
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @oldslug, '.html');
