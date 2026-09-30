-- C200 Adobe Lightroom Masterclass: 1-day non-WSQ twin of TGS-2026064712
-- (CASL - Mastering Adobe Lightroom for Photo Editing); courseware duplicated
-- from that course.
--
-- 1. "What's This Course About" follows the parent, written as a literal (see 1619),
--    naming this course instead of the parent's "WSQ's Digital Image Production with
--    Lightroom course". No day count. Course topics (description) already carry the
--    parent's three topics and are left alone; meta_description, Duration 7.5,
--    Sessions 1 and the $350 fee are already correct.
-- 2. Funding block pointed at the funded CASL twin (it only said "No funding").
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): switch the schedule template to A09 (parent is on
-- (SG) WSQ-A09) via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C200' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064712' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- ------------------------------------------------- About from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Step into the world of professional photo editing with the Adobe Lightroom Masterclass. This comprehensive guide covers all the key aspects of Adobe Lightroom, from basic image organization to advanced editing techniques. By the course\'s end, you\'ll know how to adjust exposure, manage colors, and apply effects to produce high-quality images that captivate your audience.</p><p>This skill-centric course is built around hands-on exercises and real-world scenarios. You will gain practical experience in image selection, cropping, retouching, and applying filters, setting you up for success in any photo editing venture. Whether you\'re a budding photographer or an established creative looking to level up, this course equips you with the expertise to navigate the vast world of digital image production efficiently.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_short AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C200 - Funding and Grant', 'course_C200_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C200_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C200_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C200_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For CASL funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-mastering-adobe-lightroom-for-photo-editing.html" title="CASL - Mastering Adobe Lightroom for Photo Editing">CASL - Mastering Adobe Lightroom for Photo Editing</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C200_funding_and_grant';
