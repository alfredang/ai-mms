-- 945: Rename TGS-2023037545
--        "WSQ - Native iOS Apps Development with C++ and Vibe Coding"
--      -> "WSQ - AI Vibe Coding for iOS Mobile Apps Development"
--      + guarded-INSERT the missing Learning Outcomes cms/block.
--
-- Course code (SKU) is UNCHANGED - TGS-2023037545 stays, so every funding /
-- SkillsFuture / SFEC / SFC / PSEA / UTAP deep link keyed on the course code
-- remains correct, and every per-course cms/block (brochure, certification,
-- skills_framework, funding_and_grant) keeps resolving.
--
-- This is a RETITLE, not a repurpose. The subject is unchanged: the course
-- still teaches native iOS application development in C++ with AI-assisted
-- vibe coding. Only the emphasis in the TITLE moves from the language (C++) to
-- the method (AI Vibe Coding), aligning it with the AI Vibe Coding Series it
-- already sits in (category 414). Because the subject is unchanged, category
-- placements, learning outcomes and the funding apparatus are all preserved -
-- see "NOT rewritten" below.
--
-- Pre-authoring EAV sweep (feedback_tgs_course_rename_checklist mandates this
-- BEFORE writing the migration, not after): dumped every
-- catalog_product_entity_varchar + _text row for entity 1134 joined to
-- eav_attribute, then grepped for the old title AND its distinctive tech words
-- (C++, iOS, Xcode, Swift, Apple, Native). Hits classified below.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels -> new title
--   2. url_key -> wsq-ai-vibe-coding-for-ios-mobile-apps-development ;
--      url_path DELETEd at every scope (store 0 AND store 1 both held a row)
--      so the Catalog URL Rewrites indexer regenerates it
--   3. 301 the old slug at the new one, and repoint the 42 legacy alias
--      rewrites that 301 INTO the old slug so inbound links take one hop
--   4. meta_keyword refreshed to lead with the new course name
--   5. whoshouldattend -> iOS-app-development job roles (the old list was a
--      generic C++ list naming neither iOS nor vibe coding - surface 10)
--   6. trainerprofile -> the three bios' SECOND paragraphs are course-teaching
--      claims scoped to the OLD course title ("In "Programming Methodologies in
--      C++," ..."), which is not even this course's current title - retargeted
--      at iOS delivery. FIRST paragraphs are career-history CREDENTIALS and are
--      left byte-identical (surface 6 / the 937 two-paragraph split).
--   7. media gallery per-image label
--   8. Learning Outcomes cms/block - CREATED (surface 6b: it does not exist)
--
-- SLUG COLLISION CHECK (checklist step 3 - and this course is the exact trap
-- the checklist describes). SG has a live non-WSQ twin, C879 (entity 879,
-- status=1 ENABLED), whose name is ALREADY "AI Vibe Coding for iOS Mobile Apps
-- Development" - byte-identical to this course's new title - and which ALREADY
-- OWNS the unprefixed slug `ai-vibe-coding-for-ios-mobile-apps-development`.
-- The WSQ course therefore MUST take the `wsq-`-prefixed stem. Verified free:
-- zero core_url_rewrite rows on `wsq-ai-vibe-coding-for-ios-mobile-apps-%`, so
-- there is no is_system=0 squatter for INSERT IGNORE to silently no-op against
-- (cf. 647). The `wsq-` prefix also keeps the two pages' rewrite sets
-- permanently apart, exactly as the `casl-` prefix did in 930/937.
--
-- SIBLING-FAMILY / TWIN ANCHORING (checklist surface 11): every LIKE in this
-- file is anchored on the FULL old filename
-- `wsq-native-ios-apps-development-with-c-and-vibe-coding.html`, never on a
-- bare stem like `%ios%` or `%vibe-coding%`. A loose stem would sweep up the
-- twin C879's rows, the `ai-vibe-coding-series` category paths and the ~12
-- other AI-Vibe-Coding courses, silently hijacking live unrelated pages.
--
-- meta_title deliberately omits BOTH the leading "WSQ" token and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time, prepending the funding prefix for any SG TGS- SKU and appending
-- the brand postfix (Block/Html/Head.php). The OLD row had BOTH baked in
-- ("WSQ Native iOS Apps Development with C++ and Vibe Coding | Tertiary Courses
-- Singapore") - the exact duplicated-title bug 853 existed to clean up. The
-- rename is the moment to fix it (cf. 933), so it is replaced here.
--
-- NOT rewritten (each verified against the DB before authoring):
--   - `description` (Course Outline): the live value ALREADY matches the five
--     requested topics byte-for-byte (probed t1..t5 - all present, same
--     h3.course-topic-h3 shape). No statement emitted; editing it would be a
--     no-op diff.
--   - `short_description` (About This Course): the live value ALREADY matches
--     all four requested paragraphs (probed p1..p4 - all present) and carries
--     NO `<h2>Course Brochure</h2>` tail (its sections were extracted to
--     per-course cms/block rows in the 2026-07-21 strip), so there is nothing
--     to splice and nothing to replace. Confirmed rather than assumed - a
--     splice guarded on LOCATE('<h2>Course Brochure</h2>') would have silently
--     no-opped here.
--   - `prerequisite`: swept for C++ / iOS / Apple - ZERO hits (checklist
--     surface 11 verified, not assumed). It holds the entire funding apparatus
--     (PWM, eligibility table, SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal
--     Process) and is never rewritten wholesale.
--   - cms_block _brochure / _certification / _skills_framework /
--     _funding_and_grant: keyed on the unchanged SKU; each probed for C++/iOS -
--     all topic-neutral, zero old-title mentions. The skills_framework block
--     cites "Software Design-3 ICT-DES-3005-1.1 TSC", which is the accredited
--     TSC registered against the unchanged SKU and stays.
--   - `image` / `small_image` / `thumbnail`: hold the uploaded JPG's filesystem
--     path (/l/e/learn-c_-fundamentals-...jpg). These are PATHS, not display
--     text - the storefront renders the R2 `course_image_url` cover - so
--     renaming them would 404 the file. Classified as hits-but-not-leaks (937).
--   - Category placements: all 11 stay. This is a retitle, not a brand-drop or
--     subject change - the course is still iOS (77), Mobile Apps (50),
--     C/C++/C# (80), Programming (31), AI Courses (252), AI Vibe Coding Series
--     (414) and WSQ Programming & Vibe Coding (425). Nothing is falsified by
--     the new title, so no catalog_category_product / _index edits (contrast
--     934/936, where dropping "Pearson VUE" did falsify two placements).
--   - `additional_note` / `venue` / `googlemap` / `trainers` / duration /
--     sessions / price: unchanged by a rename.
--   - catalogsearch_query: swept on the full old filename AND the bare course
--     code - ZERO rows. The statement below is a guarded no-op kept for the
--     case where prod holds rows the local backup lacks (search redirects are
--     DATA - see feedback_search_redirects_always_apply_live).
--
-- The cover PNG and brochure PDF bake the old title - regenerate both on prod
-- after this applies (MMD_CourseImage strips the "WSQ - " prefix at render).
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops); rewrite/search statements are
-- additionally guarded on the SG store. Idempotent - re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037545' LIMIT 1);
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_keyword');
SET @a_wsa  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'whoshouldattend');
SET @a_tp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'trainerprofile');

-- ---------------------------------------------------------------- 1. varchars
-- "WSQ - " prefix retained: the SKU is unchanged so the segment is unchanged,
-- and the storefront H1 wants the prefix (checklist step 1).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'WSQ - AI Vibe Coding for iOS Mobile Apps Development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No "WSQ" token and no brand suffix - MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'AI Vibe Coding for iOS Mobile Apps Development Training' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'AI Vibe Coding for iOS Mobile Apps Development training in Singapore. Design, build, test and publish native iOS apps with C++ and AI-assisted vibe coding, from architecture to App Store release. Up to 70% WSQ funding subsidy.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- `wsq-` prefix is REQUIRED here: live twin C879 already owns the unprefixed
-- slug `ai-vibe-coding-for-ios-mobile-apps-development` (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'wsq-ai-vibe-coding-for-ios-mobile-apps-development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "WSQ - " prefix) - they are alt text
-- on the course cover, which itself renders without the prefix
-- (CourseImage/Model/Cover.php::cleanTitle strips WSQ/CASL/IBF).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'AI Vibe Coding for iOS Mobile Apps Development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'AI Vibe Coding for iOS Mobile Apps Development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'AI Vibe Coding for iOS Mobile Apps Development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------- 2. url_path at all scopes
-- This course held url_path rows at BOTH store 0 and store 1; delete both so
-- the Catalog URL Rewrites indexer regenerates from the new url_key.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Repoint the existing rewrite row (the system row still holds the old
-- request_path until reindex) and force it permanent + manual; create the row
-- where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'wsq-ai-vibe-coding-for-ios-mobile-apps-development.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'wsq-native-ios-apps-development-with-c-and-vibe-coding.html'
    AND store_id IN (0, 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('wsq-native-ios-apps-development-with-c-and-vibe-coding.html'), '-', s.store_id),
       'wsq-native-ios-apps-development-with-c-and-vibe-coding.html',
       'wsq-ai-vibe-coding-for-ios-mobile-apps-development.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'wsq-native-ios-apps-development-with-c-and-vibe-coding.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old slug - 42 rows across three
-- historical titles this course has carried (wsq-programming-methodologies-in-c,
-- wsq-programming-methodologies-in-c-plus-plus,
-- wsq-learn-c-fundamentals-with-ai-assisted-tools-and-vibe-coding) plus two
-- unrelated legacy Jetson aliases, in bare AND category-prefixed variants.
-- Repointed straight at the new bare slug so inbound links take ONE hop, not a
-- chain. Anchored on the FULL old filename (checklist surface 11) so the twin
-- C879 and the ai-vibe-coding-series category paths are never swept in. System
-- category rows regenerate + auto-301 on reindex.
UPDATE core_url_rewrite
  SET target_path = 'wsq-ai-vibe-coding-for-ios-mobile-apps-development.html'
  WHERE @sg = 1 AND @e IS NOT NULL
    AND is_system = 0
    AND target_path LIKE '%wsq-native-ios-apps-development-with-c-and-vibe-coding.html'
    AND request_path <> 'wsq-native-ios-apps-development-with-c-and-vibe-coding.html';

-- ------------------------------------------------------------ 4. meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'AI Vibe Coding for iOS Mobile Apps Development, iOS app development course Singapore, WSQ iOS development training, AI assisted coding iOS, vibe coding mobile apps, native iOS apps C++, App Store publishing, iOS testing debugging simulators, WSQ funded IT course, mobile app development training' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- -------------------------------------------------------- 5. whoshouldattend
-- Checklist surface 10. The old list was a GENERIC C++ role list that named
-- neither iOS nor vibe coding ("Game Developer (using C++)", "Embedded Systems
-- Developer", "High-Performance Computing Specialist", "Financial Quantitative
-- Developer", "3D Graphics Programmer (using C++)", "Firmware Engineer.") -
-- inherited from the course's earlier "Programming Methodologies in C++"
-- incarnation and wrong for an iOS apps course under either title. Repointed at
-- iOS-app-development roles. C++ is retained where it is genuinely the skill
-- (the course does teach C++), per the "classify, don't blanket-rewrite" rule.
-- Full replace to a constant - naturally idempotent.
UPDATE catalog_product_entity_text
  SET value = '<ul>\n<li>iOS App Developer</li>\n<li>Mobile Application Developer</li>\n<li>Software Engineer</li>\n<li>C++ Developer</li>\n<li>Full-Stack Developer (extending to mobile)</li>\n<li>Application Developer</li>\n<li>Systems Programmer</li>\n<li>Cross-Platform App Developer</li>\n<li>UI/UX Developer (building iOS interfaces)</li>\n<li>QA / Test Engineer (mobile app testing)</li>\n<li>Mobile Product Manager</li>\n<li>Technical Lead (mobile projects)</li>\n<li>IT Specialist (wanting to learn iOS development)</li>\n<li>Freelance App Developer</li>\n<li>Tech Start-up Founder</li>\n</ul>'
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_wsa AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_wsa;

-- --------------------------------------------------------- 6. trainerprofile
-- Checklist surface 6 / the 937 two-paragraph split. Each of the three bios is
-- exactly two paragraphs:
--   para 1 = career-history CREDENTIALS (Standard Chartered / HP / TikTok, SMU
--            and NTU degrees, game-development background, 500+ programmes,
--            "C++, Python and Java" expertise) - REAL FACTS, preserved
--            byte-identically. Rewriting them would falsify a bio.
--   para 2 = a course-teaching claim opening 'In "Programming Methodologies in
--            C++," ...' - scoped to a title this course no longer even carries
--            (it predates the current name), so it is retargeted at iOS
--            delivery here.
-- Targeted REPLACE() on the exact full paragraph strings only, so the
-- &ldquo;/&rdquo;/&nbsp; entities and the data-start/data-end attributes
-- elsewhere in the blob survive untouched. Each REPLACE is naturally idempotent
-- (the search string is absent after the first run).
-- NOTE: single-line REPLACE strings - a multi-line REPLACE() silently no-ops on
-- these CRLF WYSIWYG blobs (feedback_multiline_replace_fails_on_crlf_blobs).
UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    'In &ldquo;Programming Methodologies in C++,&rdquo; Siew Yee provides learners with an in-depth understanding of software design principles, algorithmic logic, and structured programming. His sessions emphasize clean code practices, object-oriented programming, and system optimization techniques. By integrating real-world software engineering concepts, he helps participants build a strong foundation in C++ programming and apply it effectively to modern applications.',
    'In &ldquo;AI Vibe Coding for iOS Mobile Apps Development,&rdquo; Siew Yee provides learners with an in-depth understanding of iOS software design principles, application architecture, and structured programming. His sessions emphasize clean code practices, object-oriented programming, and AI-assisted development workflows. By integrating real-world software engineering concepts, he helps participants build a strong foundation in iOS app development and apply it effectively to modern mobile applications.')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    'In &ldquo;Programming Methodologies in C++,&rdquo; Fritz guides learners through the principles of modular programming and data abstraction using C++. His sessions focus on developing efficient, maintainable, and scalable code while reinforcing strong algorithmic problem-solving skills. Through project-based exercises, he enables participants to gain practical experience and confidence in applying C++ methodologies to diverse software solutions.',
    'In &ldquo;AI Vibe Coding for iOS Mobile Apps Development,&rdquo; Fritz guides learners through the principles of modular application design and data abstraction using C++ on iOS. His sessions focus on developing efficient, maintainable, and scalable apps while reinforcing strong algorithmic problem-solving skills. Through project-based exercises, he enables participants to gain practical experience and confidence in applying AI-assisted coding methodologies to iOS app development.')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    'In &ldquo;Programming Methodologies in C++,&rdquo; Dr. Ang combines theoretical depth with practical insight to help learners understand the core concepts of structured and object-oriented programming. His sessions focus on algorithmic design, memory management, and performance optimization. By linking fundamental programming techniques to modern software applications, he equips learners with the ability to write efficient, reliable, and production-grade C++ programs.',
    'In &ldquo;AI Vibe Coding for iOS Mobile Apps Development,&rdquo; Dr. Ang combines theoretical depth with practical insight to help learners understand the core concepts of iOS application design and object-oriented programming. His sessions focus on app architecture, memory management, and performance optimization. By linking fundamental programming techniques to AI-assisted development workflows, he equips learners with the ability to build efficient, reliable, and production-grade iOS applications.')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_tp;

-- ------------------------------------------------ 7. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI Vibe Coding for iOS Mobile Apps Development'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------------- 8. Learning Outcomes cms/block
-- Checklist surface 6b: this course has NO
-- `course_TGS-2023037545_learning_outcomes` block (verified COUNT(*) = 0) and
-- its short_description carries no "<h2>Learning Outcomes</h2>" heading for the
-- regex fallback, so the What You'll Learn card is currently suppressed
-- entirely by the `!== ''` guard in
-- app/design/frontend/ultimo/default/template/catalog/product/view.phtml.
-- A bare UPDATE would silently no-op, so guarded-INSERT first (940 shape).
--
-- The five outcomes are the SSG-accredited outcomes registered against the
-- UNCHANGED SKU. They legitimately still name C++ methodologies: the new topics
-- are delivered AGAINST these same outcomes, and the course does still teach
-- C++. Per the 937 precedent this is NOT a leak to "fix" - it must not drift
-- from the course registry, and it must not fail the post-apply rendered-page
-- grep for "C++".
-- IDEMPOTENCY WARNING - do NOT "simplify" this back to the
-- `INSERT ... ON DUPLICATE KEY UPDATE` shape used by migration 940.
-- `cms_block` in this schema has NO unique index on `identifier` (SHOW INDEX
-- returns PRIMARY on block_id only), so ON DUPLICATE KEY NEVER FIRES and every
-- re-apply inserts ANOTHER row. Proven here: a forced re-apply of this file
-- produced blocks 3204 AND 3205 with the same identifier, and the storefront
-- then picks one arbitrarily. The DB already carries such duplicates from this
-- pattern (course_cancellation_policy x7, course_certification x6); 940 only
-- stayed single-row because it happened to be applied exactly once.
-- Guarded INSERT (NOT EXISTS) + unconditional UPDATE converges on every run.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT
    'Course TGS-2023037545 - Learning Outcomes',
    'course_TGS-2023037545_learning_outcomes',
    '<p>By end of the course, learners should be able to:</p>\n<ul>\n<li>LO1: Determine basic software components using C++ methodologies to meet functional specifications.</li>\n<li>LO2: Apply C++ methodologies and tools for software creation.</li>\n<li>LO3: Select essential C++ controls and features to meet software design requirements.</li>\n<li>LO4: Examine the interoperability and functionality of C++ software components.</li>\n<li>LO5: Generate C++ design documentation aligned with user specifications.</li>\n</ul>',
    NOW(), NOW(), 1
FROM dual
WHERE NOT EXISTS (
    SELECT 1 FROM (SELECT block_id FROM cms_block
                   WHERE identifier = 'course_TGS-2023037545_learning_outcomes') x
);

-- Converge content/title/state on every subsequent run (and heal any row that
-- pre-dated this migration).
UPDATE cms_block
   SET title       = 'Course TGS-2023037545 - Learning Outcomes',
       content     = '<p>By end of the course, learners should be able to:</p>\n<ul>\n<li>LO1: Determine basic software components using C++ methodologies to meet functional specifications.</li>\n<li>LO2: Apply C++ methodologies and tools for software creation.</li>\n<li>LO3: Select essential C++ controls and features to meet software design requirements.</li>\n<li>LO4: Examine the interoperability and functionality of C++ software components.</li>\n<li>LO5: Generate C++ design documentation aligned with user specifications.</li>\n</ul>',
       is_active   = 1,
       update_time = NOW()
 WHERE identifier = 'course_TGS-2023037545_learning_outcomes';

-- Map to store 0 (all stores) - matches every other course_* section block.
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
WHERE identifier = 'course_TGS-2023037545_learning_outcomes';

-- ---------------------------------------------- 9. search-term redirects
-- Swept local on the full old filename AND the bare course code: ZERO rows.
-- Kept as a guarded no-op in case prod holds rows the local backup lacks.
-- REPLACE on the full SG-domain URL - partner-safe (never matches a partner's
-- own slug) and anchored on the full filename so the twin C879's rows and the
-- other AI-Vibe-Coding courses' rows can never be hijacked.
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/wsq-native-ios-apps-development-with-c-and-vibe-coding.html', 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-ios-mobile-apps-development.html')
  WHERE redirect LIKE '%wsq-native-ios-apps-development-with-c-and-vibe-coding.html%';
