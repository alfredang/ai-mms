-- C156 Canva Design Masterclass: 1-day non-WSQ twin of TGS-2024042369
-- (WSQ - Exploring the Art of Visual Communication with Canva).
--
-- 1. "What's This Course About" and course topics follow the WSQ parent, written as
--    literals (see 1619). About names this course instead of the WSQ title; neither
--    text states a day count.
-- 2. meta_description rewritten without the "1-day" day count; Duration 7.5 hrs and
--    Sessions 1 asserted (1-day course, $350 unchanged).
-- 3. Cover alt/gallery labels still carried the retired "Visual Magic with Canva:
--    Design Like a Pro" name -> the course name.
-- 4. Funding block created if missing and pointed at the WSQ twin.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): align the schedule template with the parent's
-- (SG) WSQ- template via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C156' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024042369' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @title := 'Canva Design Masterclass';

SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Embark on an insightful journey into the world of visual design with our course, "Canva Design Masterclass." This course is meticulously crafted to empower you with the ability to create compelling visual communication projects using Canva, blending typography seamlessly with media elements for impactful designs. Whether you\'re a budding designer or looking to enhance your professional skill set, this course offers a deep dive into the practical and aesthetic aspects of Canva, teaching you how to bring your creative ideas to life with professional flair.</p>\r\n<p>The course further delves into the creation and evaluation of Canva storyboards and task flows, incorporating modern design best practices. Through hands-on exercises and expert guidance, you will learn to strategize your designs, effectively employing Canva\'s wide range of tools and features. Collaborative projects form a core component of the curriculum, allowing you to work with others to enhance the effectiveness of your visual communication. This course is ideal for individuals seeking to master Canva for personal or professional purposes, equipping you with the skills to communicate ideas visually with confidence and creativity.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Introduction to Canva and Basic Design Principles\\u00a0","subsecs":[{"title":"Navigating Canva\'s interface and features","links":[]},{"title":"Principles of typography and logo design","links":[]},{"title":"Basics of visual communication design","links":[]},{"title":"Creating simple designs and layouts","links":[]},{"title":"Experimenting with Canva\'s text and image tools","links":[]}]},{"title":"Topic 2: Color and Form in Canva Design\\u00a0","subsecs":[{"title":"Fundamentals of color theory and application","links":[]},{"title":"Exploring color schemes and palettes in Canva","links":[]},{"title":"The role of forms and shapes in design","links":[]},{"title":"Practical exercises on color and form harmonization","links":[]},{"title":"Designing for different environments and contexts","links":[]}]},{"title":"Topic 3: Storyboarding and Flow Design in Canva\\u00a0","subsecs":[{"title":"Techniques for creating effective storyboards","links":[]},{"title":"Developing task flows for visual projects","links":[]},{"title":"Utilizing Canva for ideation and conceptualization","links":[]},{"title":"Hands-on exercises in storyboard creation","links":[]}]},{"title":"Topic 4: Best Practices and Aesthetic Analysis in Canva\\u00a0","subsecs":[{"title":"Understanding and applying design best practices","links":[]},{"title":"Techniques for aesthetic and functional analysis","links":[]},{"title":"Critiquing and improving Canva projects","links":[]},{"title":"Workshop on designing with user experience in mind","links":[]},{"title":"Group activities for peer review and feedback","links":[]}]},{"title":"Topic 5: Critical Review and Enhancement Strategies in Canva\\u00a0","subsecs":[{"title":"Methods for critiquing visual designs","links":[]},{"title":"Strategies for effective visual communication","links":[]},{"title":"Workshops on enhancing existing Canva designs","links":[]},{"title":"Collaborative exercises for peer-to-peer learning","links":[]},{"title":"Techniques for iterative design improvements","links":[]}]},{"title":"Topic 6: Innovative Approaches to Design in Canva\\u00a0","subsecs":[{"title":"Developing innovative design strategies","links":[]},{"title":"Exploring advanced features and tools in Canva","links":[]},{"title":"Group projects for practical application","links":[]},{"title":"Presentations on innovative design solutions","links":[]}]}] -->\r\n<p><strong>Topic 1: Introduction to Canva and Basic Design Principles&#160;</strong></p>\r\n<p><em>Navigating Canva\'s interface and features</em></p>\r\n<p><em>Principles of typography and logo design</em></p>\r\n<p><em>Basics of visual communication design</em></p>\r\n<p><em>Creating simple designs and layouts</em></p>\r\n<p><em>Experimenting with Canva\'s text and image tools</em></p>\r\n<p><strong>Topic 2: Color and Form in Canva Design&#160;</strong></p>\r\n<p><em>Fundamentals of color theory and application</em></p>\r\n<p><em>Exploring color schemes and palettes in Canva</em></p>\r\n<p><em>The role of forms and shapes in design</em></p>\r\n<p><em>Practical exercises on color and form harmonization</em></p>\r\n<p><em>Designing for different environments and contexts</em></p>\r\n<p><strong>Topic 3: Storyboarding and Flow Design in Canva&#160;</strong></p>\r\n<p><em>Techniques for creating effective storyboards</em></p>\r\n<p><em>Developing task flows for visual projects</em></p>\r\n<p><em>Utilizing Canva for ideation and conceptualization</em></p>\r\n<p><em>Case studies of effective storyboard designs</em></p>\r\n<p><em>Hands-on exercises in storyboard creation</em></p>\r\n<p><strong>Topic 4: Best Practices and Aesthetic Analysis in Canva&#160;</strong></p>\r\n<p><em>Understanding and applying design best practices</em></p>\r\n<p><em>Techniques for aesthetic and functional analysis</em></p>\r\n<p><em>Critiquing and improving Canva projects</em></p>\r\n<p><em>Workshop on designing with user experience in mind</em></p>\r\n<p><em>Group activities for peer review and feedback</em></p>\r\n<p><strong>Topic 5: Critical Review and Enhancement Strategies in Canva&#160;</strong></p>\r\n<p><em>Methods for critiquing visual designs</em></p>\r\n<p><em>Strategies for effective visual communication</em></p>\r\n<p><em>Workshops on enhancing existing Canva designs</em></p>\r\n<p><em>Collaborative exercises for peer-to-peer learning</em></p>\r\n<p><em>Techniques for iterative design improvements</em></p>\r\n<p><strong>Topic 6: Innovative Approaches to Design in Canva&#160;</strong></p>\r\n<p><em>Developing innovative design strategies</em></p>\r\n<p><em>Exploring advanced features and tools in Canva</em></p>\r\n<p><em>Case studies of successful visual communication</em></p>\r\n<p><em>Group projects for practical application</em></p>\r\n<p><em>Presentations on innovative design solutions</em></p>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

-- ------------------------------------------------ meta / duration -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master visual communication with Canva in this hands-on masterclass. Design with typography, colour and form, build storyboards and task flows, and critique and enhance campaigns at Tertiary Courses Singapore.'
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
SELECT 'Course C156 - Funding and Grant', 'course_C156_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C156_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C156_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C156_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-exploring-the-art-of-visual-communication-with-canva.html" title="WSQ - Exploring the Art of Visual Communication with Canva">WSQ - Exploring the Art of Visual Communication with Canva</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C156_funding_and_grant';
