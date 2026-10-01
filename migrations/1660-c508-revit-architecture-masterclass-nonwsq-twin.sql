-- C508 "Autodesk Revit Architecture Masterclass": the 2-day non-WSQ twin of TGS-2021004287
-- (WSQ - Architecture Drawing with Revit). Name and slug (autodesk-revit-architecture-masterclass)
-- are already right, so there is no rename, no 301 and no cover re-render.
--
-- 1. "What's This Course About" follows the WSQ parent. The parent's "WSQ-accredited Revit
--    course" is reworded to "hands-on Revit course"; its inline "Autodesk ATC" h2 blurb and
--    C508's inline ATC banner image are NOT carried over - the Authorised Training Partner
--    card renders from atc_partners (autodesk_atc, already ticked). Otherwise verbatim, as
--    ASCII literals. Course topics (description) are already identical to the parent's 4.
--    Neither text states a day count. Duration 15 hrs, Sessions 2 and $700 stay as they are.
-- 2. meta_description named a retired course ("linking architecture to designing retaining
--    walls"); rewritten (no day count).
-- 3. Funding block: a non-WSQ course carries no funding; the block says so and links the
--    WSQ twin (verified 200, no redirect, on www.tertiarycourses.com.sg).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush. Schedule template already pairs B09 with (SG) WSQ-B09.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C508' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021004287' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master Autodesk Revit Architecture in this hands-on masterclass. Model sites, walls, roofs and stairs, then document and specify with rooms, area plans, sections, families, schedules and drawing sheets at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------- About from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Step up your architectural design game with our hands-on Revit course. Tailored for beginners and experienced professionals, this course provides a deep dive into the essentials of Building Information Modeling (BIM) using Revit software. You will learn how to create detailed floor plans, elevations, and 3D models, in addition to managing building data effectively for construction or renovation projects.</p>\r\n<p>By the end of this course, you''ll be proficient in creating comprehensive architectural drafts, manipulating parametric objects, and organizing project data efficiently. You''ll gain hands-on experience through project-based learning that simulates real-world scenarios, preparing you to excel in the architectural design industry. Equip yourself with the knowledge and skills to produce superior construction plans and designs with Revit.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C508 - Funding and Grant', 'course_C508_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C508_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C508_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C508_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-architecture-drawing-with-revit.html" title="WSQ - Architecture Drawing with Revit">WSQ - Architecture Drawing with Revit</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C508_funding_and_grant';
