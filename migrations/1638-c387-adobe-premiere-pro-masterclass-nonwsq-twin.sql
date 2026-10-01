-- C387 Adobe Premiere Pro Masterclass: 2-day non-WSQ twin of TGS-2026064536
-- (CASL - Video Editing with Premiere Pro); courseware duplicated from that course.
--
-- 1. "What's This Course About" follows the parent, written as a literal (see 1619),
--    naming this course instead of the parent's "WSQ's Video Editing with Premiere
--    Pro course". No day count. Course topics (description) already carry the
--    parent's five topics and are left alone; Duration 15, Sessions 2 days and the
--    $700 fee are already correct.
-- 2. meta_description still described the retired "Adobe Premiere Pro CC Essentials"
--    course (multicam etc.) - rewritten for this course, no day count, < 255 chars.
-- 3. Funding block pointed at the funded CASL twin (it only said "No funding").
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): switch the schedule template to B07 (requested by
-- the user) via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C387' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064536' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_meta  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');

-- ------------------------------------------------- About from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Unleash your creativity in video post-production with the Adobe Premiere Pro Masterclass. Designed for both beginners and those looking to advance their skills, this course covers the fundamentals of editing, special effects, and sound manipulation. By the end of the course, you\'ll be proficient in cutting sequences, layering transitions, and creating compelling video content that stands out.</p><p>To ensure a comprehensive learning experience, this course includes hands-on exercises and real-world projects that put your skills to the test. You\'ll be guided through the entire editing process, from importing and organizing media to exporting the final cut. Along the way, you\'ll pick up essential skills in color correction, audio enhancement, and advanced editing techniques, providing you with a robust skill set for any video editing challenge.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_short AND store_id <> 0;

-- ------------------------------------------------- meta description -----
UPDATE catalog_product_entity_varchar
   SET value = 'Master video editing with Adobe Premiere Pro: cutting, trimming, pacing, transitions, audio, graphics, colour correction, captions and export, in a hands-on masterclass at Tertiary Courses Singapore.'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_meta;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C387 - Funding and Grant', 'course_C387_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C387_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C387_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C387_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For CASL funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-video-editing-with-premiere-pro.html" title="CASL - Video Editing with Premiere Pro">CASL - Video Editing with Premiere Pro</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C387_funding_and_grant';
