-- C337: "Mastering Electrostatic Discharge Control (ESD) for Engineering Professionals" ->
-- "Electrostatic Discharge Control (ESD) Masterclass", the 1-day non-WSQ twin of
-- TGS-2024051412 (WSQ - Electrostatic Discharge (ESD) Control for Lab and Factory
-- Engineers and Managers).
--
-- 1. name, url_key/url_path (mastering-electrostatic-discharge-control-esd-for-engineering-
--    professionals -> electrostatic-discharge-control-esd-masterclass), cover alt/gallery
--    labels, meta_title/description/keyword.
-- 2. "What's This Course About" and course topics follow the WSQ parent (the 4 parent
--    topics, without the WSQ LU1/LU2 learning-unit headings the old copy carried).
--    Written as ASCII literals, not a parent join (see 1619). Neither text states a day
--    count. Duration 7.5 hrs, Sessions 1 and $350 stay as they are.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. Funding block (existing, "No funding is available") now also links the WSQ twin.
-- 5. 301s: the product's system rows are renamed in place to the new slug (so the new
--    URL resolves without a rewrite refresh); every old path, bare or category-prefixed,
--    301s one hop to the new BARE slug, and legacy RP rows are flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template -> counterpart of the parent's
-- template via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C337' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024051412' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Electrostatic Discharge Control (ESD) Masterclass';
SET @old_slug  := 'mastering-electrostatic-discharge-control-esd-for-engineering-professionals';
SET @new_slug  := 'electrostatic-discharge-control-esd-masterclass';

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
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mtitle;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master electrostatic discharge (ESD) control in this hands-on masterclass. Learn ESD principles, EPA and grounding controls, ANSI/ESD S20.20 and IEC 61340 compliance, testing, auditing and incident CAPA at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Electrostatic Discharge, ESD Control, ESD Masterclass, ESD Training, EPA, Grounding and Bonding, Ionization, ESD Testing, ESD Audit, ANSI/ESD S20.20, IEC 61340, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course equips engineers and managers with the essential knowledge and skills to manage Electrostatic Discharge (ESD) in lab and factory environments. Participants will learn about ESD principles, the causes of static charge generation, and the impact of ESD on IC manufacturing. The course delves into ESD control practices, including grounding systems, anti-static materials, ionization devices, and ESD-safe handling procedures.</p>\n<p>Through hands-on training, participants will evaluate and implement ESD control standards such as ANSI/ESD S20.20 and IEC 61340. They will also learn to conduct ESD performance tests, audit control measures, and foster employee awareness to mitigate risks. This course empowers professionals to improve ESD safety and ensure compliance in critical operational environments.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Basics of ESD","subsecs":[{"title":"Static Charge Generation","links":[]},{"title":"How ESD Occurs","links":[]},{"title":"Types of ESD Events (HBM, MM and CDM) in IC chips","links":[]},{"title":"ESD Catastrophic and Latent Failure Modes","links":[]},{"title":"Economic and Operational Impact of ESD on IC Manufacturing Processes","links":[]}]},{"title":"Topic 2: ESD Control Principles, Equipment and Practices","subsecs":[{"title":"Grounding and Bonding Principles","links":[]},{"title":"Electrostatic Field Shielding","links":[]},{"title":"Elimination or Reduction of Charge Generation","links":[]},{"title":"Proper Handling and Storage of ESD-sensitive (ESDS) Items","links":[]},{"title":"Grounding Systems (Grounded Workstations, Grounding Wrist Straps and Footwear)","links":[]},{"title":"Anti-static Materials (ESD Mats, Conductive Bags and Containers)","links":[]},{"title":"Ionization Devices (Air Ionizers for Neutralizing Charges)","links":[]},{"title":"ESD Monitoring Equipment (ESD Monitors and Alarms)","links":[]},{"title":"ESD Control Garments (Smocks, Gloves and Finger Cots)","links":[]},{"title":"Setting Up EPA","links":[]},{"title":"ESD-Safe Packaging and Transport","links":[]},{"title":"Maintenance of ESD Control Equipment","links":[]},{"title":"Common Mistakes to Avoid in ESDS Environment","links":[]}]},{"title":"Topic 3: ESD Control Standards, Testing and Auditing","subsecs":[{"title":"Overview of Relevant ESD Control Standards (ANSI/ESD S20.20 and IEC 61340)","links":[]},{"title":"Compliance Requirements for ESD-Controlled Environments","links":[]},{"title":"ESD Control Testing Procedures (Wrist Strap and Footwear Testing, Surface Resistance Testing and Ionization Efficiency Testing)","links":[]},{"title":"Periodic Auditing of ESD Control Measures","links":[]},{"title":"ESD Performance Metrics","links":[]}]},{"title":"Topic 4: Employee Training and Awareness of ESD Control","subsecs":[{"title":"Role of Employees in ESD Control","links":[]},{"title":"Fostering Awareness of ESD-Safe Behavior","links":[]},{"title":"Identifying, Analyzing and Reporting ESD Incidents","links":[]},{"title":"Corrective Actions to Mitigate Future ESD Risks","links":[]},{"title":"Certification of Competency in ESD Control","links":[]}]}] -->\n<p><strong>Topic 1: Basics of ESD</strong></p>\n<p><em>Static Charge Generation</em></p>\n<p><em>How ESD Occurs</em></p>\n<p><em>Types of ESD Events (HBM, MM and CDM) in IC chips</em></p>\n<p><em>ESD Catastrophic and Latent Failure Modes</em></p>\n<p><em>Economic and Operational Impact of ESD on IC Manufacturing Processes</em></p>\n<p><strong>Topic 2: ESD Control Principles, Equipment and Practices</strong></p>\n<p><em>Grounding and Bonding Principles</em></p>\n<p><em>Electrostatic Field Shielding</em></p>\n<p><em>Elimination or Reduction of Charge Generation</em></p>\n<p><em>Proper Handling and Storage of ESD-sensitive (ESDS) Items</em></p>\n<p><em>Grounding Systems (Grounded Workstations, Grounding Wrist Straps and Footwear)</em></p>\n<p><em>Anti-static Materials (ESD Mats, Conductive Bags and Containers)</em></p>\n<p><em>Ionization Devices (Air Ionizers for Neutralizing Charges)</em></p>\n<p><em>ESD Monitoring Equipment (ESD Monitors and Alarms)</em></p>\n<p><em>ESD Control Garments (Smocks, Gloves and Finger Cots)</em></p>\n<p><em>Setting Up EPA</em></p>\n<p><em>ESD-Safe Packaging and Transport</em></p>\n<p><em>Maintenance of ESD Control Equipment</em></p>\n<p><em>Common Mistakes to Avoid in ESDS Environment</em></p>\n<p><strong>Topic 3: ESD Control Standards, Testing and Auditing</strong></p>\n<p><em>Overview of Relevant ESD Control Standards (ANSI/ESD S20.20 and IEC 61340)</em></p>\n<p><em>Compliance Requirements for ESD-Controlled Environments</em></p>\n<p><em>ESD Control Testing Procedures (Wrist Strap and Footwear Testing, Surface Resistance Testing and Ionization Efficiency Testing)</em></p>\n<p><em>Periodic Auditing of ESD Control Measures</em></p>\n<p><em>ESD Performance Metrics</em></p>\n<p><strong>Topic 4: Employee Training and Awareness of ESD Control</strong></p>\n<p><em>Role of Employees in ESD Control</em></p>\n<p><em>Fostering Awareness of ESD-Safe Behavior</em></p>\n<p><em>Identifying, Analyzing and Reporting ESD Incidents</em></p>\n<p><em>Corrective Actions to Mitigate Future ESD Risks</em></p>\n<p><em>Certification of Competency in ESD Control</em></p>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C337-20260930-205141.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C337 - Funding and Grant', 'course_C337_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C337_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C337_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C337_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-electrostatic-discharge-esd-control-for-lab-and-factory-engineers-and-managers.html" title="WSQ - Electrostatic Discharge (ESD) Control for Lab and Factory Engineers and Managers">WSQ - Electrostatic Discharge (ESD) Control for Lab and Factory Engineers and Managers</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C337_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c337_old;
CREATE TEMPORARY TABLE tmp_c337_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c337_old
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
  FROM tmp_c337_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c337_old;
