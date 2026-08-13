-- 957: Repurpose TGS-2024042588
--   "WSQ - Microsoft Power Platform Functional Consultant (PL-200)"
--     -> "WSQ - Copilot for Power Automate"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: pivot from the Microsoft PL-200
-- certification track to building natural-language business agents with
-- Copilot Studio driving agentic Power Automate workflows.
--
-- Same shape as 955 (TGS-2023039344).
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope, INCLUDING
-- the store-1 row), meta_title / meta_description / meta_keyword (all three have
-- a store-1 override that would shadow store 0 -- both scopes rewritten),
-- short_description, description (40 PL-200 topics -> the 4 supplied topics;
-- LSN_DATA JSON kept in sync with the visible markup), trainerprofile (all five
-- bios name PL-200 in their teaching paragraph), image/small_image/thumbnail
-- labels, media-gallery label, course_image_url (fresh R2 cover), a 301 for
-- the old bare slug, and category
-- placement (add AI Courses 252; drop the eight Microsoft/Power-Platform-
-- specific listings), mirrored into catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2024042588_learning_outcomes -- the four supplied LOs are
--     BYTE-IDENTICAL to the live block (the admin re-stated the same accredited
--     outcomes). Nothing to write.
--   * course_TGS-2024042588_skills_framework -- Applications Integration
--     ICT-DIT-3003-1.1 still describes the course: LO2 is API-level integration
--     across programs, and Topic 3 is integrating Copilot agents with business
--     data, APIs and applications. The standard holds.
--   * course_TGS-2024042588_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; the fee table and OpenCerts wording are unaffected.
--   * whoshouldattend -- 15 generic developer/analyst/consultant roles; every
--     one still fits a Copilot-for-Power-Automate course.
--   * prerequisite / additional_note -- funding apparatus and logistics. The
--     Power BI Desktop software line stays: Power BI is still part of the
--     Power Platform tooling learners connect agents to.
--   * assessment_methods -- unchanged assessment mode.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * Categories 3 (All Courses), 15 (WSQ and IBF courses), 53 (Software
--     Training), 72/292/293/301/345 (the WSQ listings), 107 (Power Automate),
--     182 (Certification Exam Prep -- the broad parent; the course still carries
--     a WSQ Statement of Achievement) -- they describe the NEW content
--     correctly. 107 in particular is now MORE apt, not less.
--   * badge tags (WSQ / SkillsFuture Credit / PSEA / UTAP / SFEC / MCES /
--     Absentee Payroll) -- funding eligibility is unchanged by a content pivot.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024042588' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_tprof  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_cimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Copilot for Power Automate'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- The live rows carry a store-1 override ("... | Tertiary Courses Singapore",
-- the pre-Seotitle hand-written form) that shadows store 0, so this UPDATE is
-- deliberately NOT scoped to store 0 -- it rewrites both rows.
UPDATE catalog_product_entity_varchar
   SET value = 'Copilot for Power Automate'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to build intelligent business agents with Microsoft Copilot Studio and Power Automate. Covers conversation topics, agentic workflows, API and data integration, approvals, testing, security and governance.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'Copilot for Power Automate, Microsoft Copilot Studio, agentic workflows, business agents, natural language interface, conversation topics, Power Automate flows, workflow automation, API integration, human approval, agentic automation, AI agents, WSQ Copilot course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope (there IS a store-1 row here) so the Catalog
-- URL Rewrites indexer regenerates it; a surviving store-scoped row shadows the
-- new URL.
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-copilot-for-power-automate'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-copilot-for-power-automate.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/<e>', is_system = 1), so a plain INSERT IGNORE silently
-- no-ops against the unique key on (request_path, store_id). Convert that row
-- in place into a permanent redirect instead; the indexer then mints a fresh
-- system row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-copilot-for-power-automate.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-microsoft-power-platform-functional-consultant-pl-200.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2024042588-rp-957-', s.store_id),
       'wsq-microsoft-power-platform-functional-consultant-pl-200.html',
       'wsq-copilot-for-power-automate.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'Copilot for Power Automate'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Copilot for Power Automate'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- The storefront renders course_image_url (an R2 PNG rendered from the title),
-- NOT the image/small_image filesystem paths -- so a repurpose that skips this
-- leaves the OLD branded cover under the NEW title. Re-rendered from the local
-- container with the product's own badge tags (WSQ / SkillsFuture Credit / PSEA
-- / UTAP / SFEC / Absentee Payroll / MCES) and uploaded to the shared R2 bucket;
-- verified HTTP 200 before baking the URL in here.
UPDATE catalog_product_entity_varchar
   SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042588-20260813-040418.png'
 WHERE entity_id = @e AND attribute_id = @a_cimg AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. The 40 PL-200 topics (each with an <em> subsection
-- list) are replaced wholesale by the four supplied topics -- topic-level only,
-- so subsecs are empty. Four topics -- matches LO1-LO4.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Designing Natural-Language Business Agents with Copilot Studio","subsecs":[]},{"title":"Topic 2: Building Agentic Workflows with Power Automate","subsecs":[]},{"title":"Topic 3: Integrating Copilot Agents with Business Data, APIs and Applications","subsecs":[]},{"title":"Topic 4: Testing, Securing and Optimizing Agentic Automation Solutions","subsecs":[]}] -->
<p><strong>Topic 1: Designing Natural-Language Business Agents with Copilot Studio</strong></p>
<p><strong>Topic 2: Building Agentic Workflows with Power Automate</strong></p>
<p><strong>Topic 3: Integrating Copilot Agents with Business Data, APIs and Applications</strong></p>
<p><strong>Topic 4: Testing, Securing and Optimizing Agentic Automation Solutions</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Full replace: the live short_description carries two Microsoft-partner tails
-- ("Microsoft Learning Partner" Org ID + "Certification Exam at Pearson Vue"
-- with a PL-200 registration deep link and an exam-voucher cross-sell). Both
-- are dead once the course stops preparing learners for the PL-200 exam, so the
-- whole attribute is replaced with the supplied prose. No <h2>Course Brochure</h2>
-- tail here (that lives in the _brochure cms/block), so nothing else is lost.
UPDATE catalog_product_entity_text
   SET value = '<p>Copilot for Power Automate equips participants with practical skills to build intelligent business agents using Microsoft Copilot Studio and Power Automate. Participants will learn to create a natural-language interface that allows users to ask questions, submit requests, retrieve information, and initiate business processes through conversational interactions.</p>
<p>The course focuses on connecting Copilot Studio agents to Power Automate workflows that perform agentic tasks across business systems. These tasks may include processing forms, sending notifications, updating records, generating documents, requesting approvals, retrieving data, and coordinating multi-step workflows. Participants will learn to design conversation topics, manage variables, collect user inputs, trigger automated flows, and return relevant results to users.</p>
<p>Through hands-on activities, learners will develop end-to-end agentic automation solutions that combine natural-language interaction, decision logic, workflow automation, and AI-generated responses. The course also covers API and data integration, error handling, human approval checkpoints, testing, security, governance, and workflow monitoring. By the end of the course, participants will be able to create Copilot Studio agents that understand user requests and use Power Automate to complete practical business tasks securely and efficiently.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------- 7. Learning Outcomes
-- INTENTIONALLY NOT WRITTEN. The supplied LO1-LO4 are byte-identical to the
-- live course_TGS-2024042588_learning_outcomes block (Dataverse/Power App
-- feasibility, Business Flow + Power Automate API integration, Power Virtual
-- Agent + Power BI testing, Power AI Builder modifications). The accredited
-- outcomes are unchanged by this content pivot, which is why the
-- ICT-DIT-3003-1.1 Applications Integration standard also stays.

-- -------------------------------------------------------- 8. Trainer bios
-- Five bios, each two paragraphs: para 1 = career CREDENTIALS -- FACTS, left
-- untouched (the Microsoft/Azure/PMP certifications the trainers actually hold
-- stay accurate). Para 2 = a course-teaching claim, and ALL FIVE open with
-- 'In "Microsoft Power Platform Functional Consultant (PL-200),"' -- every one
-- is retargeted to the new subject.
-- Single-line REPLACE() on the full paragraph string (a multi-line pattern
-- no-ops against the WYSIWYG blob's CRLF line endings). Each pattern below was
-- LOCATE()-probed against live data before writing.

-- Sanjiv Venkatram
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Power Platform Functional Consultant (PL-200),&rdquo; Sanjiv provides practical insights into automating business processes, building model-driven apps, and integrating Power BI analytics within enterprise environments. His sessions emphasize security, governance, and scalability, helping participants design robust Power Platform solutions aligned with modern organizational needs.',
       'In this course, Sanjiv provides practical insights into designing Copilot Studio agents, automating business processes with Power Automate, and integrating agentic workflows across enterprise systems. His sessions emphasize security, governance, and scalability, helping participants design robust agentic automation solutions aligned with modern organizational needs.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Eugene Wong
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Power Platform Functional Consultant (PL-200),&rdquo; Eugene focuses on enabling learners to design end-to-end low-code applications and automate business processes. His training integrates real-world use cases that demonstrate how data visualization and automation can enhance productivity and operational transparency. He empowers participants to apply Microsoft Power Platform tools effectively to drive organizational efficiency and innovation.',
       'In this course, Eugene focuses on enabling learners to design end-to-end agentic automation solutions and natural-language business agents. His training integrates real-world use cases that demonstrate how conversational interfaces and workflow automation can enhance productivity and operational transparency. He empowers participants to apply Copilot Studio and Power Automate effectively to drive organizational efficiency and innovation.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Bernard Peh
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Power Platform Functional Consultant (PL-200),&rdquo; Bernard guides participants through building and deploying Power Apps, Power Automate workflows, and Power BI dashboards. His sessions emphasize solution design, integration with Microsoft Dataverse, and governance best practices. Through hands-on exercises, he equips professionals with the ability to deliver scalable, low-code business applications that streamline operations and improve decision-making.',
       'In this course, Bernard guides participants through building and deploying Copilot Studio agents and the Power Automate workflows behind them. His sessions emphasize conversation design, integration with business data and APIs, and governance best practices. Through hands-on exercises, he equips professionals with the ability to deliver scalable agentic automation that streamlines operations and improves decision-making.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Truman Ng
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Power Platform Functional Consultant (PL-200),&rdquo; Truman focuses on teaching participants how to design secure, high-performance Power Platform solutions within hybrid environments. His sessions cover system integration, data security, and automation orchestration. Through his systems-engineering approach, he enables learners to design intelligent workflows that optimize operations and drive digital transformation.',
       'In this course, Truman focuses on teaching participants how to design secure, high-performance agentic automation within hybrid environments. His sessions cover API and system integration, data security, human approval checkpoints, and automation orchestration. Through his systems-engineering approach, he enables learners to design intelligent workflows that optimize operations and drive digital transformation.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Audrey Lin
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Power Platform Functional Consultant (PL-200),&rdquo; Audrey teaches participants how to design Power Apps, automate workflows with Power Automate, and integrate insights from Power BI. Her sessions focus on problem-solving, process optimization, and data visualization. Drawing from her project management and instructional experience, she helps learners confidently apply Power Platform tools to analyze business needs and implement scalable, user-focused digital solutions.',
       'In this course, Audrey teaches participants how to design Copilot Studio conversation topics, automate the work behind them with Power Automate, and return useful results to users. Her sessions focus on problem-solving, process optimization, and testing. Drawing from her project management and instructional experience, she helps learners confidently apply Copilot Studio and Power Automate to analyze business needs and implement scalable, user-focused agentic solutions.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 9. Category placement
-- The repurpose changes the SUBJECT: the course is no longer a Microsoft
-- Power Platform certification track and no longer prepares learners for the
-- PL-200 exam, so drop the eight Microsoft/Power-Platform-specific listings:
--    11 "Microsoft"                        218 "Power Platform"
--   135 "Microsoft Certification Exam Prep" 233 "Power Apps"
--   358 "Microsoft Certification Exam Prep" 326 "Power BI"
--   413 "Power Platform Certification"       53 "Software Training"
-- and join 252 "AI Courses", the master listing every AI course belongs to.
-- 107 "Power Automate" STAYS -- Power Automate is now the core of the course.
-- The WSQ listings (15, 72, 292, 293, 301, 345), the broad 182 "Certification
-- Exam Prep" parent and 3 "All Courses" all stay -- they describe the NEW
-- content correctly.
-- Both sides mirrored into catalog_category_product_index or the storefront
-- listings never change.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (11, 53, 135, 218, 233, 326, 358, 413) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (11, 53, 135, 218, 233, 326, 358, 413) AND @e IS NOT NULL;

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
