-- C391 "AutoCAD Masterclass": the 2-day non-WSQ twin of TGS-2021005538
-- (WSQ - Technical Drawing with AutoCAD). Name and slug (autocad-masterclass) are already
-- right, so there is no rename, no 301 and no cover re-render.
--
-- 1. "What's This Course About" and course topics follow the WSQ parent (its 5 topics).
--    The parent's "WSQ-accredited AutoCAD course" is reworded to "hands-on AutoCAD course";
--    otherwise verbatim, written as ASCII literals. Neither text states a day count.
--    Duration 15 hrs, Sessions 2 and $700 stay as they are.
-- 2. meta_description still named the retired "AutoCAD Essential Training"; rewritten
--    (no day count). meta_keyword refreshed to match.
-- 3. Funding block: a non-WSQ course carries no funding; the block says so and links the
--    WSQ twin (verified 200, no redirect, on www.tertiarycourses.com.sg).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template -> the counterpart of the parent's
-- (SG) WSQ-B## template via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C391' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021005538' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master AutoCAD in this hands-on masterclass. Learn 2D drafting and modifying, layers, blocks and xrefs, dimensions, part lists, layouts and plotting to produce precise technical drawings at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'AutoCAD, AutoCAD Masterclass, AutoCAD Course, Technical Drawing, CAD Drafting, 2D Drafting, Layers, Blocks, Dimensioning, Plotting, Autodesk, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Dive into the world of technical drawing with our hands-on AutoCAD course. Our comprehensive curriculum covers everything from basic drafting techniques to advanced architectural and engineering plans. Designed to fit the needs of professionals and beginners alike, this course offers hands-on training in 2D and 3D modeling, ensuring you grasp the full range of AutoCAD''s capabilities.</p>\n<p>By the end of this course, you will be able to create precise and informative technical drawings for various industries. This includes mastering dimensions, layers, blocks, and attributes, as well as understanding how to incorporate text and annotations for maximum clarity. Practical exercises and real-world projects will further sharpen your skills, making you a proficient AutoCAD user capable of handling complex technical drawing tasks.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Getting Started with AutoCAD</h3>\n<ul>\n<li>AutoCAD User Interface</li>\n<li>Basic AutoCAD Operations</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2: Technical Drawing with AutoCAD</h3>\n<ul>\n<li>Drawing Objects</li>\n<li>Modifying Objects</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3: Part Lists</h3>\n<ul>\n<li>Organizing Objects</li>\n<li>Drawing with Accuracy</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4: Design Documentation</h3>\n<ul>\n<li>Layouts, Printing, Outputs</li>\n<li>Annotative Techniques</li>\n</ul>\n<h3 class="course-topic-h3">Topic 5: Design Specification</h3>\n<ul>\n<li>Reusable Content</li>\n<li>Drawing Management</li>\n</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C391 - Funding and Grant', 'course_C391_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C391_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C391_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C391_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-technical-drawing-with-autocad.html" title="WSQ - Technical Drawing with AutoCAD">WSQ - Technical Drawing with AutoCAD</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C391_funding_and_grant';
