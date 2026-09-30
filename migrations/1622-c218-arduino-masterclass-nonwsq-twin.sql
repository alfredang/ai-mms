-- C218: "Robotics with Arduino" -> "Arduino Masterclass", the 1-day non-WSQ twin of
-- TGS-2020506075 (WSQ - Practical Electronics Design with Arduino Microcontroller).
--
-- 1. name, url_key/url_path (robotics-with-arduino -> arduino-masterclass),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. "What's This Course About" and course topics follow the WSQ parent (About with the
--    parent's old course name replaced by the new title). Written as literals, not a
--    parent join (see 1619). Stays 1 day / 7.5 hrs / $350.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. Funding block created (C218 had none) and linked to the WSQ twin.
-- 5. 301s: the product's system rows are renamed in place to the new slug (so the new
--    URL resolves without a rewrite refresh); every old path, bare or category-prefixed,
--    301s one hop to the new BARE slug, and legacy RP rows are flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule templates - parent (SG) WSQ-A01 (gid 253)
-- -> (SG) WSQ-A06 (gid 300); C218 stays on / is set to A06 (gid 186). Then flat reindex
-- + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C218' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2020506075' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Arduino Masterclass';
SET @old_slug  := 'robotics-with-arduino';
SET @new_slug  := 'arduino-masterclass';

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
SELECT 4, @a_mdesc, 0, @pid, 'Master Arduino in this hands-on masterclass. Learn embedded systems and basic electronics, work with analog and digital sensors, and control servos and stepper motors for robotics at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Arduino, Arduino Masterclass, Embedded Systems, Microcontroller, Electronics, Sensors, Actuators, Servo Control, Stepper Motor, Robotics, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Ready to bring robots to life? Our Arduino Masterclass focuses exclusively on robotics applications. Get hands-on experience programming Arduino microcontrollers, integrating sensors, and designing control systems. From basic tasks like movement and obstacle detection to more complex functions like automated decision-making, this course offers a robust foundation for building your own robotic systems.</p>\n<p>But there''s more! Dive deeper into advanced control algorithms and state-of-the-art sensor fusion techniques that can make your robots smarter and more autonomous. Whether you''re interested in building service robots, automated manufacturing systems, or even robotic art installations, this course equips you with the skills to design and implement sophisticated robotic solutions. By mastering these techniques, you''ll become a sought-after talent in the rapidly expanding field of robotics.</p>\n<p><span style="color: #ff0000;"><strong>Note that the Arduino kit is used for the training. The course fee does not include the kit.</strong></span></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Introduction of Embedded Systems","subsecs":[{"title":"Overview of Embedded Systems","links":[]},{"title":"Applications of Embedded Systems","links":[]},{"title":"Introduction to Arduino Microcontroller","links":[]},{"title":"Serial Communication","links":[]}]},{"title":"Topic 2: Introduction to Basic Electronics","subsecs":[{"title":"Basic Electronics Concepts","links":[]},{"title":"Digital Input/Output","links":[]},{"title":"Pulse Width Modulation (PWM)","links":[]}]},{"title":"Topic 3: Analog Sensors and Transducers","subsecs":[{"title":"Overview of Analog Sensors and Transducers","links":[]},{"title":"Analog Input/Output","links":[]},{"title":"Servo Control","links":[]}]},{"title":"Topic 4: Digital Sensors and Transductors","subsecs":[{"title":"Overview of Digital Sensors and Transducers","links":[]},{"title":"Light Activation by Motion Detection","links":[]}]},{"title":"Topic 5: Actuators","subsecs":[{"title":"Overview of Actuator Networks","links":[]},{"title":"Stepper Motor Control","links":[]}]}] -->\n<p><strong>Topic 1: Introduction of Embedded Systems</strong></p>\n<p><em>Overview of Embedded Systems</em></p>\n<p><em>Applications of Embedded Systems</em></p>\n<p><em>Introduction to Arduino Microcontroller</em></p>\n<p><em>Serial Communication</em></p>\n<p><strong>Topic 2: Introduction to Basic Electronics</strong></p>\n<p><em>Basic Electronics Concepts</em></p>\n<p><em>Digital Input/Output</em></p>\n<p><em>Pulse Width Modulation (PWM)</em></p>\n<p><strong>Topic 3: Analog Sensors and Transducers</strong></p>\n<p><em>Overview of Analog Sensors and Transducers</em></p>\n<p><em>Analog Input/Output</em></p>\n<p><em>Servo Control</em></p>\n<p><strong>Topic 4: Digital Sensors and Transductors</strong></p>\n<p><em>Overview of Digital Sensors and Transducers</em></p>\n<p><em>Light Activation by Motion Detection</em></p>\n<p><strong>Topic 5: Actuators</strong></p>\n<p><em>Overview of Actuator Networks</em></p>\n<p><em>Stepper Motor Control</em></p>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C218-20260930-193215.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C218 - Funding and Grant', 'course_C218_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C218_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C218_funding_and_grant';

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-practical-electronics-design-with-arduino-microcontroller.html" title="WSQ - Practical Electronics Design with Arduino Microcontroller">WSQ - Practical Electronics Design with Arduino Microcontroller</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C218_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c218_old;
CREATE TEMPORARY TABLE tmp_c218_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c218_old
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
  FROM tmp_c218_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c218_old;
