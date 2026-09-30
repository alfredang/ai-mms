-- C163 Adobe After Effects Masterclass: 1-day non-WSQ twin of TGS-2026065048
-- (CASL - Compositing and Visual Effects with After Effects).
--
-- 1. "What's This Course About" and course topics follow the parent, written as literals
--    (see 1619/1621). About names this course instead of "WSQ's Video Editing with After
--    Effects course"; neither text states a day count. Replaces the retired "After Effects
--    CC Essential" copy and its three old topics.
-- 2. meta_description rewritten for the new syllabus (no day count); Duration 7.5 hrs
--    (was 7) and Sessions 1 asserted (1-day course, $350 unchanged).
-- 3. Cover alt/gallery labels asserted to the course name.
-- 4. Funding block created if missing and pointed at the funded CASL twin.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): align the schedule template with the parent's
-- (SG) WSQ- template via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C163' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026065048' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @title := 'Adobe After Effects Masterclass';

SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Step up your video editing game with the Adobe After Effects Masterclass. This course is structured to give you a comprehensive understanding of creating awe-inspiring visual effects, intricate animations, and professional motion graphics. Whether you are a beginner or an experienced editor, this course provides you with the expertise to breathe life into your video projects.</p>\r\n<p>Benefit from hands-on exercises and real-world scenarios that cover everything from the basics to more advanced techniques. You\'ll explore the entire production workflow, including keyframe manipulation, 3D layers, and various visual effects. With individualized guidance and practical projects, you\'ll finish the course equipped with skills that are highly sought after in the video editing and animation sectors.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Review Video Content for Editing with After Effects","subsecs":[{"title":"Review the video scripts and identify video quality issues","links":[]},{"title":"Develop possible editing solutions to rectify the video quality issues using After Effects","links":[]}]},{"title":"Topic 2: Video Editing Using After Effects","subsecs":[{"title":"Develop an After Effects editing plan","links":[]},{"title":"Basic video editing techniques using After Effects","links":[]},{"title":"Review the animation, special effects and rendering on the video content","links":[]}]},{"title":"Topic 3: Advanced Video Editing Techniques with After Effects","subsecs":[{"title":"Assess the edited video for exporting","links":[]},{"title":"Fix additional video issues using advanced After Effects techniques","links":[]},{"title":"Introduction to After Effects Robo brush","links":[]}]}] -->\r\n<p><strong>Topic 1: Review Video Content for Editing with After Effects</strong></p>\r\n<p><em>Review the video scripts and identify video quality issues</em></p>\r\n<p><em>Develop possible editing solutions to rectify the video quality issues using After Effects</em></p>\r\n<p><strong>Topic 2: Video Editing Using After Effects</strong></p>\r\n<p><em>Develop an After Effects editing plan</em></p>\r\n<p><em>Basic video editing techniques using After Effects</em></p>\r\n<p><em>Review the animation, special effects and rendering on the video content</em></p>\r\n<p><strong>Topic 3: Advanced Video Editing Techniques with After Effects</strong></p>\r\n<p><em>Assess the edited video for exporting</em></p>\r\n<p><em>Fix additional video issues using advanced After Effects techniques</em></p>\r\n<p><em>Introduction to After Effects Robo brush</em></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

-- ------------------------------------------------ meta / duration -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master compositing, motion graphics and visual effects in Adobe After Effects in this hands-on masterclass. Review footage, animate, key, track and deliver QC-checked renders at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_mdesc, @a_dur, @a_sess) AND store_id <> 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '7.5' FROM DUAL WHERE @ok AND @a_dur IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '1' FROM DUAL WHERE @ok AND @a_sess IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @title
 WHERE @ok AND g.entity_id = @pid;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C163 - Funding and Grant', 'course_C163_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C163_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C163_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C163_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For CASL funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-compositing-and-visual-effects-with-after-effects.html" title="CASL - Compositing and Visual Effects with After Effects">CASL - Compositing and Visual Effects with After Effects</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C163_funding_and_grant';
