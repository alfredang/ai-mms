-- C752: "Corporate ESG and Sustainability" -> "Sustainability Masterclass", the 2-day non-WSQ twin of
-- TGS-2023021099 (WSQ - Carbon Footprint Management for Sustainability).
--
-- 1. name, url_key/url_path (corporate-esg-and-sustainability -> sustainability-masterclass),
--    cover alt/gallery labels, meta_title/description/keyword (old meta advertised WSQ funding).
-- 2. Fee / Duration / Sessions already $700 / 15 hrs / 2 -> unchanged (store-scope overrides cleared below).
-- 3. "What's This Course About" and course topics follow the WSQ parent (its 2 About paragraphs,
--    "WSQ Carbon Footprint Management for Sustainability course" -> "Sustainability Masterclass", and its
--    3 topics, LSN_DATA JSON + HTML). ASCII literals, not a parent join: the parent's topics carry latin1
--    mojibake quotes around "hot spots" (dropped here) and the typo "ISO:140001" (-> ISO 14001).
-- 4. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 5. Funding block: "No funding" pointing at the WSQ twin (already did; wording normalised).
-- 6. 301s: the product's system rows are renamed in place to the new slug; every old path, bare or
--    category-prefixed, 301s one hop to the new BARE slug; legacy RP rows and search redirects are
--    flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Schedule template B19 -> B13 (= parent's WSQ-B13) was switched on prod via the code path, not here.
-- Post-deploy (not doable in SQL): refreshProductRewrite, then flat/price reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C752' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023021099' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Sustainability Masterclass';
SET @old_slug  := 'corporate-esg-and-sustainability';
SET @new_slug  := 'sustainability-masterclass';

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
SELECT 4, @a_mdesc, 0, @pid, 'Learn carbon footprint management for sustainability: identify emission hot spots, calculate your carbon footprint, prioritise reduction initiatives and build a reduction plan in this masterclass at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Sustainability Masterclass, Sustainability Training, Carbon Footprint Management, Carbon Footprint Calculation, Carbon Emission Reduction, Carbon Hot Spots, ISO 14001, Environmental Management System, EMS, Corporate Sustainability, ESG, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Enhance your proficiency in environmental sustainability with our Sustainability Masterclass. Aimed at both professionals and organizations, this course offers comprehensive training in measuring, analyzing, and managing carbon emissions. You''ll acquire skills in calculating carbon footprints, setting emission targets, and implementing reduction strategies. By the end of this course, you''ll be well-equipped to make impactful decisions that drive organizational sustainability while conforming to global standards.</p>\n<p>Step into the role of an environmental steward by mastering carbon management practices tailored for modern businesses. The course covers essential topics such as greenhouse gas accounting, emission reduction techniques, and stakeholder engagement for sustainability. Ideal for managers, sustainability officers, and those interested in corporate responsibility, this course provides you with the skillset to lead sustainability initiatives, reduce operational costs, and enhance your organization''s reputation for environmental stewardship.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Identifying and Analyzing Carbon Footprint Hot Spots","subsecs":[{"title":"Overview of ISO 14001 standards","links":[]},{"title":"Identify potential carbon footprint hot spots","links":[]},{"title":"Carbon footprint calculator","links":[]},{"title":"Analyse the potential of hot spots for carbon footprint reduction","links":[]}]},{"title":"Topic 2: Prioritising Carbon Footprint Reduction Initiatives","subsecs":[{"title":"Identify feasible technology to address carbon footprint hot spots","links":[]},{"title":"Methods for projecting carbon reduction potentials","links":[]},{"title":"Prioritising carbon footprint reduction initiatives","links":[]}]},{"title":"Topic 3: Implementing Carbon Footprint Reduction Plan","subsecs":[{"title":"Fundamentals of environment management systems (EMS)","links":[]},{"title":"Key components of carbon footprint reduction plans","links":[]},{"title":"Develop carbon footprint reduction plans","links":[]}]}] -->\n<p><strong>Topic 1: Identifying and Analyzing Carbon Footprint Hot Spots</strong></p>\n<p><em>Overview of ISO 14001 standards</em></p>\n<p><em>Identify potential carbon footprint hot spots</em></p>\n<p><em>Carbon footprint calculator</em></p>\n<p><em>Analyse the potential of hot spots for carbon footprint reduction</em></p>\n<p><strong>Topic 2: Prioritising Carbon Footprint Reduction Initiatives</strong></p>\n<p><em>Identify feasible technology to address carbon footprint hot spots</em></p>\n<p><em>Methods for projecting carbon reduction potentials</em></p>\n<p><em>Prioritising carbon footprint reduction initiatives</em></p>\n<p><strong>Topic 3: Implementing Carbon Footprint Reduction Plan</strong></p>\n<p><em>Fundamentals of environment management systems (EMS)</em></p>\n<p><em>Key components of carbon footprint reduction plans</em></p>\n<p><em>Develop carbon footprint reduction plans</em></p>\n'
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
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C752-20261001-082250.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C752 - Funding and Grant', 'course_C752_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C752_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C752_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C752_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-carbon-footprint-management-for-sustainability.html" title="WSQ - Carbon Footprint Management for Sustainability">WSQ - Carbon Footprint Management for Sustainability</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C752_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c752_old;
CREATE TEMPORARY TABLE tmp_c752_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c752_old
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
  FROM tmp_c752_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c752_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
