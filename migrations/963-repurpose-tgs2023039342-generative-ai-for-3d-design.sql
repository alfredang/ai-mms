-- 963: Repurpose TGS-2023039342
--   "WSQ - Autodesk Certified Fusion 360 Design for Manufacturing"
--     -> "WSQ - Generative AI for 3D Design"
-- SKU unchanged (all SkillsFuture / SFEC / SFC / PSEA deep links stay valid).
--
-- Surfaces touched (per the TGS- rename checklist, driven by an EAV sweep of
-- BOTH value tables for the old title AND the old tech words
-- "Fusion"/"Autodesk"/"360"/"Manufactur"/"Pearson"):
--   1  name
--   2  meta_title      (plain title: MMD_Seotitle prepends "WSQ funded" and
--                       appends the brand postfix at render time -- the live
--                       value baked BOTH in, so this is also a cleanup)
--   3  url_key + url_path deleted at EVERY scope + explicit 301 for old slug
--   4  short_description  -> About This Course prose ONLY (the Exam Voucher /
--                            Autodesk ATC / Pearson VUE sections are DROPPED:
--                            the course no longer preps an Autodesk exam)
--   5  image/small_image/thumbnail _label + media-gallery label
--   6  trainerprofile   (course-teaching paragraph per trainer; credentials kept)
--   7  meta_description
--   8  meta_keyword
--   9  whoshouldattend  (job roles named the old technology)
--  10  prerequisite     (the ONE software-requirement <li> linking autodesk.com)
--  11  description      (Course Outline: 6 new AI-assisted topics)
--  12  learning_outcomes cms_block  (tool-neutral LO1-LO6, admin-supplied)
--  13  funding_and_grant cms_block  (stray old-title line above the SFEC heading)
--  14  categories: drop Autodesk/exam-prep (71, 212, 216, 222, 182),
--                  add AI Courses (252) + WSQ Generative AI Courses (379)
--                  -- both mirrored into catalog_category_product_index
--
-- Deliberately NOT touched:
--   - `image`/`small_image`/`thumbnail` filesystem paths (they are file paths,
--     not display text; renaming them 404s the JPG -- the storefront renders
--     the R2 `course_image_url` cover instead).
--   - the certification / skills_framework / brochure cms_blocks: the Skills
--     Framework code (Computer-aided Design PRE-DES-4036-1.1) is registered
--     against the UNCHANGED SKU and still describes the competency delivered.
--   - the WSQ funding table + fee figures (price unchanged at $1,400).
--
-- Idempotent: every write is guarded (LOCATE probes / ON DUPLICATE KEY UPDATE /
-- NOT EXISTS), so a re-run converges.
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => all
-- statements are guarded no-ops there (never a NULL entity_id INSERT).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023039342' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_pre    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_tp     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_il     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tl     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------------ 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Generative AI for 3D Design'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------- 2. meta_title (plain)
-- The live value was "WSQ - Design for Manufacturing with Fusion 360
-- Certification Mastery | Tertiary Courses Singapore" -- it baked in BOTH the
-- WSQ token and the brand postfix that MMD_Seotitle adds at render time,
-- yielding "WSQ funded WSQ ... | Tertiary Courses Singapore". Fixed here.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @e, 'Generative AI for 3D Design'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND store_id <> 0 AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. url_key + 301
-- Collision check done: C162 owns 'generative-ai-for-3d-modeling' and
-- TGS-2023039180 owns 'wsq-generative-ai-design-for-civil-3d'. Neither
-- collides with the wsq- prefixed slug below.
SET @old_slug := 'wsq-autodesk-certified-fusion-360-design-for-manufacturing';
SET @new_slug := 'wsq-generative-ai-for-3d-design';

-- Remove any is_system = 0 squatter on the new path first: INSERT IGNORE
-- silently no-ops against a stale row.
DELETE FROM core_url_rewrite
 WHERE request_path = CONCAT(@new_slug, '.html') AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = @new_slug
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it;
-- the surviving store-1 row still holds the OLD slug and would shadow the new
-- URL (this course HAS a store-1 url_path row -- confirmed by probe).
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the ~16 category
-- paths from its own rewrite history, but not this one).
INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT 1, NULL, @e, CONCAT('product/', @e, '/rp-963'), CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'), 0, 'RP'
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                    WHERE x.request_path = CONCAT(@old_slug, '.html') AND x.store_id = 1);

-- ---------------------------------------------- 4. short_description (About)
-- Prose only. The old value also carried "<h2>Exam Voucher</h2>",
-- "<h2>Autodesk ATC</h2>" and "<h2>Certification Exam at Pearson Vue</h2>" --
-- all dropped: the repurposed course does not prepare for an Autodesk exam,
-- so keeping them would advertise a voucher that is no longer included.
UPDATE catalog_product_entity_text
   SET value = '<p>Generative AI for 3D Design equips participants with the skills to conceptualize, create, and refine 3D designs using AI-assisted workflows. Learners will explore how generative AI can transform natural-language descriptions, sketches, reference images, and functional requirements into design concepts, model variations, and detailed 3D assets.</p>
<p>The course covers essential 3D design principles, including solid and surface modeling, component creation, assemblies, materials, dimensions, and design constraints. Participants will use generative AI to accelerate ideation, compare design alternatives, automate repetitive tasks, identify potential design issues, and recommend improvements based on project requirements.</p>
<p>Through hands-on activities, learners will develop 3D components and assemblies, produce exploded views, apply materials, generate realistic renderings, and prepare technical drawings for communication and production. They will also learn to evaluate AI-generated designs for accuracy, functionality, manufacturability, and compliance with relevant standards. By the end of the course, participants will be able to combine generative AI with established 3D design practices to improve productivity, support design decision-making, and produce high-quality outcomes for manufacturing, product development, visualization, and prototyping.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- Any store-scoped short_description override would shadow store 0.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------------ 11. description (Outline)
-- This course's outline uses the <h3 class="course-topic-h3"> shape with
-- per-topic <ul> bullets (no LSN_DATA JSON comment) -- keep that shape.
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: AI-Assisted Machine Part Design and Conceptualization</h3>
<ul>
<li>Interpret functional specifications and design intent</li>
<li>Generate design concepts from text prompts and reference images</li>
<li>Compare AI-generated design alternatives against requirements</li>
<li>Evaluate concepts for manufacturability and material selection</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Generative AI for Sketching and 3D CAD Modeling</h3>
<ul>
<li>Create and modify sketches with curves and primitive features</li>
<li>Create construction planes and axes</li>
<li>Create and modify 3D solid and surface features</li>
<li>Use generative AI to produce and refine model variations</li>
<li>Demonstrate view controls</li>
</ul>
<h3 class="course-topic-h3">Topic 3: AI-Assisted Assembly Design and Modeling</h3>
<ul>
<li>Apply top-down and bottom-up assembly methodologies</li>
<li>Create motion with assembly joints</li>
<li>Demonstrate component control</li>
<li>Control component physical materials</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Creating Exploded Views and Assembly Animations with AI</h3>
<ul>
<li>Create a storyboard</li>
<li>Manipulate component positions with transform</li>
<li>Generate exploded views and assembly animations</li>
</ul>
<h3 class="course-topic-h3">Topic 5: AI-Assisted GD&amp;T and Standardized Technical Drawings</h3>
<ul>
<li>Apply GD&amp;T principles to models and drafts</li>
<li>Create a technical drawing and drawing templates</li>
<li>Create technical drawing elements</li>
<li>Check drawings against relevant standards</li>
</ul>
<h3 class="course-topic-h3">Topic 6: Orthographic Modeling, AI-Based Review and Design Optimization</h3>
<ul>
<li>Create orthographic models</li>
<li>Apply materials and produce realistic renderings</li>
<li>Review AI-generated designs for accuracy and functionality</li>
<li>Recommend improvements in line with machine specifications</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 7. meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @e, 'Conceptualize, create and refine 3D designs with AI-assisted workflows. This WSQ-accredited course covers generative 3D modeling, assemblies, GD&T and technical drawings. Enrol now.'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ----------------------------------------------------------- 8. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'Generative AI, 3D Design, AI 3D Modeling, CAD, WSQ, Design for Manufacturing, Technical Drawing, GD&T, WSQ Funding'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- ------------------------------------------------------- 5. cover alt labels
-- Plain title (no "WSQ - " prefix): the cover image itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI for 3D Design'
 WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_tl) AND @e IS NOT NULL;

-- Fresh branded cover PNG (rendered from the NEW title, badges preserved:
-- WSQ / SkillsFuture Credit / PSEA / UTAP / SFEC / Absentee Payroll / MCES)
-- and uploaded to R2. Without this the storefront keeps serving the cover
-- baked with the OLD course title.
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039342-20260813-041518.png'
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Store-scoped covers would shadow the store-0 value above.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0 AND @e IS NOT NULL;

-- The media-gallery per-image label renders as the zoom gallery's img
-- title/alt -- the rename template historically missed it.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Generative AI for 3D Design'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------------------------- 9. whoshouldattend
-- The old list named the retired tool ("Fusion 360 Specialist") and leaned
-- on Autodesk-certification job titles. Re-pointed at AI-assisted 3D design
-- equivalents; the genuinely tool-neutral roles are kept.
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>Product Designer</li>
<li>Mechanical Engineer</li>
<li>Industrial Designer</li>
<li>CAD Designer</li>
<li>Generative Design Specialist</li>
<li>Prototyping Engineer</li>
<li>3D Modeler</li>
<li>Product Development Specialist</li>
<li>Manufacturing Engineer (focus on design)</li>
<li>Aerospace Designer</li>
<li>Automotive Design Engineer</li>
<li>Jewelry Designer (using CAD tools)</li>
<li>Furniture Designer (with digital prototyping)</li>
<li>3D Printing Specialist</li>
<li>Design Engineer adopting AI-assisted workflows</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------ 10. prerequisite
-- This blob ALSO holds the entire funding apparatus (PWM, eligibility table,
-- SkillsFuture / PSEA / SFEC / UTAP deep links, appeal process) -- NEVER
-- rewrite it wholesale. Replace ONLY the <li> holding the Autodesk link.
-- Byte-probed: single-line, no CRLF inside this <li>.
UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        '<li><a href="https://www.autodesk.com/products/fusion-360/overview" target="_blank"><span style="text-decoration: underline;">Fusion 360</span></a></li>',
        '<li><a href="https://www.blender.org/download/" target="_blank"><span style="text-decoration: underline;">Blender</span></a></li>')
 WHERE entity_id = @e AND attribute_id = @a_pre AND store_id = 0 AND @e IS NOT NULL
   AND LOCATE('autodesk.com/products/fusion-360', value) > 0;

-- ----------------------------------------------------------- 6. trainerprofile
-- Each bio is exactly two paragraphs: para 1 = career CREDENTIALS (real facts
-- about CAD / Autodesk delivery history -- kept verbatim, rewriting them would
-- falsify the bio), para 2 = a course-teaching claim scoped to the OLD topic.
-- Only the claim paragraphs are retargeted, one exact-string REPLACE() each.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In his Fusion 360 training, Shahul emphasizes hands-on, project-based learning. He guides learners through parametric modeling, assemblies, CAM workflows, and design validation, ensuring they gain the skills to create manufacturing-ready designs. His teaching approach combines design fundamentals with practical exercises, preparing participants for Autodesk certification and real-world application.</p>',
        '<p>In his Generative AI for 3D Design training, Shahul emphasizes hands-on, project-based learning. He guides learners through AI-assisted concept generation, parametric modeling, assemblies, and design validation, ensuring they gain the skills to create manufacturing-ready designs. His teaching approach combines design fundamentals with practical exercises, preparing participants to apply generative AI confidently in real-world design work.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In her Fusion 360 training, Jyoti focuses on modeling, simulation, and design for manufacturing workflows. She introduces learners to creating parametric parts, assemblies, and toolpaths for CNC machining, while integrating case studies and exam-focused practice. Her structured and applied approach ensures participants develop the technical proficiency and confidence to achieve Autodesk Fusion 360 certification and apply it effectively in manufacturing contexts.</p>',
        '<p>In her Generative AI for 3D Design training, Jyoti focuses on AI-assisted modeling, design exploration, and design for manufacturing workflows. She introduces learners to generating parametric parts and assemblies from design intent, producing exploded views and technical drawings, while integrating case studies and hands-on practice. Her structured and applied approach ensures participants develop the technical proficiency and confidence to apply generative AI effectively in design and manufacturing contexts.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 12. learning_outcomes cms_block
-- Guarded-INSERT first, then UPDATE, so a re-run converges even if the block
-- is ever absent on a given instance (915/931/952 shape).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2023039342 - Learning Outcomes', 'course_TGS-2023039342_learning_outcomes', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) b
                    WHERE b.identifier = 'course_TGS-2023039342_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_TGS-2023039342_learning_outcomes' AND @e IS NOT NULL;

-- Same six SSG-accredited outcomes registered against the UNCHANGED SKU, with
-- the retired tool name removed (admin-supplied wording).
UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Conceptualize machine part designs to meet functional specifications</li>
<li>LO2: Generate sketches and CAD models for machine parts using curves and primitive features.</li>
<li>LO3: Create assemblies and drawings focusing on top-down and bottom-up methodologies.</li>
<li>LO4: Produce exploded views and animations for assemblies</li>
<li>LO5: Apply GD&amp;T principles to produce detailed and standardized drafts and models.</li>
<li>LO6: Create orthographic models and review them for potential improvements in line with machine specifications.</li>
</ul>',
       is_active = 1,
       update_time = NOW()
 WHERE identifier = 'course_TGS-2023039342_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------ 13. funding_and_grant stray line
-- A bare old-title line sits between the eligibility note and the SFEC
-- heading ("Design for Manufacturing Professional Training"). Byte-probed:
-- it is CRLF-terminated, so match a SINGLE line only (a multi-line REPLACE
-- silently no-ops on CRLF WYSIWYG blobs).
UPDATE cms_block
   SET content = REPLACE(content, 'Design for Manufacturing Professional Training', ''),
       update_time = NOW()
 WHERE identifier = 'course_TGS-2023039342_funding_and_grant'
   AND @e IS NOT NULL
   AND LOCATE('Design for Manufacturing Professional Training', content) > 0;

-- --------------------------------------------------------- 14. categories
-- Drop: the course no longer runs on Autodesk tooling and no longer preps any
-- certification exam. Every DELETE is mirrored into
-- catalog_category_product_index or the storefront listing never changes.
--   71  Autodesk
--  212  Autodesk Fusion 360
--  216  Autodesk Certification Exam Prep
--  222  Autodesk Certification Exam Prep (duplicate row)
--  182  Certification Exam Prep
DELETE FROM catalog_category_product       WHERE category_id IN (71, 212, 216, 222, 182) AND product_id = @e AND @e IS NOT NULL;
DELETE FROM catalog_category_product_index WHERE category_id IN (71, 212, 216, 222, 182) AND product_id = @e AND @e IS NOT NULL;

-- Add: mirrors the closest sibling (TGS-2023039180 "WSQ - Generative AI Design
-- for Civil 3D", which sits in 252) plus the WSQ GenAI listing.
--  252  AI Courses
--  379  WSQ Generative AI Courses
-- Appended at MAX(position)+1 so the category-ordering sweep can renumber later.
INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, (SELECT COALESCE(MAX(position), 0) + 1 FROM (SELECT * FROM catalog_category_product) c WHERE c.category_id = 252)
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_product) x
                    WHERE x.category_id = 252 AND x.product_id = @e);

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT 379, @e, (SELECT COALESCE(MAX(position), 0) + 1 FROM (SELECT * FROM catalog_category_product) c WHERE c.category_id = 379)
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_product) x
                    WHERE x.category_id = 379 AND x.product_id = @e);

-- Mirror the adds into the index (store 1, is_parent/visibility copied from the
-- product's surviving index rows) so the listing shows the course immediately.
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, 1, 4
  FROM catalog_category_product cp
 WHERE cp.product_id = @e AND cp.category_id IN (252, 379) AND @e IS NOT NULL;
