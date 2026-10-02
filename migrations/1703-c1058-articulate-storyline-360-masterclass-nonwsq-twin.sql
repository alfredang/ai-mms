-- C1058 Articulate Storyline 360 Masterclass = the 2-day non-WSQ twin of TGS-2024042308 (WSQ - Mastering
-- Articulate Storyline 360 for e-Learning Content Creation, 4 days). Courseware v1.0 converted from the WSQ v10 set
-- (github.com/tertiarycourses/C1058-Articulate-Storyline-360-Masterclass).
--
-- 1. Course fee $350 -> $700 (every scope row), Duration 7.5 -> 15 hrs, Sessions 1 -> 2 (was a 1-day course).
-- 2. "What's This Course About" copied from the parent (its opener names this course instead); course topics
--    copied from the parent's LSN_DATA (same 4 topics / 28 sub-topics; NBSP + bullet bytes ASCII-sanitised).
--    No day count, no WSQ wording. Store-scope overrides removed.
-- Name / slug / meta description unchanged (meta states no day count). Funding block course_C1058_funding_and_grant
-- already points at the WSQ twin (200). Schedule template -> B07 is a code path (CoursesaveController), not SQL.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: price + flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1058' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024042308' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_price := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ------------------------------------------------------------ fee / duration / sessions -----
INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 700 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_decimal SET value = 700
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '15' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '2' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_dur, @a_sess) AND store_id <> 0;

-- ------------------------------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Dive into the realm of e-Learning content creation with our "Articulate Storyline 360 Masterclass" course. This comprehensive program equips you with the expertise to conceptualize and map out engaging digital storyboards, utilizing the advanced capabilities of Articulate Storyline 360. You\'ll learn the principles of effective storytelling and how to integrate them into your e-Learning projects, ensuring your content is both educational and captivating. This course is perfect for educators, instructional designers, and anyone interested in enhancing their skills in creating compelling e-Learning materials.</p>\n<p>In this course, you will also explore the latest industry trends and features in e-Learning content development. Gain insights into identifying and determining diverse e-Learning content that resonates with learners. The course covers effective modes for distributing interactive e-Learning content, allowing you to reach a wider audience effectively. Additionally, you will develop guidelines and understand the nuances of content delivery frequency to ensure effective e-Learning delivery. By the end of this course, you\'ll have a profound understanding of using Articulate Storyline 360 to create innovative and impactful e-Learning experiences.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1 Get Started on Articulate Storyline 360","subsecs":[{"title":"Storyline 360: Creating a New Project","links":[]},{"title":"Mastering the Storyline 360 Interface","links":[]},{"title":"Working with Slides and Layers","links":[]},{"title":"Importing Slides","links":[]},{"title":"Working with Quiz Slides","links":[]},{"title":"Working with the Question Editor","links":[]},{"title":"Working with Result Slides","links":[]},{"title":"Using Question Banks","links":[]},{"title":"Using the Media Library","links":[]},{"title":"Working with Content Library 360 Media","links":[]}]},{"title":"Topic 2 - Working with Assets","subsecs":[{"title":"Working with Pictures","links":[]},{"title":"Working with 360° Images","links":[]},{"title":"Working with Videos","links":[]},{"title":"Working with Audio","links":[]},{"title":"Adding Accessibility","links":[]},{"title":"Working with Web Content","links":[]},{"title":"Adding and Editing Screen Recordings","links":[]},{"title":"Working with Shapes, Captions, Text Boxes, and Tables","links":[]},{"title":"Working with Text","links":[]},{"title":"Formatting, Sizing, and Positioning Objects","links":[]}]},{"title":"Topic 3 Interactivity","subsecs":[{"title":"Adding Zoom Regions","links":[]},{"title":"Adding Interactive Objects","links":[]},{"title":"Timeline, States, and Notes","links":[]},{"title":"Applying Animations and Slide Transitions","links":[]}]},{"title":"Topic 4 Presentation","subsecs":[{"title":"Customizing Your Course Design","links":[]},{"title":"Customizing the Player","links":[]},{"title":"Collaborating with Stakeholders","links":[]},{"title":"Reviewing and Publishing a Course","links":[]}]}] -->\n<p><strong>Topic 1 Get Started on Articulate Storyline 360</strong></p>\n<p><em>Storyline 360: Creating a New Project</em></p>\n<p><em>Mastering the Storyline 360 Interface</em></p>\n<p><em>Working with Slides and Layers</em></p>\n<p><em>Importing Slides</em></p>\n<p><em>Working with Quiz Slides</em></p>\n<p><em>Working with the Question Editor</em></p>\n<p><em>Working with Result Slides</em></p>\n<p><em>Using Question Banks</em></p>\n<p><em>Using the Media Library</em></p>\n<p><em>Working with Content Library 360 Media</em></p>\n<p><strong>Topic 2 - Working with Assets</strong></p>\n<p><em>Working with Pictures</em></p>\n<p><em>Working with 360° Images</em></p>\n<p><em>Working with Videos</em></p>\n<p><em>Working with Audio</em></p>\n<p><em>Adding Accessibility</em></p>\n<p><em>Working with Web Content</em></p>\n<p><em>Adding and Editing Screen Recordings</em></p>\n<p><em>Working with Shapes, Captions, Text Boxes, and Tables</em></p>\n<p><em>Working with Text</em></p>\n<p><em>Formatting, Sizing, and Positioning Objects</em></p>\n<p><strong>Topic 3 Interactivity</strong></p>\n<p><em>Adding Zoom Regions</em></p>\n<p><em>Adding Interactive Objects</em></p>\n<p><em>Timeline, States, and Notes</em></p>\n<p><em>Applying Animations and Slide Transitions</em></p>\n<p><strong>Topic 4 Presentation</strong></p>\n<p><em>Customizing Your Course Design</em></p>\n<p><em>Customizing the Player</em></p>\n<p><em>Collaborating with Stakeholders</em></p>\n<p><em>Reviewing and Publishing a Course</em></p>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;
