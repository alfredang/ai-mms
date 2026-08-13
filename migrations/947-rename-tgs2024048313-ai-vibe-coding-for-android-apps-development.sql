-- 947: Rename TGS-2024048313
--        "WSQ - Native Android Apps Development with Java and Vibe Coding"
--      -> "WSQ - AI Vibe Coding for Android Apps Development"
--
-- Course code (SKU) is UNCHANGED - TGS-2024048313 stays, so every SkillsFuture /
-- SFEC / SFC / PSEA / UTAP deep link keyed on the course code remains correct.
-- Follows the TGS- rename playbook (851-855 -> 929/930/933/937 precedent shapes).
--
-- This is a RETITLE, not a repurpose. The subject matter is unchanged: the
-- course still teaches native Android app development with Java plus AI vibe
-- coding, against the same SSG-accredited Java LOs. Only the emphasis in the
-- TITLE moves to the AI Vibe Coding framing. Consequently the topic-bearing
-- surfaces (description / short_description / whoshouldattend / prerequisite /
-- categories / skills framework) are all still accurate and are NOT rewritten -
-- see the pre-authoring EAV sweep results noted per section below.
--
-- ---------------------------------------------------------------------------
-- TWIN COLLISION - the load-bearing decision in this file.
-- ---------------------------------------------------------------------------
-- SG already has a LIVE, ENABLED non-WSQ twin: product 139 / SKU C139, named
-- EXACTLY "AI Vibe Coding for Android Apps Development" (S$700, 2-day AI Vibe
-- Coding Series course, cats 3/50/55/78/252/414), owning the bare slug
--   ai-vibe-coding-for-android-apps-development
-- Per the user's instruction ("This change is only for WSQ courses, do not
-- change anything on the non-WSQ courses") C139 is left completely untouched:
-- not renamed, not disabled, not re-slugged, no rewrites repointed.
--
-- The WSQ course therefore keeps BOTH the "WSQ - " name prefix and the "wsq-"
-- slug prefix, which is the standard SG pattern for a WSQ/non-WSQ twin pair and
-- keeps the two pages' rewrites permanently apart:
--   name     WSQ - AI Vibe Coding for Android Apps Development
--   url_key  wsq-ai-vibe-coding-for-android-apps-development
-- Verified free: no product owns that url_key (the only LIKE
-- '%ai-vibe-coding-for-android%' hit is C139's bare slug).
--
-- The twin is also a live third party to the sweep predicates below (rename
-- checklist "non-WSQ TWIN" section): every core_url_rewrite / catalogsearch_query
-- predicate here is anchored on the FULL old filename
-- 'wsq-native-android-apps-development-with-java-and-vibe-coding.html', never on
-- a bare '%android%' stem, so C139's rows can never be swept up.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels -> new title
--   2. url_key -> wsq-ai-vibe-coding-for-android-apps-development ; url_path
--      deleted at every scope so the Catalog URL Rewrites indexer regenerates it
--   3. 301 the old bare slug at the new one (repoint the pre-reindex system row
--      + INSERT IGNORE fallback, both scopes), and repoint every legacy alias
--      rewrite that 301s INTO the old slug (the ~25 java-programming-methodologies,
--      deep-learning-with-r and deep-learning-with-keras-658 rows, incl. all
--      their category-prefixed variants) straight at the new bare slug so
--      inbound links take one hop, not a chain
--   4. meta_keyword refreshed to lead with the new course name
--   5. media gallery per-image label
--
-- meta_title deliberately omits BOTH the leading "WSQ" token and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time, prepending the funding prefix for any SG TGS- SKU and appending
-- the brand postfix (Block/Html/Head.php). Baking either in yields the
-- duplicated title tag that 853 had to clean up. The old row had BOTH baked in
-- ("WSQ Native Android Apps Development with Java and Vibe Coding | Tertiary
-- Courses Singapore") - fixed here (checklist surface 2, cf. 933).
--
-- NOT rewritten (each verified against the DB before authoring):
--   - description (Course Outline): the live 5 topics are BYTE-IDENTICAL to the
--     5 topics supplied in the request (Topic 1 Introduction to Native Android
--     Application Development and Vibe Coding ... Topic 5 Application
--     Documentation, Performance Optimization, Multi-threading, and Google Play
--     Store Deployment). Nothing to change.
--   - short_description (About This Course): the live 4 paragraphs are
--     BYTE-IDENTICAL to the 4 paragraphs supplied in the request. The row holds
--     ONLY the intro copy (no "<h2>Course Brochure</h2>" tail - its sections were
--     extracted to per-course cms/block rows in the 2026-07-21 strip), so there
--     is nothing to splice either. Nothing to change.
--   - Learning Outcomes: the supplied LO1-LO5 are the SSG-accredited Java
--     outcomes registered against the UNCHANGED SKU. NOTE there is no
--     course_TGS-2024048313_learning_outcomes cms_block on this course (it
--     predates the 885-891 extraction and its short_description never carried a
--     Learning Outcomes heading), so the What You'll Learn card renders from
--     whatever the product view supplies - creating a block here would be a NEW
--     content surface, out of scope for a retitle, and the outcomes are
--     unchanged by it either way. The LOs legitimately still say "Java" - that
--     is the accredited wording, not a leak; do not "fix" it (checklist
--     surface 6b + the 937 learning-outcomes note).
--   - whoshouldattend: 20 job roles, swept - all framework-neutral software
--     roles (Java Developer, Software Engineer, Application Developer,
--     Backend Developer, ...). "Java Developer" is still exactly right for a
--     course that still teaches Java. Not a leak (checklist surface 10).
--   - prerequisite: swept for 'java' / 'android' - ZERO hits. Its Minimum
--     Software/Hardware Requirement links only Visual Studio Code. It holds the
--     whole funding apparatus (PWM, eligibility table, SkillsFuture / PSEA /
--     SFEC / UTAP deep links, Appeal Process) and is never rewritten wholesale
--     (checklist surface 11).
--   - trainerprofile: one bio (Angel Koh), two paragraphs. Para 1 is career-
--     history CREDENTIALS (15 years maritime/defence, C#, Java, Octave, ArcGIS,
--     data fusion) - rewriting it would falsify the bio. Para 2 is a
--     course-teaching claim about Java programming methodologies - still
--     accurate, the course still teaches Java OOP and modular design. No
--     old-TITLE text in either paragraph. Nothing to change (checklist
--     surface 6; cf. the 929 "verify, then skip" precedent).
--   - cms_block _brochure / _certification / _skills_framework /
--     _funding_and_grant: all keyed on the unchanged SKU. Checked each row -
--     the brochure block is a bare SKU-keyed PDF link with no title text, the
--     certification + funding blocks are topic-neutral boilerplate, and the
--     skills_framework block names the accredited TSC ("Software Design-4
--     ICT-DES-4005-1.1") which is unchanged by a retitle. No old-title mention
--     in any of them (checklist surface 8).
--   - image / small_image / thumbnail: these hold the uploaded JPG's filesystem
--     path (/w/s/wsq---java-programming-methodologies-.jpg) and WILL match an
--     old-title/old-tech grep. They are PATHS, not display text - the storefront
--     renders the R2 course_image_url cover - so renaming them would 404 the
--     file. Classified and skipped (937 precedent).
--   - Category placements: unchanged. The retitle drops no brand and changes no
--     subject, so all 13 placements stay accurate - incl. 75 Java (still Java),
--     78 Android (still Android), 414 AI Vibe Coding Series and 425 WSQ
--     Programming & Vibe Coding (already correctly placed for the AI Vibe Coding
--     framing), plus the WSQ funding cats 15/292/293/301.
--   - Funding badge tags (WSQ, SkillsFuture Credit, PSEA, SFEC, UTAP-adjacent
--     MCES, Absentee Payroll): keyed on the product, unaffected by a retitle.
--   - additional_note / venue / googlemap / duration (32h) / sessions (4) /
--     price: unchanged by a rename.
--   - catalogsearch_query: swept for the old slug AND the bare course code -
--     ZERO rows locally. The statement below is a guarded no-op kept for the
--     case where prod has rows the local backup lacks (search redirects are
--     DATA - see feedback_search_redirects_always_apply_live). It is anchored on
--     the FULL old filename so C139's own rows can never be hijacked.
--
-- The cover PNG bakes the old title - regenerate it on prod after this applies
-- (MMD_CourseImage strips the "WSQ - " prefix at render). The brochure PDF is
-- SKU-keyed and its link survives, but its cover page also bakes the old title.
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops); rewrite/search statements are
-- additionally guarded on the SG store. Idempotent - re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024048313' LIMIT 1);
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

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'WSQ - AI Vibe Coding for Android Apps Development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No "WSQ" token and no brand suffix - MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'AI Vibe Coding for Android Apps Development Training' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'AI Vibe Coding for Android Apps Development training in Singapore. Use AI coding assistants with Java and Android Studio to design, build, test and publish native Android apps to the Google Play Store. Enjoy up to 70% WSQ funding subsidy.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- "wsq-" prefixed: keeps this page's rewrites permanently apart from the live
-- non-WSQ twin C139, which owns the bare slug (see TWIN COLLISION in header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'wsq-ai-vibe-coding-for-android-apps-development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "WSQ - " prefix) - they are alt text on
-- the course cover, which itself renders without the prefix (Cover.php
-- cleanTitle strips WSQ/CASL/IBF).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'AI Vibe Coding for Android Apps Development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'AI Vibe Coding for Android Apps Development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'AI Vibe Coding for Android Apps Development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------- 2. url_path at all scopes
-- Local has rows at BOTH store 0 and store 1; delete every scope so the URL
-- Rewrites indexer regenerates from the new url_key.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Repoint the existing rewrite row (the system row still holds the old
-- request_path until reindex) and force it permanent + manual; create the row
-- where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'wsq-ai-vibe-coding-for-android-apps-development.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'wsq-native-android-apps-development-with-java-and-vibe-coding.html'
    AND store_id IN (0, 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('wsq-native-android-apps-development-with-java-and-vibe-coding.html'), '-', s.store_id),
       'wsq-native-android-apps-development-with-java-and-vibe-coding.html',
       'wsq-ai-vibe-coding-for-android-apps-development.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'wsq-native-android-apps-development-with-java-and-vibe-coding.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old slug - bare AND category-prefixed
-- targets (java-programming-methodologies.html, deep-learning-with-r.html,
-- deep-learning-with-keras-658.html; ~25 rows). Repoint straight at the new bare
-- slug so inbound links take one hop, not a chain. System category rows
-- regenerate + auto-301 on reindex.
--
-- Anchored on the FULL old filename (checklist surface 11 / sibling-family
-- over-match): a '%android%' stem would sweep up the live non-WSQ twin C139's
-- own alias rows. This predicate cannot match them - C139's slug carries no
-- "wsq-native-android-apps-development-with-java-and-vibe-coding" substring.
UPDATE core_url_rewrite
  SET target_path = 'wsq-ai-vibe-coding-for-android-apps-development.html'
  WHERE @sg = 1 AND @e IS NOT NULL
    AND is_system = 0
    AND target_path LIKE '%wsq-native-android-apps-development-with-java-and-vibe-coding.html'
    AND request_path <> 'wsq-native-android-apps-development-with-java-and-vibe-coding.html';

-- ------------------------------------------------------------ 4. meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'AI Vibe Coding for Android Apps Development, WSQ Android development course, AI assisted Android app development, vibe coding Android Singapore, native Android apps Java, Android Studio training, Google Play Store deployment course, WSQ mobile app development, Java Android programming, AI coding assistant mobile apps' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- ------------------------------------------------ 5. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI Vibe Coding for Android Apps Development'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------- 6. search-term redirects
-- Swept local: ZERO rows point at the old slug or the bare course code. Kept as
-- a guarded no-op in case prod holds rows the local backup lacks. REPLACE on the
-- full SG-domain URL with the FULL old filename - so the live non-WSQ twin
-- C139's redirect rows (which point at its own bare slug) can never be hijacked.
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/wsq-native-android-apps-development-with-java-and-vibe-coding.html', 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-android-apps-development.html')
  WHERE redirect LIKE '%wsq-native-android-apps-development-with-java-and-vibe-coding.html%';
