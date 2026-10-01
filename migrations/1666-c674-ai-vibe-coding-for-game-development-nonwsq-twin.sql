-- C674 AI Vibe Coding for Game Development = non-WSQ twin of TGS-2025052674
-- (WSQ - AI Vibe Coding for Game Development), converted to a 2-day course to
-- match its WSQ parent.
--
-- 1. Fee $350 -> $700 (2 days at the standard $350/day), every scope row.
-- 2. Duration tile 7.5 -> 15 hrs; Sessions tile 1 -> 2.
-- 3. "What's This Course About" (`short_description`) and the course topics
--    (`description`) copied from the WSQ parent, with the parent's course name
--    ("WSQ AI Vibe Coding for Game Development") swapped for this one; any
--    store-scope override is dropped so store 0 renders.
-- 4. Meta description rewritten without the old "1-day" claim.
-- 5. Funding block created (C674 had none) and linked to the WSQ twin.
--
-- The schedule template (-> B15) is switched through the code path, not SQL.
-- Every statement joins on the TGS- parent, so partner sites (no parent) are no-ops.
-- Idempotent: re-running writes the same values.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity c ON c.entity_id = d.entity_id AND TRIM(c.sku) = 'C674'
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.attribute_code = 'price' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025052674'
   SET d.value = 700;

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C674'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'duration' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025052674'
   SET v.value = '15';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C674'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'sessions' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025052674'
   SET v.value = '2';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C674'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'meta_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025052674'
   SET v.value = 'Design, build and prototype games fast with AI vibe coding: gameplay systems, game environments, AI-assisted testing, optimisation and deployment in a hands-on course at Tertiary Courses Singapore.';

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, c.entity_id, '<p><strong>AI Vibe Coding for Game Development</strong> is a hands-on course that teaches participants how to rapidly design, develop, and prototype games using AI-powered coding assistants and modern game development tools. Instead of spending excessive time writing repetitive code, participants will learn how to leverage Generative AI to accelerate game development while understanding the fundamental principles of game design, programming, and interactive media.</p>\n<p>The course begins with the fundamentals of game development, including project setup, game architecture, level design, asset management, gameplay mechanics, physics, animation, and user interface design. Participants will use AI coding assistants to generate, explain, debug, and optimise game scripts, enabling them to build game features faster while maintaining code quality and consistency.</p>\n<p>Building on these foundations, participants will develop interactive gameplay systems such as player controls, character movement, collision detection, scoring systems, inventory management, AI-controlled characters, and event-driven game logic. They will also learn to create engaging game environments by integrating animations, audio, visual effects, and interactive objects including doors, switches, elevators, and collectibles.</p>\n<p>Throughout the course, participants will adopt a Vibe Coding workflow that combines AI-assisted development with iterative design, testing, debugging, and optimisation. They will learn effective prompt engineering techniques for game development, best practices for AI-assisted coding, code refactoring, and performance optimisation to create efficient and maintainable game projects.</p>\n<p>By the end of the course, participants will be able to confidently design, build, test, debug, and refine complete game prototypes using AI-assisted development tools, significantly improving productivity while producing engaging games for desktop, mobile, or other supported platforms.</p>'
  FROM catalog_product_entity c
  JOIN eav_attribute a ON a.attribute_code = 'short_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025052674'
 WHERE TRIM(c.sku) = 'C674'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, c.entity_id, '<!-- LSN_DATA: [{"title":"Topic 1: AI Vibe Coding Fundamentals for Game Development","subsecs":[],"links":[]},{"title":"Topic 2: Building Interactive Gameplay and Game Systems","subsecs":[],"links":[]},{"title":"Topic 3: AI-Assisted Testing, Optimization, and Game Deployment","subsecs":[],"links":[]}] -->\n<p><strong>Topic 1: AI Vibe Coding Fundamentals for Game Development</strong></p>\n<p><strong>Topic 2: Building Interactive Gameplay and Game Systems</strong></p>\n<p><strong>Topic 3: AI-Assisted Testing, Optimization, and Game Deployment</strong></p>'
  FROM catalog_product_entity c
  JOIN eav_attribute a ON a.attribute_code = 'description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025052674'
 WHERE TRIM(c.sku) = 'C674'
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE t FROM catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C674'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code IN ('short_description', 'description') AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025052674'
 WHERE t.store_id <> 0;

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C674 - Funding and Grant', 'course_C674_funding_and_grant', '', NOW(), NOW(), 1
  FROM catalog_product_entity p
 WHERE TRIM(p.sku) = 'TGS-2025052674'
   AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C674_funding_and_grant')
 LIMIT 1;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_C674_funding_and_grant';

UPDATE cms_block b
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025052674'
   SET b.content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-game-development.html" title="WSQ - AI Vibe Coding for Game Development">WSQ - AI Vibe Coding for Game Development</a></span></p>',
       b.update_time = NOW()
 WHERE b.identifier = 'course_C674_funding_and_grant';
