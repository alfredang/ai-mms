-- 851: Rename TGS-2024045797 "WSQ - Project Management Professional (PMP) 35 PDU Training"
--      -> "WSQ - Project Management Professional".
--
-- Course code (SKU) is UNCHANGED — TGS-2024045797 stays, so every SkillsFuture /
-- SFEC / SFC / PSEA deep link in short_description remains correct and no funding
-- content is touched.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels  -> new title
--   2. url_key -> wsq-project-management-professional ; url_path deleted at every
--      scope so the Catalog URL Rewrites indexer regenerates it
--   3. explicit 301 from the old top-level slug (the indexer auto-301s category
--      paths, but the bare path is belt-and-braces — see 647 for the pattern)
--   4. short_description: the two intro paragraphs ("About This Course") are
--      rewritten; the tail from "<h2>Course Brochure</h2>" onward is spliced
--      byte-identically so Brochure / Skills Framework / Certification /
--      WSQ Funding survive untouched
--   5. media gallery per-image label
--
-- Topics Covered (description) and the LO1-LO5 CMS block
-- (course_TGS-2024045797_learning_outcomes) already match the requested content
-- verbatim and are deliberately NOT rewritten here.
--
-- The cover PNG needs no code change: MMD_CourseImage strips a leading "WSQ -"
-- from the title before rendering (Model/Cover.php::cleanTitle), so the image
-- shows "Project Management Professional" while the storefront name keeps the
-- WSQ marker. The existing PNG still bakes the old long title — regenerate the
-- cover from the admin after this migration applies.
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops).

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045797' LIMIT 1);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'WSQ - Project Management Professional' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'WSQ Project Management Professional | Tertiary Courses Singapore' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'WSQ Project Management Professional training in Singapore. Learn to scope, plan, execute, monitor and close medium-scale projects, manage risks and engage stakeholders, and prepare for PMP certification. Up to 70% WSQ funding.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'wsq-project-management-professional' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "WSQ -" prefix) — they are alt text on
-- the course cover, which itself renders without the prefix.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'Project Management Professional' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'Project Management Professional' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'Project Management Professional' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------------- 2. url_path at all scopes
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Drop any non-system squatter on the old path first (see 647: INSERT IGNORE
-- silently no-ops against a stale is_system row and the 301 never ships).
DELETE FROM core_url_rewrite
WHERE is_system = 0
  AND request_path = 'wsq-project-management-professional-pmp-35-pdu-training.html'
  AND @e IS NOT NULL;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_tgs2024045797_old_', s.store_id),
       'wsq-project-management-professional-pmp-35-pdu-training.html',
       'wsq-project-management-professional.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite c
    WHERE c.store_id = s.store_id
      AND c.request_path = 'wsq-project-management-professional-pmp-35-pdu-training.html'
      AND c.is_system = 1);

-- ------------------------------------------ 4. short_description intro rewrite
-- Splice: new "About This Course" paragraphs + everything from Course Brochure
-- onward preserved byte-for-byte (Skills Framework, Certification, WSQ Funding).
UPDATE catalog_product_entity_text
SET value = CONCAT('<p>This course, Project Management Professional Training, is designed for aspiring project managers to gain critical skills needed for PMP certification. The course covers the full project lifecycle, starting from aligning projects with business objectives and identifying stakeholders to developing comprehensive project plans. Learners will explore project governance, compliance, and the strategic value of projects within an organization.</p>\n<p>In the second half, participants will focus on executing and monitoring projects, honing leadership skills, managing team performance, and resolving conflicts. The course also covers risk management, project change control, and successful project closure, with an emphasis on knowledge transfer and benefits realization. This training prepares participants for the PMP certification and ensures they are equipped to manage medium-scale projects effectively.</p>\n',
                   SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
WHERE entity_id = @e AND @e IS NOT NULL
  AND attribute_id = @a_sd
  AND LOCATE('<h2>Course Brochure</h2>', value) > 0;

-- ------------------------------------------------- 5. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Project Management Professional'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------------ 6. brochure CMS block
-- Title-only text fix; the PDF path is keyed on the unchanged SKU.
UPDATE cms_block
SET title = 'Course Brochure - TGS-2024045797'
WHERE identifier = 'course_TGS-2024045797_brochure';
