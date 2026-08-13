-- 959: Repurpose TGS-2024042310
--   "WSQ - Mastering Game Development with Unity and C# Programming Basics"
--     -> "WSQ - AI for Game Development"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: the course keeps Unity + C# as the
-- delivery stack but pivots to AI-assisted development -- Claude Code and Codex
-- as coding agents for scripting, prototyping, debugging, refactoring, testing,
-- version control and documentation.
--
-- Sibling of 950 (TGS-2024052076), 951 (TGS-2024051414) and 955 (TGS-2023039344).
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description (About narrative replaced with
-- the supplied copy; the "Certification Exam at Pearson Vue" section drops -- the
-- course no longer preps the Unity certification), description (5 Unity/C# topics
-- -> the 5 supplied AI-assisted topics), trainerprofile (all four bios'
-- course-teaching paragraphs name the old course), image/small_image/thumbnail
-- labels, media-gallery label, a 301 for the old bare slug, and category placement
-- (add 252 AI Courses, mirrored into catalog_category_product_index).
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2024042310_learning_outcomes -- the live block is BYTE-IDENTICAL
--     to the five LOs the admin supplied (LO1..LO5). They are the SSG-accredited
--     outcomes registered against the unchanged SKU, so the new AI-assisted topics
--     are delivered AGAINST those same outcomes. The What You'll Learn card will
--     legitimately keep naming C#/Unity -- that is the accredited standard, not a
--     leak. Do not "fix" it.
--   * course_TGS-2024042310_skills_framework -- Software Design ICT-DES-3005-1.1
--     still describes the course (AI-assisted or not, it is software design).
--   * course_TGS-2024042310_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; the fee table and OpenCerts wording are unaffected.
--   * whoshouldattend -- 15 game-development / software roles (Unity Game
--     Developer, Game Designer, Technical Artist, ...). The course still teaches
--     Unity game development, so every role still fits.
--   * prerequisite -- its only old-tech hit is the unity.com/download software
--     link under "Minimum Software/Hardware Requirement", and Unity IS still the
--     tool taught. This attribute also holds the whole funding apparatus (PWM,
--     eligibility table, SkillsFuture/PSEA/SFEC/UTAP deep links) -- never rewrite
--     it wholesale.
--   * additional_note / assessment_methods -- logistics and assessment mode.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--   * catalogsearch_query -- no row redirects at the old slug (the only match is
--     the bare course code TGS-2024042310, whose redirect is NULL). Nothing to
--     retarget; search redirects are applied live, never via a migration.
--   * Categories 3, 15, 31 (Programming), 53, 69, 72, 80 (C/C++/C#), 100 (Gaming
--     & Animation), 206 (Unity), 292, 293, 301, 360, 376 (WSQ Gaming), 425 (WSQ
--     Programming & Vibe Coding) -- the course still teaches Unity/C# game
--     development, so every existing placement still describes it correctly.
--     This is an ADD-only category change.
--
-- New slug checked for collisions: wsq-ai-for-game-development is unused
-- (the neighbours are ai-vibe-coding-for-game-development / C674,
-- wsq-ai-vibe-coding-for-game-development / TGS-2025052674 and
-- ai-vibe-coding-for-unity-game-development / C841 -- all distinct).
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024042310' LIMIT 1);

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

-- ---------------------------------------------------------------------------
-- 1. name -- keep the "WSQ - " prefix (the storefront H1 wants it).
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'WSQ - AI for Game Development'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_name AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path.
--    url_path is DELETED at every scope so the Catalog URL Rewrites indexer
--    regenerates it; a surviving store-scoped row would shadow the new URL.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_urlk, 0, @e, 'wsq-ai-for-game-development'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlk AND store_id <> 0 AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. meta_title -- PLAIN title. No leading "WSQ", no "| Tertiary Courses ..."
--    suffix: MMD_Seotitle prepends the funding token and appends the brand
--    postfix at render time. The live value baked in BOTH.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @e, 'AI for Game Development'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. meta_description -- varchar attribute. Feeds <meta name=description>,
--    og:description, twitter:description AND the JSON-LD description.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @e,
       'Build Unity games with AI coding agents. Use Claude Code and Codex to generate C# scripts, prototype 3D gameplay, debug and refactor code, run tests, manage version control and produce documentation. WSQ funded course with hands-on projects.'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. meta_keyword -- text attribute.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @e,
       'AI for game development, AI game development course, Claude Code Unity, Codex game development, AI assisted coding Unity, Unity C# AI agent, AI game programming Singapore, WSQ AI game development, AI coding agent game design, vibe coding Unity'
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. short_description -- the "About This Course" narrative.
--    The live value has NO "<h2>Course Brochure</h2>" tail (this course's
--    sections were already extracted into cms/block rows), so a full replace is
--    correct here -- a LOCATE()-guarded splice would silently no-op.
--    The supplied copy is used verbatim, in the admin's paragraph order.
--    The "Certification Exam at Pearson Vue" section is dropped: the course no
--    longer preps the Unity certification. (view.phtml strips that heading at
--    render time anyway, so this only cleans the stored value.)
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @e,
       CONCAT(
         '<p>Master the essentials of game development with a focus on Unity and C# programming. This course introduces learners to key C# methodologies for software design and development in Unity. Participants will explore core concepts like scripting fundamentals, object-oriented programming, and the integration of controls and functionalities required to meet game design specifications. By the end of the course, learners will be able to identify and apply essential C# methods to create functional Unity game software.</p>',
         '<p>Learn to use Claude Code and Codex as AI coding agents to develop interactive games with Unity and C#. You will apply AI-assisted workflows to generate scripts, create gameplay mechanics, debug errors, refactor code, and improve game performance.</p>',
         '<p>Through hands-on projects, you will design and build Unity games using C# classes and objects while working with scenes, game objects, components, physics, user interfaces, animations, and player controls. You will also use Claude Code and Codex to understand existing codebases, automate repetitive development tasks, manage version control, conduct testing, and produce technical documentation. By the end of the course, you will be equipped to create, evaluate, troubleshoot, and maintain Unity game projects using modern AI-powered development practices.</p>'
       )
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 7. description -- the Course Outline. Five supplied topics replace the five
--    Unity/C#-only topics. Markup follows the live shape
--    (<h3 class="course-topic-h3"> + <ul>), which is what the theme renders.
--    The live value carries no LSN_DATA JSON comment, so none is added.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e,
       CONCAT(
         '<h3 class="course-topic-h3">Topic 1: Unity and C# Programming with Claude Code and Codex</h3>',
         '<ul>',
         '<li>Installing and setting up Unity and Visual Studio Code</li>',
         '<li>Exploring the Unity interface, scenes, game objects and components</li>',
         '<li>Getting started with C# scripting in Unity</li>',
         '<li>Setting up Claude Code and Codex as AI coding agents</li>',
         '<li>Prompting an AI agent to generate and explain C# scripts</li>',
         '</ul>',
         '<h3 class="course-topic-h3">Topic 2: Prototyping 3D Games with AI-Assisted Coding</h3>',
         '<ul>',
         '<li>Setting up a simple 3D game scene</li>',
         '<li>Transform component, public and private variables</li>',
         '<li>Keyboard and player input handling</li>',
         '<li>Rigidbody physics, colliders and trigger collisions</li>',
         '<li>Prefabs, instantiating and destroying game objects</li>',
         '<li>Using AI agents to prototype gameplay mechanics rapidly</li>',
         '</ul>',
         '<h3 class="course-topic-h3">Topic 3: Enhancing Unity Gameplay, UI, Animation and Audio</h3>',
         '<ul>',
         '<li>Importing assets for sprites, audio and animation</li>',
         '<li>Creating animations in Unity</li>',
         '<li>Building the user interface (UI)</li>',
         '<li>Effects (FX) and post processing</li>',
         '<li>Game audio</li>',
         '<li>AI-assisted refactoring and game performance optimisation</li>',
         '</ul>',
         '<h3 class="course-topic-h3">Topic 4: Developing Complete Unity Games with C# Classes and Objects</h3>',
         '<ul>',
         '<li>Applying object oriented programming with C# classes and objects</li>',
         '<li>Control statements, loops, functions and coroutines</li>',
         '<li>Accessing components with the GetComponent function</li>',
         '<li>Using AI agents to understand an existing game codebase</li>',
         '<li>Automating repetitive development tasks with Claude Code and Codex</li>',
         '</ul>',
         '<h3 class="course-topic-h3">Topic 5: Game Testing, Deployment, Documentation and Version Control</h3>',
         '<ul>',
         '<li>Debugging and error handling with AI coding agents</li>',
         '<li>Conducting game testing with AI assistance</li>',
         '<li>Managing version control for a Unity project</li>',
         '<li>Producing technical and design documentation</li>',
         '<li>Deployment: building and publishing your game</li>',
         '</ul>'
       )
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 8. trainerprofile -- retarget ONLY the course-teaching paragraphs. Each bio's
--    career-history paragraph is left byte-identical: those are real
--    credentials (Fritz's Unity/C# engineering history, Jyoti's Autodesk
--    teaching record, Dr Ang's PhD) and rewriting them would falsify a bio.
--    Targeted REPLACE() per paragraph so the &ndash; / &ldquo; entities and the
--    data-start/data-end attributes survive untouched.
-- ---------------------------------------------------------------------------

-- 8a. Tan Wei Liang -- teaching paragraph 2.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this WSQ course, Wei Liang applies his expertise to guide learners through game development fundamentals using Unity and C# programming basics. His teaching emphasizes hands-on coding, structured exercises, and project-based learning, ensuring participants gain both the technical skills and creative confidence to develop interactive games.',
       'In this WSQ course, Wei Liang applies his expertise to guide learners through AI-assisted game development using Claude Code and Codex alongside Unity and C#. His teaching emphasizes hands-on coding with AI agents, structured exercises, and project-based learning, ensuring participants gain both the technical skills and creative confidence to develop interactive games.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND @e IS NOT NULL;

-- 8b. Lim Fang Cheng Fritz -- teaching paragraph.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;C# Programming Methodologies for Unity Game Development,&rdquo; Fritz teaches participants how to apply object-oriented programming principles in Unity for efficient and modular game development. His sessions cover scripting fundamentals, debugging, and performance optimization, emphasizing industry best practices. Through practical examples and guided projects, he helps learners build the technical and problem-solving skills required to design and deploy professional-grade Unity games.',
       'In &ldquo;AI for Game Development,&rdquo; Fritz teaches participants how to apply object-oriented programming principles in Unity while using Claude Code and Codex to accelerate efficient and modular game development. His sessions cover AI-assisted scripting, debugging, refactoring, and performance optimization, emphasizing industry best practices. Through practical examples and guided projects, he helps learners build the technical and problem-solving skills required to design and deploy professional-grade Unity games.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND @e IS NOT NULL;

-- 8c. Jyoti Chopra -- teaching paragraph.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;C# Programming Methodologies for Unity Game Development,&rdquo; Jyoti introduces learners to the creative aspects of Unity development through 3D modeling, environment setup, and design visualization. Her sessions integrate design theory with Unity scripting fundamentals, helping learners understand how to translate artistic concepts into dynamic, interactive spaces. With her strong foundation in visualization and software design, she provides learners with a balanced approach to both the technical and creative dimensions of game development.',
       'In &ldquo;AI for Game Development,&rdquo; Jyoti introduces learners to the creative aspects of Unity development through 3D modeling, environment setup, and design visualization. Her sessions integrate design theory with AI-assisted Unity scripting, helping learners understand how to translate artistic concepts into dynamic, interactive spaces. With her strong foundation in visualization and software design, she provides learners with a balanced approach to both the technical and creative dimensions of game development.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND @e IS NOT NULL;

-- 8d. Dr. Alfred Ang -- teaching sentence inside paragraph 2.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'For this WSQ course, he equips learners with a solid foundation in C# programming, Unity development, and interactive content creation.',
       'For this WSQ course, he equips learners with a solid foundation in AI-assisted development with Claude Code and Codex, C# programming in Unity, and interactive content creation.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 9. Cover alt text -- image_label / small_image_label / thumbnail_label and the
--    media-gallery per-image label. Plain title, no "WSQ - " prefix: the cover
--    renderer strips the prefix (Cover.php::cleanTitle).
--    NOTE: image/small_image/thumbnail themselves are filesystem PATHS and are
--    intentionally left alone -- renaming them 404s the file.
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ilab, 0, @e, 'AI for Game Development' WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_slab, 0, @e, 'AI for Game Development' WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_tlab, 0, @e, 'AI for Game Development' WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND store_id <> 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI for Game Development'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 10. Category placement -- ADD ONLY.
--     The course is absent from "AI Courses" (252), the master AI listing that
--     every sibling AI repurpose (950 / 951 / 955) belongs to. Every existing
--     placement still describes the course (it still teaches Unity/C# game
--     development), so nothing is dropped.
--     Resolved BY NAME, never by hardcoded id. Appended at MAX(position)+1 so
--     the category-ordering sweep can renumber later.
--     Mirrored into catalog_category_product_index or the storefront listing
--     never changes.
-- ---------------------------------------------------------------------------
SET @cat_ai := (SELECT v.entity_id
                  FROM catalog_category_entity_varchar v
                  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3
                 WHERE a.attribute_code = 'name' AND v.store_id = 0 AND v.value = 'AI Courses'
                 LIMIT 1);

SET @pos_ai := (SELECT IFNULL(MAX(position), 0) + 1 FROM catalog_category_product WHERE category_id = @cat_ai);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat_ai, @e, @pos_ai
WHERE @e IS NOT NULL AND @cat_ai IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat_ai, @e, @pos_ai, 1, s.store_id, 4
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL AND @cat_ai IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 11. 301 for the old bare slug.
--     The URL Rewrites indexer auto-301s the ~20 category paths from its rewrite
--     history; the bare slug needs an explicit row. Any is_system = 0 squatter on
--     the old path is removed first -- INSERT IGNORE silently no-ops against a
--     stale row.
-- ---------------------------------------------------------------------------
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-mastering-game-development-with-unity-and-c-programming-basics.html'
   AND is_system = 0
   AND @e IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       'TGS-2024042310-rp',
       'wsq-mastering-game-development-with-unity-and-c-programming-basics.html',
       'wsq-ai-for-game-development.html',
       0,
       'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;
