-- 958: Repurpose TGS-2022017519
--   "WSQ - Develop Augmented Reality (AR) Applications"
--     -> "WSQ - AI Vibe Coding for Augmented Reality (AR) Applications"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: the AR subject is RETAINED; the delivery
-- pivots from hand-coding in Unity to AI vibe coding (Claude Code / Codex) as the
-- primary development method. Joins the AI Vibe Coding family alongside the WSQ
-- siblings 1017/1134/1219/1272 and the non-WSQ twin C435.
--
-- Same shape as 946 / 947 / 951 / 955.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title
-- (currently bakes in BOTH the "WSQ" funding token and the brand suffix that
-- MMD_Seotitle adds at render time -- the exact 853 bug), meta_description,
-- meta_keyword, short_description, description (3 Unity topics -> the 3 supplied
-- topics, LSN_DATA JSON kept in sync with the visible markup), trainerprofile
-- (the single bio's teaching paragraph names the OLD delivery), image/small_image/
-- thumbnail labels, media-gallery label, a 301 for the old bare slug, and
-- category placement (add 252 "AI Courses"), mirrored into
-- catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2022017519_learning_outcomes -- the three supplied LOs are
--     BYTE-IDENTICAL in substance to the live accredited outcomes (only sentence
--     case differs). WSQ LOs are locked to the TSC standard; the AR subject did
--     not change, only the tool used to build the applications. Rewriting them
--     would desync the page from what SSG registered. Verified by reading the
--     block: LO1 storyboarding/UI principles, LO2 working principles + runtimes,
--     LO3 overlay/AR-vs-VR/adjustments -- all three match the supplied text.
--   * course_TGS-2022017519_skills_framework -- Augmented Reality Application
--     PRE-CTS-3001-1.1 under the Precision Skills Framework still describes the
--     course exactly; the outcomes are unchanged so the standard still holds.
--   * course_TGS-2022017519_certification / _funding_and_grant / _brochure --
--     keyed on the unchanged SKU; fee table and OpenCerts wording unaffected.
--   * whoshouldattend -- 15 roles, ALL AR/XR/3D-generic (AR Developer, UX/UI
--     Designer for AR, Spatial Computing Developer, ...). Checked every <li>:
--     none names Unity or any tool the repurpose drops, so every role still fits.
--   * prerequisite -- holds the entire funding apparatus (PWM, Funding
--     Eligibility table, SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal Process).
--     Probed for the old tool: no Unity/unity3d.com link in it, so there is
--     nothing to retarget and it is left completely alone.
--   * additional_note / assessment_methods / duration (16h) / sessions (2).
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--   * Categories 147 "Immersive Technologies", 397 "WSQ Immersive AR Courses",
--     69 "Media & Design", 72 "WSQ Media & Marketing Courses", 53 "Software
--     Training", 360 "Graphics Software", 301 "WSQ IT & Security Courses",
--     292/293/15/3 (WSQ + all-courses listings) -- the course is still an AR
--     course, so every one of these still describes it correctly.
--   * Category 206 "Unity" -- KEPT. Topic 2 still develops the AR application in
--     Unity (the AI assistant writes the Unity code), so the placement remains
--     accurate. This is the one judgement call that differs from 955, where the
--     dropped brand had genuinely left the syllabus.
--   * catalogsearch_query -- all 27 rows matching the old title / bare course
--     code have redirect IS NULL (nothing was ever pointed at the old slug), so
--     there is no redirect to retarget. Verified before writing; search redirects
--     are data and are applied live, never via a migration.
--
-- SLUG COLLISION CHECK (checklist step 3): the non-WSQ twin C435 "AI Vibe Coding
-- for Augmented Reality (AR)" already owns `ai-vibe-coding-for-augmented-reality-ar`.
-- The `wsq-` prefix avoids it; `wsq-ai-vibe-coding-for-augmented-reality-ar-applications`
-- had 0 rows in core_url_rewrite. The twin is otherwise untouched.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2022017519' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_tprof  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI Vibe Coding for Augmented Reality (AR) Applications'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time. The LIVE value was
-- "WSQ Develop Augmented Reality (AR) Applications - Create the Future Today |
-- Tertiary Courses Singapore" -- it baked in BOTH, yielding a doubled title.
-- Fixed here to the bare course title (matches sibling 1219 "... Course").
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding for Augmented Reality (AR) Applications Course'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Design and build immersive Augmented Reality (AR) applications using AI vibe coding tools such as Claude Code or Codex. Covers storyboarding, spatial tracking, plane detection, anchors, animation and deployment. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'AI vibe coding, Augmented Reality, AR application development, Claude Code, Codex, Unity AR, AR storyboarding, spatial tracking, plane detection, anchors, 3D objects, AR user interface design, AI-assisted coding, WSQ AR course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope (store 0 AND store 1 both hold a row here) so
-- the Catalog URL Rewrites indexer regenerates it; a surviving store-scoped row
-- shadows the new URL.
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-vibe-coding-for-augmented-reality-ar-applications'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-vibe-coding-for-augmented-reality-ar-applications.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- The old bare slug is held by this product's SYSTEM rewrite (id_path
-- 'product/<e>', is_system = 1), so a plain INSERT IGNORE silently no-ops
-- against the unique key on (request_path, store_id). Convert that row in place
-- into a permanent redirect; the indexer then mints a fresh system row for the
-- NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-vibe-coding-for-augmented-reality-ar-applications.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-develop-augmented-reality-ar-applications.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2022017519-rp-958-', s.store_id),
       'wsq-develop-augmented-reality-ar-applications.html',
       'wsq-ai-vibe-coding-for-augmented-reality-ar-applications.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix
-- (CourseImage/Model/Cover.php::cleanTitle).
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding for Augmented Reality (AR) Applications'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI Vibe Coding for Augmented Reality (AR) Applications'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. The three live Unity topics (each with three
-- <em> subsections) are replaced by the three supplied topics -- topic-level
-- only, so subsecs are empty. Three topics -- matches LO1-LO3.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: AR User Interface Design and Storyboarding with AI Vibe Coding","subsecs":[]},{"title":"Topic 2: AR Application Development with Unity, Claude Code or Codex","subsecs":[]},{"title":"Topic 3: Testing, Reviewing and Optimizing AR Application","subsecs":[]}] -->
<p><strong>Topic 1: AR User Interface Design and Storyboarding with AI Vibe Coding</strong></p>
<p><strong>Topic 2: AR Application Development with Unity, Claude Code or Codex</strong></p>
<p><strong>Topic 3: Testing, Reviewing and Optimizing AR Application</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Full replace with the supplied prose. The live value is ONLY intro copy (two
-- marketing paragraphs) -- it carries NO <h2>Course Brochure</h2> tail, because
-- this course's sections were already extracted to cms/block rows (verified:
-- _brochure, _certification, _skills_framework, _funding_and_grant and
-- _learning_outcomes all exist). So a full replace loses nothing, and the
-- splice-on-LOCATE form from the checklist would have silently no-op'd here.
UPDATE catalog_product_entity_text
   SET value = '<p>Learn to design and develop immersive Augmented Reality (AR) applications using AI vibe coding tools such as Claude Code or Codex. You will use natural-language prompts to generate code, create prototypes, troubleshoot errors, and accelerate AR development while maintaining control over application quality and functionality.</p>
<p>Explore essential AR concepts, including 3D objects, spatial tracking, plane detection, anchors, camera interaction, lighting, animation, and touch-based controls. Through hands-on activities, you will build interactive AR experiences that blend digital content with real-world environments.</p>
<p>You will also learn to refine AI-generated code, optimize application performance, test AR experiences on supported devices, manage project versions, and prepare applications for deployment. By the end of the course, you will be able to use AI-assisted workflows to create engaging, practical, and user-friendly AR applications for education, marketing, entertainment, training, and other real-world use cases.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------- 7. Learning Outcomes block
-- INTENTIONALLY NOT REWRITTEN. The supplied LOs match the live accredited block
-- outcome-for-outcome (LO1 storyboarding + UI principles, LO2 working principles
-- + AR runtimes, LO3 overlay / AR-vs-VR / adjustments). The AR competency did
-- not change -- only the tool used to build the applications -- so the block and
-- the PRE-CTS-3001-1.1 skills-framework block both stay as registered with SSG.
-- (Checklist surface 6b does not apply: the block EXISTS here, block_id 1766.)

-- -------------------------------------------------------- 8. Trainer bio
-- One bio (Jyoti Chopra), two paragraphs. Para 1 = career CREDENTIALS (Autodesk
-- Certified Professional, the CAD/architectural project history) -- FACTS, left
-- untouched. Para 2 closes with a course-teaching claim that frames the course as
-- a transition "from traditional CAD tools to immersive digital environments";
-- retargeted to the AI vibe coding delivery. Single-line REPLACE() on the full
-- sentence string (a multi-line pattern no-ops against the WYSIWYG blob's CRLF
-- line endings -- see feedback_multiline_replace_fails_on_crlf_blobs).
--
-- NOTE (verified on the RENDERED page after applying): this edit is currently
-- DORMANT. trainers.phtml prefers `courses_trainers.description` (the central
-- Trainer Profile page -- row 14 for Jyoti Chopra) over the per-course blob, so
-- the storefront shows her central bio, not this text. That central bio is
-- generic AutoCAD/design copy naming NO course, and it is SHARED by 56 courses,
-- so it is deliberately left untouched -- retargeting it for this one repurpose
-- would falsify her bio on all the others. The blob is still corrected here
-- because it is the fallback whenever the central row is absent or status = 0,
-- and it must not keep naming the old delivery.
-- See feedback_trainer_bio_renders_from_courses_trainers_not_trainerprofile.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'Her experience in simulation, visualization, and 3D modeling directly complements the development of Augmented Reality (AR) applications, enabling learners to transition from traditional CAD tools to immersive digital environments. By combining technical depth, hands-on industry experience, and a learner-focused approach, Jyoti empowers participants to develop innovative AR solutions that enhance design, interactivity, and user experience.',
       'Her experience in simulation, visualization, and 3D modeling directly complements the development of Augmented Reality (AR) applications, enabling learners to move from traditional design tools to AI-assisted development of immersive digital environments. In this course she guides participants in using AI vibe coding tools such as Claude Code or Codex to storyboard, generate and refine AR application code, then test and optimize the result on real devices. By combining technical depth, hands-on industry experience, and a learner-focused approach, Jyoti empowers participants to develop innovative AR solutions that enhance design, interactivity, and user experience.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 9. Category placement
-- ADD ONLY -- nothing is dropped. Unlike 955 (which dropped a brand that left
-- the syllabus), this repurpose KEEPS the AR subject and keeps Unity in Topic 2,
-- so all 12 existing placements still describe the course. The one gap: the
-- course is now an AI course and was missing from 252 "AI Courses", the master
-- listing that 98 of its TGS- siblings already belong to.
-- Inserted at MAX(position)+1 so the category-ordering sweep can renumber later,
-- and mirrored into catalog_category_product_index or the storefront listing
-- never shows it (see feedback_category_swap_needs_index_mirror).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 252), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 252);

INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 252, @e, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE cp.category_id = 252 AND cp.product_id = @e AND s.store_id > 0 AND @e IS NOT NULL;
