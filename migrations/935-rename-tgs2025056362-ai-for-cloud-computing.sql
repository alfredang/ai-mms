-- 935: Rename TGS-2025056362
--        "WSQ - Pearson Vue Certified IT Specialist - Cloud Computing"
--      -> "WSQ - AI for Cloud Computing"
--      + new Course Outline (description), About This Course (short_description),
--        Learning Outcomes block, and a category re-placement off the retired
--        Pearson VUE exam-prep listings onto the AI listings.
--
-- Course code (SKU) is UNCHANGED - TGS-2025056362 stays, so every SkillsFuture /
-- SFEC / SFC / PSEA deep link keyed on the course code remains correct, and the
-- funding_and_grant / certification / skills_framework / brochure cms/block rows
-- (all keyed on the SKU) keep working untouched.
--
-- Follows the 851/853/855 TGS- rename playbook via the 929/930/931/933 precedent
-- shapes and the feedback_tgs_course_rename_checklist 9-surface list.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels -> new title
--   2. url_key -> ai-for-cloud-computing ; url_path deleted at every scope so
--      the Catalog URL Rewrites indexer regenerates it
--   3. 301 the old slug at the new one (repoint the pre-reindex system row +
--      INSERT IGNORE fallback, both scopes), and repoint every legacy alias
--      rewrite that 301s INTO the old WSQ slug straight at the new bare slug so
--      inbound links take one hop, not a chain
--   4. description -> the new 3-topic Course Outline (replaces the LU/T outline,
--      LSN_DATA comment included so the admin outline editor stays in sync)
--   5. short_description -> the new 4-paragraph About This Course (FULL replace)
--   6. learning_outcomes cms_block -> the three new LOs
--   7. meta_keyword refreshed to lead with the new course name
--   8. media gallery per-image label
--   9. category re-placement (see below)
--  10. search-term redirects: exactly THREE live SG rows point at this course
--
-- CATEGORY RE-PLACEMENT (surface 9) - the non-obvious part of this rename.
-- The course currently sits in cat 402 "IT Specialists Exam Prep" and cat 435
-- "Pearson VUE Certification Exam Prep" alongside 19 other Pearson VUE titles.
-- After the rename it no longer preps anyone for a Pearson VUE exam, so leaving
-- it there would put an "AI for Cloud Computing" tile in the middle of a
-- Pearson-VUE-branded listing. Both placements are DROPPED. It also was NOT in
-- cat 252 "AI Courses" - the master AI listing that every sibling AI course
-- (Agentic AI for HR / Generative AI for SEO / AI for eCommerce ...) belongs to
-- - so cat 252 is ADDED. Retained as-is: cat 3 All Courses, 15 WSQ and IBF,
-- 55 Infocomm Technology, 87 Cloud Computing, 182 Certification Exam Prep,
-- 292 WSQ Funded, 301 WSQ IT & Security, 345 WSQ Certification, 426 WSQ Cloud
-- Computing & Networking - all still accurate for an AI-for-cloud WSQ course.
-- New position in cat 252 = MAX(position)+1 so the category-ordering sweep can
-- renumber it later without a collision here.
--
-- meta_title deliberately omits BOTH the leading "WSQ" and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time, prepending the funding prefix for any SG TGS- SKU and appending
-- the brand postfix (Block/Html/Head.php). The row being replaced here had BOTH
-- baked in ("WSQ Pearson Vue ... Course | Tertiary Courses Singapore"), which is
-- exactly the duplicated-title bug 853 existed to clean up - fixed by this file.
--
-- NOT rewritten (verified against SG prod before authoring):
--   - cms_block course_TGS-2025056362_certification: generic Certificate of
--     Achievement + OpenCerts copy, no Pearson VUE mention
--   - cms_block course_TGS-2025056362_skills_framework: ICT-DIT-3020-1.1 Cloud
--     Computing - still the accredited competency standard, unchanged
--   - cms_block _funding_and_grant + _brochure: keyed on the unchanged SKU,
--     no old-title text
--   - trainerprofile (5269 chars): byte-probed with LOCATE - the bios mention
--     "certification-ready skills" generically but NEVER the old course title,
--     so there is nothing to replace (checklist surface 6 verified, then skipped)
--   - whoshouldattend (20 cloud job roles) + prerequisite + additional_note:
--     no old-title text, all still accurate for the renamed course
--   - the C1814 NON-WSQ TWIN "Pearson Vue Certified IT Specialist Cloud
--     Computing" is a SEPARATE LIVE PRODUCT and is deliberately left completely
--     alone - it still legitimately preps for the Pearson VUE exam and keeps
--     both its slug and its cat 402/435 placements.
--
-- SEARCH REDIRECTS - only 3 of the 16 rows matching "pearson-vue...cloud" point
-- at THIS course; the other 13 point at the C1814 twin's own slug
-- (pearson-vue-certified-it-specialist-cloud-computing.html, no wsq- prefix) and
-- MUST NOT be touched. The 3 retargeted here are matched on the full
-- SG-domain WSQ-slug URL (partner-safe, and the leading '/wsq-' in the pattern
-- is what excludes the twin's rows):
--   "Pearson Vue Certified IT Specialist Cloud Computing", "TGS-2025056362",
--   "Pearson vue certificate IT specialist"
-- The first and third are Pearson-VUE-intent queries. They are pointed at the
-- LIVE C1814 twin (which still teaches exactly that) rather than at the renamed
-- AI page - retargeting by topic, not blindly to the new slug, per the
-- repurpose rule in feedback_tgs_course_rename_checklist. Only the bare course
-- code TGS-2025056362 follows the course to its new slug.
-- Search redirects are DATA - also applied live on prod per
-- feedback_search_redirects_always_apply_live; this file is the rebuild copy.
--
-- The cover PNG and brochure PDF bake the old title - regenerate both on prod
-- after this applies (MMD_CourseImage strips the "WSQ - " prefix at render).
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops); rewrite/search/category
-- statements are additionally guarded on the SG store. Idempotent - re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e    := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025056362' LIMIT 1);
SET @sg   := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_keyword');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'description');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'WSQ - AI for Cloud Computing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No "WSQ" prefix and no brand suffix - MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'AI for Cloud Computing Course' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'AI for Cloud Computing training in Singapore. Use AI to set up cloud environments, deploy applications, run installation and database tests, troubleshoot issues and manage security, governance and cost. Enjoy up to 70% WSQ funding subsidy' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'ai-for-cloud-computing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "WSQ - " prefix) - they are alt text on
-- the course cover, which itself renders without the prefix (Cover.php
-- cleanTitle strips WSQ/CASL/IBF).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'AI for Cloud Computing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'AI for Cloud Computing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'AI for Cloud Computing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------- 2. url_path at all scopes
-- (prod carries a store-1 row as well as store 0 - both go, indexer regenerates)
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Repoint the existing rewrite row (the system row still holds the old
-- request_path until reindex) and force it permanent + manual; create the row
-- where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'ai-for-cloud-computing.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'wsq-pearson-vue-certified-it-specialist-cloud-computing.html'
    AND store_id IN (0, 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('wsq-pearson-vue-certified-it-specialist-cloud-computing.html'), '-', s.store_id),
       'wsq-pearson-vue-certified-it-specialist-cloud-computing.html',
       'ai-for-cloud-computing.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'wsq-pearson-vue-certified-it-specialist-cloud-computing.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old WSQ slug (bare AND
-- category-prefixed targets) - repoint straight at the new bare slug so inbound
-- links take one hop, not a chain. System category rows regenerate + auto-301 on
-- reindex. The LIKE pattern is anchored on the 'wsq-' prefix so the C1814 twin's
-- own alias rows (same stem, no wsq-) are NOT caught.
UPDATE core_url_rewrite
  SET target_path = 'ai-for-cloud-computing.html'
  WHERE @sg = 1 AND @e IS NOT NULL
    AND is_system = 0
    AND target_path LIKE '%wsq-pearson-vue-certified-it-specialist-cloud-computing.html'
    AND request_path <> 'wsq-pearson-vue-certified-it-specialist-cloud-computing.html';

-- --------------------------------------------- 4. description (Course Outline)
-- New 3-topic outline as provided. The LSN_DATA JSON comment is what the admin
-- Edit Course outline editor parses, so it is rewritten in lockstep with the
-- visible markup - leaving the old LU1-LU3 JSON behind would make the editor
-- show the retired Pearson VUE outline.
UPDATE catalog_product_entity_text
  SET value = CONCAT(
    '<!-- LSN_DATA: [{"title":"Topic 1: AI-Assisted Cloud Environment Setup and Service Integration","subsecs":[],"links":[]},',
    '{"title":"Topic 2: AI-Powered Cloud Deployment, Installation and Database Testing","subsecs":[],"links":[]},',
    '{"title":"Topic 3: AI-Assisted Cloud Troubleshooting, Security and Quality Management","subsecs":[],"links":[]}] -->\n',
    '<h3 class="course-topic-h3">Topic 1: AI-Assisted Cloud Environment Setup and Service Integration</h3>\n',
    '<h3 class="course-topic-h3">Topic 2: AI-Powered Cloud Deployment, Installation and Database Testing</h3>\n',
    '<h3 class="course-topic-h3">Topic 3: AI-Assisted Cloud Troubleshooting, Security and Quality Management</h3>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_desc AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_desc;

-- ---------------------------------- 5. short_description (About This Course)
-- FULL replace: this course's sections were already extracted to cms/block rows
-- (no "<h2>Course Brochure</h2>" tail in short_description - verified on prod),
-- so the splice form would silently no-op here. Plain UPDATE to a constant -
-- naturally idempotent.
UPDATE catalog_product_entity_text
  SET value = CONCAT(
    '<p>AI for Cloud Computing equips participants with the practical skills to plan, implement, monitor, and maintain cloud environments using artificial intelligence. Learners will explore cloud service and deployment models, virtualization, networking, storage, databases, application deployment, security, governance, and cost management.</p>\n',
    '<p>Through hands-on activities, participants will use AI tools to interpret business and technical requirements, recommend suitable cloud architectures, generate configuration guidance, automate routine tasks, and produce technical documentation. They will learn to set up cloud environments, deploy applications, configure storage and databases, integrate services, and apply access controls aligned with organizational requirements.</p>\n',
    '<p>The course also covers AI-assisted cloud operations. Participants will use AI to analyze logs and performance metrics, troubleshoot deployment and connectivity issues, identify security or configuration risks, and recommend remediation actions. Emphasis is placed on validating AI-generated recommendations, protecting sensitive information, maintaining human oversight, and balancing performance, scalability, security, reliability, and cost.</p>\n',
    '<p>By the end of the course, learners will be able to combine foundational cloud knowledge with AI-assisted workflows to develop, test, optimize, and manage secure and reliable cloud solutions. The course is suitable for learners with basic IT knowledge who want to build practical capabilities in modern cloud computing.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_sd AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_sd;

-- ------------------------------------------- 6. Learning Outcomes cms_block
-- The block EXISTS on prod (block_id 1972) and its three LOs already match the
-- requested LO1-LO3 verbatim. Re-stated here anyway so a rebuilt-from-scratch DB
-- converges to the same content, using the guarded-INSERT-then-UPDATE shape
-- (915) because a bare UPDATE silently no-ops where the block is absent.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2025056362 - Learning Outcomes', 'course_TGS-2025056362_learning_outcomes', '', NOW(), NOW(), 1
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2025056362_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2025056362_learning_outcomes';

UPDATE cms_block
  SET content = CONCAT(
    '<p>By end of the course, learners should be able to:</p>\n<ul>\n',
    '<li>LO1: Set up cloud environments aligned with user needs using relevant integration techniques and testing methods.</li>\n',
    '<li>LO2: Run installation and database tests to identify and troubleshoot potential cloud deployment issues.</li>\n',
    '<li>LO3: Resolve implementation problems using diagnostic tools while adhering to security and quality standards.</li>\n</ul>'),
      update_time = NOW()
  WHERE identifier = 'course_TGS-2025056362_learning_outcomes';

-- ------------------------------------------------------------ 7. meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'AI for cloud computing, AI cloud computing course Singapore, WSQ cloud computing course, AI-assisted cloud deployment, cloud environment setup, cloud troubleshooting with AI, cloud security and governance, AI cloud operations, cloud database testing, WSQ funded cloud course' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- ------------------------------------------------ 8. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI for Cloud Computing'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------- 9. category re-placement
-- Drop the two Pearson-VUE-branded exam-prep listings (see header). DELETE is
-- naturally idempotent.
DELETE FROM catalog_category_product
WHERE @sg = 1 AND @e IS NOT NULL AND product_id = @e AND category_id IN (402, 435);

DELETE FROM catalog_category_product_index
WHERE @sg = 1 AND @e IS NOT NULL AND product_id = @e AND category_id IN (402, 435);

-- Add the master AI listing (cat 252) that every sibling AI course belongs to.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 252), 0) + 1
FROM dual
WHERE @sg = 1 AND @e IS NOT NULL
  AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 252);

-- ------------------------------------------- 10. search-term redirects (3 rows)
-- Only rows on the WSQ slug - the '/wsq-' anchor excludes the C1814 twin's 13
-- rows. The bare course code follows the course to its new slug.
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/ai-for-cloud-computing.html'
  WHERE query_text = 'TGS-2025056362'
    AND redirect LIKE '%/wsq-pearson-vue-certified-it-specialist-cloud-computing.html%';

-- The two Pearson-VUE-intent queries go to the LIVE non-WSQ twin (C1814), which
-- still teaches exactly what they ask for - retarget by TOPIC, not to the
-- renamed page.
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/pearson-vue-certified-it-specialist-cloud-computing.html'
  WHERE query_text IN ('Pearson Vue Certified IT Specialist Cloud Computing', 'Pearson vue certificate IT specialist')
    AND redirect LIKE '%/wsq-pearson-vue-certified-it-specialist-cloud-computing.html%';
