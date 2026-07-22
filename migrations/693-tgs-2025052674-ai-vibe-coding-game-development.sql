-- 693: Repurpose WSQ course TGS-2025052674
--   "WSQ - Fast-Track to Unreal Game Development for Aspiring Game Developers"
--   -> "WSQ - AI Vibe Coding for Game Development"
-- SG-only in effect: TGS- SKUs do not exist on partner sites, so @e is NULL
-- there and every statement below is a guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052674');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_tp    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');

-- Name + labels + cover
UPDATE catalog_product_entity_varchar SET value = 'WSQ - AI Vibe Coding for Game Development'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052674-20260722-162753.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'WSQ - AI Vibe Coding for Game Development'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope
UPDATE catalog_product_entity_varchar SET value = 'wsq-ai-vibe-coding-for-game-development'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = 'WSQ AI Vibe Coding for Game Development | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'Design, build, and prototype games fast with AI coding assistants: gameplay systems, AI-assisted testing, and optimisation. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md AND store_id = 0;
UPDATE catalog_product_entity_text SET value = 'WSQ game development course, AI vibe coding games, AI-assisted game development Singapore, game prototyping with AI, Unreal Blueprint course, gameplay programming, AI coding assistant training, game testing and debugging, game design course'
  WHERE entity_id = @e AND attribute_id = @a_mk AND store_id = 0;

-- Course outline (description) — keep this course's LSN_DATA + <p><strong> shape
UPDATE catalog_product_entity_text SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: AI Vibe Coding Fundamentals for Game Development","subsecs":[],"links":[]},{"title":"Topic 2: Building Interactive Gameplay and Game Systems","subsecs":[],"links":[]},{"title":"Topic 3: AI-Assisted Testing, Optimization, and Game Deployment","subsecs":[],"links":[]}] -->', '\n',
'<p><strong>Topic 1: AI Vibe Coding Fundamentals for Game Development</strong></p>', '\n',
'<p><strong>Topic 2: Building Interactive Gameplay and Game Systems</strong></p>', '\n',
'<p><strong>Topic 3: AI-Assisted Testing, Optimization, and Game Deployment</strong></p>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- About This Course (short_description): new intro paragraphs, splice the
-- Brochure / Skills Framework / Certification / WSQ Funding sections byte-identical.
UPDATE catalog_product_entity_text SET value = CONCAT(
'<p><strong>WSQ AI Vibe Coding for Game Development</strong> is a hands-on course that teaches participants how to rapidly design, develop, and prototype games using AI-powered coding assistants and modern game development tools. Instead of spending excessive time writing repetitive code, participants will learn how to leverage Generative AI to accelerate game development while understanding the fundamental principles of game design, programming, and interactive media.</p>', '\n',
'<p>The course begins with the fundamentals of game development, including project setup, game architecture, level design, asset management, gameplay mechanics, physics, animation, and user interface design. Participants will use AI coding assistants to generate, explain, debug, and optimise game scripts, enabling them to build game features faster while maintaining code quality and consistency.</p>', '\n',
'<p>Building on these foundations, participants will develop interactive gameplay systems such as player controls, character movement, collision detection, scoring systems, inventory management, AI-controlled characters, and event-driven game logic. They will also learn to create engaging game environments by integrating animations, audio, visual effects, and interactive objects including doors, switches, elevators, and collectibles.</p>', '\n',
'<p>Throughout the course, participants will adopt a Vibe Coding workflow that combines AI-assisted development with iterative design, testing, debugging, and optimisation. They will learn effective prompt engineering techniques for game development, best practices for AI-assisted coding, code refactoring, and performance optimisation to create efficient and maintainable game projects.</p>', '\n',
'<p>By the end of the course, participants will be able to confidently design, build, test, debug, and refine complete game prototypes using AI-assisted development tools, significantly improving productivity while producing engaging games for desktop, mobile, or other supported platforms.</p>', '\n',
SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('<h2>Course Brochure</h2>', value) > 0;

-- Learning Outcomes cms_block
UPDATE cms_block SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>', '\n',
'<ul>', '\n',
'<li>LO1: Interpret technical briefs to implement level maps and import gameplay assets using Unreal game engines.</li>', '\n',
'<li>LO2: Apply Unreal Blueprint for game development and design.</li>', '\n',
'<li>LO3: Test and debug Unreal scripts while maintaining up-to-date documentation for level scripting.</li>', '\n',
'</ul>')
  WHERE identifier = 'course_TGS-2025052674_learning_outcomes';

-- Trainer bios: retitle course quotes only (Unreal mentions stay — the WSQ
-- learning outcomes still cover Unreal engines and Blueprint).
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'Fast-Track to Unreal Game Development for Aspiring Game Developers', 'AI Vibe Coding for Game Development')
  WHERE entity_id = @e AND attribute_id = @a_tp;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'Fast-Track to Unreal Game Development', 'AI Vibe Coding for Game Development')
  WHERE entity_id = @e AND attribute_id = @a_tp;
