-- 959: Repurpose TGS-2023040473
--   "WSQ - Unity Certified User: Programmer Training"
--     -> "WSQ - AI for Unity 2D and 3D Game Development"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: pivot from the Unity Certified User
-- (Programmer) certification exam-prep track to AI-assisted Unity development
-- with Claude Code / Codex.
--
-- Sibling of 950/951/953/955/956 -- same shape, same certification-exam-prep
-- origin, same "AI for <domain>" destination.
--
-- SLUG / TWIN CHECK (checklist surface 3).
--   Live products whose url_key stems near the new title, all verified distinct:
--     C674  ai-vibe-coding-for-game-development
--     TGS-2025052674 wsq-ai-vibe-coding-for-game-development
--     C841  ai-vibe-coding-for-unity-game-development
--     TGS-2024042310 wsq-mastering-game-development-with-unity-and-c-programming-basics
--   None owns `ai-for-unity-2d-and-3d-game-development` or the `wsq-` prefixed
--   form (0 rows in catalog_product_entity_varchar.url_key and 0 in
--   core_url_rewrite.request_path). The `wsq-` prefix is kept anyway, matching
--   every sibling WSQ course, so the rewrites stay permanently apart from the
--   non-WSQ Unity/game-dev family.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description, description, trainerprofile
-- (the three teaching paragraphs that name the retired Unity certification exam),
-- image/small_image/thumbnail labels, media-gallery label, 301 for the old bare
-- slug, and category placement (add AI Courses 252; drop the three
-- certification-exam-prep listings 182/338/369), mirrored into
-- catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2023040473_learning_outcomes -- the supplied LO1-LO3 are
--     BYTE-IDENTICAL to the live block (they are the SSG-accredited outcomes
--     registered against the unchanged SKU; the new topics are delivered against
--     those same outcomes). Guarded-INSERT + UPDATE are still emitted per
--     surface 6b so the file converges on any site whose block is missing.
--   * course_TGS-2023040473_skills_framework -- MED-GDP-4003-1.1 Game Technical
--     Design under the Media Skills Framework. The accredited mapping follows the
--     unchanged SKU; the deliverable is still 2D/3D game development.
--   * course_TGS-2023040473_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; fee table and OpenCerts wording unaffected.
--     (Funding is tag-driven for TGS- since 891 -- the block is orphaned data.)
--   * whoshouldattend -- 15 roles (Game Developer, AR/VR Developer, Software
--     Engineer, Game Designer, Simulation Developer...). ONE is tool-specific:
--     "Unity Developer" -- and the course STILL teaches Unity, so it is not a
--     leak. Verified role by role; no edit.
--   * prerequisite -- holds the entire funding apparatus (PWM, eligibility table,
--     SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal Process). Its only tool hit
--     is the "Minimum Software/Hardware Requirement" <li> linking unity.com --
--     STILL the correct tool for this course (unlike 956, where the tool itself
--     was retired). No edit. Never rewrite this attribute wholesale.
--   * additional_note / venue -- laptop logistics, tool-agnostic.
--   * Badge tags (WSQ, MCES, SFEC, UTAP, PSEA, SkillsFuture Credit, Absentee
--     Payroll) -- funding entitlement follows the unchanged SKU.
--   * duration (32h) / sessions (4) -- unchanged by the repurpose.
--   * Categories 3/15/53/55/69/72/100/206/292/293/301/345/349/360/376 -- broad
--     parents and subject listings (All Courses, Software Training, Gaming &
--     Animation, Unity, WSQ Gaming Courses...) that still describe the NEW
--     content. Only the near-pure CERTIFICATION EXAM PREP listings are dropped.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--
-- NOTE on search redirects (checklist surface 7): every catalogsearch_query row
-- matching 'unity' has a NULL/empty redirect, and NO row's redirect points at the
-- old slug or the bare SKU -- verified before writing. There is nothing to
-- retarget, so no catalogsearch_query statement is included. Blindly filling them
-- would ALSO be wrong: the "unity game development" intent belongs to the live
-- non-WSQ twins C674/C841 and to TGS-2024042310, not to this page.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023040473' LIMIT 1);

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
-- "WSQ - " prefix retained: segment unchanged (WSQ tag, TGS- SKU), and the
-- storefront H1 wants it.
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI for Unity 2D and 3D Game Development'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- The live value baked in BOTH ("WSQ Unity Certified User Programmer Exam Prep |
-- Tertiary Courses Singapore"); the repurpose is the moment to fix that, per
-- migrations 933/953/956.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Unity 2D and 3D Game Development'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Build 2D and 3D games with Unity, C# and AI coding agents such as Claude Code or Codex. Covers AI-assisted scripting, gameplay prototyping, physics, animation, UI, testing and deployment.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'AI Unity game development, AI coding agents for Unity, Claude Code Unity, Codex Unity, 2D game development Unity, 3D game prototyping, C# scripting with AI, AI-assisted game programming, Unity gameplay mechanics, game testing and deployment, WSQ Unity course Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL (this product has store-0
-- AND store-1 url_path rows).
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-for-unity-2d-and-3d-game-development'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-for-unity-2d-and-3d-game-development.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- The old bare slug is held by this product's SYSTEM rewrite (id_path
-- 'product/1466', is_system = 1, store 1), so a plain INSERT IGNORE silently
-- no-ops against the unique key on (request_path, store_id). Convert that row in
-- place into a permanent redirect instead; the indexer then mints a fresh system
-- row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-for-unity-2d-and-3d-game-development.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-unity-certified-user-programmer-training.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2023040473-rp-959-', s.store_id),
       'wsq-unity-certified-user-programmer-training.html',
       'wsq-ai-for-unity-2d-and-3d-game-development.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Unity 2D and 3D Game Development'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI for Unity 2D and 3D Game Development'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------ 5. Learning Outcomes block
-- The supplied outcomes are BYTE-IDENTICAL to the live block content (LO1-LO3 as
-- accredited against the unchanged SKU). The UPDATE below is therefore a no-op
-- on SG today; it is emitted anyway so the file converges on any DB whose block
-- drifted, and the guarded INSERT covers surface 6b (a bare UPDATE silently
-- no-ops on a course whose block was never created).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2023040473 - Learning Outcomes',
       'course_TGS-2023040473_learning_outcomes',
       '', NOW(), NOW(), 1
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2023040473_learning_outcomes') x);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2023040473_learning_outcomes';

UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Analyze gaming trends and prepare technical briefs aligning with state-of-the-art technology.</li>
<li>LO2:&nbsp;Develop 2D game using Unity coding standards to meet the game''s technical requirements</li>
<li>LO3:&nbsp;Develop 3D game prototypes using Unity with programming teams to meet the game''s technical goals.</li>
</ul>',
       update_time = NOW()
 WHERE identifier = 'course_TGS-2023040473_learning_outcomes';

-- ------------------------------------ 6. Course Outline (description)
-- The old outline was 3 topics with ~30 Unity-certification subsections. The
-- supplied outline is THREE topic-level entries. Kept in the live field's own
-- shape: <h3 class="course-topic-h3"> headings, which is what this product uses
-- (it has NO <!-- LSN_DATA --> JSON comment, so there is no JSON to keep in sync
-- -- verified against the live value before writing).
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: Game Design and AI-Assisted Unity Development with Claude Code or Codex</h3>
<h3 class="course-topic-h3">Topic 2: Developing 2D Games with Unity and C#</h3>
<h3 class="course-topic-h3">Topic 3: Developing 3D Game Prototypes with Unity and AI Coding Agents</h3>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 7. About This Course (sdesc)
-- Full replace is correct here: this course's short_description has NO
-- <h2>Course Brochure</h2> tail (post-885 block model), so there is nothing to
-- splice. The one retired section it DID hold inline -- "Certification Exam at
-- Pearson Vue", including the deep link to the Unity certification registration
-- page and the Authorised Pearson Vue Testing Center claim -- is dropped
-- deliberately: the course no longer prepares learners for that exam, so
-- advertising it under the new title would misrepresent it.
UPDATE catalog_product_entity_text
   SET value = '<p>AI for Unity 2D and 3D Game Development equips learners with practical skills to design, build, test, and deploy interactive games using Unity, C#, and AI coding agents such as Claude Code or Codex. Participants will learn to use AI-assisted development workflows to generate and explain C# scripts, prototype gameplay mechanics, troubleshoot errors, refactor code, and accelerate repetitive development tasks.</p>
<p>Through hands-on projects, learners will explore Unity''s development environment and work with GameObjects, components, physics, collisions, prefabs, animations, user interfaces, audio, visual effects, and player controls. They will apply C# programming concepts, including variables, control statements, loops, functions, classes, and objects, to create both 2D and 3D game experiences.</p>
<p>The course also covers prompt and context techniques for guiding Claude Code or Codex, reviewing AI-generated code, testing game functionality, managing projects with version control, producing technical documentation, and building games for deployment. By the end of the course, learners will be able to use modern AI-powered development practices to create, evaluate, troubleshoot, and maintain Unity 2D and 3D game projects.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------------- 8. Trainer bios
-- Three bios, each two paragraphs: para 1 = career CREDENTIALS -- FACTS (real
-- Unity/C#/CAD/BIM expertise, NTU/SUSS/Curtin lectureships, ACLP certification).
-- Left untouched: rewriting a career history would falsify a bio. Para 2 in each
-- is a course-teaching claim scoped to the retired Unity Certified User
-- (Programmer) exam -- all three are retargeted at the AI-assisted Unity
-- workflow. Note Unity/C# themselves STAY (still the course's toolchain); only
-- the EXAM-PREP framing goes.
-- Single-line REPLACE() on the full paragraph string (a multi-line pattern
-- no-ops against the WYSIWYG blob's CRLF line endings).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In his Unity training, Wei Liang emphasizes practical, hands-on coding. He teaches learners how to build scripts in C#, manage object interactions, and implement game mechanics. His project-based approach ensures participants gain both the technical knowledge and applied skills to succeed in the Unity Certified User: Programmer exam.',
       'In this course, Wei Liang emphasizes practical, hands-on coding with AI coding agents. He teaches learners how to generate and review C# scripts with Claude Code or Codex, manage object interactions, and implement 2D and 3D game mechanics. His project-based approach ensures participants gain both the technical knowledge and the judgement to evaluate AI-generated code before shipping it.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In Unity Programmer training, Jyoti brings a design-oriented perspective, helping learners understand 3D modeling, texturing, and visualization workflows that integrate into Unity. She emphasizes design aesthetics and visual storytelling, ensuring participants not only code effectively but also create visually compelling interactive experiences.',
       'In this course, Jyoti brings a design-oriented perspective, helping learners understand 3D modeling, texturing, and visualization workflows that integrate into Unity. She emphasizes design aesthetics and visual storytelling, ensuring participants can direct AI coding agents to build interactive experiences that are visually compelling as well as technically sound.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In his Unity courses, Dr. Ang emphasizes structured programming and algorithmic thinking. He trains learners in applying C# for game logic, physics, and data management, while also exploring AI-driven features within Unity. His approach ensures participants develop both exam-ready coding proficiency and the ability to apply Unity in broader simulation and AI contexts.',
       'In this course, Dr. Ang emphasizes structured programming and algorithmic thinking. He trains learners in applying C# for game logic, physics, and data management, and in using prompt and context techniques to drive AI coding agents. His approach ensures participants develop both applied coding proficiency and the ability to apply Unity in broader simulation and AI contexts.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 9. Category placement
-- The repurpose changes the PURPOSE: the course no longer prepares learners for
-- the Unity Certified User (Programmer) exam, so drop:
--   369 "Unity Certification Exam Prep" -- pure Unity exam-prep listing; its only
--       other member is the non-WSQ C841, which keeps it.
--   338 "Others Certification Exam Prep" -- 29-member exam-prep listing.
--   182 "Certification Exam Prep" -- the parent of both. Dropped here (unlike
--       956, which kept it) because after 369+338 go there is no exam-prep
--       child left to justify the parent placement, and the course preps no
--       exam at all; the WSQ Statement of Achievement is covered by 345
--       "WSQ Certification Courses", which is KEPT.
-- and join 252 "AI Courses", the master listing every sibling AI course belongs
-- to (TGS-2024049780 / TGS-2024052076 / TGS-2024051414 / TGS-2023039344 /
-- TGS-2025056362 all sit in it).
-- KEPT: 206 "Unity" and 100 "Gaming & Animation" / 376 "WSQ Gaming Courses" --
-- the course still teaches Unity game development; 349/360/69 media & graphics
-- parents; 293/301 WSQ subject listings; 345 "WSQ Certification Courses" (the
-- SoA is unchanged). The accredited Skills Framework mapping
-- (MED-GDP-4003-1.1 Game Technical Design) is unchanged.
-- Both sides mirrored into catalog_category_product_index or the storefront
-- listings never change.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (182, 338, 369) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (182, 338, 369) AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, COALESCE((SELECT MAX(position) FROM (SELECT position FROM catalog_category_product WHERE category_id = 252) p), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 252);

INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 252, @e, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE cp.category_id = 252 AND cp.product_id = @e AND s.store_id > 0 AND @e IS NOT NULL;
