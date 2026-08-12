-- 937: Rename TGS-2026064472
--        "CASL - Hands-On Web App Development with Javascript"
--      -> "CASL - AI Vibe Coding for REST API"
--      + new Course Outline (description) and About This Course (short_description)
--
-- Course code (SKU) is UNCHANGED - TGS-2026064472 stays, so every funding /
-- SkillsFuture / SFEC / SFC / PSEA deep link keyed on the course code remains
-- correct. Follows the 851/853/855 TGS- rename playbook via the 929/930/933
-- precedent shapes.
--
-- This is a REPURPOSE (the subject changes from generic Javascript to REST API
-- development via AI Vibe Coding), not a pure retitle, so the topic-bearing
-- surfaces (whoshouldattend, trainerprofile, meta_keyword) are rewritten too -
-- see the pre-authoring EAV sweep results noted per section below.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels -> new title
--   2. url_key -> casl-ai-vibe-coding-for-rest-api ; url_path deleted at every
--      scope so the Catalog URL Rewrites indexer regenerates it
--   3. 301 the old slug at the new one (repoint the pre-reindex system row +
--      INSERT IGNORE fallback, both scopes), and repoint every legacy alias
--      rewrite that 301s INTO the old slug (wsq-javascript-programming,
--      wsq-web-design-html-css-course-1089, incl. all their category-prefixed
--      variants) straight at the new bare slug so inbound links take one hop,
--      not a chain
--   4. description -> the new 6-topic Course Outline
--   5. short_description -> the new 4-paragraph About This Course. FULL
--      replace: verified on prod that this course's short_description holds
--      ONLY the intro copy (no "<h2>Course Brochure</h2>" tail - its sections
--      were extracted to per-course cms/block rows in the 2026-07-21 strip), so
--      a splice would silently no-op. Every load-bearing section (Learning
--      Outcomes / Brochure / Skills Framework / Certification / Funding /
--      Funding Validity) lives in cms/block rows keyed on the unchanged SKU.
--   6. meta_keyword refreshed to lead with the new course name
--   7. whoshouldattend -> REST-API-oriented job roles (the old list named the
--      old technology: "Front-End Developer", "Web Designer", "Mobile App
--      Developer (using frameworks like React Native)", "CMS Developer (e.g.,
--      WordPress, Joomla)", "Game Developer (for web-based games)" - surface 10
--      of the rename checklist)
--   8. trainerprofile -> the four bios' SECOND paragraphs are course-teaching
--      claims about Javascript training ("In his JavaScript training...", "In
--      her JavaScript-focused training...") - retargeted at REST API delivery.
--      Their FIRST paragraphs are career-history CREDENTIALS (real Node.js /
--      Vue.js / Firebase experience, Forbes 30 Under 30, polytechnic teaching
--      history) and are left byte-identical - rewriting them would falsify a
--      bio (rename checklist surface 6).
--   9. media gallery per-image label
--
-- meta_title deliberately omits BOTH the leading segment prefix and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time, prepending the funding prefix for any SG TGS- SKU and appending
-- the brand postfix (Block/Html/Head.php). Baking either in yields the
-- duplicated title tag that 853 had to clean up. The old row had BOTH baked in
-- ("CASL Javascript Programming for Beginners - Start Your Coding Journey |
-- Tertiary Courses Singapore") - replaced here.
--
-- NOT rewritten (verified against the DB before authoring):
--   - cms_block course_TGS-2026064472_learning_outcomes: LO1-LO6 already match
--     the requested outcomes verbatim. These are the SSG-accredited outcomes
--     registered against the unchanged SKU and must NOT drift from the course
--     registry - the new REST API topics are delivered against these same
--     outcomes (LO6 "Code Javascript API" is the REST API outcome).
--   - cms_block _brochure / _certification / _skills_framework /
--     _funding_and_grant / _funding_validity: keyed on the unchanged SKU, all
--     topic-neutral, no old-title mention (checked each row's content).
--   - prerequisite: swept for "javascript" - ZERO hits. It holds the funding
--     apparatus (PWM, eligibility table, SkillsFuture/PSEA/SFEC/UTAP deep
--     links, Appeal Process) and is never rewritten wholesale.
--   - additional_note / venue / googlemap / assessment_methods / duration /
--     sessions / price: unchanged by a rename.
--   - Category placements: the course keeps Web Development (4), Javascript
--     (96) and its WSQ/CASL funding + IT categories. The accredited LOs are
--     still Javascript outcomes and REST API development is squarely web
--     development, so no placement is falsified by this rename - unlike a
--     brand-dropping repurpose (cf. 936's Pearson VUE drop).
--   - catalogsearch_query: swept for the old slug AND the bare course code -
--     ZERO rows. The statement below is a guarded no-op kept for the case
--     where prod has rows the local backup lacks (search redirects are DATA -
--     see feedback_search_redirects_always_apply_live).
--
-- Slug-collision check (rename checklist step 3): SG has a non-WSQ twin C428
-- "AI Vibe Coding for REST API" - but its slug is
-- "hands-on-rest-api-development-with-fastapi", NOT the stem used here, so
-- "casl-ai-vibe-coding-for-rest-api" is free. The CASL- prefix additionally
-- keeps this page's rewrites from ever colliding with the twin's.
--
-- The cover PNG and brochure PDF bake the old title - regenerate both on prod
-- after this applies (MMD_CourseImage strips the "CASL - " prefix at render).
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops); rewrite/search statements are
-- additionally guarded on the SG store. Idempotent - re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064472' LIMIT 1);
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
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'description');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');
SET @a_wsa  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'whoshouldattend');
SET @a_tp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'trainerprofile');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'CASL - AI Vibe Coding for REST API' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No segment prefix and no brand suffix - MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'AI Vibe Coding for REST API Training' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'AI Vibe Coding for REST API training in Singapore. Use AI coding assistants to design, build, test and document RESTful APIs - routing, validation, error handling, authentication and database integration. Up to 70% CASL funding subsidy.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'casl-ai-vibe-coding-for-rest-api' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "CASL -" prefix) - they are alt text
-- on the course cover, which itself renders without the prefix (Cover.php
-- cleanTitle strips WSQ/CASL/IBF).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'AI Vibe Coding for REST API' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'AI Vibe Coding for REST API' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'AI Vibe Coding for REST API' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------- 2. url_path at all scopes
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Repoint the existing rewrite row (the system row still holds the old
-- request_path until reindex) and force it permanent + manual; create the row
-- where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'casl-ai-vibe-coding-for-rest-api.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'casl-hands-on-web-app-development-with-javascript.html'
    AND store_id IN (0, 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('casl-hands-on-web-app-development-with-javascript.html'), '-', s.store_id),
       'casl-hands-on-web-app-development-with-javascript.html',
       'casl-ai-vibe-coding-for-rest-api.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'casl-hands-on-web-app-development-with-javascript.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old slug (bare AND category-prefixed
-- targets: wsq-javascript-programming.html and
-- wsq-web-design-html-css-course-1089.html, ~20 rows) - repoint straight at the
-- new bare slug so inbound links take one hop, not a chain. System category
-- rows regenerate + auto-301 on reindex.
UPDATE core_url_rewrite
  SET target_path = 'casl-ai-vibe-coding-for-rest-api.html'
  WHERE @sg = 1 AND @e IS NOT NULL
    AND is_system = 0
    AND target_path LIKE '%casl-hands-on-web-app-development-with-javascript.html'
    AND request_path <> 'casl-hands-on-web-app-development-with-javascript.html';

-- --------------------------------------------- 4. description (Course Outline)
-- New 6-topic outline as provided; authored in the same shape as the row it
-- replaces (h3.course-topic-h3). The old row carried per-topic <ul> bullets;
-- the supplied outline is topic-level only, matching the 933 precedent.
UPDATE catalog_product_entity_text
  SET value = '<h3 class="course-topic-h3">Topic 1: REST API Fundamentals and AI Vibe Coding</h3>\n<h3 class="course-topic-h3">Topic 2: AI-Assisted API Functions, Routing and Security</h3>\n<h3 class="course-topic-h3">Topic 3: Request Handling, Data Validation and JSON Responses</h3>\n<h3 class="course-topic-h3">Topic 4: API Error Handling, Testing and Debugging</h3>\n<h3 class="course-topic-h3">Topic 5: API Architecture, Data Models and Database Integration</h3>\n<h3 class="course-topic-h3">Topic 6: REST API Documentation, Integration and Deployment</h3>'
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_desc AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_desc;

-- ---------------------------------- 5. short_description (About This Course)
-- FULL replace (see header): the four new paragraphs as supplied. Plain UPDATE
-- to a constant - naturally idempotent.
UPDATE catalog_product_entity_text
  SET value = CONCAT(
    '<p>AI Vibe Coding for REST API equips participants with the practical skills to design, build, test and document RESTful APIs using natural-language instructions and AI coding assistants. Instead of writing every line of code manually, learners will describe application requirements, generate API components and iteratively refine the code through AI-assisted development workflows.</p>\n',
    '<p>Participants will learn essential REST API concepts, including resources, endpoints, HTTP methods, request and response structures, status codes and JSON data exchange. The course covers routing, input validation, error handling, authentication and database integration, enabling learners to develop reliable APIs for web, mobile and business applications.</p>\n',
    '<p>Through hands-on exercises, participants will use AI to generate boilerplate code, troubleshoot errors, refactor functions and create automated API tests. They will also learn to review AI-generated code for accuracy, security and maintainability rather than accepting outputs without verification. API documentation, version control and deployment practices are introduced to support effective collaboration and real-world implementation.</p>\n',
    '<p>By the end of the course, participants will be able to transform functional requirements into working REST API services using AI Vibe Coding, validate API behaviour and confidently improve generated solutions through structured prompting, testing and human oversight.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_sd AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_sd;

-- ------------------------------------------------------------ 6. meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'AI Vibe Coding for REST API, REST API training Singapore, AI-assisted API development, vibe coding REST API, RESTful API course, API design and development, CASL REST API course, AI coding assistant API, API testing and documentation, backend API development' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- -------------------------------------------------------- 7. whoshouldattend
-- Rename checklist surface 10: the old job-role list named the OLD technology
-- (Front-End Developer, Web Designer, "Mobile App Developer (using frameworks
-- like React Native)", "CMS Developer (e.g., WordPress, Joomla)", "Game
-- Developer (for web-based games)"). Repointed at REST-API-relevant roles.
-- Full replace to a constant - naturally idempotent.
UPDATE catalog_product_entity_text
  SET value = '<ul>\n<li>Backend Developer</li>\n<li>API Developer</li>\n<li>Full-Stack Developer</li>\n<li>Web Developer</li>\n<li>Software Engineer (looking to expand skill set)</li>\n<li>Mobile App Developer (consuming REST APIs)</li>\n<li>Integration Developer</li>\n<li>Systems Analyst</li>\n<li>DevOps Engineer (supporting API deployment)</li>\n<li>Data Engineer (building data services)</li>\n<li>QA / Test Engineer (API testing)</li>\n<li>Solution Architect (designing API-driven systems)</li>\n<li>IT Specialist (wanting to learn API development)</li>\n<li>Product Manager (wishing to understand technical aspects)</li>\n<li>Tech Start-up Founder</li>\n</ul>'
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_wsa AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_wsa;

-- --------------------------------------------------------- 8. trainerprofile
-- Rename checklist surface 6. Each bio's SECOND paragraph is a course-teaching
-- claim scoped to the old Javascript course; retarget those at REST API
-- delivery. Each bio's FIRST paragraph is career-history CREDENTIALS (genuine
-- Node.js / Vue.js / Firebase / React experience, Forbes 30 Under 30,
-- polytechnic teaching history) and is preserved byte-identically - rewriting
-- it would falsify the bio. Targeted REPLACE() on the exact teaching-claim
-- paragraphs only, so the &ndash; / &nbsp; entities elsewhere survive.
UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    '<p>In his JavaScript training, Shahul emphasizes project-based learning, guiding participants in building interactive and functional web applications. His sessions cover DOM manipulation, event handling, responsive design, and integration with APIs. By blending technical rigor with practical exercises, he ensures learners acquire the confidence to develop web apps that meet professional standards and business requirements.</p>',
    '<p>In his REST API training, Shahul emphasizes project-based learning, guiding participants in designing and building functional API services with AI coding assistants. His sessions cover endpoint design, request handling, data validation, authentication, and integration with client applications. By blending technical rigor with practical exercises, he ensures learners acquire the confidence to develop APIs that meet professional standards and business requirements.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    '<p>In his web app development courses, Fritz emphasizes technical mastery in JavaScript fundamentals and advanced frameworks. He guides learners in building end-to-end applications, from structuring code and handling user interactions to deploying apps on cloud platforms. With his strong software development background and learner-centered teaching style, Fritz equips participants with both the coding skills and problem-solving mindset to succeed in web development.</p>',
    '<p>In his REST API courses, Fritz emphasizes technical mastery in API fundamentals and AI-assisted development workflows. He guides learners in building end-to-end services, from structuring routes and handling requests to deploying APIs on cloud platforms. With his strong software development background and learner-centered teaching style, Fritz equips participants with both the coding skills and problem-solving mindset to succeed in backend development.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    '<p>As a trainer, Afiq emphasizes hands-on, real-world coding experience. He has conducted JavaScript workshops under SGUP programs, teaching learners to build responsive and interactive web apps. His training covers JavaScript fundamentals, asynchronous programming, API integration, and deployment workflows, preparing participants to design and implement modern web applications effectively.</p>',
    '<p>As a trainer, Afiq emphasizes hands-on, real-world coding experience. He has conducted developer workshops under SGUP programs, teaching learners to build reliable and well-structured services. His training covers REST API fundamentals, asynchronous programming, authentication, and deployment workflows, preparing participants to design and implement modern API services effectively.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    '<p>In her JavaScript-focused training, Janice leverages her commercial expertise to teach learners how to enhance websites with interactive and dynamic features. Her courses cover JavaScript basics, form validation, and DOM manipulation, enabling participants to improve user experience and functionality in their web projects. By integrating technical coding with business application insights, Janice equips learners to build professional-grade web applications that align with both user needs and organizational goals.</p>',
    '<p>In her REST API-focused training, Janice leverages her commercial expertise to teach learners how to connect systems and services through well-designed APIs. Her courses cover API basics, request and response handling, and data validation, enabling participants to integrate platforms and automate workflows in their business projects. By integrating technical coding with business application insights, Janice equips learners to build professional-grade API services that align with both user needs and organizational goals.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_tp;

-- ------------------------------------------------ 9. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI Vibe Coding for REST API'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------- 10. search-term redirects
-- Swept local: ZERO rows point at the old slug or the bare course code. Kept as
-- a guarded no-op in case prod holds rows the local backup lacks. REPLACE on
-- the full SG-domain URL - partner-safe (never matches a partner's own slug).
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/casl-hands-on-web-app-development-with-javascript.html', 'https://www.tertiarycourses.com.sg/casl-ai-vibe-coding-for-rest-api.html')
  WHERE redirect LIKE '%casl-hands-on-web-app-development-with-javascript.html%';
